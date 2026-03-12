-- Converting strings to `DATETIME`
ALTER TABLE main_data 
MODIFY COLUMN started_at DATETIME,
MODIFY COLUMN ended_at DATETIME;

-- Cleanup NULL
UPDATE main_data 
SET start_lat = NULL WHERE start_lat = '' OR start_lat = '0';
UPDATE main_data 
SET start_lng = NULL WHERE start_lng = '' OR start_lng = '0';
UPDATE main_data 
SET end_lat = NULL WHERE end_lat = '' OR end_lat = '0';
UPDATE main_data 
SET end_lng = NULL WHERE end_lng = '' OR end_lng = '0';

-- Converting strings to `DECIMAL`
ALTER TABLE main_data 
MODIFY COLUMN start_lat DECIMAL(10, 8),
MODIFY COLUMN start_lng DECIMAL(11, 8),
MODIFY COLUMN end_lat DECIMAL(10, 8),
MODIFY COLUMN end_lng DECIMAL(11, 8);

-- Inconsistent travel record
SELECT COUNT(*) AS inconsist_travel_count
FROM main_data
WHERE ended_at < started_at;

-- Trip Duration Validation
SELECT COUNT(*) AS less_than_60
FROM main_data
WHERE started_at >= ended_at 
   OR TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60;

-- Calculate average duration with raw data
SELECT 
    member_casual, 
    COUNT(*) as total_rows,
    AVG(TIMESTAMPDIFF(MINUTE, started_at, ended_at)) as raw_avg_duration
FROM main_data
GROUP BY member_casual;

-- Calculate average duration with cleaned data
SELECT 
    member_casual, 
    COUNT(*) AS total_rows,
    ROUND(AVG(CASE 
        WHEN TIMESTAMPDIFF(SECOND, started_at, ended_at) >= 60 
             AND started_at < ended_at 
        THEN TIMESTAMPDIFF(SECOND, started_at, ended_at) 
        ELSE NULL 
    END) / 60, 2) AS cleaned_avg_duration
FROM main_data
GROUP BY member_casual;

--Create final data
CREATE VIEW v_clean_trips AS
SELECT *
FROM main_data
WHERE started_at < ended_at 
  AND TIMESTAMPDIFF(SECOND, started_at, ended_at) >= 60;
