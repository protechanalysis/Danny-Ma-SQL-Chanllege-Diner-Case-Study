----- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
----- the week is starting from 0 you can add 1 after the parenthesis to start from 1
select week(registration_date, '2021-01-01') as week_number, count(*) as num
from runners
group by week_number;

----- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id, avg(timestampdiff(minute, order_time,pickup_time)) as avg_time
from runner_orders
inner join customer_orders
using(order_id)
group by runner_id;

----- Is there any relationship between the number of pizzas and how long the order takes to prepare
with rela as (
	select c.order_id, count(pizza_id) as num_pizza, minute(timediff(pickup_time, order_time)) as time_taken
	from customer_orders c
	inner join runner_orders as r
	using(order_id)
	where cancellation = 'Not cancelled'
    group by c.order_id, time_taken)
select num_pizza, avg(time_taken) as preparation_time
from rela
group by num_pizza;

----- What was the average distance travelled for each customer?
select customer_id, avg(distance)
from customer_orders
inner join runner_orders
using(order_id)
where cancellation = 'Not cancelled'
group by customer_id;

----- What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) as difference
from runner_orders
where cancellation = 'Not cancelled';

-----  What was the average speed for each runner for each delivery and do you notice any trend for these values?
select runner_id, order_id, avg(distance*60/duration) as average_speed
from runner_orders
where cancellation = 'Not cancelled'
group by runner_id, order_id;

----- What is the successful delivery percentage for each runner?
with delivery as (
	select runner_id, count(*) as num_order_assign
    from runner_orders
    group by runner_id),
    success as (
    select runner_id, count(*) as num_success
    from runner_orders
    where cancellation = 'Not cancelled'
    group by runner_id)
select runner_id, (num_success/sum(num_order_assign)) * 100 as successful_delivery
from delivery
inner join success
using(runner_id)
group by runner_id;