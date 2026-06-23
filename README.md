# ClickHouse Medallion Architecture, Airbyte/dbt/clickhouse

Local implementation of a Medallion architecture with Bronze and Silver layers. MySQL is the source, Airbyte OSS handles ingestion into ClickHouse (Bronze), and dbt transforms and enriches the data into the Silver layer.

**Author:** Rodrigo Ribeiro — [LinkedIn](https://www.linkedin.com/in/rodrigo-ribeiro-pro/) · [Portfolio](https://dbconsultoria.github.io/)

---

## Stack

| Technology | Version | Role |
|---|---|---|
| MySQL | 8.0 | Source database (external, running on Docker) |
| Airbyte OSS | 0.50.33 | ELT ingestion pipeline (MySQL → Bronze) |
| ClickHouse | 24.8 | Analytical store — Bronze and Silver layers |
| dbt-core | 1.11.11 | Silver layer transformations |
| dbt-clickhouse | 1.10.1 | dbt adapter for ClickHouse |

---

## Directory Structure

```
ClickHouseMedallion/
├── clickhouse/
│   └── docker-compose.yml             # ClickHouse + medallion_net network
├── airbyte/
│   ├── docker-compose.yml             # Airbyte OSS (7 services)
│   └── config/
│       └── dynamicconfig/
│           └── development.yaml       # Temporal dynamic config (required)
├── dbt/                               # Silver layer — dbt project
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── macros/
│   │   └── generate_schema_name.sql   # Overrides default schema naming
│   └── models/
│       ├── sources.yml                # Bronze source declarations
│       └── silver/
│           ├── schema.yml             # Documentation and data tests
│           ├── silver_categories.sql
│           ├── silver_products.sql
│           ├── silver_customers.sql
│           ├── silver_orders.sql
│           └── silver_order_details.sql
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

## stack.sh — Automation Script

All stack operations are managed by `stack.sh` at the project root.

```bash
chmod +x stack.sh   # first time only

./stack.sh up               # start ClickHouse + Airbyte (with health checks)
./stack.sh down             # stop the stack
./stack.sh restart          # stop + start
./stack.sh status           # container status for both composes
./stack.sh health           # HTTP health check on all 4 endpoints
./stack.sh dbt              # run full dbt pipeline (debug → Silver → Gold → test)
./stack.sh logs             # tail logs: clickhouse + airbyte-server + airbyte-worker
./stack.sh logs airbyte-server  # tail logs for a specific service
./stack.sh reset            # remove all volumes and restart (DESTRUCTIVE)
./stack.sh help             # show all commands
```

`up` handles startup order automatically: ClickHouse first (creates `medallion_net`), waits for healthy, creates `bronze` database, then starts Airbyte and waits for the API.

`dbt` creates the Python virtualenv and installs `dbt-core` + `dbt-clickhouse` on first run.

---

## Starting the Stack (manual)

If not using `stack.sh`, order matters — ClickHouse must start first (it creates `medallion_net`).

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

## Silver Layer — dbt

The Silver layer cleans, types, and enriches the Bronze tables. It is managed entirely by dbt and writes to the `silver` database in ClickHouse.

### What dbt does per table

| Silver table | Source | Transformations |
|---|---|---|
| `silver.silver_categories` | `bronze.tbcategories` | Types, remove Nullable, snake_case |
| `silver.silver_products` | `bronze.tbproducts` | Types, `active → is_active (Bool)`, `salevalue → Decimal(18,2)`, JOIN → `category_description` |
| `silver.silver_customers` | `bronze.tbcustomers` | Types, column rename to snake_case (`Name → name`, etc.), `BirthDate → birth_date (Date)` |
| `silver.silver_orders` | `bronze.tborders` | Types, JOIN → `customer_name`, `customer_email` |
| `silver.silver_order_details` | `bronze.tborderdetail` | Types, JOIN → `product_description`, `sale_value`, adds `line_total` |

All Silver tables include audit columns `_ingested_at` and `_normalized_at` (renamed from Airbyte metadata). Airbyte internal columns (`_airbyte_ab_id`, hashids) are dropped.

### DAG — full pipeline (Bronze → Silver → Gold)

```
bronze.tbcategories ──► silver_categories ──┐
                                             ├──► silver_products ──┬──► gold_sales_by_product
bronze.tbproducts ───────────────────────────┘                      │    gold_sales_by_category
                                                                     │
bronze.tbcustomers ──► silver_customers ──┐                         │
                                          ├──► silver_orders ───────┼──► gold_order_summary
bronze.tborders ──────────────────────────┘                         │    gold_sales_by_customer
                                                                     │    gold_sales_by_period
bronze.tborderdetail ──► silver_order_details ──────────────────────┘
```

### Running dbt

```bash
cd dbt/

# First time: install dependencies
pip install dbt-core dbt-clickhouse

# Validate config and ClickHouse connection
dbt debug --profiles-dir .

# Materialize all layers (Silver + Gold, in DAG order)
dbt run --profiles-dir .

# Run data quality tests (48 tests across Silver and Gold)
dbt test --profiles-dir .

# Run only one layer
dbt run --profiles-dir . --select silver
dbt run --profiles-dir . --select gold

# Run a single model and its upstream dependencies
dbt run --profiles-dir . --select +gold_sales_by_product

# Re-run after a Bronze sync (full refresh)
dbt run --profiles-dir . --full-refresh
```

### Known ClickHouse limitation

The dbt built-in `accepted_values` test generates `NOT IN (UNION ALL subquery)`, which ClickHouse 24.8 does not support (`UNSUPPORTED_METHOD`). For `Bool` columns like `is_active` this test is omitted — the type system already enforces valid values.

### Silver queries

```sql
-- Check all Silver tables
SELECT name, engine, total_rows
FROM system.tables
WHERE database = 'silver'
ORDER BY name;

-- Products with category
SELECT code, description, sale_value, is_active, category_description
FROM silver.silver_products
LIMIT 10;

-- Orders with customer data
SELECT code, customer_name, customer_email, order_date
FROM silver.silver_orders
LIMIT 10;

-- Order details with product data
SELECT orders_code, product_description, quantity, sale_value, line_total
FROM silver.silver_order_details
LIMIT 10;
```

---

## Gold Layer — dbt

The Gold layer aggregates and enriches Silver data into analytical marts ready for consumption. It writes to the `gold` database in ClickHouse.

### Models

| Gold table | Description | Key metrics |
|---|---|---|
| `gold.gold_order_summary` | One row per order | `total_items`, `total_revenue`, `avg_item_value` |
| `gold.gold_sales_by_product` | Revenue and volume per product | `total_orders`, `total_quantity`, `total_revenue`, `avg_sale_value` |
| `gold.gold_sales_by_category` | Revenue per category with share % | `total_products_sold`, `total_revenue`, `revenue_share_pct` |
| `gold.gold_sales_by_customer` | LTV and behaviour per customer | `total_orders`, `total_revenue`, `avg_order_value`, `days_as_customer` |
| `gold.gold_sales_by_period` | Monthly revenue with MoM growth | `total_orders`, `total_revenue`, `prev_month_revenue`, `mom_growth_pct` |

### Gold queries

```sql
-- Check all Gold tables
SELECT name, engine, total_rows
FROM system.tables
WHERE database = 'gold'
ORDER BY name;

-- Order summary
SELECT order_code, order_date, customer_name, total_items, total_revenue, avg_item_value
FROM gold.gold_order_summary
ORDER BY order_date DESC
LIMIT 10;

-- Top products by revenue
SELECT product_description, category_description, total_orders, total_revenue
FROM gold.gold_sales_by_product
ORDER BY total_revenue DESC
LIMIT 10;

-- Category revenue share
SELECT category_description, total_revenue, revenue_share_pct
FROM gold.gold_sales_by_category
ORDER BY total_revenue DESC;

-- Top customers by LTV
SELECT customer_name, total_orders, total_revenue, avg_order_value, days_as_customer
FROM gold.gold_sales_by_customer
ORDER BY total_revenue DESC
LIMIT 10;

-- Monthly revenue with MoM growth
SELECT period, total_orders, total_revenue, prev_month_revenue, mom_growth_pct
FROM gold.gold_sales_by_period
ORDER BY year, month;
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
