----- How many pizzas were ordered?
SELECT count(*) as number_of_orders
FROM customer_orders;

----- How many unique customer orders were made?
SELECT count(distinct order_id) as unique_order
FROM customer_orders;

-----  How many successful orders were delivered by each runner?
select runner_id, count(*) as successful_order
from runner_orders
where cancellation = 'Not cancelled'
group by runner_id;

----- How many of each type of pizza was delivered?
select pizza_name, count(order_id) as num_delivered
from runner_orders
inner join customer_orders
using(order_id)
inner join pizza_names 
using(pizza_id)
where cancellation = 'Not cancelled'
group by pizza_name;

----- How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id, pizza_name, count(order_id) as num_order
from customer_orders
inner join pizza_names 
using(pizza_id)
group by customer_id, pizza_name;

----- What was the maximum number of pizzas delivered in a single order?
with single_order as (select c.order_id, count(pizza_id) as num_order
	  from customer_orders as c
      inner join runner_orders as r on c.order_id=r.order_id 
      where cancellation = 'Not cancelled'
      group by c.order_id)
select order_id, num_order
from single_order
where num_order = (select max(num_order) from single_order);


----- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_id, pizza_id, count(pizza_id) as chang
from customer_orders
inner join runner_orders
using(order_id)
where (exclusions != 0 or extras != 0) and cancellation = 'Not cancelled'
group by customer_id, pizza_id;
select customer_id, pizza_id, count(pizza_id) as no_change
from customer_orders
inner join runner_orders
using(order_id)
where (exclusions = 0 and extras = 0) and cancellation = 'Not cancelled'
group by customer_id, pizza_id;


-----  How many pizzas were delivered that had both exclusions and extras?
select count(pizza_id) as exclusions_extras
from customer_orders
inner join runner_orders
using(order_id)
where (exclusions != 0 and extras != 0) and cancellation = 'Not cancelled';


----- What was the total volume of pizzas ordered for each hour of the day?
select hour(order_time) as Hour_of_day, count(*) as num_of_order
from customer_orders
group by Hour_of_day
order by num_of_order desc;

----- What was the volume of orders for each day of the week?
select weekday(order_time) as weekday, count(*) as num_of_order
from customer_orders
group by weekday
order by num_of_order;
