-- =============================================================================
-- Olist E-Commerce MySQL Schema
-- Big Data Computing CAT II – Project 1
-- =============================================================================

CREATE DATABASE IF NOT EXISTS olist_ecommerce
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE olist_ecommerce;

-- ---------------------------------------------------------------------------
-- Drop tables in dependency order (children first, parents later)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_category_name_translation;
DROP TABLE IF EXISTS geolocation;

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id             VARCHAR(50)  NOT NULL,
    customer_unique_id      VARCHAR(50)  NOT NULL,
    customer_zip_code_prefix VARCHAR(10) NOT NULL,
    customer_city           VARCHAR(100) NOT NULL,
    customer_state          CHAR(2)      NOT NULL,
    PRIMARY KEY (customer_id),
    INDEX idx_customer_unique (customer_unique_id),
    INDEX idx_customer_state  (customer_state)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- sellers
-- ---------------------------------------------------------------------------
CREATE TABLE sellers (
    seller_id               VARCHAR(50)  NOT NULL,
    seller_zip_code_prefix  VARCHAR(10)  NOT NULL,
    seller_city             VARCHAR(100) NOT NULL,
    seller_state            CHAR(2)      NOT NULL,
    PRIMARY KEY (seller_id),
    INDEX idx_seller_state (seller_state)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
CREATE TABLE products (
    product_id                  VARCHAR(50)  NOT NULL,
    product_category_name       VARCHAR(100),
    product_name_lenght         INT,
    product_description_lenght  INT,
    product_photos_qty          INT,
    product_weight_g            DECIMAL(10,2),
    product_length_cm           DECIMAL(10,2),
    product_height_cm           DECIMAL(10,2),
    product_width_cm            DECIMAL(10,2),
    PRIMARY KEY (product_id),
    INDEX idx_product_category (product_category_name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- product_category_name_translation
-- ---------------------------------------------------------------------------
CREATE TABLE product_category_name_translation (
    product_category_name         VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100) NOT NULL,
    PRIMARY KEY (product_category_name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
    order_id                        VARCHAR(50)  NOT NULL,
    customer_id                     VARCHAR(50)  NOT NULL,
    order_status                    VARCHAR(30)  NOT NULL,
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME,
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer    (customer_id),
    INDEX idx_orders_status      (order_status),
    INDEX idx_orders_purchase_ts (order_purchase_timestamp),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
CREATE TABLE order_items (
    order_id            VARCHAR(50)     NOT NULL,
    order_item_id       INT             NOT NULL,
    product_id          VARCHAR(50)     NOT NULL,
    seller_id           VARCHAR(50)     NOT NULL,
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2)   NOT NULL,
    freight_value       DECIMAL(10,2)   NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_oi_product (product_id),
    INDEX idx_oi_seller  (seller_id),
    CONSTRAINT fk_oi_order   FOREIGN KEY (order_id)   REFERENCES orders   (order_id),
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_oi_seller  FOREIGN KEY (seller_id)  REFERENCES sellers  (seller_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- order_payments
-- ---------------------------------------------------------------------------
CREATE TABLE order_payments (
    order_id             VARCHAR(50)   NOT NULL,
    payment_sequential   INT           NOT NULL,
    payment_type         VARCHAR(30)   NOT NULL,
    payment_installments INT           NOT NULL,
    payment_value        DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    INDEX idx_pay_type (payment_type),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- order_reviews
-- ---------------------------------------------------------------------------
CREATE TABLE order_reviews (
    review_id               VARCHAR(50) NOT NULL,
    order_id                VARCHAR(50) NOT NULL,
    review_score            TINYINT     NOT NULL,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id),
    INDEX idx_rev_order (order_id),
    INDEX idx_rev_score (review_score),
    CONSTRAINT fk_rev_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- geolocation  (no FK – zip codes appear multiple times)
-- ---------------------------------------------------------------------------
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10)    NOT NULL,
    geolocation_lat             DECIMAL(10,6)  NOT NULL,
    geolocation_lng             DECIMAL(10,6)  NOT NULL,
    geolocation_city            VARCHAR(100)   NOT NULL,
    geolocation_state           CHAR(2)        NOT NULL,
    INDEX idx_geo_zip   (geolocation_zip_code_prefix),
    INDEX idx_geo_state (geolocation_state)
) ENGINE=InnoDB;

-- End of schema
