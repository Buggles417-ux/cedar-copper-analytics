-- Product performance by category


select
	p.category,
	count(distinct p.product_id) as products,
	sum(oi.quantity) as units_sold,
	count(distinct o.order_id) as category_orders,
	round(sum(oi.net_item_revenue),0) as revenue
from products p
	join order_items oi on p.product_id = oi.product_id
	join orders o on oi.order_id = o.order_id
group by p.category
order by revenue desc

-- Findings:
-- Each category contains exactly 10 products, reflecting the structure of the mock dataset rather than a realistic product assortment.
-- Cookware generated the highest revenue at approximately $1.04M.
-- Cookware and Tabletop together generated approximately 43% of total product revenue.
-- Seasonal Kitchen generated the fewest units sold and category orders.


-----------------------------------------------------------------------------------------------------------------------------------------


-- Top products by revenue


select
	p.product_id,
	p.product_name,
	p.category,
	sum(oi.quantity) as units_sold,
	round(sum(oi.net_item_revenue),0) as revenue
from products p join order_items oi on p.product_id = oi.product_id
group by 
	p.product_id,
	p.product_name,
	p.category
order by revenue desc
limit 10

-- Findings:
-- Copper Core Cookware Set generated the highest product revenue at approximately $294K.
-- Knife Block Set ranked second at approximately $200K.
-- Four of the top 10 products by revenue are in the Cookware category.
-- High revenue does not appear to be driven by units sold alone, suggesting product price is an important factor.

----------------------------------------------------------------------------------------------------------------------

-- Top products by units sold

select
	p.product_id,
	p.product_name,
	p.category,
	sum(oi.quantity) as units_sold,
	round(sum(oi.net_item_revenue),0) as revenue
from products p join order_items oi on p.product_id = oi.product_id
group by 
	p.product_id,
	p.product_name,
	p.category
order by units_sold desc
limit 10


-- Findings:
-- Linen Napkin Set sold the most units at 1,344.
-- Tabletop and Kitchen Tools dominate the top 10 products by units sold.
-- The highest-volume product generated relatively low revenue, showing that unit volume and revenue tell different stories.
-- Knife Block Set combines strong unit sales with much higher revenue than most other high-volume products.


-----------------------------------------------------------------------------------------------------------------------


-- Average selling price by product


select
	p.product_id,
	p.product_name,
	p.category,
	sum(oi.quantity) as units_sold,
round(sum(oi.net_item_revenue), 2) as net_item_revenue,
round(
		sum(oi.net_item_revenue) *1.0 / sum(oi.quantity),
		2
		) as average_selling_price
from products p join order_items oi on p.product_id = oi.product_id
group by 
	p.product_id,
	p.product_name,
	p.category
order by average_selling_price desc
limit 10

-- Findings:
-- Copper Core Cookware Set has the highest average selling price at $239.02 per unit.
-- The products with the highest average selling prices are not necessarily the products with the highest unit sales.
-- Higher-priced Cookware products generate strong revenue despite selling fewer units than some lower-priced products.

-- Follow-up question:
-- How much is each product discounted from its unit price, both in dollars and as a percentage?

------------------------------------------------------------------------------------------------------------------------------------


-- Returned order-item rate by product

select
    p.product_id,
    p.product_name,
    p.category,
    sum(oi.quantity) as units_sold,
    count(distinct oi.order_item_id) as order_item_lines,
    count(distinct r.order_item_id) as returned_order_items,
    round(
        100.0 * count(distinct r.order_item_id)
        / count(distinct oi.order_item_id),
        1
    ) as returned_order_item_rate_pct
from products p
join order_items oi
    on p.product_id = oi.product_id
left join returns r
    on oi.order_item_id = r.order_item_id
group by
    p.product_id,
    p.product_name,
    p.category
order by returned_order_item_rate_pct desc
limit 10;


-- Findings:
-- Entertaining Cheese Board has the highest returned order-item rate at 12.7%, with 81 returned order-item lines out of 638.
-- Eight of the top 10 products are in the Seasonal Kitchen category, indicating a potential category-level issue requiring investigation.
-- Returned order-item rate should be reviewed alongside order-item volume before drawing conclusions or recommending corrective action.

-- Limitation:
-- The returns table does not include returned quantity. This metric therefore measures the percentage of order-item lines associated
-- with a return record, not the percentage of individual units returned.
