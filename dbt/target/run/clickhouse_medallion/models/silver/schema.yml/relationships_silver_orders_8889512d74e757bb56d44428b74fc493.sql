
    
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select customer_code as from_field
    from `silver`.`silver_orders`
    where customer_code is not null
),

parent as (
    select code as to_field
    from `silver`.`silver_customers`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
-- end_of_sql
settings join_use_nulls = 1



  
  
    ) dbt_internal_test