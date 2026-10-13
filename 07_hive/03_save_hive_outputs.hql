-- =============================================================================
-- Save key Hive query results as HDFS tables for downstream use / reporting
-- Big Data Computing CAT II - Project 1
--
-- Run with:  hive -f 03_save_hive_outputs.hql
-- =============================================================================

USE olist_ecommerce;

SET hive.exec.dynamic.partition.mode=nonstrict;

-- -- Revenue by category -------------------------------------------------------
DROP TABLE IF EXISTS result_revenue_by_category;
CREATE TABLE result_revenue_by_category
STORED AS ORC
AS
SELECT
    COALESCE(t.product_category_name_english, 'Unknown')  AS category,
    COUNT(DISTINCT oi.order_id)  AS order_count,
    COUNT(oi.product_id)         AS units_sold,
    ROUND(SUM(oi.price), 2)     AS total_revenue,
    ROUND(AVG(oi.price), 2)     AS avg_price
FROM order_items oi
JOIN orders   o  ON oi.order_id   = o.order_id
JOIN products p  ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(t.product_category_name_english, 'Unknown')
ORDER BY total_revenue DESC;

-- -- Delivery time vs review score ---------------------------------------------
DROP TABLE IF EXISTS result_delivery_vs_score;
CREATE TABLE result_delivery_vs_score
STORED AS ORC
AS
SELECT
    r.review_score,
    COUNT(*)  AS orders,
    ROUND(AVG(DATEDIFF(
        TO_DATE(o.order_delivered_customer_date),
        TO_DATE(o.order_purchase_timestamp)
    )), 1)    AS avg_delivery_days
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date != '\\N'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_purchase_timestamp != '\\N'
GROUP BY r.review_score
ORDER BY r.review_score;

-- -- Monthly trend -------------------------------------------------------------
DROP TABLE IF EXISTS result_monthly_trend;
CREATE TABLE result_monthly_trend
STORED AS ORC
AS
SELECT
    SUBSTR(o.order_purchase_timestamp, 1, 7) AS year_month,
    COUNT(DISTINCT o.order_id)               AS order_count,
    ROUND(SUM(p.payment_value), 2)           AS monthly_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_purchase_timestamp != '\\N'
GROUP BY SUBSTR(o.order_purchase_timestamp, 1, 7)
ORDER BY year_month;

SHOW TABLES LIKE 'result*';
