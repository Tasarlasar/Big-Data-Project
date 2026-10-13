#!/usr/bin/env bash
# =============================================================================
# Import Amazon Reviews JSONL into MongoDB
# Big Data Computing CAT II – Project 1
#
# Uses mongoimport for bulk loading.
# Reads from local staging directory (after download/sample step).
#
# Usage:
#   bash 02_import_amazon_reviews.sh [/path/to/Automotive.jsonl]
# =============================================================================

set -euo pipefail

JSONL_FILE="${1:-/tmp/amazon_staging/reviews/Automotive_sample.jsonl}"
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_DB="ecommerce_bigdata"
COLLECTION="amazon_reviews"

if [ ! -f "$JSONL_FILE" ]; then
    echo "ERROR: JSONL file not found: $JSONL_FILE"
    echo "Run 04_amazon_hdfs/01_download_amazon_data.sh first (optionally with --sample)."
    exit 1
fi

LINE_COUNT=$(wc -l < "$JSONL_FILE")
echo "Importing ${LINE_COUNT} review records from ${JSONL_FILE}"
echo "Target: ${MONGO_DB}.${COLLECTION} on ${MONGO_HOST}:${MONGO_PORT}"
echo ""

mongoimport \
    --host     "${MONGO_HOST}:${MONGO_PORT}" \
    --db       "${MONGO_DB}" \
    --collection "${COLLECTION}" \
    --type     json \
    --file     "${JSONL_FILE}" \
    --numInsertionWorkers 4

echo ""
COUNT=$(mongosh --quiet --host "${MONGO_HOST}:${MONGO_PORT}" \
    --eval "db.getSiblingDB('${MONGO_DB}').${COLLECTION}.countDocuments()" 2>/dev/null)
echo "Documents in ${COLLECTION}: ${COUNT}"
echo "Import complete."
