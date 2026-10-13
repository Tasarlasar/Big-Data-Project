#!/usr/bin/env bash
# =============================================================================
# Amazon Reviews'23 – Download and stage to HDFS
# Big Data Computing CAT II – Project 1
#
# Downloads the Automotive category subset (reviews + metadata) from
# https://amazon-reviews-2023.github.io/ and loads it into HDFS.
#
# The full Automotive reviews dataset is ~20 M records.  For lab use we
# download the smallest available zipped chunk or use a sample.
#
# Usage:
#   bash 01_download_amazon_data.sh [--sample]
#
#   --sample  Download a lightweight Electronics 5-core sample instead
#             (~1 GB) for faster lab demonstrations.
# =============================================================================

set -euo pipefail

SAMPLE_MODE=false
if [[ "${1:-}" == "--sample" ]]; then
    SAMPLE_MODE=true
fi

LOCAL_STAGING="/tmp/amazon_staging"
HDFS_REVIEWS="/user/bigdata/ecommerce/raw/semi_structured/amazon_reviews"
HDFS_META="/user/bigdata/ecommerce/raw/semi_structured/amazon_metadata"

mkdir -p "${LOCAL_STAGING}/reviews"
mkdir -p "${LOCAL_STAGING}/metadata"

# ---------------------------------------------------------------------------
# Download URLs  (Amazon Reviews 2023 – McAuley Lab)
# Source: https://amazon-reviews-2023.github.io/
# ---------------------------------------------------------------------------
if [ "$SAMPLE_MODE" = true ]; then
    echo "Sample mode: downloading Electronics 5-core (smaller subset)."
    REVIEW_URL="https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/review_categories/Automotive.jsonl.gz"
    META_URL="https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/meta_categories/meta_Automotive.jsonl.gz"
else
    echo "Full mode: downloading Automotive reviews (~20M records)."
    REVIEW_URL="https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/review_categories/Automotive.jsonl.gz"
    META_URL="https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/meta_categories/meta_Automotive.jsonl.gz"
fi

# Function to detect if file is gzipped by checking magic bytes (1f 8b)
is_gzipped() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    # Check first two bytes: gzip magic number is 0x1f8b
    local magic_bytes=$(xxd -p -l 2 "$file" 2>/dev/null)
    if [[ "$magic_bytes" == "1f8b" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to download and process a single file (review or metadata)
download_and_process() {
    local url="$1"
    local local_gz_path="$2"
    local local_jsonl_path="$3"

    echo "Downloading to ${local_gz_path}…"
    curl -L -o "${local_gz_path}" "${url}"

    # Detect if file is gzipped
    if is_gzipped "${local_gz_path}"; then
        echo "Detected gzip format. Decompressing…"
        gunzip -k "${local_gz_path}"
    else
        echo "Detected plain JSONL format. No decompression needed."
        # Copy the plain JSONL to the expected path (it's already the .jsonl)
        cp "${local_gz_path}" "${local_jsonl_path}"
        # Remove the .gz file since it's not actually gzipped
        rm -f "${local_gz_path}"
    fi
}

# ---------------------------------------------------------------------------
# Download and process review JSONL
# ---------------------------------------------------------------------------
echo ""
echo "Downloading reviews…"
download_and_process "${REVIEW_URL}" "${LOCAL_STAGING}/reviews/Automotive.jsonl.gz" "${LOCAL_STAGING}/reviews/Automotive.jsonl"

# ---------------------------------------------------------------------------
# Download and process product metadata JSONL
# ---------------------------------------------------------------------------
echo ""
echo "Downloading product metadata…"
download_and_process "${META_URL}" "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl.gz" "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl"

# ---------------------------------------------------------------------------
# Create _sample symlink for downstream steps (if in sample mode)
# ---------------------------------------------------------------------------
if [ "$SAMPLE_MODE" = true ]; then
    echo ""
    echo "Creating sample symlinks for downstream steps…"
    ln -sf Automotive.jsonl "${LOCAL_STAGING}/reviews/Automotive_sample.jsonl"
    ln -sf meta_Automotive.jsonl "${LOCAL_STAGING}/metadata/meta_Automotive_sample.jsonl"
fi

# ---------------------------------------------------------------------------
# Count records
# ---------------------------------------------------------------------------
REVIEW_COUNT=$(wc -l < "${LOCAL_STAGING}/reviews/Automotive.jsonl")
META_COUNT=$(wc -l < "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl")
echo ""
echo "Reviews:  ${REVIEW_COUNT} records"
echo "Metadata: ${META_COUNT} records"

# ---------------------------------------------------------------------------
# Upload to HDFS
# ---------------------------------------------------------------------------
echo ""
echo "Uploading reviews to HDFS…"
hdfs dfs -put -f "${LOCAL_STAGING}/reviews/Automotive.jsonl" "${HDFS_REVIEWS}/"

echo "Uploading metadata to HDFS…"
hdfs dfs -put -f "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl" "${HDFS_META}/"

# ---------------------------------------------------------------------------
# Keep compressed originals in HDFS as well (saves space for archival)
# Only upload .gz if it exists (i.e., the file was originally gzipped)
# ---------------------------------------------------------------------------
if [[ -f "${LOCAL_STAGING}/reviews/Automotive.jsonl.gz" ]]; then
    hdfs dfs -put -f "${LOCAL_STAGING}/reviews/Automotive.jsonl.gz" "${HDFS_REVIEWS}/"
else
    echo "Skipping HDFS upload of Automotive.jsonl.gz (file not present - was plain JSONL)"
fi

if [[ -f "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl.gz" ]]; then
    hdfs dfs -put -f "${LOCAL_STAGING}/metadata/meta_Automotive.jsonl.gz" "${HDFS_META}/"
else
    echo "Skipping HDFS upload of meta_Automotive.jsonl.gz (file not present - was plain JSONL)"
fi

echo ""
echo "HDFS amazon_reviews:"
hdfs dfs -ls "${HDFS_REVIEWS}/"
echo ""
echo "HDFS amazon_metadata:"
hdfs dfs -ls "${HDFS_META}/"

echo ""
echo "Amazon data ingestion complete."
