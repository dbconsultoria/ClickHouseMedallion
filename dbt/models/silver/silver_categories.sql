{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(code)'
) }}

SELECT
    toInt32(assumeNotNull(code))        AS code,
    coalesce(description, '')           AS description,
    _airbyte_emitted_at                 AS _ingested_at,
    _airbyte_normalized_at              AS _normalized_at
FROM {{ source('bronze', 'tbcategories') }}
WHERE code IS NOT NULL
