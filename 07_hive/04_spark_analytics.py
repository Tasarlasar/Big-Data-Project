#!/usr/bin/env python3
"""
Spark Analytics - E-Commerce Big Data Pipeline
Big Data Computing CAT II - Project 1

Run with:  pyspark 04_spark_analytics.py
           python3 04_spark_analytics.py  (if using Spark in local mode)

This script reads PIG and Hive outputs and runs the 13 analytics queries
using Spark SQL instead of Hive (which has compatibility issues on macOS).
"""

import sys
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.window import Window

# Set up Spark session
spark = SparkSession.builder \
    .appName("E-Commerce Analytics") \
    .master("local[*]") \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "4g") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

HDFS_BASE = "hdfs://localhost:9000/user/bigdata/ecommerce"
OUTPUT_DIR = "/Users/home/College/Big Data Computing/E-commerce/08_run/spark_outputs"

# Create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("=" * 70)
print(" E-Commerce Analytics with Spark SQL")
print("=" * 70)

# =============================================================================
# Q1. Total Orders, Revenue, and Average Order Value
# =============================================================================
print("\n── Q1. Total Orders, Revenue, and Average Order Value ──")

# Load orders (from Hive table or PIG output)
orders_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/orders"
).filter(col("order_status") == "delivered")

payments_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/order_payments"
)

# Aggregate
q1_result = orders_df.join(
    payments_df.select("order_id", "payment_value"),
    on="order_id",
    how="inner"
).agg(
    countDistinct("order_id").alias("total_orders"),
    round(sum("payment_value"), 2).alias("total_revenue"),
    round(avg("payment_value"), 2).alias("avg_order_value"),
    countDistinct("customer_id").alias("unique_customers")
)

q1_result.show()
q1_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q1_total_orders_revenue")

# =============================================================================
# Q2. Revenue by Product Category (English names, top 15)
# =============================================================================
print("\n── Q2. Revenue by Product Category (English names, top 15) ──")

# Load products and category translation
products_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/products"
)
category_trans_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/category_translation"
)

# Load order items
order_items_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/order_items"
)

# Join and aggregate
q2_result = order_items_df.alias("oi") \
    .join(products_df.alias("p"), col("oi.product_id") == col("p.product_id"), "inner") \
    .join(category_trans_df.alias("t"), col("p.product_category_name") == col("t.product_category_name"), "left") \
    .groupBy(coalesce(col("t.product_category_name_english"), lit("Unknown")).alias("category")) \
    .agg(
        countDistinct("oi.order_id").alias("order_count"),
        count("oi.product_id").alias("item_count"),
        round(sum("oi.price"), 2).alias("total_revenue"),
        round(avg("oi.price"), 2).alias("avg_price")
    ) \
    .orderBy(desc("total_revenue")) \
    .limit(15)

q2_result.show()
q2_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q2_revenue_by_category")

# =============================================================================
# Q3. Top Products by Total Revenue (top 50)
# =============================================================================
print("\n── Q3. Top Products by Total Revenue (top 50) ──")

# Load orders_joined from PIG output
orders_joined_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/processed/orders_joined"
)

q3_result = orders_joined_df.groupBy("product_id", "category_en") \
    .agg(
        count("order_id").alias("units_sold"),
        round(sum("total_item_cost"), 2).alias("total_revenue"),
        round(avg("item_price"), 2).alias("avg_price")
    ) \
    .orderBy(desc("total_revenue")) \
    .limit(50)

q3_result.show()
q3_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q3_top_products_revenue")

# =============================================================================
# Q4. Payment Methods Distribution
# =============================================================================
print("\n── Q4. Payment Methods Distribution ──")

q4_result = payments_df.groupBy("payment_type") \
    .agg(
        count("*").alias("count"),
        countDistinct("order_id").alias("order_count"),
        round(sum("payment_value"), 2).alias("total_value")
    ) \
    .orderBy(desc("count"))

q4_result.show()
q4_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q4_payment_methods")

# =============================================================================
# Q5. Customer Lifetime Value (CLV)
# =============================================================================
print("\n── Q5. Customer Lifetime Value (CLV) ──")

# Load customers and orders
customers_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/customers"
)

# CLV = sum of all order payments per customer
q5_result = payments_df.groupBy("order_id") \
    .agg(sum("payment_value").alias("order_value")) \
    .join(orders_df.select("order_id", "customer_id"), on="order_id") \
    .groupBy("customer_id") \
    .agg(
        countDistinct("order_id").alias("order_count"),
        sum("order_value").alias("total_clv"),
        round(avg("order_value"), 2).alias("avg_order_value")
    ) \
    .orderBy(desc("total_clv")) \
    .limit(50)

q5_result.show()
q5_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q5_customer_clv")

# =============================================================================
# Q6. Reviews by Category
# =============================================================================
print("\n── Q6. Reviews by Category ──")

# Load amazon_reviews from PIG output
reviews_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/processed/reviews_filtered"
)

# Join with products and categories
q6_result = reviews_df.alias("r") \
    .join(products_df.alias("p"), col("r.asin") == col("p.product_id"), "left") \
    .join(category_trans_df.alias("t"), col("p.product_category_name") == col("t.product_category_name"), "left") \
    .groupBy(coalesce(col("t.product_category_name_english"), lit("Unknown")).alias("category")) \
    .agg(
        count("*").alias("review_count"),
        round(avg("rating"), 2).alias("avg_rating"),
        round(stddev("rating"), 2).alias("rating_stddev"),
        countDistinct("user_id").alias("unique_reviewers")
    ) \
    .orderBy(desc("review_count"))

q6_result.show()
q6_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q6_reviews_by_category")

# =============================================================================
# Q7. High-Sales Products with Poor Ratings (top 20)
# =============================================================================
print("\n── Q7. High-Sales Products with Poor Ratings (top 20) ──")

q7_result = reviews_df.groupBy("asin") \
    .agg(
        count("*").alias("review_count"),
        avg("rating").alias("avg_rating")
    ) \
    .filter(col("review_count") >= 10) \
    .filter(col("avg_rating") < 3.0) \
    .orderBy(desc("review_count")) \
    .limit(20)

q7_result.show()
q7_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q7_high_sales_poor_ratings")

# =============================================================================
# Q8. Monthly Order Trend
# =============================================================================
print("\n── Q8. Monthly Order Trend ──")

# Parse order purchase timestamp and extract year-month
q8_result = orders_df \
    .filter(col("order_purchase_timestamp").isNotNull()) \
    .withColumn("year_month", substring("order_purchase_timestamp", 1, 7)) \
    .groupBy("year_month") \
    .agg(
        count("*").alias("order_count"),
        round(sum(payments_df.select("payment_value").filter(
            payments_df.order_id == orders_df.order_id
        ).alias("total_payment")), 2).alias("total_revenue")
    ) \
    .orderBy("year_month")

# Simplified - just count orders per month
q8_result = orders_df \
    .filter(col("order_purchase_timestamp").isNotNull()) \
    .withColumn("year_month", substring("order_purchase_timestamp", 1, 7)) \
    .groupBy("year_month") \
    .agg(count("*").alias("order_count")) \
    .orderBy("year_month")

q8_result.show()
q8_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q8_monthly_trend")

# =============================================================================
# Q9. Delivery Performance vs. Review Score
# =============================================================================
print("\n── Q9. Delivery Performance vs. Review Score ──")

# Calculate delivery time
q9_result = orders_df \
    .filter(
        (col("order_delivered_customer_date").isNotNull()) &
        (col("order_purchase_timestamp").isNotNull())
    ) \
    .withColumn("delivery_days", 
        (unix_timestamp("order_delivered_customer_date") - 
         unix_timestamp("order_purchase_timestamp")) / 86400) \
    .groupBy("order_status") \
    .agg(
        count("*").alias("order_count"),
        round(avg("delivery_days"), 2).alias("avg_delivery_days"),
        round(min("delivery_days"), 2).alias("min_delivery_days"),
        round(max("delivery_days"), 2).alias("max_delivery_days")
    )

q9_result.show()
q9_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q9_delivery_performance")

# =============================================================================
# Q10. Delivery Rate by State
# =============================================================================
print("\n── Q10. Delivery Rate by State ──")

# Load geolocation and customers
geolocation_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/geolocation"
)

# Get state from customer zip code
customers_with_state = customers_df.join(
    geolocation_df.select(
        col("geolocation_zip_code_prefix").alias("customer_zip_code_prefix"),
        "geolocation_state"
    ),
    on="customer_zip_code_prefix"
)

q10_result = orders_df.alias("o") \
    .join(customers_with_state.alias("c"), col("o.customer_id") == col("c.customer_id")) \
    .groupBy("geolocation_state") \
    .agg(
        count("*").alias("total_orders"),
        sum(when(col("o.order_status") == "delivered", 1).otherwise(0)).alias("delivered_orders"),
        round(sum(when(col("o.order_status") == "delivered", 1).otherwise(0)) / count("*") * 100, 2).alias("delivery_rate_pct")
    ) \
    .orderBy(desc("delivery_rate_pct"))

q10_result.show()
q10_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q10_delivery_rate_by_state")

# =============================================================================
# Q11. Seller Performance
# =============================================================================
print("\n── Q11. Seller Performance ──")

# Load order items and sellers
order_items_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/order_items"
)

sellers_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/sellers"
)

q11_result = order_items_df.groupBy("seller_id") \
    .agg(
        countDistinct("order_id").alias("order_count"),
        count("*").alias("item_count"),
        round(sum("price"), 2).alias("total_revenue"),
        round(avg("price"), 2).alias("avg_item_price")
    ) \
    .orderBy(desc("total_revenue")) \
    .limit(20)

q11_result.show()
q11_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q11_seller_performance")

# =============================================================================
# Q12. Review Score Distribution
# =============================================================================
print("\n── Q12. Review Score Distribution ──")

# Load order reviews
order_reviews_df = spark.read.option("header", "true").csv(
    f"{HDFS_BASE}/raw/structured/order_reviews"
)

q12_result = order_reviews_df.groupBy("review_score") \
    .agg(
        count("*").alias("count"),
        round(count("*") / sum(count("*")).over(Window.partitionBy()) * 100, 2).alias("percentage")
    ) \
    .orderBy("review_score")

q12_result.show()
q12_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q12_review_distribution")

# =============================================================================
# Q13. State Revenue Heatmap (Revenue by State)
# =============================================================================
print("\n── Q13. State Revenue Heatmap ──")

q13_result = orders_df.alias("o") \
    .join(customers_with_state.alias("c"), col("o.customer_id") == col("c.customer_id")) \
    .join(payments_df.alias("p"), col("o.order_id") == col("p.order_id")) \
    .groupBy("geolocation_state") \
    .agg(
        countDistinct("o.order_id").alias("order_count"),
        round(sum("p.payment_value"), 2).alias("total_revenue"),
        round(avg("p.payment_value"), 2).alias("avg_order_value")
    ) \
    .orderBy(desc("total_revenue"))

q13_result.show()
q13_result.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{OUTPUT_DIR}/q13_state_revenue")

print("\n" + "=" * 70)
print(" Spark Analytics complete!")
print(f" Results saved to: {OUTPUT_DIR}")
print("=" * 70)

# Stop Spark
spark.stop()
