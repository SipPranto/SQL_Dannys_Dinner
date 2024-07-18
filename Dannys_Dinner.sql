CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);



use dannys_diner
-- What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) As Total_Spend from sales s
join menu m on m.product_id=s.product_id
group by customer_id


-- How many days has each customer visited the restaurant?
select customer_id,count(DISTINCT order_date) as Visting_day
from sales
group by customer_id

-- What was the first item from the menu purchased by each customer?
select customer_id,order_date,product_name from
(select customer_id,sales.product_id,product_name,order_date,
dense_rank() over(partition by customer_id order by order_date asc) as rnk
from sales
join menu on menu.product_id=sales.product_id)p
where p.rnk=1


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name,count(product_id)
from menu
group by product_name


-- Which item was the most popular for each customer?
select customer_id,product_name from
(select *,
dense_rank () over (partition by customer_id order by total_number desc) as rnk from
(select customer_id,product_name,count(product_name) as total_number 
from sales
join menu on menu.product_id=sales.product_id
group by customer_id,product_name)p)k
where k.rnk=1


-- Which item was purchased first by the customer after they became a member?
select customer_id,product_name from
(select *,
dense_rank() over(partition by customer_id order by order_date asc) as rnk from
(select s.customer_id,order_date,s.product_id,m.product_name,join_date
from sales s
join menu m on m.product_id=s.product_id
join members mb on mb.customer_id=s.customer_id
where order_date>join_date)p)k
where k.rnk=1


-- Which item was purchased just before the customer became a member?
WITH before_mem AS(
	select s.customer_id,order_date,join_date,product_name from sales s
	join menu m on m.product_id=s.product_id
	join members mb on mb.customer_id=s.customer_id
	where s.order_date<mb.join_date
),
	ranking as(
		select *,
		max(order_date) over(partition by customer_id ) as rnk
		from before_mem
)
select customer_id,product_name from ranking
where rnk=1


-- What is the total items and amount spent for each member before they became a member?
WITH t1 AS(
	select s.customer_id,order_date,join_date,product_name,price from sales s
    join menu m on m.product_id=s.product_id
	join members mb on mb.customer_id=s.customer_id
	where s.order_date<mb.join_date
)
select customer_id,count(product_name) as Item_number,sum(price) as Total_spend 
from t1
group by customer_id
    

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with point_tab1 as(
select s.customer_id,order_date,product_name,price ,
case 
	when product_name like 'sushi' then 2
    else 1
    end as 'point'
from sales s
join menu m on m.product_id=s.product_id
),
 point_tab2 as(
select *,(price*point) as Total_point
from point_tab1)

select customer_id,sum(Total_point) from point_tab2
group by customer_id

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH t1 AS(
	select s.customer_id,order_date,join_date,product_name,price from sales s
    join menu m on m.product_id=s.product_id
	join members mb on mb.customer_id=s.customer_id

),t2 as(
   select customer_id,product_name,order_date,join_date,price,datediff(join_date,order_date) as difference,monthname(order_date) as month_name, 
   case 
		when datediff(join_date,order_date)>0 and datediff(join_date,order_date)<8 then 2
		when product_name like 'sushi' then 2
        else 1
        end as 'point'
        from t1
)
select customer_id,sum(price*point) as Total_Point
from t2
where month_name like 'January'
group by  customer_id



--  Danny also requires further information about the ranking of products. he purposely does not need the ranking of non member purchases so he expects NULL ranking values for customers who are not yet part of the loyalty program.
with t1 as(
select product_name,sum(price) as Total  from members mb
join sales s on s.customer_id=mb.customer_id
join menu m on m.product_id=s.product_id
group by product_name)

select *, dense_rank() over(partition by product_name order by Total desc) as rnk from t1
order by rnk asc




