#!/usr/bin/env bash
# =============================================================================
# HDFS Directory Setup – Tokyo Railway Big Data Pipeline
# Big Data Computing CAT II – Project 2
#
# Usage:  bash 01_hdfs_setup.sh
# =============================================================================

set -euo pipefail

HDFS_ROOT="/user/bigdata/tokyo_transport"

echo "=================================================="
echo " Creating HDFS directory structure under ${HDFS_ROOT}"
echo "=================================================="

# ---------------------------------------------------------------------------
# 1. Raw GTFS structured data (by operator type)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/gtfs/jr_east
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/gtfs/tokyo_metro
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/gtfs/toei
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/gtfs/private_railway

# ---------------------------------------------------------------------------
# 2. Raw semi-structured operator metadata
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/raw/semi_structured/operator_metadata

# ---------------------------------------------------------------------------
# 3. Processed data (PIG outputs)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/aggregated_routes
hdfs dfs -mkdir -p ${HDFS_ROOT}/processed/station_network

# ---------------------------------------------------------------------------
# 4. Analytical outputs (Hive external table locations)
# ---------------------------------------------------------------------------
hdfs dfs -mkdir -p ${HDFS_ROOT}/analytics/hive

# ---------------------------------------------------------------------------
# 5. Set permissions
# ---------------------------------------------------------------------------
hdfs dfs -chmod -R 775 ${HDFS_ROOT}

echo ""
echo "Final HDFS directory tree:"
hdfs dfs -ls -R ${HDFS_ROOT} 2>/dev/null | awk '{print $NF}' | sort

echo ""
echo "Done. HDFS directories created successfully."
