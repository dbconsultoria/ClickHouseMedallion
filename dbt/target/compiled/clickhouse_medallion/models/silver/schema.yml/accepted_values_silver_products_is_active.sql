
    
    

with all_values as (

    select
        is_active as value_field,
        count(*) as n_records

    from `silver`.`silver_products`
    group by is_active

)

select *
from all_values
where value_field not in (
    
)


