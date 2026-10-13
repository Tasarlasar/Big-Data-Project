-- =============================================================================
-- PIG Script 3: Join Olist Orders, Items, Products, and Payments
-- Big Data Computing CAT II – Project 1
--
-- Inputs:  HDFS raw/structured/{orders, order_items, products, order_payments,
--                               category_translation}
-- Output:  processed/orders_joined
--
-- Operations demonstrated: LOAD, JOIN, FILTER, FOREACH, STORE
-- =============================================================================

-- ── 1. Load raw Olist tables ──────────────────────────────────────────────────
orders = LOAD '/user/bigdata/ecommerce/raw/structured/orders'
         USING PigStorage(',')
         AS (order_id:chararray,
             customer_id:chararray,
             order_status:chararray,
             order_purchase_timestamp:chararray,
             order_approved_at:chararray,
             order_delivered_carrier_date:chararray,
             order_delivered_customer_date:chararray,
             order_estimated_delivery_date:chararray);

order_items = LOAD '/user/bigdata/ecommerce/raw/structured/order_items'
              USING PigStorage(',')
              AS (order_id:chararray,
                  order_item_id:int,
                  product_id:chararray,
                  seller_id:chararray,
                  shipping_limit_date:chararray,
                  price:float,
                  freight_value:float);

products = LOAD '/user/bigdata/ecommerce/raw/structured/products'
           USING PigStorage(',')
           AS (product_id:chararray,
               product_category_name:chararray,
               product_name_lenght:int,
               product_description_lenght:int,
               product_photos_qty:int,
               product_weight_g:float,
               product_length_cm:float,
               product_height_cm:float,
               product_width_cm:float);

payments = LOAD '/user/bigdata/ecommerce/raw/structured/order_payments'
           USING PigStorage(',')
           AS (order_id:chararray,
               payment_sequential:int,
               payment_type:chararray,
               payment_installments:int,
               payment_value:float);

category_trans = LOAD '/user/bigdata/ecommerce/raw/structured/category_translation'
                 USING PigStorage(',')
                 AS (product_category_name:chararray,
                     product_category_name_english:chararray);

-- ── 2. Filter: keep only 'delivered' orders ───────────────────────────────────
delivered_orders = FILTER orders BY order_status == 'delivered';

-- ── 3. Skip CSV header rows (Sqoop imports have no header; direct uploads do) ─
-- Remove rows where order_id looks like the header string
clean_orders  = FILTER delivered_orders  BY order_id   != 'order_id';
clean_items   = FILTER order_items       BY order_id   != 'order_id';
clean_products= FILTER products          BY product_id != 'product_id';
clean_payments= FILTER payments          BY order_id   != 'order_id';
clean_cats    = FILTER category_trans    BY product_category_name != 'product_category_name';

-- ── 4. Aggregate payments: one row per order (total_payment, primary type) ────
grouped_payments = GROUP clean_payments BY order_id;
agg_payments = FOREACH grouped_payments GENERATE
    group                                AS order_id,
    SUM(clean_payments.payment_value)    AS total_payment,
    COUNT(clean_payments)                AS payment_count;

-- ── 5. Join items ↔ products ↔ category translation ───────────────────────────
items_products = JOIN clean_items    BY product_id,
                      clean_products BY product_id;

items_products_cat = JOIN items_products BY clean_products::product_category_name LEFT OUTER,
                          clean_cats     BY product_category_name;

-- Flatten and rename for clarity
items_enriched = FOREACH items_products_cat GENERATE
    clean_items::order_id                              AS order_id,
    clean_items::order_item_id                         AS order_item_id,
    clean_items::product_id                            AS product_id,
    clean_items::seller_id                             AS seller_id,
    clean_items::price                                 AS item_price,
    clean_items::freight_value                         AS freight_value,
    clean_products::product_category_name              AS category_pt,
    clean_cats::product_category_name_english          AS category_en;

-- ── 6. Join orders ↔ enriched items ↔ payments ────────────────────────────────
orders_items = JOIN clean_orders   BY order_id,
                    items_enriched BY order_id;

orders_items_payments = JOIN orders_items  BY clean_orders::order_id LEFT OUTER,
                             agg_payments  BY order_id;

-- ── 7. Final projection ───────────────────────────────────────────────────────
orders_joined = FOREACH orders_items_payments GENERATE
    clean_orders::order_id                             AS order_id,
    clean_orders::customer_id                          AS customer_id,
    clean_orders::order_status                         AS order_status,
    clean_orders::order_purchase_timestamp             AS purchase_ts,
    clean_orders::order_delivered_customer_date        AS delivered_ts,
    clean_orders::order_estimated_delivery_date        AS estimated_delivery_ts,
    items_enriched::order_item_id                      AS item_id,
    items_enriched::product_id                         AS product_id,
    items_enriched::seller_id                          AS seller_id,
    items_enriched::item_price                         AS item_price,
    items_enriched::freight_value                      AS freight_value,
    (items_enriched::item_price + items_enriched::freight_value) AS total_item_cost,
    items_enriched::category_pt                        AS category_pt,
    items_enriched::category_en                        AS category_en,
    agg_payments::total_payment                        AS order_total_payment;

-- ── 8. Store joined dataset ───────────────────────────────────────────────────
-- Remove existing output directory (like Sqoop --delete-target-dir)
rmf '/user/bigdata/ecommerce/processed/orders_joined'

STORE orders_joined
    INTO '/user/bigdata/ecommerce/processed/orders_joined'
    USING PigStorage(',');

-- Quick row count
cnt = FOREACH (GROUP orders_joined ALL) GENERATE COUNT(orders_joined);
DUMP cnt;
