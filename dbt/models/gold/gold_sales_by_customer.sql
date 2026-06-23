{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(customer_email)'
) }}

SELECT
    o.customer_name,
    o.customer_email,
    countDistinct(o.code)                                           AS total_orders,
    SUM(od.quantity * od.sale_value)                                AS total_revenue,
    ROUND(
        toFloat64(SUM(od.quantity * od.sale_value)) / countDistinct(o.code),
        2
    )                                                               AS avg_order_value,
    MIN(o.order_date)                                               AS first_order_date,
    MAX(o.order_date)                                               AS last_order_date,
    -- dateDiff retorna 0 para clientes com apenas um pedido (first = last)
    dateDiff('day', MIN(o.order_date), MAX(o.order_date))           AS days_as_customer
FROM {{ ref('silver_orders') }} AS o
JOIN {{ ref('silver_order_details') }} AS od
    ON od.orders_code = o.code
GROUP BY
    o.customer_name,
    o.customer_email
