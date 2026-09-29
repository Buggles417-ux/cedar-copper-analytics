# Cedar & Copper Data Quality and Validation

## Purpose

This document records the validation completed for the Cedar & Copper analytics portfolio project. The checks confirm that the SQLite source supports the finalized customer and product analyses and establishes controlled baseline values for the Power BI report.

**Validation scope:** January 1, 2024 through December 31, 2025 order activity  
**Source:** `cedar_copper.db`  
**Validation outcome:** **Approved for portfolio analysis with documented limitations**

The database passed its primary-key, referential-integrity, financial-reconciliation, and return-record tests. The principal limitations concern synthetic data, blank text used instead of SQL `NULL`, the meaning of `first_order_date`, and the absence of returned quantity.

## 1. Row Counts

| Table | Row count | Expected grain |
|---|---:|---|
| `customers` | 10,000 | One row per customer |
| `orders` | 30,000 | One row per order |
| `order_items` | 68,292 | One row per order-item line |
| `products` | 80 | One row per product |
| `returns` | 3,861 | One row per returned order-item line |
| `stores` | 25 | One row per store |
| `marketing_campaigns` | 60 | One row per campaign |

**Result:** Pass. All seven expected tables are populated.

## 2. Unique-Key and Duplicate Checks

| Table | Key | Rows | Distinct keys | Null keys | Duplicate keys | Status |
|---|---|---:|---:|---:|---:|---|
| `customers` | `customer_id` | 10,000 | 10,000 | 0 | 0 | Pass |
| `orders` | `order_id` | 30,000 | 30,000 | 0 | 0 | Pass |
| `order_items` | `order_item_id` | 68,292 | 68,292 | 0 | 0 | Pass |
| `products` | `product_id` | 80 | 80 | 0 | 0 | Pass |
| `returns` | `return_id` | 3,861 | 3,861 | 0 | 0 | Pass |
| `stores` | `store_id` | 25 | 25 | 0 | 0 | Pass |
| `marketing_campaigns` | `campaign_id` | 60 | 60 | 0 | 0 | Pass |

**Result:** Pass. Every declared business key is complete and unique.

## 3. Missing and Blank Values

No SQL `NULL` values or blank strings were found in required identifiers, dates, product fields, customer classifications, quantities, or financial fields.

The following optional fields use blank text rather than SQL `NULL`:

| Field | Blank rows | Interpretation | Status |
|---|---:|---|---|
| `orders.store_id` | 20,806 | All 7,377 Mobile App and 13,429 Web orders; store is not applicable | Expected |
| `orders.campaign_id` | 8,745 | Orders not attributed to a campaign | Expected |
| `orders.promo_code` | 16,651 | Orders without a promotion code | Expected |
| `marketing_campaigns.promo_code` | 22 | Campaigns without a promotion code | Expected |

**Validation rule:** Convert blank optional identifiers to `NULL` in Power Query or account for both blank and `NULL` in SQL filters. This prevents blank values from being misclassified as orphaned keys.

## 4. Orphaned-Record and Relationship Checks

| Relationship tested | Orphans | Status |
|---|---:|---|
| `orders.customer_id` → `customers.customer_id` | 0 | Pass |
| `order_items.order_id` → `orders.order_id` | 0 | Pass |
| `order_items.product_id` → `products.product_id` | 0 | Pass |
| `returns.order_id` → `orders.order_id` | 0 | Pass |
| `returns.order_item_id` → `order_items.order_item_id` | 0 | Pass |
| `returns.product_id` → `products.product_id` | 0 | Pass |
| Populated `orders.store_id` → `stores.store_id` | 0 | Pass |
| Populated `orders.campaign_id` → `marketing_campaigns.campaign_id` | 0 | Pass |

**Result:** Pass. All populated foreign keys resolve to a valid parent record.

## 5. Revenue and Financial Reconciliation

| Validation | Result | Status |
|---|---:|---|
| Sum of `orders.net_order_amount` | $3,999,618.75 | Pass |
| Sum of `order_items.net_item_revenue` | $3,999,618.75 | Pass |
| Difference between order and item revenue | $0.00 | Pass |
| Orders with order-level/item-level revenue mismatch | 0 | Pass |
| Orders with stored item count different from actual line count | 0 | Pass |
| Orders failing gross amount − discount = net amount | 0 | Pass |
| Order-item lines failing quantity × unit price − discount = net revenue | 0 | Pass |
| Order-item lines failing quantity × unit cost = net item cost | 0 | Pass |
| Order-item lines failing net revenue − net cost = net margin | 0 | Pass |
| Rows with nonpositive quantity | 0 | Pass |
| Rows with negative sales or cost values | 0 | Pass |

**Result:** Pass. Revenue reconciles exactly between the order and order-item grains, and all tested financial formulas are internally consistent.

**Modeling control:** Do not join raw `orders` directly to raw `order_items` and then sum order-level revenue. That repeats the order amount once per line. Use an order-grain measure, an item-grain measure, or aggregate before joining.

## 6. Return-Data Validation

| Validation | Result | Status |
|---|---:|---|
| Return records | 3,861 | Pass |
| Distinct return IDs | 3,861 | Pass |
| Distinct returned order-item lines | 3,861 | Pass |
| Distinct orders with returns | 3,660 | Pass |
| Orders marked `Returned` | 3,660 | Pass |
| Returned orders without a return record | 0 | Pass |
| Return records tied to an order not marked `Returned` | 0 | Pass |
| Return/order-item order-ID mismatches | 0 | Pass |
| Return/order-item product-ID mismatches | 0 | Pass |
| Return dates before order dates | 0 | Pass |
| Nonpositive refunds | 0 | Pass |
| Refunds greater than linked line revenue | 0 | Pass |
| Total refund amount | $212,006.10 | Baseline |

**Result:** Pass. Each return record maps to one unique order-item line, and return status, dates, products, orders, and refund amounts are consistent.

**Important limitation:** The returns table has no returned-quantity field. Therefore, the approved return KPI is the percentage of order-item lines associated with a return record—not the percentage of individual units returned.

## 7. KPI Baseline Totals

These values are the control totals for validating SQL outputs and Power BI measures.

| KPI | Approved baseline |
|---|---:|
| Total customers | 10,000 |
| Purchasing customers | 8,877 |
| Customers with no order in the analysis window | 1,123 |
| Total orders | 30,000 |
| Completed orders | 26,340 |
| Net sales before refunds | $3,999,618.75 |
| Refunds | $212,006.10 |
| Refund-adjusted net revenue | $3,787,612.65 |
| Units sold | 82,714 |
| Average order value | $133.32 |
| Net item margin | $2,316,550.50 |
| Net item margin percent | 57.92% |
| Orders per purchasing customer | 3.38 |
| Revenue per purchasing customer | $450.56 |
| Average selling price per unit | $48.35 |
| Returned order-item rate | 5.65% |

The baseline for **Completed Orders** excludes the 3,660 orders with `order_status = 'Returned'`. Net Sales Before Refunds includes all recorded order revenue before the separately stored refunds are deducted.

## 8. Date and Coverage Checks

| Data area | Minimum date | Maximum date |
|---|---|---|
| Orders | 2024-01-01 | 2025-12-31 |
| Returns | 2024-01-07 | 2026-01-31 |
| Customer signups | 2021-07-11 | 2025-12-14 |
| Product launches | 2022-03-01 | 2024-06-05 |
| Campaign activity | 2024-01-01 | 2025-12-28 |

Returns extend one month beyond the order analysis period, which is reasonable for orders returned after purchase. Return reporting should use the order date for sales-period analysis and the return date for operational return timing.

## 9. Known Limitations and Reporting Rules

1. **Synthetic data:** Cedar & Copper is a fictional retailer and the dataset is mock data. Patterns should be presented as business interpretations of the dataset, not as claims about a real company.
2. **Return grain:** Returned quantity is unavailable. Use the returned order-item rate and label it clearly; do not call it a unit return rate.
3. **Refund timing:** Refunds are stored separately from order revenue. Use `net_order_amount` for pre-refund net sales and subtract aggregated refunds only for refund-adjusted revenue.
4. **Blank optional keys:** Optional store, campaign, and promotion identifiers are represented by blank strings. Normalize them to `NULL` during Power BI preparation.
5. **Customer first-order date:** `customers.first_order_date` is populated even for the 1,123 customers with no orders in the 2024–2025 order table, and it does not consistently equal the first order within this reporting window. Treat it as a historical/source attribute, not as a value derived from the available orders.
6. **Customer denominators:** Customer-base percentages use all 10,000 customer records. Purchasing-customer KPIs use the 8,877 customers with at least one order in the analysis window.
7. **Revenue grain:** Sum `orders.net_order_amount` only at order grain and `order_items.net_item_revenue` only at item grain. Avoid duplicated totals from one-to-many joins.
8. **Returned-order treatment:** Returned orders remain in pre-refund sales and are offset only when the refund-adjusted metric is used. Dashboard labels must make that distinction visible.
9. **Rounding:** Calculate with full stored precision and round only the displayed result.

## 10. Validation Conclusion

The Cedar & Copper database is sufficiently complete and internally consistent for the planned SQL analysis and Power BI dashboard. No duplicate primary keys, required-field gaps, genuine foreign-key orphans, revenue discrepancies, invalid return links, or financial-formula failures were found. The project can proceed using the KPI baselines and reporting rules in this document.

Before publishing the dashboard, each Power BI measure should be reconciled to the KPI baseline table above.
