-- =============================================================================
-- PIG Script 4: Aggregate Route Statistics
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Input:  HDFS processed/gtfs_joined
-- Output: HDFS processed/{trips_per_route,stops_per_route,routes_per_operator}
--
-- Operations demonstrated: LOAD, GROUP, FOREACH, DISTINCT, ORDER, STORE, LIMIT, DUMP
-- =============================================================================

-- ── 1. Load joined GTFS data ──────────────────────────────────────────────────
gtfs_joined = LOAD '/user/bigdata/tokyo_transport/processed/gtfs_joined'
              USING PigStorage(',')
              AS (
                  operator_prefix:chararray,
                  route_id:chararray,
                  route_long_name:chararray,
                  trip_id:chararray,
                  service_id:chararray,
                  stop_id:chararray,
                  stop_name:chararray,
                  stop_lat:double,
                  stop_lon:double,
                  arrival_time:chararray,
                  departure_time:chararray,
                  stop_sequence:int
              );

-- ── 2. trips_per_route: GROUP by (operator_prefix, route_id, route_long_name), COUNT trips ──────────
by_route = GROUP gtfs_joined BY (operator_prefix, route_id, route_long_name);

trips_per_route = FOREACH by_route GENERATE
    FLATTEN(group)                            AS (operator_prefix, route_id, route_long_name),
    COUNT(gtfs_joined)                        AS trip_count;

-- Order by trip_count descending
trips_per_route_sorted = ORDER trips_per_route BY trip_count DESC;

-- Store full trips_per_route
STORE trips_per_route_sorted
    INTO '/user/bigdata/tokyo_transport/processed/trips_per_route'
    USING PigStorage(',');

-- DUMP top 10
top10_trips = LIMIT trips_per_route_sorted 10;
DUMP top10_trips;


-- ── 3. stops_per_route: GROUP by (operator_prefix, route_id), DISTINCT stop_ids, COUNT ────────────
-- First build distinct stops per route using nested FOREACH
stops_per_route_nested = FOREACH by_route {
    distinct_stops = DISTINCT gtfs_joined.stop_id;
    GENERATE
        FLATTEN(group)                      AS (operator_prefix, route_id, route_long_name),
        COUNT(distinct_stops)               AS stop_count;
};

stops_per_route = FOREACH stops_per_route_nested GENERATE
    operator_prefix,
    route_id,
    stop_count;

-- Store stops_per_route
STORE stops_per_route
    INTO '/user/bigdata/tokyo_transport/processed/stops_per_route'
    USING PigStorage(',');


-- ── 4. routes_per_operator: GROUP by operator_prefix, COUNT DISTINCT route_ids ────────────────────
by_operator = GROUP gtfs_joined BY operator_prefix;

routes_per_operator = FOREACH by_operator {
    distinct_routes = DISTINCT gtfs_joined.route_id;
    GENERATE
        group                                   AS operator_prefix,
        COUNT(distinct_routes)                  AS route_count;
};

-- Store routes_per_operator
STORE routes_per_operator
    INTO '/user/bigdata/tokyo_transport/processed/routes_per_operator'
    USING PigStorage(',');
