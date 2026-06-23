{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(order_date, order_code)'
) }}

SELECT
    o.code                                                          AS order_code,
    o.order_date,
    o.customer_name,
    o.customer_email,
    SUM(od.quantity)                                                AS total_items,
    SUM(od.quantity * od.sale_value)                                AS total_revenue,
    -- toFloat64 antes da divisão evita erros de tipo Decimal ÷ Int no ClickHouse
    ROUND(
        toFloat64(SUM(od.quantity * od.sale_value)) / SUM(od.quantity),
        2
    )                                                               AS avg_item_value
FROM {{ ref('silver_orders') }} AS o
JOIN {{ ref('silver_order_details') }} AS od
    ON od.orders_code = o.code
GROUP BY
    o.code,
    o.order_date,
    o.customer_name,
    o.customer_email
