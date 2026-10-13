-- =============================================================================
-- Hive Table Creation - E-Commerce Big Data Pipeline
-- Big Data Computing CAT II - Project 1
--
-- Creates external Hive tables pointing to HDFS data.
-- Using EXTERNAL tables preserves data in HDFS if the table is dropped.
--
-- Run with:  hive -f 01_create_tables.hql
--            beeline -u jdbc:hive2://localhost:10000 -f 01_create_tables.hql
-- =============================================================================

-- Tables are created in the default database

-- -----------------------------------------------------------------------------
-- 1. customers
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS customers;
CREATE EXTERNAL TABLE customers (
    customer_id              STRING,
    customer_unique_id       STRING,
    customer_zip_code_prefix STRING,
    customer_city            STRING,
    customer_state           STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/customers'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 2. sellers
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS sellers;
CREATE EXTERNAL TABLE sellers (
    seller_id              STRING,
    seller_zip_code_prefix STRING,
    seller_city            STRING,
    seller_state           STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/sellers'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 3. products
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS products;
CREATE EXTERNAL TABLE products (
    product_id                 STRING,
    product_category_name      STRING,
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           DOUBLE,
    product_length_cm          DOUBLE,
    product_height_cm          DOUBLE,
    product_width_cm           DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/products'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 4. category_translation
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS category_translation;
CREATE EXTERNAL TABLE category_translation (
    product_category_name         STRING,
    product_category_name_english STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/category_translation'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 5. orders
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE EXTERNAL TABLE orders (
    order_id                      STRING,
    customer_id                   STRING,
    order_status                  STRING,
    order_purchase_timestamp      STRING,
    order_approved_at             STRING,
    order_delivered_carrier_date  STRING,
    order_delivered_customer_date STRING,
    order_estimated_delivery_date STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/orders'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 6. order_items
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE EXTERNAL TABLE order_items (
    order_id            STRING,
    order_item_id       INT,
    product_id          STRING,
    seller_id           STRING,
    shipping_limit_date STRING,
    price               DOUBLE,
    freight_value       DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/order_items'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 7. order_payments
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS order_payments;
CREATE EXTERNAL TABLE order_payments (
    order_id             STRING,
    payment_sequential   INT,
    payment_type         STRING,
    payment_installments INT,
    payment_value        DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/order_payments'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 8. order_reviews
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS order_reviews;
CREATE EXTERNAL TABLE order_reviews (
    review_id               STRING,
    order_id                STRING,
    review_score            INT,
    review_comment_title    STRING,
    review_comment_message  STRING,
    review_creation_date    STRING,
    review_answer_timestamp STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/raw/structured/order_reviews'
TBLPROPERTIES ("skip.header.line.count"="1");

-- -----------------------------------------------------------------------------
-- 9. amazon_reviews  (from PIG-processed filtered reviews)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS amazon_reviews;
CREATE EXTERNAL TABLE amazon_reviews (
    asin          STRING,
    parent_asin   STRING,
    user_id       STRING,
    rating        FLOAT,
    title         STRING,
    review_text   STRING,
    helpful_vote  INT,
    is_verified   INT,
    ts            BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/processed/reviews_filtered';

-- -----------------------------------------------------------------------------
-- 10. orders_joined  (PIG-processed enriched orders)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS orders_joined;
CREATE EXTERNAL TABLE orders_joined (
    order_id            STRING,
    customer_id         STRING,
    order_status        STRING,
    purchase_ts         STRING,
    delivered_ts        STRING,
    estimated_ts        STRING,
    item_id             INT,
    product_id          STRING,
    seller_id           STRING,
    item_price          DOUBLE,
    freight_value       DOUBLE,
    total_item_cost     DOUBLE,
    category_pt         STRING,
    category_en         STRING,
    order_total_payment DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/processed/orders_joined';

-- -----------------------------------------------------------------------------
-- 11. revenue_by_category  (PIG-processed)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS revenue_by_category;
CREATE EXTERNAL TABLE revenue_by_category (
    category          STRING,
    item_count        BIGINT,
    total_revenue     DOUBLE,
    avg_item_price    DOUBLE,
    min_price         DOUBLE,
    max_price         DOUBLE,
    total_freight     DOUBLE,
    distinct_orders   BIGINT,
    distinct_products BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/ecommerce/processed/revenue_by_category';

-- -----------------------------------------------------------------------------
-- Verify all tables are visible
-- -----------------------------------------------------------------------------
SHOW TABLES;
