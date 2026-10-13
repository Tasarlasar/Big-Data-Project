-- =============================================================================
-- Hive Analytics Queries - Tokyo Railway Pipeline (CAT II Project 2)
--
-- Run with:  hive -f 02_analytics_queries.hql
-- =============================================================================

USE tokyo_transport;

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.cli.print.header=true;

-- =============================================================================
-- Q1. Count stations per operator (from clean_stops)
-- =============================================================================
SELECT
    operator_prefix,
    COUNT(*) AS station_count
FROM clean_stops
GROUP BY operator_prefix
ORDER BY station_count DESC;

-- =============================================================================
-- Q2. Count routes per operator (from clean_routes)
-- =============================================================================
SELECT
    operator_prefix,
    COUNT(*) AS route_count
FROM clean_routes
GROUP BY operator_prefix
ORDER BY route_count DESC;

-- =============================================================================
-- Q3. Count trips per route ordered by trip_count DESC (from trips_per_route)
-- =============================================================================
SELECT
    operator_prefix,
    route_id,
    route_long_name,
    trip_count
FROM trips_per_route
ORDER BY trip_count DESC;

-- =============================================================================
-- Q4. Top 20 most-connected stations (routes served) from station_connectivity
-- =============================================================================
SELECT
    stop_id,
    stop_name,
    routes_served
FROM station_connectivity
ORDER BY routes_served DESC
LIMIT 20;

-- =============================================================================
-- Q5. Stations served by 3+ routes (multi-line interchanges) from station_connectivity
-- =============================================================================
SELECT
    stop_id,
    stop_name,
    routes_served
FROM station_connectivity
WHERE routes_served >= 3
ORDER BY routes_served DESC;

-- =============================================================================
-- Q6. Routes with most stops from stops_per_route
-- =============================================================================
SELECT
    operator_prefix,
    route_id,
    stop_count
FROM stops_per_route
ORDER BY stop_count DESC;

-- =============================================================================
-- Q7. Services scheduled per hour of day from hourly_services
-- =============================================================================
SELECT
    LPAD(hour, 2, '0') AS hour_of_day,
    service_count
FROM hourly_services
ORDER BY hour;

-- =============================================================================
-- Q8. Operator network comparison (routes, trips, stations) from operator_network_summary
-- =============================================================================
SELECT
    operator_prefix,
    total_routes,
    total_trips,
    total_stops
FROM operator_network_summary
ORDER BY total_trips DESC;

-- =============================================================================
-- Q9. Average stops per route per operator (join stops_per_route + routes_per_operator)
-- =============================================================================
SELECT
    s.operator_prefix,
    ROUND(SUM(s.stop_count) / SUM(r.route_count), 2) AS avg_stops_per_route
FROM stops_per_route s
JOIN routes_per_operator r
    ON s.operator_prefix = r.operator_prefix
GROUP BY s.operator_prefix
ORDER BY avg_stops_per_route DESC;

-- =============================================================================
-- Q10. Top 10 busiest routes by trip count from trips_per_route
-- =============================================================================
SELECT
    operator_prefix,
    route_id,
    route_long_name,
    trip_count
FROM trips_per_route
ORDER BY trip_count DESC
LIMIT 10;

-- =============================================================================
-- Q11. Distribution of route types from clean_routes
-- Route type codes: 0=tram,1=subway,2=rail,3=bus,4=ferry,5=cable car,6=gondola,7=funicular
-- =============================================================================
SELECT
    route_type,
    CASE route_type
        WHEN 0 THEN 'Tram'
        WHEN 1 THEN 'Subway'
        WHEN 2 THEN 'Rail'
        WHEN 3 THEN 'Bus'
        WHEN 4 THEN 'Ferry'
        WHEN 5 THEN 'Cable Car'
        WHEN 6 THEN 'Gondola'
        WHEN 7 THEN 'Funicular'
        ELSE 'Unknown'
    END AS route_type_name,
    COUNT(*) AS count
FROM clean_routes
GROUP BY route_type
ORDER BY route_type;

-- =============================================================================
-- Q12. Find routes that appear in gtfs_joined with both service_id=0 (weekday) and service_id=1 (weekend)
-- Routes that run 7 days
-- =============================================================================
SELECT DISTINCT route_id, route_long_name
FROM gtfs_joined
GROUP BY route_id, route_long_name
HAVING COUNT(DISTINCT service_id) >= 2;

-- =============================================================================
-- Q13. Total number of unique stops across all operators
-- =============================================================================
SELECT COUNT(DISTINCT stop_id) AS total_unique_stops
FROM clean_stops;

-- =============================================================================
-- Q14. Total number of unique routes across all operators
-- =============================================================================
SELECT COUNT(DISTINCT route_id) AS total_unique_routes
FROM clean_routes;

-- =============================================================================
-- Q15. Average trip count per route by operator
-- =============================================================================
SELECT
    operator_prefix,
    COUNT(*) AS total_routes,
    SUM(trip_count) AS total_trips,
    ROUND(AVG(trip_count), 2) AS avg_trips_per_route
FROM trips_per_route
GROUP BY operator_prefix
ORDER BY total_trips DESC;
