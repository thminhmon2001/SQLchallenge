--What are the standard ingredients for each pizza?
with recipes as(
	select 	pizza_id
			,UNNEST(string_to_array(toppings, ','))::INTEGER AS topping
	from pizza_runner.pizza_recipes)
select 	pizza_name
		,string_agg(topping_name,', ') as recipe
from recipes r
inner join pizza_runner.pizza_names pn on pn.pizza_id = r.pizza_id
inner join pizza_runner.pizza_toppings pt on r.topping = pt.topping_id
group by pizza_name;

--What was the most commonly added extra?
with extra_topping as (
	select 	order_id
			,customer_id
			,unnest(string_to_array(extras, ','))::integer as extra
	from pizza_runner.customer_orders
	where extras <> '' and extras <> 'null')
select 	topping_name
		,count(topping_name)
from extra_topping et
inner join pizza_runner.pizza_toppings pt on et.extra = pt.topping_id
group by 1
order by 2 desc
limit 1;

--What was the most common exclusion?
with exclusion_topping as (
	select 	order_id
			,customer_id
			,unnest(string_to_array(exclusions, ','))::integer as exclusions
	from pizza_runner.customer_orders
	where exclusions <> '' and exclusions <> 'null')
	
select 	topping_name
		,count(topping_name)
from exclusion_topping et
inner join pizza_runner.pizza_toppings pt on et.exclusions = pt.topping_id
group by 1
order by 2 desc
limit 1;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
with replace_null as(
	select	order_id
			,customer_id
			,pizza_id
			,case when (exclusions = 'null' or exclusions = '' or exclusions is NULL) then '0'
				  else exclusions end as exclusion
			,case when (extras = 'null' or extras = '' or extras is NULL) then '0'
				  else extras end as extra
	from pizza_runner.customer_orders
),
record_exclusion as(
	select 	order_id
			,customer_id
			,pizza_id
			,unnest(string_to_array(exclusion, ','))::integer as exclusions
	from replace_null)
select 	order_id
		,customer_id
		,pizza_name
from record_exclusion re
left join pizza_runner.pizza_names pn on pn.pizza_id = re.pizza_id
full outer join pizza_runner.pizza_toppings pt on pt.topping_id = re.exclusions

			