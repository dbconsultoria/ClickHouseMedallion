{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(product_code)'
) }}

SELECT
    od.product_code,
    -- silver_products.description = nome do produto; renomeado para clareza na Gold
    p.description                                                   AS product_description,
    p.category_description,
    p.is_active,
    countDistinct(od.orders_code)                                   AS total_orders,
    SUM(od.quantity)                                                AS total_quantity,
    SUM(od.quantity * od.sale_value)                                AS total_revenue,
    ROUND(
        toFloat64(SUM(od.quantity * od.sale_value)) / SUM(od.quantity),
        2
    )                                                               AS avg_sale_value
FROM {{ ref('silver_order_details') }} AS od
JOIN {{ ref('silver_products') }} AS p
    ON od.product_code = p.code
GROUP BY
    od.product_code,
    p.description,
    p.category_description,
    p.is_active
