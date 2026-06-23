
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select category_description
from `silver`.`silver_products`
where category_description is null



  
  
    ) dbt_internal_test