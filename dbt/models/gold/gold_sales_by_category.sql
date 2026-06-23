{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(category_description)'
) }}

WITH aggregated AS (
    SELECT
        p.category_description,
        countDistinct(od.product_code)              AS total_products_sold,
        SUM(od.quantity)                            AS total_quantity,
        SUM(od.quantity * od.sale_value)            AS total_revenue
    FROM {{ ref('silver_order_details') }} AS od
    JOIN {{ ref('silver_products') }} AS p
        ON od.product_code = p.code
    GROUP BY p.category_description
)

SELECT
    category_description,
    total_products_sold,
    total_quantity,
    total_revenue,
    -- ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING garante que o
    -- SUM cubra todas as linhas do resultado, independente da linha atual
    ROUND(
        toFloat64(total_revenue)
        / toFloat64(SUM(total_revenue) OVER (
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )) * 100,
        2
    )                                               AS revenue_share_pct
FROM aggregated
