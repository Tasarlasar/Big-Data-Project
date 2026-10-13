-- =============================================================================
-- PIG Script 2: Normalize Operator Names
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Input:  HDFS processed/clean_stops, processed/clean_routes
-- Output: HDFS processed/normalized_operators
--
-- Operations demonstrated: LOAD, FOREACH, GENERATE, JOIN, GROUP, COUNT, STORE, DUMP
-- =============================================================================

-- ── 1. Load cleaned stops and routes ───────────────────────────────────────────
clean_stops = LOAD '/user/bigdata/tokyo_transport/processed/clean_stops'
              USING PigStorage(',')
              AS (
                  stop_id:chararray,
                  stop_code:chararray,
                  stop_name:chararray,
                  stop_lat:double,
                  stop_lon:double,
                  operator_prefix:chararray
              );

clean_routes = LOAD '/user/bigdata/tokyo_transport/processed/clean_routes'
               USING PigStorage(',')
               AS (
                   route_id:chararray,
                   route_short_name:chararray,
                   route_long_name:chararray,
                   route_type:int,
                   operator_prefix:chararray
               );

-- ── 2. Define operator lookup table ───────────────────────────────────────────
-- Maps operator prefixes to human-readable English names
-- Load from HDFS (operator_lookup.csv is uploaded by the runner script)
-- Path can be overridden via -p OPERATOR_LOOKUP_PATH
operator_lookup = LOAD '${OPERATOR_LOOKUP_PATH}'
    USING PigStorage(',') AS (operator_prefix:chararray, operator_name:chararray);

-- ── 3. Join stops with operator lookup ────────────────────────────────────────
stops_with_name = JOIN clean_stops BY operator_prefix LEFT OUTER,
                  operator_lookup BY operator_prefix;

stops_normalized = FOREACH stops_with_name GENERATE
    clean_stops::stop_id    AS stop_id,
    clean_stops::stop_name  AS stop_name,
    clean_stops::stop_lat   AS stop_lat,
    clean_stops::stop_lon   AS stop_lon,
    operator_lookup::operator_name AS operator_name;

-- ── 4. Join routes with operator lookup ───────────────────────────────────────
routes_with_name = JOIN clean_routes BY operator_prefix LEFT OUTER,
                   operator_lookup BY operator_prefix;

routes_normalized = FOREACH routes_with_name GENERATE
    clean_routes::route_id      AS route_id,
    clean_routes::route_long_name AS route_long_name,
    operator_lookup::operator_name AS operator_name;

-- ── 5. Create normalized_operators relation (union of stops and routes) ───────
stops_projected = FOREACH stops_normalized GENERATE
    stop_id,
    stop_name,
    stop_lat,
    stop_lon,
    operator_name,
    'stop' AS record_type;

routes_projected = FOREACH routes_normalized GENERATE
    route_id AS stop_id,
    route_long_name AS stop_name,
    (double)0.0 AS stop_lat,
    (double)0.0 AS stop_lon,
    operator_name,
    'route' AS record_type;

normalized_operators = UNION stops_projected, routes_projected;

-- ── 6. Store normalized operators ─────────────────────────────────────────────
STORE normalized_operators
    INTO '/user/bigdata/tokyo_transport/processed/normalized_operators'
    USING PigStorage(',');

-- ── 7. Distribution analysis: count records per operator ──────────────────────
operator_distribution = GROUP normalized_operators BY operator_name;

operator_counts = FOREACH operator_distribution GENERATE
    group AS operator_name,
    COUNT(normalized_operators) AS record_count;

operator_counts_sorted = ORDER operator_counts BY record_count DESC;

DUMP operator_counts_sorted;
