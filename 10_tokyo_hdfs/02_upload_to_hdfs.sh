#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Tokyo Railway Pipeline - HDFS Upload Script (CAT II Project 2)
# Uploads consolidated GTFS files to HDFS with operator-based organization
# =============================================================================

echo "=========================================="
echo "Step 2: Upload GTFS Data to HDFS"
echo "=========================================="

# Detect root directory dynamically
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source and target paths
SOURCE_DIR="${ROOT}/09_tokyo_gtfsgenerator/raw"
HDFS_BASE="/user/bigdata/tokyo_transport/raw/gtfs"

# HDFS subdirectories for each operator group
HDFS_JR_EAST="${HDFS_BASE}/jr_east"
HDFS_TOKYO_METRO="${HDFS_BASE}/tokyo_metro"
HDFS_TOEI="${HDFS_BASE}/toei"
HDFS_PRIVATE_RAILWAY="${HDFS_BASE}/private_railway"
HDFS_ALL="${HDFS_BASE}/all"

# GTFS files to upload
GTFS_FILES=("agency.txt" "calendar.txt" "calendar_dates.txt" "feed_info.txt" "routes.txt" "stop_times.txt" "stops.txt" "translations.txt" "trips.txt")

echo ""
echo "--- Creating HDFS directories ---"

hdfs dfs -mkdir -p "${HDFS_JR_EAST}"
hdfs dfs -mkdir -p "${HDFS_TOKYO_METRO}"
hdfs dfs -mkdir -p "${HDFS_TOEI}"
hdfs dfs -mkdir -p "${HDFS_PRIVATE_RAILWAY}"
hdfs dfs -mkdir -p "${HDFS_ALL}"

echo "HDFS directories created successfully."

echo ""
echo "--- Uploading GTFS files to all operators location ---"

for file in "${GTFS_FILES[@]}"; do
    echo "Uploading ${file} to ${HDFS_ALL}..."
    hdfs dfs -put -f "file://${SOURCE_DIR}/${file}" "${HDFS_ALL}/"
done

echo ""
echo "--- Uploading GTFS files to operator-specific locations ---"

# Upload all GTFS files to each operator group (PIG scripts will filter by prefix)
echo "Uploading to JR-East location..."
for file in "${GTFS_FILES[@]}"; do
    hdfs dfs -put -f "file://${SOURCE_DIR}/${file}" "${HDFS_JR_EAST}/"
done

echo "Uploading to TokyoMetro location..."
for file in "${GTFS_FILES[@]}"; do
    hdfs dfs -put -f "file://${SOURCE_DIR}/${file}" "${HDFS_TOKYO_METRO}/"
done

echo "Uploading to Toei location..."
for file in "${GTFS_FILES[@]}"; do
    hdfs dfs -put -f "file://${SOURCE_DIR}/${file}" "${HDFS_TOEI}/"
done

echo "Uploading to Private Railway location..."
for file in "${GTFS_FILES[@]}"; do
    hdfs dfs -put -f "file://${SOURCE_DIR}/${file}" "${HDFS_PRIVATE_RAILWAY}/"
done

echo ""
echo "--- Generating and uploading operator metadata JSON ---"

# Create temporary JSON file using heredoc
METADATA_JSON=$(cat <<'EOF'
{
  "operators": [
    {
      "agency_id": "JR-East",
      "name_en": "East Japan Railway Company",
      "name_ja": "東日本旅客鉄道株式会社",
      "type": "JR",
      "hdfs_subdir": "jr_east"
    },
    {
      "agency_id": "TokyoMetro",
      "name_en": "Tokyo Metro",
      "name_ja": "東京メトロ",
      "type": "Metro",
      "hdfs_subdir": "tokyo_metro"
    },
    {
      "agency_id": "Toei",
      "name_en": "Tokyo Metropolitan Bureau of Transportation",
      "name_ja": "東京都交通局",
      "type": "Metro",
      "hdfs_subdir": "toei"
    },
    {
      "agency_id": "Tokyu",
      "name_en": "Tokyu Corporation",
      "name_ja": "東急株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Keio",
      "name_en": "Keio Corporation",
      "name_ja": "京王電鉄株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Seibu",
      "name_en": "Seibu Railway",
      "name_ja": "西武鉄道株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Tobu",
      "name_en": "Tobu Railway",
      "name_ja": "東武鉄道株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Sotetsu",
      "name_en": "Sagami Railway",
      "name_ja": "相模鉄道株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Keikyu",
      "name_en": "Keikyu Corporation",
      "name_ja": "京浜急行電鉄株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Keisei",
      "name_en": "Keisei Electric Railway",
      "name_ja": "京成電鉄株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Odakyu",
      "name_en": "Odakyu Electric Railway",
      "name_ja": "小田急電鉄株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Yurikamome",
      "name_en": "Yurikamome Urban Transportation Authority",
      "name_ja": "ゆりかもめ",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "TWR",
      "name_en": "Tokyo Waterfront Area Rapid Transit",
      "name_ja": "東京臨海高速鉄道",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "MIR",
      "name_en": "New Transit Miyazaki",
      "name_ja": "新交通宮崎",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "SR",
      "name_en": "Shin-Keisei Railway",
      "name_ja": "新京成電鉄",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "ShinKeisei",
      "name_en": "Shin-Keisei Railway",
      "name_ja": "新京成電鉄株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Hokuso",
      "name_en": "Hokuso Railway",
      "name_ja": "北総鉄道株式会社",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "TamaMonorail",
      "name_en": "Tokyo Tama Monorail",
      "name_ja": "東京多摩Monorail",
      "type": "Monorail",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "Minatomirai",
      "name_en": "Minatomirai Railway",
      "name_ja": "みなとみらい線",
      "type": "Private",
      "hdfs_subdir": "private_railway"
    },
    {
      "agency_id": "TokyoMonorail",
      "name_en": "Tokyo Monorail",
      "name_ja": "東京モノレール",
      "type": "Monorail",
      "hdfs_subdir": "private_railway"
    }
  ]
}
EOF
)

# Write metadata JSON to temp file
TEMP_DIR=$(mktemp -d)
METADATA_FILE="${TEMP_DIR}/operator_metadata.json"
echo "${METADATA_JSON}" > "${METADATA_FILE}"

# Upload metadata JSON
HDFS_METADATA_DIR="/user/bigdata/tokyo_transport/raw/semi_structured/operator_metadata"
hdfs dfs -mkdir -p "${HDFS_METADATA_DIR}"
hdfs dfs -put -f "file://${METADATA_FILE}" "${HDFS_METADATA_DIR}/operator_metadata.json"

# Cleanup temp file
rm -rf "${TEMP_DIR}"

echo "Operator metadata uploaded to ${HDFS_METADATA_DIR}/operator_metadata.json"

echo ""
echo "--- Verifying HDFS uploads ---"
hdfs dfs -ls -R "${HDFS_BASE}"

echo ""
echo "=========================================="
echo "Done: All GTFS files uploaded to HDFS"
echo "=========================================="
