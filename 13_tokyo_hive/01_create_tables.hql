-- =============================================================================
-- Hive Table Creation - Tokyo Railway Pipeline (CAT II Project 2)
--
-- Creates external Hive tables pointing to HDFS data.
-- Using EXTERNAL tables preserves data in HDFS if the table is dropped.
--
-- Run with:  hive -f 01_create_tables.hql
--            beeline -u jdbc:hive2://localhost:10000 -f 01_create_tables.hql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS tokyo_transport;

USE tokyo_transport;

-- -----------------------------------------------------------------------------
-- 1. clean_stops (from PIG-processed GTFS data)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_stops;
CREATE EXTERNAL TABLE clean_stops (
    stop_id       STRING,
    stop_name     STRING,
    stop_lat      DOUBLE,
    stop_lon      DOUBLE,
    operator_prefix STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/clean_stops';

-- -----------------------------------------------------------------------------
-- 2. clean_routes (from PIG-processed GTFS data)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_routes;
CREATE EXTERNAL TABLE clean_routes (
    route_id          STRING,
    route_short_name  STRING,
    route_long_name   STRING,
    route_type        INT,
    operator_prefix   STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/clean_routes';

-- -----------------------------------------------------------------------------
-- 3. clean_trips (from PIG-processed GTFS data)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_trips;
CREATE EXTERNAL TABLE clean_trips (
    route_id        STRING,
    service_id      STRING,
    trip_id         STRING,
    direction_id    INT,
    operator_prefix STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/clean_trips';

-- -----------------------------------------------------------------------------
-- 4. clean_stop_times (from PIG-processed GTFS data)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_stop_times;
CREATE EXTERNAL TABLE clean_stop_times (
    trip_id       STRING,
    arrival_time  STRING,
    departure_time STRING,
    stop_id       STRING,
    stop_sequence INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/clean_stop_times';

-- -----------------------------------------------------------------------------
-- 5. gtfs_joined (from PIG-processed joined GTFS data)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS gtfs_joined;
CREATE EXTERNAL TABLE gtfs_joined (
    operator_prefix   STRING,
    route_id          STRING,
    route_long_name   STRING,
    trip_id           STRING,
    service_id        INT,
    stop_id           STRING,
    stop_name         STRING,
    stop_lat          DOUBLE,
    stop_lon          DOUBLE,
    arrival_time      STRING,
    departure_time    STRING,
    stop_sequence     INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/gtfs_joined';

-- -----------------------------------------------------------------------------
-- 6. trips_per_route (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS trips_per_route;
CREATE EXTERNAL TABLE trips_per_route (
    operator_prefix STRING,
    route_id        STRING,
    route_long_name STRING,
    trip_count      BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/trips_per_route';

-- -----------------------------------------------------------------------------
-- 7. stops_per_route (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS stops_per_route;
CREATE EXTERNAL TABLE stops_per_route (
    operator_prefix STRING,
    route_id        STRING,
    stop_count      BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/stops_per_route';

-- -----------------------------------------------------------------------------
-- 8. routes_per_operator (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS routes_per_operator;
CREATE EXTERNAL TABLE routes_per_operator (
    operator_prefix STRING,
    route_count     BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/routes_per_operator';

-- -----------------------------------------------------------------------------
-- 9. station_connectivity (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS station_connectivity;
CREATE EXTERNAL TABLE station_connectivity (
    stop_id      STRING,
    stop_name    STRING,
    routes_served BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/station_connectivity';

-- -----------------------------------------------------------------------------
-- 10. hourly_services (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS hourly_services;
CREATE EXTERNAL TABLE hourly_services (
    hour          STRING,
    service_count BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/hourly_services';

-- -----------------------------------------------------------------------------
-- 11. operator_network_summary (from PIG-processed aggregation)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS operator_network_summary;
CREATE EXTERNAL TABLE operator_network_summary (
    operator_prefix STRING,
    total_trips     BIGINT,
    total_stops     BIGINT,
    total_routes    BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/bigdata/tokyo_transport/processed/operator_network_summary';

-- -----------------------------------------------------------------------------
-- 12. transport_analytics_summary (managed table for computed results)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS transport_analytics_summary;
CREATE TABLE transport_analytics_summary (
    metric_name   STRING,
    metric_value  STRING,
    description   STRING
)
STORED AS ORC;

-- -----------------------------------------------------------------------------
-- Verify all tables are visible
-- -----------------------------------------------------------------------------
SHOW TABLES;
