-- =============================================================================
-- Quick schema and data-quality verification queries
-- =============================================================================

USE olist_ecommerce;

-- 1. Table overview
SHOW TABLES;

-- 2. Row counts (expected: ~99k customers, ~99k orders, ~112k items, etc.)
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'olist_ecommerce'
ORDER BY TABLE_ROWS DESC;

-- 3. Orders with NULL purchase timestamp (should be 0)
SELECT COUNT(*) AS null_purchase_ts FROM orders WHERE order_purchase_timestamp IS NULL;

-- 4. Order status distribution
SELECT order_status, COUNT(*) AS cnt
FROM orders
GROUP BY order_status
ORDER BY cnt DESC;

-- 5. Payment type distribution
SELECT payment_type, COUNT(*) AS cnt, ROUND(SUM(payment_value),2) AS total_value
FROM order_payments
GROUP BY payment_type
ORDER BY cnt DESC;

-- 6. Review score distribution
SELECT review_score, COUNT(*) AS cnt
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 7. Products without a category
SELECT COUNT(*) AS no_category FROM products WHERE product_category_name IS NULL OR product_category_name = '';

-- 8. Top 10 product categories by product count
SELECT p.product_category_name,
       t.product_category_name_english,
       COUNT(*) AS product_count
FROM products p
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY p.product_category_name, t.product_category_name_english
ORDER BY product_count DESC
LIMIT 10;
