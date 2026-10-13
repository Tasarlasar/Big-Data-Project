#!/usr/bin/env bash
# =============================================================================
# Sqoop Import – MySQL → HDFS
# Big Data Computing CAT II – Project 1
#
# Imports all Olist relational tables from MySQL into HDFS using Sqoop.
# Each table lands in its dedicated HDFS directory as CSV (text) with a
# comma delimiter so Hive can read it directly.
#
# Prerequisites:
#   - Sqoop installed and on PATH
#   - MySQL JDBC driver in $SQOOP_HOME/lib
#   - MySQL server reachable from the Hadoop edge node
#   - HDFS directories already created (run 02_hdfs/01_hdfs_setup.sh first)
#
# Usage:
#   export MYSQL_PASS=yourpassword
#   bash 01_sqoop_import.sh
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration – edit these to match your environment
# ---------------------------------------------------------------------------
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="olist_ecommerce"
MYSQL_USER="root"
MYSQL_PASS="${MYSQL_PASS:-changeme}"          # prefer passing via env variable
HDFS_ROOT="/user/bigdata/ecommerce/raw/structured"
NUM_MAPPERS=4                                 # tune to available cluster nodes
JDBC_URL="jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}?useSSL=false&serverTimezone=UTC"

# ---------------------------------------------------------------------------
# Helper: import one table
# ---------------------------------------------------------------------------
sqoop_import() {
    local TABLE="$1"
    local SPLIT_COL="${2:-}"        # column used for parallelism; empty = single mapper
    local TARGET="${HDFS_ROOT}/${TABLE}"

    echo ""
    echo "── Importing table: ${TABLE} ──────────────────────────────"

    # Remove existing HDFS directory so re-runs don't fail
    hdfs dfs -rm -r -f "${TARGET}" || true

    local SPLIT_ARG=""
    if [ -n "$SPLIT_COL" ]; then
        SPLIT_ARG="--split-by ${SPLIT_COL} -m ${NUM_MAPPERS}"
    else
        SPLIT_ARG="-m 1"
    fi

    sqoop import \
        --connect          "${JDBC_URL}" \
        --username         "${MYSQL_USER}" \
        --password         "${MYSQL_PASS}" \
        --table            "${TABLE}" \
        --target-dir       "${TARGET}" \
        --fields-terminated-by ',' \
        --lines-terminated-by  '\n' \
        --null-string      '\\N' \
        --null-non-string  '\\N' \
        --delete-target-dir \
        ${SPLIT_ARG}

    echo "   Rows in HDFS:"
    hdfs dfs -cat "${TARGET}/part-m-*" 2>/dev/null | wc -l || echo "   (check manually)"
}

# ---------------------------------------------------------------------------
# Import each table
# Note: split-by column must be numeric for multi-mapper imports.
#       Tables with no obvious numeric PK use -m 1.
# ---------------------------------------------------------------------------
sqoop_import "customers"                         ""                      # ~99 k rows; no numeric PK
sqoop_import "sellers"                           ""                      # ~3 k rows
sqoop_import "products"                          ""                      # ~33 k rows
sqoop_import "product_category_name_translation" ""                      # 71 rows
sqoop_import "orders"                            ""                      # ~99 k rows
sqoop_import "order_items"                       "order_item_id"         # ~113 k rows
sqoop_import "order_payments"                    "payment_sequential"    # ~104 k rows
sqoop_import "order_reviews"                     ""                      # ~105 k rows
sqoop_import "geolocation"                       ""                      # ~1 M rows (use -m 1 to avoid Cartesian)

echo ""
echo "All Sqoop imports complete."
echo "Verify with: hdfs dfs -ls /user/bigdata/ecommerce/raw/structured/"
