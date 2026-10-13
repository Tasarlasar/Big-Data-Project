-- =============================================================================
-- PIG Script 5: Network Analysis
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Input:  HDFS processed/gtfs_joined
-- Output: HDFS processed/{station_connectivity,hourly_services,operator_network_summary}
--
-- Operations demonstrated: LOAD, GROUP, FOREACH, DISTINCT, ORDER, LIMIT, DUMP, SUBSTRING
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

-- ── 2. station_connectivity: GROUP by (stop_id, stop_name), COUNT DISTINCT route_ids ──────────────
by_station = GROUP gtfs_joined BY (stop_id, stop_name);

station_connectivity = FOREACH by_station {
    distinct_routes = DISTINCT gtfs_joined.route_id;
    GENERATE
        FLATTEN(group)                            AS (stop_id, stop_name),
        COUNT(distinct_routes)                    AS routes_served;
};

-- Order by routes_served descending
station_connectivity_sorted = ORDER station_connectivity BY routes_served DESC;

-- Store full station_connectivity
STORE station_connectivity_sorted
    INTO '/user/bigdata/tokyo_transport/processed/station_connectivity'
    USING PigStorage(',');

-- DUMP top 20 most-connected stations
top20_stations = LIMIT station_connectivity_sorted 20;
DUMP top20_stations;


-- ── 3. hourly_services: extract hour from arrival_time, GROUP by hour, COUNT ─────────────────────
-- arrival_time format: HH:MM:SS (e.g., "06:15:00")
-- Extract first 2 characters for hour
hourly_services_base = FOREACH gtfs_joined GENERATE
    SUBSTRING(arrival_time, 0, 2) AS hour;

-- Remove any null or empty hours
hourly_services_clean = FILTER hourly_services_base BY hour IS NOT NULL AND hour != '';

-- Group by hour and count
by_hour = GROUP hourly_services_clean BY hour;

hourly_services = FOREACH by_hour GENERATE
    group                                   AS hour,
    COUNT(hourly_services_clean)            AS service_count;

-- Order by hour for chronological display
hourly_services_sorted = ORDER hourly_services BY hour;

-- Store hourly_services
STORE hourly_services_sorted
    INTO '/user/bigdata/tokyo_transport/processed/hourly_services'
    USING PigStorage(',');


-- ── 4. operator_network_summary: GROUP by operator_prefix, compute COUNT trips, COUNT DISTINCT stops, COUNT DISTINCT routes ────────
by_operator = GROUP gtfs_joined BY operator_prefix;

operator_network_summary = FOREACH by_operator {
    distinct_stops = DISTINCT gtfs_joined.stop_id;
    distinct_routes = DISTINCT gtfs_joined.route_id;
    GENERATE
        group                                   AS operator_prefix,
        COUNT(gtfs_joined)                      AS trip_count,
        COUNT(distinct_stops)                   AS stop_count,
        COUNT(distinct_routes)                  AS route_count;
};

-- Store operator_network_summary
STORE operator_network_summary
    INTO '/user/bigdata/tokyo_transport/processed/operator_network_summary'
    USING PigStorage(',');
