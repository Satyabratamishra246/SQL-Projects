-- 1. Data Cleansing Steps

-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

-- Convert the week_date to a DATE format
-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- Add a month_number with the calendar month for each week_date value as the 3rd column
-- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value:

    -- Segment | age band
    -- 1       | Young Adults
    -- 2       | Middle Aged
    -- 3 or 4  | Retirees
-- Add a new demographic column using the following mapping for the first letter in the segment values:

    -- Segment | demographic
    -- C       | Couples
    -- F       | Families
-- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record


SELECT
    CONVERT(DATE, TRIM(week_date), 3) AS week_date,
    DATEPART(WEEK, CONVERT(DATE, TRIM(week_date), 3)) AS week_number,
    DATEPART(MONTH, CONVERT(DATE, TRIM(week_date), 3)) AS month_number,
    DATEPART(YEAR, CONVERT(DATE, TRIM(week_date), 3)) AS calendar_year,
    region,
    platform,
    CASE WHEN segment = 'null' or segment IS NULL THEN 'unknown' ELSE segment END AS segment,
    (CASE
        WHEN segment LIKE '%1' THEN 'Young Adults'
        WHEN segment LIKE '%2' THEN 'Middle Aged'
        WHEN segment = 'null' OR segment IS NULL THEN 'unknown'
        ELSE 'Retirees' END
    ) AS age_band,
    (CASE
        WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families'
        WHEN segment = 'null' OR segment IS NULL THEN 'unknown'
        ELSE 'Retirees' END
    ) AS demographic,
    customer_type,
    transactions,
    sales,
    ROUND(CAST(sales AS FLOAT) / CAST(transactions AS FLOAT) , 2) AS avg_transaction
INTO clean_weekly_sales
FROM weekly_sales
ORDER BY week_number;

-- 2. Data Exploration

-- Q1. What day of the week is used for each week_date value?

SELECT
    DATENAME(WEEKDAY, week_date) AS day,
    DATEPART(WEEKDAY, week_date) AS day_of_week
FROM clean_weekly_sales
GROUP BY
    DATENAME(WEEKDAY, week_date),
    DATEPART(WEEKDAY, week_date);

-- Q2. What range of week numbers are missing from the dataset?

WITH AllWeeks AS (
    SELECT TOP (52) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS week_number
    FROM master.dbo.spt_values
),
PresentWeeks AS (
    SELECT DISTINCT(week_number) AS week_number
    FROM clean_weekly_sales
)
SELECT week_number
FROM AllWeeks
WHERE week_number NOT IN (SELECT week_number FROM PresentWeeks);

-- Q3. How many total transactions were there for each year in the dataset?

SELECT
    calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year;

-- Q4. What is the total sales for each region for each month?

SELECT
    region,
    month_number,
    SUM(CAST(sales AS FLOAT)) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

-- Q5. What is the total count of transactions for each platform?

SELECT
    platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;

-- Q6. What is the percentage of sales for Retail vs Shopify for each month?

WITH MonthlySales AS (
    SELECT 
        month_number,
        platform,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM 
        clean_weekly_sales
    GROUP BY 
        month_number, platform
),
TotalSales AS (
    SELECT 
        month_number,
        SUM(total_sales) AS total_sales_per_month
    FROM 
        MonthlySales
    GROUP BY 
        month_number
)
SELECT 
    ms.month_number,
    ms.platform,
    ms.total_sales,
    CAST(ms.total_sales AS FLOAT) / ts.total_sales_per_month * 100 AS percentage_of_sales
FROM 
    MonthlySales ms
JOIN 
    TotalSales ts ON ms.month_number = ts.month_number
ORDER BY 
    ms.month_number, ms.platform;

-- Q7. What is the percentage of sales by demographic for each year in the dataset?

WITH YearlySales AS (
    SELECT 
        calendar_year,
        demographic,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM 
        clean_weekly_sales
    GROUP BY 
        calendar_year, demographic
),
TotalSales AS (
    SELECT 
        calendar_year,
        SUM(total_sales) AS total_sales_per_month
    FROM 
        YearlySales
    GROUP BY 
        calendar_year
)
SELECT 
    ms.calendar_year,
    ms.demographic,
    ms.total_sales,
    CAST(ms.total_sales AS FLOAT) / ts.total_sales_per_month * 100 AS percentage_of_sales
FROM 
    YearlySales ms
JOIN 
    TotalSales ts ON ms.calendar_year = ts.calendar_year
ORDER BY 
    ms.calendar_year, ms.demographic;

-- Q8. Which age_band and demographic values contribute the most to Retail sales?

SELECT
    age_band,
    demographic,
    SUM(CAST(sales AS FLOAT)) AS TotalSales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY TotalSales DESC;

-- Q9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify?
--If not - how would you calculate it instead?

-- Wrong approach
SELECT
    calendar_year,
    platform,
    avg(avg_transaction) AS average_transaction_size
FROM clean_weekly_sales
GROUP BY calendar_year, platform;

-- This approach is incorrect because it calculates the average of the already rounded avg_transaction values, which can lead to inaccuracies.
-- The avg_transaction values are rounded for each record, and averaging these rounded values does not provide an accurate overall average transaction size.

-- right approach
SELECT
    calendar_year,
    platform,
    SUM(CAST(sales AS FLOAT)) / SUM(CAST(transactions AS FLOAT)) AS average_transaction_size
FROM clean_weekly_sales
GROUP BY calendar_year, platform;

-- 3. Before & After Analysis

-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

WITH full_table AS
    (SELECT
        *,
        CASE WHEN DATEDIFF(WEEK, week_date,'2020-06-15') BETWEEN 1 AND 4 THEN 'before'
            WHEN  DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 3 THEN 'after' END AS time_frame
    FROM clean_weekly_sales
    ),
sales_summary AS
    (SELECT
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY time_frame
    )
SELECT
    'before' AS time_frame,
    before.total_sales,
    'after' AS time_frame,
    after.total_sales,
    after.total_sales - before.total_sales AS sales_difference,
    CASE 
        WHEN before.total_sales = 0 THEN NULL 
        ELSE ((after.total_sales - before.total_sales) / before.total_sales) * 100 
    END AS percentage_change
FROM
    (SELECT total_sales FROM sales_summary WHERE time_frame = 'before') AS before,
    (SELECT total_sales FROM sales_summary WHERE time_frame = 'after') AS after;

-- What about the entire 12 weeks before and after?

WITH full_table AS
    (SELECT
        *,
        CASE WHEN DATEDIFF(WEEK, week_date,'2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN  DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' END AS time_frame
    FROM clean_weekly_sales
    ),
sales_summary AS
    (SELECT
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY time_frame
    )
SELECT
    'before' AS time_frame,
    before.total_sales,
    'after' AS time_frame,
    after.total_sales,
    after.total_sales - before.total_sales AS sales_difference,
    CASE 
        WHEN before.total_sales = 0 THEN NULL 
        ELSE ((after.total_sales - before.total_sales) / before.total_sales) * 100 
    END AS percentage_change
FROM
    (SELECT total_sales FROM sales_summary WHERE time_frame = 'before') AS before,
    (SELECT total_sales FROM sales_summary WHERE time_frame = 'after') AS after;

-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

WITH full_table AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before_2020'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after_2020'
            WHEN DATEDIFF(WEEK, week_date, '2019-06-15') BETWEEN 1 AND 12 THEN 'before_2019'
            WHEN DATEDIFF(WEEK, '2019-06-15', week_date) BETWEEN 0 AND 11 THEN 'after_2019'
            WHEN DATEDIFF(WEEK, week_date, '2018-06-15') BETWEEN 1 AND 12 THEN 'before_2018'
            WHEN DATEDIFF(WEEK, '2018-06-15', week_date) BETWEEN 0 AND 11 THEN 'after_2018'
            ELSE NULL
        END AS time_frame
    FROM clean_weekly_sales
)

SELECT
    time_frame,
    SUM(CAST(sales AS FLOAT)) AS total_sales
FROM
    full_table
WHERE
    time_frame IS NOT NULL
GROUP BY
    time_frame
ORDER BY
    time_frame;


-- 4. Bonus Question

--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

--region
--platform
--age_band
--demographic
--customer_type


-- For Region

WITH full_table AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' 
        END AS time_frame
    FROM clean_weekly_sales
),
sales_summary AS (
    SELECT
        region,
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY 
        region,
        time_frame
),
final_summary AS (
    SELECT
        region,
        MAX(CASE WHEN time_frame = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN time_frame = 'after' THEN total_sales END) AS after_sales
    FROM
        sales_summary
    GROUP BY
        region
)

SELECT
    region,
    before_sales,
    after_sales,
    CASE 
        WHEN before_sales IS NULL THEN NULL  -- Avoid division by zero
        WHEN after_sales IS NULL THEN NULL
        ELSE ((after_sales - before_sales) / before_sales) * 100  -- Calculate percentage change
    END AS percentage_change
FROM
    final_summary
ORDER BY
    percentage_change;

-- Platform

WITH full_table AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' 
        END AS time_frame
    FROM clean_weekly_sales
),
sales_summary AS (
    SELECT
        platform,
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY 
        platform,
        time_frame
),
final_summary AS (
    SELECT
        platform,
        MAX(CASE WHEN time_frame = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN time_frame = 'after' THEN total_sales END) AS after_sales
    FROM
        sales_summary
    GROUP BY
        platform
)

SELECT
    platform,
    before_sales,
    after_sales,
    CASE 
        WHEN before_sales IS NULL THEN NULL  -- Avoid division by zero
        WHEN after_sales IS NULL THEN NULL
        ELSE ((after_sales - before_sales) / before_sales) * 100  -- Calculate percentage change
    END AS percentage_change
FROM
    final_summary
ORDER BY
    percentage_change;

-- For age_band

WITH full_table AS (
    SELECT
        age_band,
        sales,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' 
        END AS time_frame
    FROM clean_weekly_sales
),
sales_summary AS (
    SELECT
        age_band,
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY 
        age_band,
        time_frame
),
final_summary AS (
    SELECT
        age_band,
        MAX(CASE WHEN time_frame = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN time_frame = 'after' THEN total_sales END) AS after_sales
    FROM
        sales_summary
    GROUP BY
        age_band
)

SELECT
    age_band,
    before_sales,
    after_sales,
    CASE 
        WHEN before_sales IS NULL THEN NULL  -- Avoid division by zero
        WHEN after_sales IS NULL THEN NULL
        ELSE ((after_sales - before_sales) / before_sales) * 100  -- Calculate percentage change
    END AS percentage_change
FROM
    final_summary
ORDER BY
    percentage_change;

-- For demographic

WITH full_table AS (
    SELECT
        demographic,
        sales,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' 
        END AS time_frame
    FROM clean_weekly_sales
),
sales_summary AS (
    SELECT
        demographic,
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY 
        demographic,
        time_frame
),
final_summary AS (
    SELECT
        demographic,
        MAX(CASE WHEN time_frame = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN time_frame = 'after' THEN total_sales END) AS after_sales
    FROM
        sales_summary
    GROUP BY
        demographic
)

SELECT
    demographic,
    before_sales,
    after_sales,
    CASE 
        WHEN before_sales IS NULL THEN NULL  -- Avoid division by zero
        WHEN after_sales IS NULL THEN NULL
        ELSE ((after_sales - before_sales) / before_sales) * 100  -- Calculate percentage change
    END AS percentage_change
FROM
    final_summary
ORDER BY
    percentage_change;

-- For customer type

WITH full_table AS (
    SELECT
        customer_type,
        sales,
        CASE 
            WHEN DATEDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12 THEN 'before'
            WHEN DATEDIFF(WEEK, '2020-06-15', week_date) BETWEEN 0 AND 11 THEN 'after' 
        END AS time_frame
    FROM clean_weekly_sales
),
sales_summary AS (
    SELECT
        customer_type,
        time_frame,
        SUM(CAST(sales AS FLOAT)) AS total_sales
    FROM
        full_table
    WHERE
        time_frame IN ('before', 'after')
    GROUP BY 
        customer_type,
        time_frame
),
final_summary AS (
    SELECT
        customer_type,
        MAX(CASE WHEN time_frame = 'before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN time_frame = 'after' THEN total_sales END) AS after_sales
    FROM
        sales_summary
    GROUP BY
        customer_type
)

SELECT
    customer_type,
    before_sales,
    after_sales,
    CASE 
        WHEN before_sales IS NULL THEN NULL  -- Avoid division by zero
        WHEN after_sales IS NULL THEN NULL
        ELSE ((after_sales - before_sales) / before_sales) * 100  -- Calculate percentage change
    END AS percentage_change
FROM
    final_summary
ORDER BY
    percentage_change;