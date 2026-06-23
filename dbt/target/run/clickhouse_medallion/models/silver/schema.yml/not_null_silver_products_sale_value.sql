
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sale_value
from `silver`.`silver_products`
where sale_value is null



  
  
    ) dbt_internal_test