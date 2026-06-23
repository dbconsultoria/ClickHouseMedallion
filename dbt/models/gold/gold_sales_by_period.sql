{{ config(
    materialized = 'table',
    engine       = 'MergeTree()',
    order_by     = '(year, month)'
) }}

WITH monthly AS (
    SELECT
        toYear(o.order_date)                        AS year,
        toMonth(o.order_date)                       AS month,
        formatDateTime(o.order_date, '%Y-%m')       AS period,
        countDistinct(o.code)                       AS total_orders,
        SUM(od.quantity * od.sale_value)            AS total_revenue
    FROM {{ ref('silver_orders') }} AS o
    JOIN {{ ref('silver_order_details') }} AS od
        ON od.orders_code = o.code
    GROUP BY year, month, period
),

with_lag AS (
    SELECT
        year,
        month,
        period,
        total_orders,
        total_revenue,
        -- lagInFrame é a função correta do ClickHouse para LAG em window functions.
        -- LAG padrão ANSI não existe no ClickHouse — lagInFrame requer frame explícito.
        -- Retorna 0 (default Decimal) quando não há linha anterior (primeiro mês).
        lagInFrame(total_revenue) OVER (
            ORDER BY year, month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                           AS _prev_revenue
    FROM monthly
)

SELECT
    year,
    month,
    period,
    total_orders,
    total_revenue,
    -- _prev_revenue = 0 indica primeiro mês (sem linha anterior): exposto como NULL
    if(_prev_revenue = 0, NULL, _prev_revenue)      AS prev_month_revenue,
    if(
        _prev_revenue = 0,
        NULL,
        ROUND(
            (toFloat64(total_revenue) - toFloat64(_prev_revenue))
            / toFloat64(_prev_revenue) * 100,
            2
        )
    )                                               AS mom_growth_pct
FROM with_lag
ORDER BY year, month
