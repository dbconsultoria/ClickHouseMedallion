

SELECT
    toInt32(assumeNotNull(od.orders))                       AS orders_code,
    toInt32(assumeNotNull(od.product))                      AS product_code,
    coalesce(p.description, '')                             AS product_description,
    -- sale_value = preço unitário do produto no momento da consulta (vem do Silver)
    coalesce(p.sale_value, CAST(0 AS Decimal(18, 2)))       AS sale_value,
    toInt32(assumeNotNull(od.quantity))                     AS quantity,
    -- line_total = valor total da linha conforme registrado no pedido (bronze.salesvalue)
    CAST(coalesce(od.salesvalue, 0) AS Decimal(18, 2))      AS line_total,
    od._airbyte_emitted_at                                  AS _ingested_at,
    od._airbyte_normalized_at                               AS _normalized_at
FROM `bronze`.`tborderdetail` AS od
-- ref() usa silver_products para ter sale_value já como Decimal(18,2),
-- evitando reconverter Float64 da Bronze duas vezes
LEFT JOIN `silver`.`silver_products` AS p
    ON toInt32(assumeNotNull(od.product)) = p.code
WHERE od.orders IS NOT NULL
  AND od.product IS NOT NULL