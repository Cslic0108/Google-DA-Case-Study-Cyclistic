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
