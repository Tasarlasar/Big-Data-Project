-- =============================================================================
-- Hive Analytics Queries - E-Commerce Big Data Pipeline
-- Big Data Computing CAT II - Project 1
--
-- Run with:  hive -f 02_analytics_queries.hql
-- =============================================================================

USE default;

SET hive.execution.engine=mr;
SET mapreduce.framework.name=local;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.cli.print.header=true;

-- =============================================================================
-- Q1. Total Orders, Revenue, and Average Order Value
-- =============================================================================
SELECT
    COUNT(DISTINCT o.order_id)            AS total_orders,
    ROUND(SUM(p.payment_value), 2)        AS total_revenue,
    ROUND(AVG(p.payment_value), 2)        AS avg_order_value,
    COUNT(DISTINCT o.customer_id)         AS unique_customers
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';

-- =============================================================================
-- Q2. Revenue by Product Category (English names, top 15)
-- =============================================================================
SELECT
    COALESCE(t.product_category_name_english, 'Unknown')  AS category,
    COUNT(DISTINCT oi.order_id)                            AS order_count,
    COUNT(oi.product_id)                                   AS units_sold,
    ROUND(SUM(oi.price), 2)                               AS total_revenue,
    ROUND(AVG(oi.price), 2)                               AS avg_price
FROM order_items oi
JOIN orders      o  ON oi.order_id    = o.order_id
JOIN products    p  ON oi.product_id  = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(t.product_category_name_english, 'Unknown')
ORDER BY total_revenue DESC
LIMIT 15;

-- =============================================================================
-- Q3. Top 20 Best-Selling Products
-- =============================================================================
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(*)                     AS units_sold,
    ROUND(SUM(oi.price), 2)     AS total_revenue,
    ROUND(AVG(oi.price), 2)     AS avg_price
FROM order_items oi
JOIN orders    o  ON oi.order_id   = o.order_id
JOIN products  p  ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id,
         COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY units_sold DESC
LIMIT 20;

-- =============================================================================
-- Q4. Payment Method Distribution
-- =============================================================================
SELECT
    payment_type,
    COUNT(DISTINCT order_id)          AS order_count,
    ROUND(SUM(payment_value), 2)      AS total_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER (), 2
    )                                 AS pct_of_orders
FROM order_payments
GROUP BY payment_type
ORDER BY order_count DESC;

-- =============================================================================
-- Q5. Customer Lifetime Value - Top 20 customers by total spend
-- =============================================================================
SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id)   AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS lifetime_value,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM customers c
JOIN orders         o  ON c.customer_id = o.customer_id
JOIN order_payments p  ON o.order_id    = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_state
ORDER BY lifetime_value DESC
LIMIT 20;

-- =============================================================================
-- Q6. Review Score Distribution and Average Rating per Category
-- =============================================================================
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(r.review_id)             AS review_count,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS five_star,
    SUM(CASE WHEN r.review_score = 4 THEN 1 ELSE 0 END) AS four_star,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS low_score
FROM order_reviews r
JOIN orders    o  ON r.order_id    = o.order_id
JOIN order_items oi ON o.order_id  = oi.order_id
JOIN products  p  ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY review_count DESC
LIMIT 20;

-- =============================================================================
-- Q7. Products with High Sales but Poor Ratings (below 3.0)
-- =============================================================================
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(oi.order_item_id)          AS units_sold,
    ROUND(SUM(oi.price), 2)         AS total_revenue,
    ROUND(AVG(r.review_score), 2)   AS avg_review_score
FROM order_items oi
JOIN orders    o  ON oi.order_id   = o.order_id
JOIN products  p  ON oi.product_id = p.product_id
JOIN order_reviews r ON o.order_id = r.order_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id,
         COALESCE(t.product_category_name_english, p.product_category_name)
HAVING units_sold >= 10 AND avg_review_score < 3.0
ORDER BY units_sold DESC
LIMIT 20;

-- =============================================================================
-- Q8. Monthly Order Trend (orders and revenue per month)
-- =============================================================================
SELECT
    SUBSTR(order_purchase_timestamp, 1, 7)  AS year_month,
    COUNT(DISTINCT o.order_id)              AS order_count,
    COUNT(DISTINCT o.customer_id)           AS unique_customers,
    ROUND(SUM(p.payment_value), 2)          AS monthly_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_purchase_timestamp != '\\N'
GROUP BY SUBSTR(order_purchase_timestamp, 1, 7)
ORDER BY year_month;

-- =============================================================================
-- Q9. Delivery Time Analysis vs Review Score
-- (Days between purchase and actual delivery, grouped by score)
-- =============================================================================
SELECT
    r.review_score,
    COUNT(*)                                AS orders,
    ROUND(AVG(
        DATEDIFF(
            TO_DATE(o.order_delivered_customer_date),
            TO_DATE(o.order_purchase_timestamp)
        )
    ), 1)                                   AS avg_delivery_days,
    ROUND(MIN(
        DATEDIFF(
            TO_DATE(o.order_delivered_customer_date),
            TO_DATE(o.order_purchase_timestamp)
        )
    ), 1)                                   AS min_delivery_days,
    ROUND(MAX(
        DATEDIFF(
            TO_DATE(o.order_delivered_customer_date),
            TO_DATE(o.order_purchase_timestamp)
        )
    ), 1)                                   AS max_delivery_days
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date != '\\N'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_purchase_timestamp != '\\N'
GROUP BY r.review_score
ORDER BY r.review_score;

-- =============================================================================
-- Q10. On-Time vs Late Delivery Rate
-- =============================================================================
SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
             THEN 'On Time'
        ELSE 'Late'
    END                               AS delivery_status,
    COUNT(*)                          AS order_count,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date != '\\N'
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_estimated_delivery_date != '\\N'
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
             THEN 'On Time'
        ELSE 'Late'
    END;

-- =============================================================================
-- Q11. Seller Performance - Top 20 Sellers by Revenue
-- =============================================================================
SELECT
    oi.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(DISTINCT oi.order_id)       AS orders_fulfilled,
    COUNT(oi.order_item_id)           AS items_sold,
    ROUND(SUM(oi.price), 2)          AS total_revenue,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score
FROM order_items oi
JOIN orders      o  ON oi.order_id  = o.order_id
JOIN sellers     s  ON oi.seller_id = s.seller_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_state, s.seller_city
ORDER BY total_revenue DESC
LIMIT 20;

-- =============================================================================
-- Q12. Amazon Reviews - Average Rating by Verification Status
--      (requires amazon_reviews table populated from PIG output)
-- =============================================================================
SELECT
    CASE WHEN is_verified = 1 THEN 'Verified' ELSE 'Not Verified' END AS purchase_type,
    COUNT(*)                    AS review_count,
    ROUND(AVG(rating), 2)      AS avg_rating,
    SUM(helpful_vote)           AS total_helpful_votes
FROM amazon_reviews
GROUP BY is_verified;

-- =============================================================================
-- Q13. State-Level Sales Heatmap
-- =============================================================================
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)    AS order_count,
    ROUND(SUM(p.payment_value), 2) AS total_spend,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM customers c
JOIN orders         o  ON c.customer_id = o.customer_id
JOIN order_payments p  ON o.order_id    = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_spend DESC;
