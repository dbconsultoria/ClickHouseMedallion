
    
    

select
    code as unique_field,
    count(*) as n_records

from `silver`.`silver_customers`
where code is not null
group by code
having count(*) > 1


