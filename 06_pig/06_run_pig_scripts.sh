#!/usr/bin/env bash
# =============================================================================
# Run all PIG scripts in order
# Big Data Computing CAT II – Project 1
#
# Usage:  bash 06_run_pig_scripts.sh
# =============================================================================

set -euo pipefail

PIG_DIR="$(dirname "$0")"

# ---------------------------------------------------------------------------
# Clean up existing output directories before running PIG scripts
# ---------------------------------------------------------------------------
echo "Cleaning up existing PIG output directories..."
for dir in reviews_filtered reviews_by_product orders_joined revenue_by_category top_products; do
    echo "  Removing /user/bigdata/ecommerce/processed/${dir}..."
    hdfs dfs -rm -r -f "/user/bigdata/ecommerce/processed/${dir}" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# Environment fixes for PIG 0.18 on Hadoop 3.5 (macOS / Homebrew)
# ---------------------------------------------------------------------------
# 1. Hadoop's hdfs/mapreduce clients need JAVA_HOME.
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

# 2. Hadoop 3.5 ships commons-collections4 but PIG's bag spilling still
#    references commons-collections 3.x (org.apache.commons.collections.buffer.
#    CircularFifoBuffer). That class exists in the jar below but is not shipped
#    to the MapReduce task containers by default, causing
#    ClassNotFoundException in any GROUP/JOIN (reduce) job. Ship it explicitly.
# Resolve PIG's install prefix (follow the symlink target to an absolute path).
PIG_BIN="$(command -v pig)"
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
echo "Shipping commons-collections jar to jobs: ${COMMONS_COLLECTIONS_JAR}"

# Put it on PIG's own client JVM classpath too (needed when DUMP streams
# reduce-side results back to the client, which also uses CircularFifoBuffer).
export PIG_CLASSPATH="${COMMONS_COLLECTIONS_JAR}:${PIG_CLASSPATH:-}"

# -D java properties MUST come before -x on the pig command line.
PIG_EXTRA_OPTS="-Dpig.additional.jars.uris=file://${COMMONS_COLLECTIONS_JAR}"

run_pig() {
    local SCRIPT="$1"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo " Running: ${SCRIPT}"
    echo "════════════════════════════════════════════════════════════"
    pig ${PIG_EXTRA_OPTS} -x mapreduce "${PIG_DIR}/${SCRIPT}"
    echo "✓ ${SCRIPT} complete"
}

run_pig 01_filter_amazon_reviews.pig
run_pig 02_reviews_by_product.pig
run_pig 03_join_olist_orders.pig
run_pig 04_revenue_by_category.pig
run_pig 05_top_products.pig

echo ""
echo "All PIG scripts completed."
echo ""
echo "Processed data locations:"
hdfs dfs -ls /user/bigdata/ecommerce/processed/
