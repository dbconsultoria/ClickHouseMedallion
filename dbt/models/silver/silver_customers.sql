{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(code)'
) }}

SELECT
    toInt32(assumeNotNull(code))        AS code,
    coalesce(Name, '')                  AS name,
    coalesce(Address, '')               AS address,
    coalesce(Phone, '')                 AS phone,
    coalesce(Email, '')                 AS email,
    -- BirthDate é opcional na fonte; mantemos Nullable(Date) na Silver
    toDate(BirthDate)                   AS birth_date,
    _airbyte_emitted_at                 AS _ingested_at,
    _airbyte_normalized_at              AS _normalized_at
FROM {{ source('bronze', 'tbcustomers') }}
WHERE code IS NOT NULL
