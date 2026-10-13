#!/usr/bin/env bash
# =============================================================================
# Upload Olist CSVs directly to HDFS (fallback when Sqoop is unavailable)
# Big Data Computing CAT II – Project 1
#
# Usage:  bash 02_upload_csvs_to_hdfs.sh /path/to/archive
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="${1:-./archive}"
HDFS_ROOT="/user/bigdata/ecommerce/raw/structured"

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "ERROR: Archive directory '$ARCHIVE_DIR' not found."
    exit 1
fi

upload() {
    local src="$1"
    local dst="$2"
    echo "Uploading $(basename $src) → $dst"
    hdfs dfs -put -f "$src" "$dst/"
}

upload "${ARCHIVE_DIR}/olist_customers_dataset.csv"              "${HDFS_ROOT}/customers"
upload "${ARCHIVE_DIR}/olist_orders_dataset.csv"                 "${HDFS_ROOT}/orders"
upload "${ARCHIVE_DIR}/olist_order_items_dataset.csv"            "${HDFS_ROOT}/order_items"
upload "${ARCHIVE_DIR}/olist_order_payments_dataset.csv"         "${HDFS_ROOT}/order_payments"
upload "${ARCHIVE_DIR}/olist_order_reviews_dataset.csv"          "${HDFS_ROOT}/order_reviews"
upload "${ARCHIVE_DIR}/olist_products_dataset.csv"               "${HDFS_ROOT}/products"
upload "${ARCHIVE_DIR}/olist_sellers_dataset.csv"                "${HDFS_ROOT}/sellers"
upload "${ARCHIVE_DIR}/olist_geolocation_dataset.csv"            "${HDFS_ROOT}/geolocation"
upload "${ARCHIVE_DIR}/product_category_name_translation.csv"    "${HDFS_ROOT}/category_translation"

echo ""
echo "Verifying uploads:"
for dir in customers orders order_items order_payments order_reviews products sellers geolocation category_translation; do
    count=$(hdfs dfs -count "${HDFS_ROOT}/${dir}" | awk '{print $3}')
    echo "  ${dir}: ${count} bytes"
done

echo ""
echo "Direct CSV upload to HDFS complete."
