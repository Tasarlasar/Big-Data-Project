-- =============================================================================
-- PIG Script 5: Top-Selling Products (by revenue and unit count)
-- Big Data Computing CAT II – Project 1
--
-- Input:  processed/orders_joined  (output of script 03)
-- Output: processed/top_products
--
-- Operations demonstrated: LOAD, FILTER, GROUP, FOREACH, ORDER, LIMIT, STORE
-- =============================================================================

-- ── 1. Load joined orders ─────────────────────────────────────────────────────
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

-- ── 2. Filter invalid rows ────────────────────────────────────────────────────
valid = FILTER joined BY
    (product_id IS NOT NULL) AND
    (item_price > 0.0);

-- ── 3. Group by product ───────────────────────────────────────────────────────
by_product = GROUP valid BY (product_id, category_en);

-- ── 4. Aggregate per product ──────────────────────────────────────────────────
-- NOTE: COUNT(DISTINCT x) is not a valid inline expression in Pig; build the
-- distinct bags inside a nested FOREACH block first.
product_stats = FOREACH by_product {
    distinct_sellers = DISTINCT valid.seller_id;
    distinct_orders  = DISTINCT valid.order_id;
    GENERATE
        FLATTEN(group)                  AS (product_id, category_en),
        COUNT(valid)                    AS units_sold,
        SUM(valid.item_price)           AS total_revenue,
        AVG(valid.item_price)           AS avg_price,
        COUNT(distinct_sellers)         AS seller_count,
        COUNT(distinct_orders)          AS order_count;
};

-- ── 5. Order by total revenue descending ─────────────────────────────────────
by_revenue = ORDER product_stats BY total_revenue DESC;
top100_by_revenue = LIMIT by_revenue 100;

-- ── 6. Order by units sold descending ────────────────────────────────────────
by_units  = ORDER product_stats BY units_sold DESC;
top100_by_units = LIMIT by_units 100;

DUMP top100_by_revenue;

-- ── 7. Store outputs ──────────────────────────────────────────────────────────
-- Remove existing output directory (like Sqoop --delete-target-dir)
rmf '/user/bigdata/ecommerce/processed/top_products'

STORE by_revenue
    INTO '/user/bigdata/ecommerce/processed/top_products'
    USING PigStorage(',');
