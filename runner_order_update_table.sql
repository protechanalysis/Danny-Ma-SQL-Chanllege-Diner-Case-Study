
update customer_orders
set extras = case 	
	when extras = '' then 'null'
    when extras is null then 'null'
    when extras = 'null' then 'null'
    else extras
    end,
    exclusions = case 
    when exclusions = '' then 'null'
    when exclusions = 'null' then 'null'
    else exclusions
    end;

select *
from customer_orders;