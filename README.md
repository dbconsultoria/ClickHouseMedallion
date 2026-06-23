# ClickHouse Medallion Architecture — Bronze Layer

Local implementation of the Bronze layer of a Medallion architecture using MySQL as the source, Airbyte OSS for ingestion, and ClickHouse as the destination.

---

## Stack

| Technology | Version | Role |
|---|---|---|
| MySQL | 8.0 | Source database (external, running on Docker) |
| ClickHouse | 24.8 | Bronze layer analytical store |
| Airbyte OSS | 0.50.33 | ELT ingestion pipeline |

---

## Directory Structure

```
ClickHouseMedallion/
├── clickhouse/
│   └── docker-compose.yml        # ClickHouse + medallion_net network
├── airbyte/
│   ├── docker-compose.yml        # Airbyte OSS (7 services)
│   └── config/
│       └── dynamicconfig/
│           └── development.yaml  # Temporal dynamic config (required)
└── README.md
```

---

## Endpoints

| Service | URL / Address | Notes |
|---|---|---|
| **Airbyte UI** | http://localhost:8000 | Main dashboard |
| **Airbyte API** | http://localhost:8001/api/v1/health | REST API |
| **ClickHouse HTTP** | http://localhost:8123 | HTTP interface |
| **ClickHouse SQL Playground** | http://localhost:8123/play | Built-in web UI to run queries |
| **ClickHouse Native** | localhost:9000 | Native TCP (clickhouse-client) |
| **MySQL (source)** | localhost:3306 | External source, not managed here |

---

## Docker Networks

Two bridge networks with **explicit subnets** to avoid Docker auto-assignment overlap:

| Network | Subnet | Owner |
|---|---|---|
| `medallion_net` | `172.30.0.0/24` | ClickHouse compose — shared across stacks |
| `airbyte_internal` | `172.31.0.0/24` | Airbyte compose — internal service bus |

> **Critical**: explicit subnets are required. Without them Docker assigns overlapping ranges, causing nginx `EHOSTUNREACH (113)` errors between Airbyte webapp and server.

---

## Starting the Stack

**Order matters — ClickHouse must start first** (it creates `medallion_net`).

```bash
# 1. Start ClickHouse (creates medallion_net)
docker compose -f clickhouse/docker-compose.yml up -d

# 2. Wait for ClickHouse to be healthy
docker inspect --format='{{.State.Health.Status}}' clickhouse

# 3. Start Airbyte (joins medallion_net as external)
docker compose -f airbyte/docker-compose.yml up -d

# 4. Wait for Airbyte server (~30–60 s)
curl http://localhost:8001/api/v1/health
```

---

## Stopping the Stack

```bash
# Stop Airbyte first
docker compose -f airbyte/docker-compose.yml down

# Then stop ClickHouse
docker compose -f clickhouse/docker-compose.yml down
```

To also remove volumes (wipes all data):
```bash
docker compose -f airbyte/docker-compose.yml down -v
docker compose -f clickhouse/docker-compose.yml down -v
```

---

## ClickHouse — SQL Playground

Open **http://localhost:8123/play** in your browser to run SQL queries directly against ClickHouse.

Useful queries:

```sql
-- List all Bronze tables with row counts
SELECT name, engine, total_rows
FROM system.tables
WHERE database = 'bronze'
ORDER BY name;

-- Preview any table
SELECT * FROM bronze.tbproducts LIMIT 10;
SELECT * FROM bronze.tbcategories LIMIT 10;
SELECT * FROM bronze.tbcustomers LIMIT 10;
SELECT * FROM bronze.tborders LIMIT 10;
SELECT * FROM bronze.tborderdetail LIMIT 10;
```

---

## ClickHouse — Bronze Database Setup

Only the **database** needs to be created manually. Airbyte creates and manages all tables automatically on first sync.

```sql
CREATE DATABASE IF NOT EXISTS bronze;
```

Run this at http://localhost:8123/play before the first Airbyte sync.

---

## Airbyte — UI Configuration

### First-run setup
Open http://localhost:8000, enter your email and organization name.

### 1. MySQL Source

**Sources → + New source → MySQL**

| Field | Value |
|---|---|
| Host | `host.docker.internal` |
| Port | `3306` |
| Database | `mydb` |
| Username | `myusr` |
| Password | `mypswd` |
| Update method | Scan Changes with User Defined Cursor |

> Use `host.docker.internal` (not `localhost`) so the connector container can reach MySQL running on the Docker host.

### 2. ClickHouse Destination

**Destinations → + New destination → ClickHouse**

| Field | Value |
|---|---|
| Host | `clickhouse` |
| Port | `8123` |
| Database | `bronze` |
| Username | `default` |
| Password | *(blank)* |
| SSL | off |

> Use the container name `clickhouse` (not `localhost`) — works because all Airbyte services join `medallion_net`.

### 3. Connections (one per table)

**Connections → + New connection → select existing source + destination**

| Setting | Value |
|---|---|
| Streams | Enable all 5 tables |
| Sync mode | Full Refresh \| Overwrite |
| Normalization | Normalized tabular data |
| Schedule | Every 24 hours |

Tables synced: `tbcategories`, `tbproducts`, `tbcustomers`, `tborders`, `tborderdetail`

---

## What Airbyte Creates in ClickHouse

For each table Airbyte creates two objects:

### Normalized tables (use these for queries)
`bronze.tbcategories`, `bronze.tbproducts`, etc.
- Source columns as `Nullable` types
- `_airbyte_ab_id` — row UUID assigned by Airbyte
- `_airbyte_emitted_at` — ingestion timestamp (equivalent to `_ingested_at`)
- `_airbyte_normalized_at` — normalization timestamp
- `_airbyte_<table>_hashid` — row hash for dedup

### Raw staging tables (Airbyte internal — do not modify)
`bronze._airbyte_raw_tbcategories`, etc.
- `_airbyte_ab_id` — row UUID
- `_airbyte_data` — full source row as JSON string
- `_airbyte_emitted_at` — ingestion timestamp

---

## Non-Obvious Configuration Requirements

These issues were discovered during setup and are documented here to avoid repeating them.

### 1. Airbyte version must be 0.50.33
Versions 0.58+ require a Keycloak service for authentication. The docker-compose approach without Keycloak only works on 0.50.x.

### 2. Flyway migration version env vars are required (no defaults)
The server and worker crash at startup without these:
```yaml
CONFIGS_DATABASE_MINIMUM_FLYWAY_MIGRATION_VERSION: 0.35.15.001
JOBS_DATABASE_MINIMUM_FLYWAY_MIGRATION_VERSION: 0.29.15.001
```

### 3. Worker internal API host env var name
The property is `INTERNAL_API_HOST`, **not** `AIRBYTE_INTERNAL_API_HOST`:
```yaml
INTERNAL_API_HOST: airbyte-server:8001
```

### 4. Docker API version mismatch on Docker Desktop
The worker image ships Docker CLI 1.41 but Docker Desktop requires API ≥ 1.44:
```yaml
DOCKER_API_VERSION: "1.44"
```

### 5. Temporal requires a dynamic config file
`temporalio/auto-setup` crashes if the path in `DYNAMIC_CONFIG_FILE_PATH` doesn't exist. The file must be bind-mounted:
```yaml
DYNAMIC_CONFIG_FILE_PATH: /etc/temporal/dynamicconfig/development.yaml
volumes:
  - ./config/dynamicconfig/development.yaml:/etc/temporal/dynamicconfig/development.yaml:ro
```

### 6. Webapp nginx requires KEYCLOAK_INTERNAL_HOST to resolve
Even without Keycloak, nginx fails to start if the upstream host doesn't resolve. Any running container name works as a placeholder:
```yaml
KEYCLOAK_INTERNAL_HOST: airbyte-db
```

### 7. Webapp nginx requires TRACKING_STRATEGY
The nginx template injects this into the page via `sub_filter`. Without it, nginx crashes with `unknown variable`:
```yaml
TRACKING_STRATEGY: logging
```

### 8. Connector containers need DOCKER_NETWORK to reach ClickHouse
Airbyte spawns connector containers via the Docker socket. To make them resolve the `clickhouse` hostname they must be placed on `medallion_net`:
```yaml
DOCKER_NETWORK: medallion_net
```

---

## Source Schema Reference

| Table | Columns |
|---|---|
| `tbcategories` | `code INT PK`, `description VARCHAR(150)` |
| `tbproducts` | `code INT PK`, `description VARCHAR(150)`, `salevalue DECIMAL(18,2)`, `active INT`, `category INT FK` |
| `tbcustomers` | `code INT PK`, `Name VARCHAR(100)`, `Address VARCHAR(250)`, `Phone VARCHAR(25)`, `Email VARCHAR(100)`, `BirthDate DATETIME` |
| `tborders` | `code INT PK`, `customer INT FK`, `orderdate TIMESTAMP` |
| `tborderdetail` | `product INT FK`, `orders INT FK`, `quantity INT`, `salesvalue DECIMAL(18,2)` |
