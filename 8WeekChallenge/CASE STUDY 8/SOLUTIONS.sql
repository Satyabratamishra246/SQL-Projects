-- Data Exploration and Cleansing

SELECT * FROM interest_map;

SELECT * FROM interest_metrics;

-- For the Data Cleaning part I will use a View instead of changing the main table itself

-- Q1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

-- instead of changing the month_year I will be creating a new column

ALTER TABLE interest_metrics 
ADD month_year_date DATE;

UPDATE interest_metrics
SET month_year_date = 
    CASE 
        WHEN LEN(month_year) = 7 AND month_year LIKE '__-____' 
            THEN DATEFROMPARTS(CAST(RIGHT(month_year, 4) AS INT), CAST(LEFT(month_year, 2) AS INT), 1)  -- Format: MM-YYYY, Day set to 1
        WHEN LEN(month_year) = 7 AND month_year LIKE '____-__' 
            THEN DATEFROMPARTS(CAST(LEFT(month_year, 4) AS INT), CAST(RIGHT(month_year, 2) AS INT), 1)  -- Format: YYYY-MM, Day set to 1
        WHEN month_year IS NULL OR month_year = 'NULL'
            THEN NULL
        ELSE NULL
    END;


-- Q2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT 
    month_year_date,
    COUNT(*) AS record_count
FROM 
    interest_metrics
GROUP BY 
    month_year_date
ORDER BY 
    CASE WHEN month_year_date IS NULL THEN 0 ELSE 1 END,
    month_year_date;

-- Q3. What do you think we should do with these null values in the fresh_segments.interest_metrics

-- When interest_id is null it's better to delete them from our analysis

SELECT
    COUNT(*) AS total_rows,
    COUNT(CASE WHEN interest_id IS NULL THEN 1 END) AS null_counts
FROM interest_metrics 

DELETE FROM interest_metrics
WHERE interest_id IS NULL;

-- Check for other null value

SELECT
    COUNT(*) AS null_count
FROM interest_metrics
WHERE
    _month IS NULL
    OR _year IS NULL
    OR month_year IS NULL
    OR composition IS NULL
    OR index_value IS NULL
    OR ranking IS NULL
    OR percentile_ranking IS NULL;

-- Since null count is low we can remove them

DELETE FROM interest_metrics
WHERE
    _month IS NULL
    OR _year IS NULL
    OR month_year IS NULL
    OR composition IS NULL
    OR index_value IS NULL
    OR ranking IS NULL
    OR percentile_ranking IS NULL;

-- Q4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

SELECT 'missing_in_interest_map' AS source, COUNT(DISTINCT im.interest_id) AS count
FROM interest_metrics im
LEFT JOIN interest_map imap ON im.interest_id = imap.id
WHERE imap.id IS NULL

UNION ALL

SELECT 'missing_in_interest_metrics', COUNT(DISTINCT imap.id)
FROM interest_map imap
LEFT JOIN interest_metrics im ON imap.id = im.interest_id
WHERE im.interest_id IS NULL;


-- Q5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT 
    id,
    COUNT(*) AS total_record_count
FROM 
    interest_map
GROUP BY 
    id
ORDER BY 
    total_record_count DESC;

-- there's only one value for each id

-- Q6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and 
-- include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.




-- Q7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

