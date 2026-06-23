
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select category_code
from `silver`.`silver_products`
where category_code is null



  
  
    ) dbt_internal_test