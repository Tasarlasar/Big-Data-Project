-- =============================================================================
-- Save key Hive query results as HDFS tables for downstream use / reporting
-- Tokyo Railway Pipeline (CAT II Project 2)
--
-- Run with:  hive -f 03_save_outputs.hql
-- =============================================================================

USE tokyo_transport;

SET hive.exec.dynamic.partition.mode=nonstrict;

-- -- Operator station counts ----------------------------------------------------
DROP TABLE IF EXISTS operator_station_counts;
CREATE TABLE operator_station_counts
STORED AS ORC
AS
SELECT
    operator_prefix,
    COUNT(*) AS station_count
FROM clean_stops
GROUP BY operator_prefix
ORDER BY station_count DESC;

-- -- Operator route counts ------------------------------------------------------
DROP TABLE IF EXISTS operator_route_counts;
CREATE TABLE operator_route_counts
STORED AS ORC
AS
SELECT
    operator_prefix,
    COUNT(*) AS route_count
FROM clean_routes
GROUP BY operator_prefix
ORDER BY route_count DESC;

-- -- Top connected stations -----------------------------------------------------
DROP TABLE IF EXISTS top_connected_stations;
CREATE TABLE top_connected_stations
STORED AS ORC
AS
SELECT
    stop_id,
    stop_name,
    routes_served
FROM station_connectivity
ORDER BY routes_served DESC
LIMIT 20;

-- -- Hourly service distribution ------------------------------------------------
DROP TABLE IF EXISTS hourly_service_distribution;
CREATE TABLE hourly_service_distribution
STORED AS ORC
AS
SELECT
    LPAD(hour, 2, '0') AS hour_of_day,
    service_count
FROM hourly_services
ORDER BY hour;

-- -- Operator network comparison ------------------------------------------------
DROP TABLE IF EXISTS operator_network_comparison;
CREATE TABLE operator_network_comparison
STORED AS ORC
AS
SELECT
    operator_prefix,
    total_trips,
    total_stops,
    total_routes
FROM operator_network_summary
ORDER BY total_trips DESC;

SELECT 'Hive outputs saved successfully' AS status;
