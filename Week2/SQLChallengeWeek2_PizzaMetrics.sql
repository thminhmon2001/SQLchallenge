--How many pizzas were ordered?
select count(pizza_id)
from pizza_runner.customer_orders;

--How many unique customer orders were made?
select count (distinct customer_id)
from pizza_runner.customer_orders;

--How many successful orders were delivered by each runner?
select runner_id
	   ,count(runner_id)
from pizza_runner.runner_orders
where cancellation = 'null' or 
	  cancellation is NULL or
	  cancellation = ''
group by runner_id
order by runner_id;

--How many of each type of pizza was delivered?
select 	pizza_id
		,count(pizza_id)	   
from pizza_runner.customer_orders as co
inner join pizza_runner.runner_orders as ro
	on co.order_id = ro.order_id
where cancellation = 'null' or 
	  cancellation is NULL or
	  cancellation = ''
group by pizza_id
order by pizza_id;

--How many Vegetarian and Meatlovers were ordered by each customer?
select 	customer_id
		,pizza_name
		,count(pizza_name)
from pizza_runner.customer_orders as co
inner join pizza_runner.pizza_names as pn
	on co.pizza_id = pn.pizza_id
group by customer_id, pizza_name
order by 1,2;

--What was the maximum number of pizzas delivered in a single order?
select 	order_id
		,count(order_id)
from pizza_runner.customer_orders
group by order_id
order by count(order_id) desc
limit 1;

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with point_pizza as(
	select 	customer_id
			,case when ((exclusions in ('null','') or exclusions is NULL) and
						(extras in ('null','') or extras is NULL)) then 0 else 1 end as points
	from pizza_runner.customer_orders
)
select 	customer_id
		,sum(points)
from point_pizza
group by customer_id
order by customer_id;

--How many pizzas were delivered that had both exclusions and extras?
with exchange_pizza as(
	select 	customer_id
			,case when ((exclusions in ('null','') or exclusions is NULL) or
						(extras in ('null','') or extras is NULL)) then 0 else 1 end as points
	from pizza_runner.customer_orders
)
select sum(points)
from exchange_pizza;

--What was the total volume of pizzas ordered for each hour of the day
select round(amount_pizza/(max_time-min_time)*60,6)
from(
	select 	count(pizza_id) as amount_pizza
			,extract(epoch from (max(order_time)-'2020-01-01 00:00:00')) as max_time
			,extract(epoch from (min(order_time)-'2020-01-01 00:00:00')) as min_time
	from pizza_runner.customer_orders);
	
--What was the volume of orders for each day of the week?
select round(count_order/(max_time-min_time)*60*24*7,6)
from(
	select 	count(distinct order_id) as count_order
			,extract(epoch from (max(order_time)-'2020-01-01 00:00:00')) as max_time
			,extract(epoch from (min(order_time)-'2020-01-01 00:00:00')) as min_time
	from pizza_runner.customer_orders)