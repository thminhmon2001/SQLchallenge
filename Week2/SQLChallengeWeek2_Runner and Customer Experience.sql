--How many runners signed up for each 1 week period?
select count/(day/7)
from(
	select 	count(distinct runner_id)
			,max(registration_date) - '2021-01-01' as day
	from pizza_runner.runners);

--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select	runner_id
		,case when max_pick - min_pick = 0 then count_order/1
			  else count_order/(max_pick-min_pick)*60 end as average_time_per_minutes
from(
	select	runner_id
			,count(runner_id) as count_order
			,extract(epoch from (max(TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS')) - '2020-01-01')) as max_pick
			,extract(epoch from (min(TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS')) - '2020-01-01')) as min_pick
	from pizza_runner.runner_orders
	where pickup_time <> 'null'
	group by runner_id
	order by runner_id);
	
--Is there any relationship between the number of pizzas and how long the order takes to prepare?
with order_pizza as(	
	select 	order_id
			,customer_id
			,order_time
			,count(pizza_id) as number_order
	from pizza_runner.customer_orders
	group by 1,2,3
	order by 1)
select 	(TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - order_time)
		,number_order
		,(TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - order_time)/number_order
from pizza_runner.runner_orders as ro
inner join order_pizza as op on ro.order_id = op.order_id
where pickup_time <> 'null';
-- số lượng có ảnh hưởng đến thời gian làm bánh, thời gian làm 1 cái bánh là khoảng chừng 10p

--What was the average distance travelled for each customer?
with distance_customer as(	
	select 	customer_id
			,CAST(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g') AS NUMERIC) AS distance
	from pizza_runner.runner_orders as ro
	inner join pizza_runner.customer_orders as co
		on ro.order_id = co.order_id
	where distance <> 'null')

select 	customer_id
		,round(sum(distance)/count(customer_id),2)
from(
	select 	distinct customer_id
			,distance
	from distance_customer
)
group by 1;

--What was the difference between the longest and shortest delivery times for all orders?
with tablea as(
	select 	*
			,CAST(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g') AS NUMERIC) AS durationn
	from pizza_runner.runner_orders
	where duration <> 'null' )
select 	t.order_id
		,CAST(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g') AS NUMERIC) AS distance
		,durationn
		,count(pizza_id)
from tablea as t
inner join pizza_runner.customer_orders as co 
	on t.order_id = co.order_id
where 	durationn = (select max(durationn) from tablea) or
		durationn = (select min(durationn) from tablea)
group by 1,2,3;
-- sự khác biết giữa thời gian vận chuyển là do khoảng cách xa và số lượng hàng hóa giao tới

--What was the average speed for each runner for each delivery and do you notice any trend for these values?
with infom as (
	select 	ro.order_id
			,runner_id
			,CAST(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g') AS NUMERIC) AS distance
			,CAST(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g') AS NUMERIC) AS duration
			,count(pizza_id)
	from pizza_runner.runner_orders ro
	inner join pizza_runner.customer_orders co
		on ro.order_id = co.order_id
	where distance <> 'null'
	group by 1,2,3,4)
select 	runner_id
		,round(sum(distance)/sum(duration),2) as km_per_min
		,sum(count)
from infom
group by 1
order by 1;

--What is the successful delivery percentage for each runner?
select 	runner_id
		,successful/count_order*100 as percentage_successfull
from	
	(select runner_id
			,count(runner_id)::float as count_order
			,sum(points)::float as successful
	from(
		select 	runner_id
				,case when (pickup_time in ('null','') or pickup_time is NULL) then 0
					  else 1 end as points 
		from pizza_runner.runner_orders)
	group by 1)
order by 1