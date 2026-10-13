#!/usr/bin/env bash
# =============================================================================
# Master Pipeline Runner – E-Commerce Big Data Pipeline
# Big Data Computing CAT II – Project 1
#
# Runs the full pipeline end-to-end in the correct dependency order.
#
# Usage:
#   export MYSQL_PASS=yourpassword
#   bash run_pipeline.sh [--skip-download] [--skip-mysql] [--skip-mongo]
#
# Flags:
#   --skip-download   Skip Amazon data download (use if already done)
#   --skip-mysql      Skip MySQL schema + load (use if already done)
#   --skip-mongo      Skip MongoDB import (use if already done)
# =============================================================================

set -eo pipefail

# Set JAVA_HOME for all tools
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

SKIP_DOWNLOAD=false
SKIP_MYSQL=false
SKIP_MONGO=false

for arg in "$@"; do
    case $arg in
        --skip-download) SKIP_DOWNLOAD=true ;;
        --skip-mysql)    SKIP_MYSQL=true    ;;
        --skip-mongo)    SKIP_MONGO=true    ;;
    esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

log() { echo ""; echo "▶ $*"; echo "$(date '+%Y-%m-%d %H:%M:%S')"; }

# ─── Step 1: HDFS Setup ───────────────────────────────────────────────────────
log "[1/8] Setting up HDFS directories"
bash "${ROOT}/02_hdfs/01_hdfs_setup.sh"

# ─── Step 2: MySQL Schema ─────────────────────────────────────────────────────
if [ "$SKIP_MYSQL" = false ]; then
    log "[2/8] Creating MySQL schema"
    if [ -n "${MYSQL_PASS:-}" ]; then
        mysql -u root -p"${MYSQL_PASS}" < "${ROOT}/01_mysql/01_create_schema.sql"
    else
        mysql -u root < "${ROOT}/01_mysql/01_create_schema.sql"
    fi

    log "[2/8] Loading Olist CSVs into MySQL"
    ARCHIVE="${ROOT}/archive"
    if [ -n "${MYSQL_PASS:-}" ]; then
        sed "s|__DATA_DIR__|${ARCHIVE}|g" "${ROOT}/01_mysql/02_load_data.sql" \
            | mysql --local-infile -u root -p"${MYSQL_PASS}" olist_ecommerce
    else
        sed "s|__DATA_DIR__|${ARCHIVE}|g" "${ROOT}/01_mysql/02_load_data.sql" \
            | mysql --local-infile -u root olist_ecommerce
    fi
else
    log "[2/8] Skipping MySQL (--skip-mysql)"
fi

# ─── Step 3: Sqoop-equivalent Import (MySQL → HDFS) ──────────────────────────
# Sqoop 1.4.7 is incompatible with Hadoop 3.5, so we use the Python equivalent
log "[3/8] Running Sqoop-equivalent import (MySQL → HDFS)"
if [ -n "${MYSQL_PASS:-}" ]; then
    python3 "${ROOT}/03_sqoop/03_sqoop_equivalent.py" --mappers 4 --password "${MYSQL_PASS}"
else
    python3 "${ROOT}/03_sqoop/03_sqoop_equivalent.py" --mappers 4
fi

# ─── Step 4: Amazon Data to HDFS ─────────────────────────────────────────────
if [ "$SKIP_DOWNLOAD" = false ]; then
    log "[4/8] Downloading and staging Amazon Reviews data"
    bash "${ROOT}/04_amazon_hdfs/01_download_amazon_data.sh" --sample
else
    log "[4/8] Skipping Amazon download (--skip-download)"
    log "      Uploading any existing staged Amazon data to HDFS…"
    STAGING="/tmp/amazon_staging"
    HDFS_REVIEWS="/user/bigdata/ecommerce/raw/semi_structured/amazon_reviews"
    HDFS_META="/user/bigdata/ecommerce/raw/semi_structured/amazon_metadata"
    [ -f "${STAGING}/reviews/Automotive_sample.jsonl" ] && \
        hdfs dfs -put -f "${STAGING}/reviews/Automotive_sample.jsonl" "${HDFS_REVIEWS}/"
    [ -f "${STAGING}/metadata/meta_Automotive_sample.jsonl" ] && \
        hdfs dfs -put -f "${STAGING}/metadata/meta_Automotive_sample.jsonl" "${HDFS_META}/"
fi

# ─── Step 5: MongoDB Setup ────────────────────────────────────────────────────
if [ "$SKIP_MONGO" = false ]; then
    log "[5/8] Setting up MongoDB collections"
    mongosh --file "${ROOT}/05_mongodb/01_setup_collections.js"

    log "[5/8] Importing Amazon reviews into MongoDB"
    bash "${ROOT}/05_mongodb/02_import_amazon_reviews.sh" \
        "/tmp/amazon_staging/reviews/Automotive_sample.jsonl"

    log "[5/8] Importing Amazon product metadata into MongoDB"
    bash "${ROOT}/05_mongodb/03_import_amazon_metadata.sh" \
        "/tmp/amazon_staging/metadata/meta_Automotive_sample.jsonl"

    log "[5/8] Building Olist enriched orders collection"
    python3 "${ROOT}/05_mongodb/04_build_olist_enriched.py" --archive "${ROOT}/archive"
else
    log "[5/8] Skipping MongoDB (--skip-mongo)"
fi

# ─── Step 6: PIG Processing ───────────────────────────────────────────────────
log "[6/8] Running PIG scripts"
bash "${ROOT}/06_pig/06_run_pig_scripts.sh"

# ─── Step 8: Analytics (Python/pandas - Hive has compatibility issues on macOS) ────────────
log "[8/8] Running Python analytics queries"
python3 "${ROOT}/07_hive/05_python_analytics.py"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Pipeline complete!"
echo " Python output saved to: 08_run/python_outputs"
echo "════════════════════════════════════════════════════════════"
