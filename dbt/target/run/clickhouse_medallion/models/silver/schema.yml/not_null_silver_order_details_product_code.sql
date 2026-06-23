
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select product_code
from `silver`.`silver_order_details`
where product_code is null



  
  
    ) dbt_internal_test