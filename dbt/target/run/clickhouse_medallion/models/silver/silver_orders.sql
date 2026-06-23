
  
    
    
    
        
         


        
  

  insert into `silver`.`silver_orders`
        ("code", "customer_code", "customer_name", "customer_email", "order_date", "_ingested_at", "_normalized_at")

SELECT
    toInt32(assumeNotNull(o.code))                  AS code,
    toInt32(assumeNotNull(o.customer))              AS customer_code,
    coalesce(c.name, '')                            AS customer_name,
    coalesce(c.email, '')                           AS customer_email,
    toDateTime(assumeNotNull(o.orderdate))          AS order_date,
    o._airbyte_emitted_at                           AS _ingested_at,
    o._airbyte_normalized_at                        AS _normalized_at
FROM `bronze`.`tborders` AS o
-- ref() usa silver_customers (já limpa e com snake_case) em vez de bronze.tbcustomers
LEFT JOIN `silver`.`silver_customers` AS c
    ON toInt32(assumeNotNull(o.customer)) = c.code
WHERE o.code IS NOT NULL
  