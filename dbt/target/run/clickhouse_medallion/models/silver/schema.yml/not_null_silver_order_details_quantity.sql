
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select quantity
from `silver`.`silver_order_details`
where quantity is null



  
  
    ) dbt_internal_test