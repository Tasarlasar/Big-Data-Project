#!/usr/bin/env bash
# =============================================================================
# Sqoop Verification – compare MySQL row counts vs HDFS part file counts
# Big Data Computing CAT II – Project 1
#
# Usage:
#   export MYSQL_PASS=yourpassword
#   bash 02_sqoop_verify.sh
# =============================================================================

set -euo pipefail

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="olist_ecommerce"
MYSQL_USER="root"
MYSQL_PASS="${MYSQL_PASS:-changeme}"
HDFS_ROOT="/user/bigdata/ecommerce/raw/structured"

TABLES=(
    customers
    sellers
    products
    product_category_name_translation
    orders
    order_items
    order_payments
    order_reviews
    geolocation
)

printf "\n%-45s %12s %12s %10s\n" "Table" "MySQL rows" "HDFS rows" "Match?"
printf "%s\n" "$(printf '─%.0s' {1..85})"

for TABLE in "${TABLES[@]}"; do
    MYSQL_COUNT=$(mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASS}" \
        -sN -e "SELECT COUNT(*) FROM ${TABLE};" "${MYSQL_DB}" 2>/dev/null)

    HDFS_COUNT=$(hdfs dfs -cat "${HDFS_ROOT}/${TABLE}/part-m-*" 2>/dev/null | wc -l)

    if [ "$MYSQL_COUNT" -eq "$HDFS_COUNT" ]; then
        MATCH="✓"
    else
        MATCH="✗ MISMATCH"
    fi

    printf "%-45s %12s %12s %10s\n" "${TABLE}" "${MYSQL_COUNT}" "${HDFS_COUNT}" "${MATCH}"
done

echo ""
