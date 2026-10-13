#!/usr/bin/env bash
# =============================================================================
# HDFS Directory Setup – E-Commerce Big Data Pipeline
# Big Data Computing CAT II – Project 1
#
# Run on the Hadoop edge/master node after HDFS is running.
# Usage:  bash 01_hdfs_setup.sh
# =============================================================================

set -euo pipefail

HDFS_ROOT="/user/bigdata/ecommerce"

echo "=================================================="
echo " Creating HDFS directory structure under ${HDFS_ROOT}"
echo "=================================================="

# ---------------------------------------------------------------------------
# 1. Raw structured data  (Olist CSVs imported via Sqoop)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/customers
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/orders
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/order_items
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/order_payments
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/order_reviews
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/products
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/sellers
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/geolocation
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/structured/category_translation

# ---------------------------------------------------------------------------
# 2. Raw semi-structured data  (Amazon JSONL)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/semi_structured/amazon_reviews
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/semi_structured/amazon_metadata

# ---------------------------------------------------------------------------
# 3. Unstructured data  (Amazon product images / videos)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/unstructured/product_images
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/unstructured/product_videos

# ---------------------------------------------------------------------------
# 4. Processed / intermediate data  (PIG outputs)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/reviews_filtered
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/reviews_by_product
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/reviews_by_category
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/orders_joined
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/top_products
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/revenue_by_category

# ---------------------------------------------------------------------------
# 5. Analytical outputs  (Hive external table locations)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/customers
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/orders
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/order_items
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/order_payments
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/order_reviews
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/products
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/sellers
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/amazon_reviews
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive/category_translation

# ---------------------------------------------------------------------------
# 6. Set permissions so all cluster users can write
# ---------------------------------------------------------------------------
hdfs dfs -chmod -R 775 ${HDFS_ROOT}

# ---------------------------------------------------------------------------
# 7. Verify structure
# ---------------------------------------------------------------------------
echo ""
echo "Final HDFS directory tree:"
hdfs dfs -ls -R ${HDFS_ROOT} | awk '{print $NF}' | sort

echo ""
echo "Done. HDFS directories created successfully."
