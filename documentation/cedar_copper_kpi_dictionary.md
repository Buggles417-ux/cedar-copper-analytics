# Cedar & Copper KPI Dictionary

## Purpose and scope

This dictionary defines the business metrics used in the Cedar & Copper SQL analyses and planned Power BI report. Unless a KPI states otherwise, the reporting period is January 1, 2024 through December 31, 2025.

### Revenue convention

The database field `net_order_amount` equals sales after discounts but before refunds. To avoid overstating what the field represents, this dictionary calls that metric **Net Sales Before Refunds**. A separate **Refund-Adjusted Net Revenue** KPI subtracts recorded refunds.

## KPI definitions

### 1. Net Sales Before Refunds

- **Business definition:** Total merchandise sales after discounts, before subtracting refunds.
- **Calculation:** `SUM(orders.net_order_amount)`
- **Source tables:** `orders`
- **Grain:** Order; aggregated by the selected reporting dimensions and period.
- **Filters:** Include all orders in the selected date range. Use `orders.order_date` as the reporting date.
- **Important limitations:** Despite the source field name, this metric is not fully refund-adjusted. Orders with `order_status = 'Returned'` retain their original `net_order_amount`. Do not subtract refunds after joining raw `orders` directly to raw `returns`, because orders with multiple returned lines could be duplicated.

### 2. Refund-Adjusted Net Revenue

- **Business definition:** Net sales after discounts less recorded refund amounts.
- **Calculation:** `SUM(orders.net_order_amount) - SUM(returns.refund_amount)`, with sales and refunds aggregated separately before combining.
- **Source tables:** `orders`, `returns`
- **Grain:** Reporting period or another shared reporting dimension after separate aggregation.
- **Filters:** Sales use `orders.order_date`; refunds use `returns.return_date`. State clearly whether the report uses transaction-date reporting or attributes refunds back to the original order period.
- **Important limitations:** Refund timing can differ from order timing. The data does not confirm whether shipping, taxes, partial refunds, or non-merchandise adjustments are included. This KPI is not used in the existing product rankings, which use pre-refund item revenue.

### 3. Completed Orders

- **Business definition:** Distinct orders whose current status is Completed.
- **Calculation:** `COUNT(DISTINCT CASE WHEN orders.order_status = 'Completed' THEN orders.order_id END)`
- **Source tables:** `orders`
- **Grain:** Order; aggregated by the selected reporting dimensions and period.
- **Filters:** `orders.order_status = 'Completed'`; use `orders.order_date`.
- **Important limitations:** The database contains only `Completed` and `Returned` statuses. A returned order is excluded even if only one item from a multi-item order was returned. This is therefore a status-based count, not a count of orders retaining some revenue.

### 4. Units Sold

- **Business definition:** Total quantity of product units recorded on order-item lines.
- **Calculation:** `SUM(order_items.quantity)`
- **Source tables:** `order_items`; join to `orders` for date, channel, location, or customer filters; join to `products` for product attributes.
- **Grain:** Order item, summed across quantity.
- **Filters:** Apply the associated order-date and reporting filters. The finalized product analysis includes all recorded order items.
- **Important limitations:** Units are not reduced for returned quantities because `returns` has no returned-quantity field. This is units sold before returns, not net units retained.

### 5. Average Order Value (AOV)

- **Business definition:** Average post-discount sales amount per distinct order before refunds.
- **Calculation:** `SUM(orders.net_order_amount) / COUNT(DISTINCT orders.order_id)`
- **Source tables:** `orders`
- **Grain:** Order.
- **Filters:** Use the same order population and date filters in both numerator and denominator. For the existing customer-segment analysis, all recorded orders are included.
- **Important limitations:** This is pre-refund AOV. Do not use `AVG(orders.net_order_amount)` after joining to `order_items` or `returns` unless orders are deduplicated first.

### 6. Net Item Margin

- **Business definition:** Merchandise revenue after item discounts minus recorded item cost.
- **Calculation:** `SUM(order_items.net_item_margin)`; validation identity: `net_item_revenue - net_item_cost`.
- **Source tables:** `order_items`; optionally `orders` and `products` for reporting dimensions.
- **Grain:** Order item.
- **Filters:** Apply associated order-date and reporting filters. Use the same row population as Net Item Revenue.
- **Important limitations:** The metric is before refunds and may exclude shipping, taxes, marketing expense, store expense, and overhead. It is a merchandise contribution margin, not company profit.

### 7. Net Item Margin Percentage

- **Business definition:** Percentage of post-discount item revenue retained after recorded item cost.
- **Calculation:** `100.0 * SUM(order_items.net_item_margin) / SUM(order_items.net_item_revenue)`
- **Source tables:** `order_items`; optionally `orders` and `products` for reporting dimensions.
- **Grain:** Ratio of aggregated order-item values.
- **Filters:** Same filters and row population in numerator and denominator; exclude or safely handle groups with zero revenue.
- **Important limitations:** Use the ratio of sums, not the average of row-level margin percentages. Like Net Item Margin, it is pre-refund and excludes non-merchandise costs.

### 8. Purchasing Customers

- **Business definition:** Unique customers with at least one recorded order in the selected period.
- **Calculation:** `COUNT(DISTINCT orders.customer_id)`
- **Source tables:** `orders`; join to `customers` for segment and customer attributes.
- **Grain:** Customer within the selected reporting period.
- **Filters:** Apply `orders.order_date` and other selected order filters. The finalized customer-value analysis includes all order statuses.
- **Important limitations:** Customers with no orders are excluded. This differs from Total Customers, which counts every row in `customers`. Results are period-dependent.

### 9. Orders per Purchasing Customer

- **Business definition:** Average number of distinct orders placed by customers who purchased during the selected period.
- **Calculation:** `COUNT(DISTINCT orders.order_id) * 1.0 / COUNT(DISTINCT orders.customer_id)`
- **Source tables:** `orders`; join to `customers` for customer attributes.
- **Grain:** Ratio calculated for the selected segment or reporting group.
- **Filters:** Use the same order population and period in numerator and denominator.
- **Important limitations:** This excludes customers with zero orders. It should be labeled “per purchasing customer,” not simply “per customer.”

### 10. Revenue per Purchasing Customer

- **Business definition:** Average post-discount sales generated by each customer who purchased during the selected period.
- **Calculation:** `SUM(orders.net_order_amount) / COUNT(DISTINCT orders.customer_id)`
- **Source tables:** `orders`; join to `customers` for customer attributes.
- **Grain:** Ratio calculated for the selected segment or reporting group.
- **Filters:** Use the same order population and period in numerator and denominator.
- **Important limitations:** This is before refunds and excludes customers with no orders. It is not lifetime value because the dataset covers only two years.

### 11. Average Selling Price per Unit

- **Business definition:** Average realized item revenue per unit sold after item-level discounts and before refunds.
- **Calculation:** `SUM(order_items.net_item_revenue) / SUM(order_items.quantity)`
- **Source tables:** `order_items`; join to `products` for product name, category, subcategory, and price tier.
- **Grain:** Product or another selected product grouping.
- **Filters:** Use the same item rows in numerator and denominator; exclude or safely handle zero-quantity groups.
- **Important limitations:** This is a quantity-weighted realized price, not the listed `standard_price` or an unweighted average of `unit_price`. It is not refund-adjusted.

### 12. Returned Order-Item Rate

- **Business definition:** Percentage of distinct order-item lines associated with a return record.
- **Calculation:** `100.0 * COUNT(DISTINCT returns.order_item_id) / COUNT(DISTINCT order_items.order_item_id)` using a LEFT JOIN from `order_items` to `returns`.
- **Source tables:** `order_items`, `returns`; join to `products` for product reporting.
- **Grain:** Order-item line, aggregated by product, category, or another selected dimension.
- **Filters:** Retain all order-item lines in the denominator. Apply the same order-date and product filters to numerator and denominator.
- **Important limitations:** The `returns` table has no returned-quantity field, so this measures returned lines rather than returned units. One line may contain multiple units. It also does not measure returned dollars. Use order-item volume alongside the rate before recommending corrective action.

## Reporting dimensions

The KPIs may be segmented by the following fields when the required joins do not change the metric grain:

- **Time:** `orders.order_date`; `returns.return_date` for refund-timing analysis
- **Customer:** `customers.customer_segment`, `customer_region`, `acquisition_channel`, `loyalty_status`
- **Product:** `products.category`, `subcategory`, `price_tier`, `product_id`
- **Channel:** `orders.sales_channel` (`Store`, `Web`, `Mobile App`)
- **Location:** `orders.sales_location`, `stores.store_name`, `store_region`
- **Marketing:** `orders.marketing_channel`, `campaign_id`, `promo_code`

## Required validation checks

Use these controls when implementing the KPIs in Power BI:

1. `SUM(orders.net_order_amount)` must reconcile to `SUM(order_items.net_item_revenue)` at **$3,999,618.75** before refunds.
2. Total distinct orders must reconcile to **30,000**.
3. Total customers must reconcile to **10,000**; purchasing customers must reconcile to **8,877** for the full period.
4. Units sold must reconcile to **82,714** before returns.
5. Net item margin must reconcile to **$2,316,550.50** and margin percentage to **57.92%** before refunds.
6. Recorded refunds must reconcile to **$212,006.10**; refund-adjusted net revenue must reconcile to **$3,787,612.65** under the documented calculation.
7. Returned order-item lines must reconcile to **3,861 of 68,292**, or **5.65%** for the full period.
8. Filters must not create many-to-many duplication between `orders`, `order_items`, and `returns`.

## Implementation note

The Power BI model should use measures rather than calculated columns for aggregating these KPIs. Every dashboard label should distinguish pre-refund sales from refund-adjusted revenue and should identify the Returned Order-Item Rate as a line-based measure.
