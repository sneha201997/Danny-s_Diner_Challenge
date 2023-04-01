/*Join All The Things*/

select s.customer_id, order_date, product_name, price,
	case when order_date>=join_date then 'Y'
		 else 'N'
    end as member     
from sales s 
left join members m on s.customer_id=m.customer_id
left join menu on s.product_id=menu.product_id
order by customer_id;  

/*Rank All The Things*/

with cte as
(select s.customer_id, order_date, product_name, price,
	case when order_date>=join_date then 'Y'
		 else 'N'
    end as members
from sales s 
left join members m on s.customer_id=m.customer_id
left join menu on s.product_id=menu.product_id
order by customer_id)  

select *, case when members='Y' then rank() over(partition by s.customer_id, members order by s.order_date)
			   else 'null'
		  end as ranking  
from cte;   