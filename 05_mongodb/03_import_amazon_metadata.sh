#!/usr/bin/env bash
# =============================================================================
# Import Amazon Product Metadata JSONL into MongoDB
# Big Data Computing CAT II – Project 1
#
# Usage:
#   bash 03_import_amazon_metadata.sh [/path/to/meta_Automotive.jsonl]
# =============================================================================

set -euo pipefail

JSONL_FILE="${1:-/tmp/amazon_staging/metadata/meta_Automotive_sample.jsonl}"
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_DB="ecommerce_bigdata"
COLLECTION="amazon_products"

if [ ! -f "$JSONL_FILE" ]; then
    echo "ERROR: JSONL file not found: $JSONL_FILE"
    exit 1
fi

LINE_COUNT=$(wc -l < "$JSONL_FILE")
echo "Importing ${LINE_COUNT} product metadata records from ${JSONL_FILE}"
echo "Target: ${MONGO_DB}.${COLLECTION}"
echo ""

mongoimport \
    --host       "${MONGO_HOST}:${MONGO_PORT}" \
    --db         "${MONGO_DB}" \
    --collection "${COLLECTION}" \
    --type       json \
    --file       "${JSONL_FILE}" \
    --upsert \
    --upsertFields parent_asin \
    --numInsertionWorkers 4

echo ""
COUNT=$(mongosh --quiet --host "${MONGO_HOST}:${MONGO_PORT}" \
    --eval "db.getSiblingDB('${MONGO_DB}').${COLLECTION}.countDocuments()" 2>/dev/null)
echo "Documents in ${COLLECTION}: ${COUNT}"
echo "Import complete."
