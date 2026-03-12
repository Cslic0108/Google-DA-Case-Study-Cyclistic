-- Creating index
 CREATE INDEX idx_started_at ON main_data(started_at);
 CREATE INDEX idx_member_casual ON main_data(member_casual);

-- Indexing validation
EXPLAIN SELECT member_casual, COUNT(*) 
FROM v_clean_trips 
WHERE started_at > '2025-01-01' 
GROUP BY member_casual;

--Dimensional Modeling & Analytical Aggregation
SELECT 
    member_casual,
    DAYOFWEEK(started_at) AS day_of_week,
    HOUR(started_at) AS hour_of_day,
    MONTH(started_at) AS month_num,
    rideable_type,
    COUNT(*) AS trip_count,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, started_at, ended_at)/60), 2) AS avg_duration
FROM v_clean_trips
GROUP BY member_casual, day_of_week, hour_of_day, month_num, rideable_type;

--Geospatial analysis
SELECT 
    start_station_name,
    member_casual,
    AVG(start_lat) AS lat,
    AVG(start_lng) AS lng,
    COUNT(*) AS trip_count
FROM v_clean_trips
WHERE start_station_name IS NOT NULL 
  AND start_station_name <> ''
  AND start_lat IS NOT NULL
GROUP BY start_station_name, member_casual;

