{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(code)'
) }}

SELECT
    toInt32(assumeNotNull(p.code))                       AS code,
    coalesce(p.description, '')                          AS description,
    -- Airbyte mapeia DECIMAL → Float64; reconvertemos para Decimal(18,2)
    CAST(coalesce(p.salevalue, 0) AS Decimal(18, 2))     AS sale_value,
    assumeNotNull(p.active) = 1                          AS is_active,
    toInt32(assumeNotNull(p.category))                   AS category_code,
    coalesce(c.description, '')                          AS category_description,
    p._airbyte_emitted_at                                AS _ingested_at,
    p._airbyte_normalized_at                             AS _normalized_at
FROM {{ source('bronze', 'tbproducts') }} AS p
-- ref() em vez de source() para aproveitar a limpeza já feita em silver_categories
-- e criar dependência explícita no DAG do dbt
LEFT JOIN {{ ref('silver_categories') }} AS c
    ON toInt32(assumeNotNull(p.category)) = c.code
WHERE p.code IS NOT NULL
