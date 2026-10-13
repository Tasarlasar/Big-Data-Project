-- =============================================================================
-- PIG Script 4: Revenue and Order Volume by Product Category
-- Big Data Computing CAT II – Project 1
--
-- Input:  processed/orders_joined  (output of script 03)
-- Output: processed/revenue_by_category
--
-- Operations demonstrated: LOAD, GROUP, FOREACH, ORDER, STORE
-- =============================================================================

-- ── 1. Load joined orders dataset ────────────────────────────────────────────
joined = LOAD '/user/bigdata/ecommerce/processed/orders_joined'
         USING PigStorage(',')
         AS (order_id:chararray,
             customer_id:chararray,
             order_status:chararray,
             purchase_ts:chararray,
             delivered_ts:chararray,
             estimated_delivery_ts:chararray,
             item_id:int,
             product_id:chararray,
             seller_id:chararray,
             item_price:float,
             freight_value:float,
             total_item_cost:float,
             category_pt:chararray,
             category_en:chararray,
             order_total_payment:float);

-- ── 2. Filter out rows with missing category ──────────────────────────────────
with_category = FILTER joined BY
    (category_en IS NOT NULL) AND (category_en != '');

-- ── 3. Group by English category ─────────────────────────────────────────────
by_category = GROUP with_category BY category_en;

-- ── 4. Aggregate: revenue, volume, avg price, unique products ─────────────────
-- NOTE: Pig does not allow COUNT(DISTINCT x) as an inline expression. The
-- distinct counts must be built inside a nested FOREACH block first.
revenue_by_category = FOREACH by_category {
    distinct_order_ids   = DISTINCT with_category.order_id;
    distinct_product_ids = DISTINCT with_category.product_id;
    GENERATE
        group                               AS category,
        COUNT(with_category)                AS item_count,
        SUM(with_category.item_price)       AS total_revenue,
        AVG(with_category.item_price)       AS avg_item_price,
        MIN(with_category.item_price)       AS min_price,
        MAX(with_category.item_price)       AS max_price,
        SUM(with_category.freight_value)    AS total_freight,
        COUNT(distinct_order_ids)           AS distinct_orders,
        COUNT(distinct_product_ids)         AS distinct_products;
};

-- ── 5. Order by revenue descending ───────────────────────────────────────────
sorted_categories = ORDER revenue_by_category BY total_revenue DESC;

-- ── 6. Show top 20 categories ─────────────────────────────────────────────────
top20 = LIMIT sorted_categories 20;
DUMP top20;

-- ── 7. Store full output ──────────────────────────────────────────────────────
-- Remove existing output directory (like Sqoop --delete-target-dir)
rmf '/user/bigdata/ecommerce/processed/revenue_by_category'

STORE sorted_categories
    INTO '/user/bigdata/ecommerce/processed/revenue_by_category'
    USING PigStorage(',');
