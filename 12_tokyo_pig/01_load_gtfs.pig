-- =============================================================================
-- PIG Script 1: Load and Clean Tokyo GTFS Data
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Input:  HDFS raw/gtfs/all/{stops,routes,trips,stop_times}.txt
-- Output: HDFS processed/{clean_stops,clean_routes,clean_trips,clean_stop_times}
--
-- Operations demonstrated: LOAD, FILTER, FOREACH, STORE
-- =============================================================================

-- ── 1. Load raw stops.txt ─────────────────────────────────────────────────────
-- Schema: stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id,
--         stop_url, location_type, parent_station, stop_timezone, wheelchair_boarding
raw_stops = LOAD '/user/bigdata/tokyo_transport/raw/gtfs/all/stops.txt'
            USING PigStorage(',')
            AS (
                stop_id:chararray,
                stop_code:chararray,
                stop_name:chararray,
                stop_desc:chararray,
                stop_lat:double,
                stop_lon:double,
                zone_id:chararray,
                stop_url:chararray,
                location_type:int,
                parent_station:chararray,
                stop_timezone:chararray,
                wheelchair_boarding:chararray
            );

-- Filter out header rows and records with essential nulls
clean_stops_raw = FILTER raw_stops BY stop_id != 'stop_id' AND stop_id IS NOT NULL;

-- Extract operator_prefix from stop_id (format: OperatorPrefix.RouteName.StationName)
-- Use REGEX_EXTRACT to get the first part before the first dot
stops_with_operator = FOREACH clean_stops_raw GENERATE
    stop_id,
    stop_code,
    stop_name,
    stop_desc,
    stop_lat,
    stop_lon,
    zone_id,
    stop_url,
    location_type,
    parent_station,
    stop_timezone,
    wheelchair_boarding,
    REGEX_EXTRACT(stop_id, '^([^\\.]+)', 1) AS operator_prefix;

-- Keep only essential columns to reduce output size
clean_stops = FOREACH stops_with_operator GENERATE
    stop_id,
    stop_code,
    stop_name,
    stop_lat,
    stop_lon,
    operator_prefix;

-- Store cleaned stops
STORE clean_stops
    INTO '/user/bigdata/tokyo_transport/processed/clean_stops'
    USING PigStorage(',');


-- ── 2. Load raw routes.txt ────────────────────────────────────────────────────
-- Schema: route_id, agency_id, route_short_name, route_long_name, route_desc,
--         route_type, route_url, route_color, route_text_color
raw_routes = LOAD '/user/bigdata/tokyo_transport/raw/gtfs/all/routes.txt'
             USING PigStorage(',')
             AS (
                 route_id:chararray,
                 agency_id:chararray,
                 route_short_name:chararray,
                 route_long_name:chararray,
                 route_desc:chararray,
                 route_type:int,
                 route_url:chararray,
                 route_color:chararray,
                 route_text_color:chararray
             );

-- Filter out header rows
clean_routes_raw = FILTER raw_routes BY route_id != 'route_id' AND route_id IS NOT NULL;

-- Extract operator_prefix from route_id (format: OperatorPrefix.RouteName)
routes_with_operator = FOREACH clean_routes_raw GENERATE
    route_id,
    agency_id,
    route_short_name,
    route_long_name,
    route_desc,
    route_type,
    route_url,
    route_color,
    route_text_color,
    REGEX_EXTRACT(route_id, '^([^\\.]+)', 1) AS operator_prefix;

-- Keep only essential columns
clean_routes = FOREACH routes_with_operator GENERATE
    route_id,
    route_short_name,
    route_long_name,
    route_type,
    operator_prefix;

-- Store cleaned routes
STORE clean_routes
    INTO '/user/bigdata/tokyo_transport/processed/clean_routes'
    USING PigStorage(',');


-- ── 3. Load raw trips.txt ─────────────────────────────────────────────────────
-- Schema: route_id, service_id, trip_id, trip_headsign, trip_short_name,
--         direction_id, block_id, shape_id, wheelchair_accessible, bikes_allowed, jp_trip_desc
raw_trips = LOAD '/user/bigdata/tokyo_transport/raw/gtfs/all/trips.txt'
            USING PigStorage(',')
            AS (
                route_id:chararray,
                service_id:chararray,
                trip_id:chararray,
                trip_headsign:chararray,
                trip_short_name:chararray,
                direction_id:int,
                block_id:chararray,
                shape_id:chararray,
                wheelchair_accessible:chararray,
                bikes_allowed:chararray,
                jp_trip_desc:chararray
            );

-- Filter out header rows
clean_trips_raw = FILTER raw_trips BY trip_id != 'trip_id' AND trip_id IS NOT NULL;

-- Extract operator_prefix from trip_id (format: OperatorPrefix.RouteName.TripCode.ServiceType)
trips_with_operator = FOREACH clean_trips_raw GENERATE
    route_id,
    service_id,
    trip_id,
    trip_headsign,
    trip_short_name,
    direction_id,
    shape_id,
    wheelchair_accessible,
    bikes_allowed,
    jp_trip_desc,
    REGEX_EXTRACT(trip_id, '^([^\\.]+)', 1) AS operator_prefix;

-- Keep only essential columns
clean_trips = FOREACH trips_with_operator GENERATE
    route_id,
    service_id,
    trip_id,
    direction_id,
    operator_prefix;

-- Store cleaned trips
STORE clean_trips
    INTO '/user/bigdata/tokyo_transport/processed/clean_trips'
    USING PigStorage(',');


-- ── 4. Load raw stop_times.txt ────────────────────────────────────────────────
-- Schema: trip_id, arrival_time, departure_time, stop_id, stop_sequence,
--         stop_headsign, pickup_type, drop_off_type, shape_dist_traveled, timepoint
raw_stop_times = LOAD '/user/bigdata/tokyo_transport/raw/gtfs/all/stop_times.txt'
                 USING PigStorage(',')
                 AS (
                     trip_id:chararray,
                     arrival_time:chararray,
                     departure_time:chararray,
                     stop_id:chararray,
                     stop_sequence:int,
                     stop_headsign:chararray,
                     pickup_type:int,
                     drop_off_type:int,
                     shape_dist_traveled:double,
                     timepoint:int
                 );

-- Filter out header rows and records with null trip_id or stop_id
clean_stop_times = FILTER raw_stop_times BY
    trip_id != 'trip_id' AND
    trip_id IS NOT NULL AND
    stop_id IS NOT NULL;

-- Keep only essential columns
clean_stop_times_proj = FOREACH clean_stop_times GENERATE
    trip_id,
    arrival_time,
    departure_time,
    stop_id,
    stop_sequence;

-- Store cleaned stop_times
STORE clean_stop_times_proj
    INTO '/user/bigdata/tokyo_transport/processed/clean_stop_times'
    USING PigStorage(',');