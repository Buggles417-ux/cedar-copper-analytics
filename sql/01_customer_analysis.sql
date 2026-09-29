-- Customer distribution by segment

select customer_segment,
	count(*) as customers,
	round(
		100.0 *	 count(*) / sum(count(*)) over (),1) as customer_pct
from customers
group by customer_segment
order by customers desc

-- Findings:
-- Repeat customers are the largest segment, representing 3,452 customers, or 34.5% of the customer base.
-- New customers are the second-largest segment at 2,784 customers, or 27.8%.
-- High Value customers represent 1,235 customers, or 12.3%, while At Risk is the smallest segment at 989 customers, or 9.9%.

----------------------------------------------------------------------------------------------------

-- Customer value by segment

select
	c.customer_segment,
	count(distinct o.customer_id) as purchasing_customers,
	count(distinct o.order_id) as orders,
	round(sum(o.net_order_amount),0) as revenue,
	round(avg(o.net_order_amount),2) as aov,
	round(count(distinct o.order_id) * 1.0/ count(distinct o.customer_id),2) as orders_per_customer,
	round(sum(o.net_order_amount) / count(distinct o.customer_id),2) as revenue_per_customer
from customers c inner join orders o on c.customer_id = o.customer_id
group by c.customer_segment
order by revenue desc;

-- Findings:
-- Repeat customers generate the most revenue at approximately $1.61M and the most orders at 12,992.
-- High Value customers lead all segments in average order value ($178.11), orders per purchasing customer (6.16), and revenue per purchasing customer ($1,097.73).
-- New and At Risk customers generate the lowest revenue per purchasing customer at $200.77 and $202.45, respectively.

----------------------------------------------------------------------------------------------------
-- Customer purchase frequency

with customer_orders as (
    select
        c.customer_id,
        count(o.order_id) as orders
    from customers c
    left join orders o
        on c.customer_id = o.customer_id
    group by c.customer_id
)

select
    case
        when orders = 0 then '0 orders'
        when orders = 1 then '1 order'
        when orders = 2 then '2 orders'
        when orders = 3 then '3 orders'
        when orders = 4 then '4 orders'
        else '5+ orders'
    end as purchase_frequency,
    count(customer_id) as customers
from customer_orders
group by
    case
        when orders = 0 then '0 orders'
        when orders = 1 then '1 order'
        when orders = 2 then '2 orders'
        when orders = 3 then '3 orders'
        when orders = 4 then '4 orders'
        else '5+ orders'
    end
order by
    case purchase_frequency
        when '0 orders' then 0
        when '1 order' then 1
        when '2 orders' then 2
        when '3 orders' then 3
        when '4 orders' then 4
        else 5
    end;
	
-- Findings:
-- Customers with 5 or more orders are the largest frequency group at 2,284 customers, or 22.8% of the customer base.
-- 1,123 customers, or 11.2%, have not placed an order; these customers were excluded by the original query.
-- One-time purchasers account for 1,868 customers, or 18.7%, while 1,948 customers have placed exactly two orders.
-- The distribution is unusually repeat-heavy for retail data, reflecting the synthetic nature of the dataset.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Top customers by revenue

select
	c.customer_id, 
	c.customer_segment,
count(distinct o.order_id) as total_orders,
round(sum(o.net_order_amount),0) as total_revenue,
	round(avg(o.net_order_amount),2) as average_order_value
from customers c join orders o on c.customer_id	 = o.customer_id
group by
	c.customer_id, 
	c.customer_segment
order by total_revenue desc
limit 10



-- Findings:
-- All top 10 customers by revenue are classified as High Value customers.
-- CUST-004622 ranks first with $3,782 in revenue from 15 orders and an average order value of $252.17.
-- CUST-000688 placed the most orders among the top 10 at 16, generating $3,579 in revenue.
-- CUST-001589 has the highest average order value among the top 10 at $361.88, generating $3,257 from 9 orders.
-- The rankings show that high customer revenue can result from greater purchase frequency, higher order value, or a combination of both.

-- Follow-up question:
-- How long have these customers been purchasing, and which customers generate the most revenue relative to their tenure?