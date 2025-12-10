create database e_commerce;
use e_commerce;

select * from olist_customers_dataset_ready;
select * from olist_order_payments_dataset;
select * from olist_order_items_dataset;
select * from olist_order_payments_dataset;
select * from olist_products_dataset;
select * from olist_sellers_dataset;
select * from product_category_name_translation;


#Total Orders, Total Revenue & Average Price per Product Category

select 
op.product_category_name 
,count( oi.order_id) as total_orders
,round(sum(oi.price),2) as total_revenue
,round(avg(oi.price),2) as average_price
from olist_order_items_dataset  oi
left join olist_products_dataset  op
		on oi.product_id =op.product_id
group by op.product_category_name
order by total_revenue;


# Number of Customers per State + Their Average Order Count
select 
customer_state
,count(distinct(customer_unique_id)) as unique_customer
,count(customer_id) as total_orders
,round(count(customer_id) / count(distinct customer_unique_id), 2) AS avg_orders_per_customer
from olist_customers_dataset_ready
group by customer_state
order by unique_customer desc;

#Seller Revenue Summary (Revenue, Freight, Avg Price)
select
seller_id
,sum(price) as total_revenue
,sum(freight_value) as total_freight
,round(avg(price),2) as average_price
from olist_order_items_dataset
group by seller_id 
order by total_revenue desc;



# Revenue per Payment Type
select
payment_type
,sum(payment_value) as total_revenue
,count(order_id) as order_count
from olist_order_payments_dataset
group by payment_type
order by total_revenue desc;


#Top 10 Most Sold Products (by Quantity)
select 
oi.product_id
,coalesce(op.product_category_name, 'Unknown') AS product_category_name
,count(oi.order_id) as total_sold
,sum(oi.price) as total_revenue
from  olist_order_items_dataset oi
left join olist_products_dataset op
	on oi.product_id=op.product_id
group by product_id,op.product_category_name
order by total_sold desc;

#  Customer Lifetime Value (LTV) – Top Spenders

with customer_spending as (
select 
	 o.customer_id
	,o.order_id
	,sum(p.payment_value) as order_value
from olist_orders_dataset o
join olist_order_payments_dataset p 
    on o.order_id=p.order_id
group by o.customer_id ,o.order_id
order by order_value desc
),

customer_ltv as (
select 
	customer_id
	,sum(order_value) as lifetime_value
from customer_spending
group by customer_id
)
select * from customer_ltv
order by lifetime_value desc;


#  Ranking Categories by Revenue 
with category_revenue as (
select 
	p.product_category_name as category
	,sum(o.price) as revenue
from olist_order_items_dataset o
join olist_products_dataset p
	on o.product_id=p.product_id
group by p.product_category_name 
),
 
  ranked_category as (
select 
category
,revenue
, rank () over(  order by revenue desc) as revenue_rank
from category_revenue 
)

select 
	e.product_category_name_english 
    ,r.revenue
    ,r.revenue_rank
from ranked_category r
join product_category_name_translation e
	 on r.category=e.ï»¿product_category_name
     limit 20;
     
#Seller Performance: Total Sales, Avg Delivery Time
select * from olist_orders_dataset;
select * from olist_order_items_dataset;

with delivery_time as (
select 
oi.seller_id
,datediff(o.order_delivered_carrier_date,o.order_purchase_timestamp) as delivery_days
from olist_order_items_dataset oi
join olist_orders_dataset o
	on o.order_id=oi.order_id 
) 
select 
s.seller_id
,count(oi.order_id) as total_sales
, round(avg(t.delivery_days),2) as avg_delivery_days
, sum(oi.price) as total_revenue
from olist_sellers_dataset s
left join olist_order_items_dataset oi
	on s.seller_id=oi.seller_id
left join delivery_time t
	on s.seller_id=t.seller_id
group by s.seller_id
order by total_revenue;




#Monthly Revenue + Running Total
select 
date_format(o.order_purchase_timestamp,'%Y-%m') as month
,sum(p.payment_value) as monthly_revenue
, sum(sum(p.payment_value)) over ( order by date_format(o.order_purchase_timestamp,'%Y-%m') ) as running_total
from olist_order_payments_dataset p
inner join olist_orders_dataset o
	on o.order_id=p.order_id
group by month
order by month;


#Top 5 Product Categories by Seller Revenue

with seller_categories as (

select 
seller_id
,product_id
,sum(price) as revenue
from olist_order_items_dataset
group by seller_id,product_id

),

categories_name as (

select 
s.seller_id
,s.revenue
,p.product_category_name as category
from seller_categories s
left join olist_products_dataset p
	on s.product_id=p.product_id
),

categories_total as (

select 
category 
,sum(revenue) as total_category_revenue
from categories_name
group by category
)
select * 
from categories_total
order by total_category_revenue desc
limit 5;



