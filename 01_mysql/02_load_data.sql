-- =============================================================================
-- Olist E-Commerce – Load CSV data into MySQL
-- Big Data Computing CAT II – Project 1
--
-- Usage:
--   export DATA_DIR=/path/to/archive
--   sed "s|__DATA_DIR__|${DATA_DIR}|g" 02_load_data.sql | mysql -u root olist_ecommerce
--
-- The DATA_DIR must be accessible to the MySQL process.
-- For LOAD DATA LOCAL INFILE, the path should be relative to the MySQL client.
-- =============================================================================

USE olist_ecommerce;

-- Allow NULL strings in CSV to be inserted as NULL
SET SESSION sql_mode = '';

-- ---------------------------------------------------------------------------
-- Helper: set the base path once (edit this line or use sed to substitute)
-- ---------------------------------------------------------------------------
-- DATA_DIR will be substituted by sed: __DATA_DIR__

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- ---------------------------------------------------------------------------
-- sellers
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, product_name_lenght, product_description_lenght,
 product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm);

-- ---------------------------------------------------------------------------
-- product_category_name_translation
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english);

-- ---------------------------------------------------------------------------
-- orders  (NULL datetime columns handled via @var trick)
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status,
 @order_purchase_timestamp, @order_approved_at,
 @order_delivered_carrier_date, @order_delivered_customer_date,
 @order_estimated_delivery_date)
SET
  order_purchase_timestamp      = NULLIF(@order_purchase_timestamp, ''),
  order_approved_at             = NULLIF(@order_approved_at, ''),
  order_delivered_carrier_date  = NULLIF(@order_delivered_carrier_date, ''),
  order_delivered_customer_date = NULLIF(@order_delivered_customer_date, ''),
  order_estimated_delivery_date = NULLIF(@order_estimated_delivery_date, '');

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);

-- ---------------------------------------------------------------------------
-- order_payments
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- ---------------------------------------------------------------------------
-- order_reviews
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score,
 @review_comment_title, @review_comment_message,
 @review_creation_date, @review_answer_timestamp)
SET
  review_comment_title    = NULLIF(@review_comment_title, ''),
  review_comment_message  = NULLIF(@review_comment_message, ''),
  review_creation_date    = NULLIF(@review_creation_date, ''),
  review_answer_timestamp = NULLIF(@review_answer_timestamp, '');

-- ---------------------------------------------------------------------------
-- geolocation  (large – ~1 M rows; load last)
-- ---------------------------------------------------------------------------
LOAD DATA LOCAL INFILE '__DATA_DIR__/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
 geolocation_city, geolocation_state);

-- ---------------------------------------------------------------------------
-- Verify row counts
-- ---------------------------------------------------------------------------
SELECT 'customers'    AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'sellers',              COUNT(*) AS row_count FROM sellers
UNION ALL
SELECT 'products',             COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'orders',               COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items',          COUNT(*) AS row_count FROM order_items
UNION ALL
SELECT 'order_payments',       COUNT(*) AS row_count FROM order_payments
UNION ALL
SELECT 'order_reviews',        COUNT(*) AS row_count FROM order_reviews
UNION ALL
SELECT 'geolocation',          COUNT(*) AS row_count FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) AS row_count FROM product_category_name_translation;
