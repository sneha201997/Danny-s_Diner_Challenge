/*What is the total amount each customer spent at the restaurant?*/

select customer_id, sum(price) 
from sales s
join menu m on s.product_id=m.product_id
group by customer_id;

/*How many days has each customer visited the restaurant?*/

select customer_id, count(distinct order_date)
from sales
group by customer_id;

/*What was the first item from the menu purchased by each customer?*/

with cte as
(select customer_id, product_id, order_date,
	row_number() over(partition by customer_id order by order_date) as rn
from sales)

select customer_id, cte.product_id, product_name
from cte
join menu m on cte.product_id=m.product_id
where rn=1;

/*What is the most purchased item on the menu and how many times was it purchased by all customers?*/

select s.product_id, product_name, count(s.product_id) as count
from sales s
join menu m on s.product_id=m.product_id
group by 1, 2
order by count desc
limit 1;

/*Which item was the most popular for each customer?*/

with cte as
(select  customer_id, pid, product_name, count,
	max(count) over(partition by customer_id) as max_count
from
(select distinct customer_id, s.product_id as pid, product_name, 
	count(s.product_id) over(partition by customer_id, s.product_id order by customer_id) as count
from sales s
join menu m on s.product_id=m.product_id
order by customer_id, count desc) x )

select customer_id, pid, product_name, count
from cte
where count=max_count;

/*Which item was purchased first by the customer after they became a member?*/

with cte as
(select s.customer_id as customer_id, product_id, order_date,
	row_number() over(partition by s.customer_id order by order_date) as rn
from sales s 
join members m on s.customer_id=m.customer_id
where order_date>= join_date)

select cte.customer_id, cte.product_id, product_name, order_date
from cte
join menu m on cte.product_id=m.product_id
where rn=1
order by cte.customer_id;

/*Which item was purchased just before the customer became a member?*/

with cte as
(select s.customer_id as customer_id, product_id, order_date,
	rank() over(partition by s.customer_id order by order_date desc) as rn
from sales s 
join members m on s.customer_id=m.customer_id
where order_date<join_date)

select cte.customer_id, cte.product_id, product_name, order_date
from cte
join menu m on cte.product_id=m.product_id
where rn=1
order by cte.customer_id;

/*What is the total items and amount spent for each member before they became a member?*/

select distinct s.customer_id as customer_id, 
	count(s.product_id) over(partition by s.customer_id) as total_items,
	sum(price) over(partition by s.customer_id) as total_amt
from sales s 
join members m on s.customer_id=m.customer_id
join menu on s.product_id=menu.product_id
where order_date<join_date;

/*If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
how many points would each customer have*/

with cte as
(select s.customer_id, s.product_id, product_name, price, 
	case when product_name='sushi' then price*20
		 when product_name!='sushi' then price*10
    end as points
from sales s
join menu m on s.product_id=m.product_id)

select distinct customer_id, sum(points) over(partition by customer_id) as total_points
from cte;

/*In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January*/

select distinct customer_id, sum(points) over(partition by customer_id)
from
(select s.customer_id as customer_id, order_date, price*20 as points
from sales s 
join members m on s.customer_id=m.customer_id
join menu on s.product_id=menu.product_id
where order_date>= join_date and month(order_date)=1) x;
