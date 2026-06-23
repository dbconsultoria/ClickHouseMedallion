
  
    
    
    
        
         


        
  

  insert into `silver`.`silver_customers`
        ("code", "name", "address", "phone", "email", "birth_date", "_ingested_at", "_normalized_at")

SELECT
    toInt32(assumeNotNull(code))        AS code,
    coalesce(Name, '')                  AS name,
    coalesce(Address, '')               AS address,
    coalesce(Phone, '')                 AS phone,
    coalesce(Email, '')                 AS email,
    -- BirthDate é opcional na fonte; mantemos Nullable(Date) na Silver
    toDate(BirthDate)                   AS birth_date,
    _airbyte_emitted_at                 AS _ingested_at,
    _airbyte_normalized_at              AS _normalized_at
FROM `bronze`.`tbcustomers`
WHERE code IS NOT NULL
  