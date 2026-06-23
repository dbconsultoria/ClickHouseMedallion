
  
    
    
    
        
         


        
  

  insert into `silver`.`silver_categories`
        ("code", "description", "_ingested_at", "_normalized_at")

SELECT
    toInt32(assumeNotNull(code))        AS code,
    coalesce(description, '')           AS description,
    _airbyte_emitted_at                 AS _ingested_at,
    _airbyte_normalized_at              AS _normalized_at
FROM `bronze`.`tbcategories`
WHERE code IS NOT NULL
  