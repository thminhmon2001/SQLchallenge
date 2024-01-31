--What is the total amount each customer spent at the restaurant?
select customer_id
	   ,sum(price) as total_amount
from dannys_diner.menu as m
inner join dannys_diner.sales as s 
	on m.product_id = s.product_id
group by customer_id
order by customer_id;

--How many days has each customer visited the restaurant?
with time_visit as (
	select s.customer_id
		   ,max(order_date) as last_day
		   ,join_date
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
	full outer join dannys_diner.members as mem
		on s.customer_id = mem.customer_id
	group by s.customer_id, join_date
)
select customer_id
	   ,last_day-join_date as days
from time_visit;

--What was the first item from the menu purchased by each customer?
with rank_order as(
	select customer_id
		   ,rank() over(partition by customer_id order by order_date) as first_time
		   ,product_name
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
)
select *
from rank_order
where first_time = 1;

--What is the most purchased item on the menu and how many times was it purchased by all customers?
with quantity as(	
	select product_name
		   ,count(*) as amount
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
	group by product_name
)
select *
from quantity
order by amount desc
limit 1;

--Which item was the most popular for each customer?
with list as(
	select customer_id
		   ,product_name
		   ,count(*) as count_item
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
	group by customer_id, product_name
)
select customer_id
	   ,best_items
from(
	select customer_id
		  ,product_name as best_items
		  ,rank() over(partition by customer_id order by count_item desc) as rank_items
	from list
)
where rank_items = 1;

--Which item was purchased first by the customer after they became a member?
select customer_id
	  ,product_name
from(
	select product_name
		  ,s.customer_id
		  ,rank() over(partition by s.customer_id order by (order_date - join_date))
		  ,order_date - join_date
		from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
			on m.product_id = s.product_id
	full outer join dannys_diner.members as mem
			on s.customer_id = mem.customer_id
	where order_date >= join_date
)
where rank = 1;

--Which item was purchased just before the customer became a member?
select customer_id
	  ,product_name
from(
	select product_name
		   ,s.customer_id
		   ,rank() over(partition by s.customer_id order by (join_date - order_date))
		   ,join_date - order_date
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
	full outer join dannys_diner.members as mem
		on s.customer_id = mem.customer_id
	where order_date < join_date
)
where rank = 1;

--What is the total items and amount spent for each member before they became a member?
select s.customer_id
	  ,count(*) as total_item
	  ,sum(price) as total_amount
from dannys_diner.menu as m
inner join dannys_diner.sales as s 
	on m.product_id = s.product_id
full outer join dannys_diner.members as mem
	on s.customer_id = mem.customer_id
where order_date < join_date
group by s.customer_id;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id
	  ,sum(points) as total_points
from(
	select customer_id
		   ,case when product_name = 'sushi' then price*2*10
		   else price*10 end as points   
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id)
group by customer_id;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id
	  ,sum(points) as total_points
from(
	select s.customer_id
		  ,case when order_date - join_date <= 7 then price * 2 * 10
		   else case when product_name = 'sushi' then price * 2 * 10
				else price * 10 end end as points
	from dannys_diner.menu as m
	inner join dannys_diner.sales as s 
		on m.product_id = s.product_id
	full outer join dannys_diner.members as mem
		on s.customer_id = mem.customer_id
	where order_date > join_date and order_date < '2021-02-01'
)
group by customer_id