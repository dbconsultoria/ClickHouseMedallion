
    
    

with child as (
    select product_code as from_field
    from `silver`.`silver_order_details`
    where product_code is not null
),

parent as (
    select code as to_field
    from `silver`.`silver_products`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null
-- end_of_sql
settings join_use_nulls = 1


