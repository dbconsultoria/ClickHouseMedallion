
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    code as unique_field,
    count(*) as n_records

from `silver`.`silver_products`
where code is not null
group by code
having count(*) > 1



  
  
    ) dbt_internal_test