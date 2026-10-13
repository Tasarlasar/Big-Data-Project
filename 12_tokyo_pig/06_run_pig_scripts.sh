#!/usr/bin/env bash
# =============================================================================
# Run all PIG scripts in order for Tokyo Railway Pipeline
# Big Data Computing CAT II – Project 2
#
# Usage:  bash 06_run_pig_scripts.sh
# =============================================================================

set -euo pipefail

PIG_DIR="$(dirname "$0")"
ROOT="$(cd "${PIG_DIR}/.." && pwd)"

# ---------------------------------------------------------------------------
# Clean up existing output directories before running PIG scripts
# ---------------------------------------------------------------------------
echo "Cleaning up existing PIG output directories..."
for dir in clean_stops clean_routes clean_trips clean_stop_times normalized_routes gtfs_joined trips_per_route stops_per_route routes_per_operator station_connectivity hourly_services operator_network_summary normalized_operators; do
    echo "  Removing /user/bigdata/tokyo_transport/processed/${dir}..."
    hdfs dfs -rm -r -f "/user/bigdata/tokyo_transport/processed/${dir}" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# Environment fixes for PIG 0.18 on Hadoop 3.5 (macOS / Homebrew)
# ---------------------------------------------------------------------------
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

# Resolve PIG's install prefix
PIG_BIN="$(command -v pig 2>/dev/null || true)"
if [ -n "${PIG_BIN}" ]; then
    PIG_TARGET="$(readlink "${PIG_BIN}" 2>/dev/null || true)"
    if [ -n "${PIG_TARGET}" ]; then
        case "${PIG_TARGET}" in
            /*) PIG_BIN="${PIG_TARGET}" ;;
            *)  PIG_BIN="$(cd "$(dirname "${PIG_BIN}")" && cd "$(dirname "${PIG_TARGET}")" && pwd)/$(basename "${PIG_TARGET}")" ;;
        esac
    fi
    PIG_LIBEXEC="$(cd "$(dirname "${PIG_BIN}")/.." && pwd)"
    COMMONS_COLLECTIONS_JAR="$(find "${PIG_LIBEXEC}" -name 'commons-collections-3*.jar' 2>/dev/null | head -1 || true)"
    if [ -z "${COMMONS_COLLECTIONS_JAR}" ] || [ ! -f "${COMMONS_COLLECTIONS_JAR}" ]; then
        COMMONS_COLLECTIONS_JAR="/opt/homebrew/Cellar/pig/0.18.0/libexec/lib/hadoop3-runtime/commons-collections-3.2.2.jar"
    fi
    export PIG_CLASSPATH="${COMMONS_COLLECTIONS_JAR}:${PIG_CLASSPATH:-}"
    # URL-encode the JAR path for file:// URIs (replace spaces with %20)
    COMMONS_COLLECTIONS_JAR_URL="${COMMONS_COLLECTIONS_JAR// /%20}"
    PIG_EXTRA_OPTS="-Dpig.additional.jars.uris=file://${COMMONS_COLLECTIONS_JAR_URL}"
else
    COMMONS_COLLECTIONS_JAR="/opt/homebrew/Cellar/pig/0.18.0/libexec/lib/hadoop3-runtime/commons-collections-3.2.2.jar"
    PIG_EXTRA_OPTS=""
fi

echo "Shipping commons-collections jar to jobs: ${COMMONS_COLLECTIONS_JAR}"

run_pig() {
    local SCRIPT="$1"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo " Running: ${SCRIPT}"
    echo "════════════════════════════════════════════════════════════"
    # Copy operator_lookup.csv to HDFS for use by MapReduce jobs
    # Use cd to ensure we're in the workspace directory for relative path
    (cd "${ROOT}" && hdfs dfs -put -f 12_tokyo_pig/operator_lookup.csv /user/bigdata/tokyo_transport/operator_lookup.csv) 2>/dev/null || true
    # Use HDFS path for operator_lookup to avoid file:// filesystem issues
    pig ${PIG_EXTRA_OPTS} -x mapreduce \
        -p OPERATOR_LOOKUP_PATH=/user/bigdata/tokyo_transport/operator_lookup.csv \
        -f "${ROOT}/12_tokyo_pig/${SCRIPT}"
    echo "✓ ${SCRIPT} complete"
}

run_pig 01_load_gtfs.pig
run_pig 02_normalize_operators.pig
run_pig 03_join_gtfs.pig
run_pig 04_aggregate_routes.pig
run_pig 05_analyze_network.pig

echo ""
echo "All PIG scripts completed."
echo ""
echo "Processed data locations:"
hdfs dfs -ls /user/bigdata/tokyo_transport/processed/ 2>/dev/null || echo "No processed data yet"
