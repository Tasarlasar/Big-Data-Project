-- =============================================================================
-- PIG Script 3: Join GTFS Data Files
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Input:  HDFS processed/{clean_stops,clean_routes,clean_trips,clean_stop_times}
-- Output: HDFS processed/gtfs_joined
--
-- Operations demonstrated: LOAD, JOIN, FILTER, FOREACH, STORE
-- =============================================================================

-- ── 1. Load cleaned GTFS files ────────────────────────────────────────────────
stops = LOAD '/user/bigdata/tokyo_transport/processed/clean_stops'
        USING PigStorage(',')
        AS (
            stop_id:chararray,
            stop_name:chararray,
            stop_lat:double,
            stop_lon:double,
            operator_prefix:chararray
        );

routes = LOAD '/user/bigdata/tokyo_transport/processed/clean_routes'
         USING PigStorage(',')
         AS (
             route_id:chararray,
             route_short_name:chararray,
             route_long_name:chararray,
             route_type:int,
             operator_prefix:chararray
         );

trips = LOAD '/user/bigdata/tokyo_transport/processed/clean_trips'
       USING PigStorage(',')
       AS (
           route_id:chararray,
           service_id:chararray,
           trip_id:chararray,
           direction_id:int,
           operator_prefix:chararray
       );

stop_times = LOAD '/user/bigdata/tokyo_transport/processed/clean_stop_times'
             USING PigStorage(',')
             AS (
                 trip_id:chararray,
                 arrival_time:chararray,
                 departure_time:chararray,
                 stop_id:chararray,
                 stop_sequence:int
             );

-- ── 2. Join routes ↔ trips (on route_id) ──────────────────────────────────────
routes_trips = JOIN routes BY route_id, trips BY route_id;

-- ── 3. Join with stop_times (on trip_id) ──────────────────────────────────────
routes_trips_times = JOIN routes_trips BY trips::trip_id,
                                 stop_times BY trip_id;

-- ── 4. Join with stops (on stop_id) ───────────────────────────────────────────
routes_trips_times_stops = JOIN routes_trips_times BY stop_times::stop_id,
                                          stops BY stop_id;

-- ── 5. Project essential columns ──────────────────────────────────────────────
-- Fields: operator_prefix, route_id, route_long_name, trip_id, service_id,
--         stop_id, stop_name, stop_lat, stop_lon, arrival_time, departure_time, stop_sequence
gtfs_joined = FOREACH routes_trips_times_stops GENERATE
    routes::operator_prefix AS operator_prefix,
    routes::route_id        AS route_id,
    routes::route_long_name AS route_long_name,
    trips::trip_id          AS trip_id,
    trips::service_id       AS service_id,
    stop_times::stop_id     AS stop_id,
    stops::stop_name        AS stop_name,
    stops::stop_lat         AS stop_lat,
    stops::stop_lon         AS stop_lon,
    stop_times::arrival_time   AS arrival_time,
    stop_times::departure_time AS departure_time,
    stop_times::stop_sequence  AS stop_sequence;

-- ── 6. Filter out rows where stop_name IS NULL (unmatched stops) ──────────────
gtfs_joined_valid = FILTER gtfs_joined BY stop_name IS NOT NULL;

-- ── 7. Store joined dataset ───────────────────────────────────────────────────
STORE gtfs_joined_valid
    INTO '/user/bigdata/tokyo_transport/processed/gtfs_joined'
    USING PigStorage(',');

-- Quick count for verification
cnt = FOREACH (GROUP gtfs_joined_valid ALL) GENERATE COUNT(gtfs_joined_valid);
DUMP cnt;
