#!/usr/bin/env bash
# =============================================================================
# Master Pipeline Runner – Tokyo Railway Big Data Pipeline
# Big Data Computing CAT II – Project 2
#
# Runs the full Tokyo Railway pipeline end-to-end in the correct dependency order.
#
# Usage:
#   bash run_pipeline.sh
# =============================================================================

set -euo pipefail

# Set JAVA_HOME for all tools
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${ROOT}/14_tokyo_run"

# Timestamp for logging
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"

# ─── Utility Functions ────────────────────────────────────────────────────────

log() {
    echo ""
    echo "▶ $*"
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

run_phase() {
    local phase_name="$1"
    local phase_num="$2"
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  PHASE ${phase_num}: ${phase_name}"
    echo "║  Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "╚════════════════════════════════════════════════════════════╝"
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: Required command '$cmd' not found in PATH"
        return 1
    fi
    return 0
}

# ─── Phase 1: HDFS Setup ──────────────────────────────────────────────────────

run_phase "HDFS SETUP" "1"
bash "${ROOT}/10_tokyo_hdfs/01_hdfs_setup.sh"
bash "${ROOT}/10_tokyo_hdfs/02_upload_to_hdfs.sh"

# ─── Phase 2: MongoDB Setup ───────────────────────────────────────────────────

run_phase "MONGODB SETUP" "2"

# Setup collections in MongoDB
mongosh tokyo_transport "${ROOT}/11_tokyo_mongodb/01_setup_collections.js" || {
    echo "WARNING: MongoDB setup failed, continuing..."
}

# Import GTFS data using mongoimport with CSV format
# routes.txt → routes collection
mongoimport --type=csv --headerline --drop \
    --db tokyo_transport --collection routes \
    --file "${ROOT}/09_tokyo_gtfsgenerator/raw/routes.txt" || {
    echo "WARNING: routes.txt import failed, continuing..."
}

# stops.txt → stations collection
mongoimport --type=csv --headerline --drop \
    --db tokyo_transport --collection stations \
    --file "${ROOT}/09_tokyo_gtfsgenerator/raw/stops.txt" || {
    echo "WARNING: stops.txt import failed, continuing..."
}

# trips.txt → trips collection
mongoimport --type=csv --headerline --drop \
    --db tokyo_transport --collection trips \
    --file "${ROOT}/09_tokyo_gtfsgenerator/raw/trips.txt" || {
    echo "WARNING: trips.txt import failed, continuing..."
}

# stop_times.txt → schedules collection
mongoimport --type=csv --headerline --drop \
    --db tokyo_transport --collection schedules \
    --file "${ROOT}/09_tokyo_gtfsgenerator/raw/stop_times.txt" || {
    echo "WARNING: stop_times.txt import failed, continuing..."
}

# ─── Phase 3: Pig Processing ──────────────────────────────────────────────────

run_phase "PIG PROCESSING" "3"

PIG_LOG_DIR="${ROOT}/12_tokyo_pig"

bash "${ROOT}/12_tokyo_pig/06_run_pig_scripts.sh" 2>&1 | tee "${PIG_LOG_DIR}/pig_all.log" || {
    echo "WARNING: pig_all.log failed, continuing..."
}

# ─── Phase 4: Hive Analytics ──────────────────────────────────────────────────

run_phase "HIVE ANALYTICS" "4"

BEELINE_URL="jdbc:hive2://localhost:10000"

# Start HiveServer2 if not already running
if ! pgrep -f 'HiveServer2' > /dev/null 2>&1; then
    echo "Starting HiveServer2..."
    hive --service hiveserver2 &
    HIVE_PID=$!
    echo "HiveServer2 started (PID: ${HIVE_PID})"
    echo "Waiting 30 seconds for HiveServer2 to become ready..."
    sleep 30
else
    echo "HiveServer2 is already running."
fi

beeline -u "$BEELINE_URL" --silent=false --fastConnect=false \
    -f "${ROOT}/13_tokyo_hive/01_create_tables.hql" || {
    echo "WARNING: Hive table creation failed, continuing..."
}

beeline -u "$BEELINE_URL" --silent=false --fastConnect=false \
    -f "${ROOT}/13_tokyo_hive/02_analytics_queries.hql" || {
    echo "WARNING: Hive analytics queries failed, continuing..."
}

beeline -u "$BEELINE_URL" --silent=false --fastConnect=false \
    -f "${ROOT}/13_tokyo_hive/03_save_outputs.hql" || {
    echo "WARNING: Hive save outputs failed, continuing..."
}

# ─── Phase 5: Final Verification ──────────────────────────────────────────────

run_phase "FINAL VERIFICATION" "5"

echo ""
echo "─── HDFS Directory Listing ──────────────────────────────────────────────"
hdfs dfs -ls -R /user/bigdata/tokyo_transport/ || {
    echo "WARNING: HDFS listing failed"
}

echo ""
echo "─── HDFS Directory Usage ────────────────────────────────────────────────"
hdfs dfs -du -h /user/bigdata/tokyo_transport/ || {
    echo "WARNING: HDFS du failed"
}

echo ""
echo "─── MongoDB Collection Counts ───────────────────────────────────────────"
mongosh --quiet --eval '
    use("tokyo_transport");
    ["operators","routes","stations","trips","schedules"].forEach(c => print(c+": "+db[c].countDocuments()))
' tokyo_transport || {
    echo "WARNING: MongoDB collection count failed"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Tokyo Railway Pipeline Complete."
echo "║  Finished: $(date '+%Y-%m-%d %H:%M:%S')"
echo "╚════════════════════════════════════════════════════════════╝"
