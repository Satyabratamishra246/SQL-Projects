SELECT TOP 10 * FROM netflix_titles;


-- Understanding Null/missing/unknown values

-- For director column

SELECT director, COUNT(*) AS null_count 
FROM netflix_titles
WHERE director IS NULL OR director = 'Unknown' OR TRIM([director]) = ''
GROUP BY director;


SELECT TOP 10 director 
FROM netflix_titles;

-- The director column has multiple values in the same column separated by commas


-- For cast column

SELECT [cast], COUNT(*) AS null_count 
FROM netflix_titles
WHERE [cast] IS NULL OR [cast] = 'Unknown' OR TRIM([cast]) = ''
GROUP BY [cast];



SELECT TOP 10 [cast]
FROM netflix_titles;

-- For title column

SELECT type, title, director
FROM netflix_titles
WHERE [title] IS NULL OR [title] = 'Unknown' OR TRIM([title]) = '';

-- Title has an unknown value
-- No it's actually the name of the mmovie 'Unknown' Hehehe

-- For Country column

SELECT COUNT(*) as Null_count
FROM netflix_titles
WHERE [country] IS NULL OR [country] = 'Unknown' OR TRIM([country]) = '';


SELECT TOP 10 country
FROM netflix_titles;

-- For  Rating coolumn

SELECT DISTINCT rating as distinct_rating FROM netflix_titles;


-- For Duration column

SELECT COUNT(*) as Null_count
FROM netflix_titles
WHERE [duration] IS NULL OR [duration] = 'Unknown' OR TRIM([duration]) = '';

-- has 3 null values

SELECT TOP 10
    [type]
    , duration
FROM netflix_titles;

-- has null, unknown and inconsistent values 

SELECT DISTINCT duration FROM netflix_titles WHERE [type] = 'Movie';

SELECT DISTINCT duration FROM netflix_titles WHERE [type] = 'TV Show';

--the movies are in min and tv shows are in seasons

-- Creating a cleaned View for better analysis

CREATE OR ALTER VIEW cleaned_table AS (
SELECT
    show_id
    , type
    , title
    , director
    , ISNULL(cast, 'Unknown') as cast
    , LTRIM(RTRIM(
        ISNULL(
            CASE 
                WHEN LTRIM(RTRIM(country)) = '' THEN 'Unknown'
                WHEN CHARINDEX(',', LTRIM(country)) = 1 THEN
                    CASE 
                        WHEN CHARINDEX(',', LTRIM(SUBSTRING(country, 2, LEN(country)))) > 0 
                        THEN SUBSTRING(LTRIM(SUBSTRING(country, 2, LEN(country))), 1, CHARINDEX(',', LTRIM(SUBSTRING(country, 2, LEN(country)))) - 1)
                        ELSE LTRIM(SUBSTRING(country, 2, LEN(country)))
                    END
                WHEN CHARINDEX(',', country) > 0 
                THEN SUBSTRING(country, 1, CHARINDEX(',', country) - 1)
                ELSE country
            END, 
            'Unknown'
        )
    )) AS country
    , CONVERT(date, date_added) as date_added
    , CAST(release_year AS CHAR(4)) as release_year-- I mistakenly imported it as int
    , CASE 
        WHEN Rating IS NULL OR Rating = '' THEN 'Unknown'
        WHEN Rating LIKE '% min' THEN 'Unknown'
        WHEN Rating IN ('G', 'TV-G', 'TV-Y', 'TV-Y7') THEN 'General Audience'
        WHEN Rating IN ('PG', 'TV-PG', 'TV-Y7-FV') THEN 'Parental Guidance Suggested'
        WHEN Rating IN ('PG-13', 'TV-14') THEN 'Parents Strongly Cautioned'
        WHEN Rating IN ('R', 'NC-17', 'TV-MA') THEN 'Restricted/Adult'
        WHEN Rating IN ('NR', 'UR', 'Unknown') THEN 'Unrated/Not Rated/Unknown'
        ELSE 'Unknown'
    END AS rating
    , CASE 
            WHEN duration IS NULL THEN NULL
            WHEN duration LIKE '%min%' THEN CAST(SUBSTRING(duration, 1, CHARINDEX(' ', duration) - 1) AS INT)
            WHEN duration LIKE '%Seasons%' THEN CAST(SUBSTRING(duration, 1, CHARINDEX(' ', duration) - 1) AS INT)
            ELSE NULL
        END AS time_value,
        CASE
            WHEN duration IS NULL THEN NULL
            WHEN duration LIKE '%min%' THEN 'min'
            WHEN duration LIKE '%Seasons%' THEN 'Seasons'
            ELSE NULL
        END AS time_unit
    , listed_in
    , description
FROM
    netflix_titles);




-- Understanding Movies & TV Shows Distribution


-- Q1. Total Movies vs TV shows

SELECT type, COUNT(show_id) AS count
FROM cleaned_table
GROUP BY type
UNION
SELECT 'Total' AS type, COUNT(show_id) AS count
FROM cleaned_table
ORDER BY [count];


-- Q2. Ranking countries based on count of movies and tv shows

WITH count_table AS (
SELECT
    country
    , type
    , COUNT(show_id) AS count
FROM cleaned_table
GROUP BY country, type
)

SELECT 
    country
    , type
    , count
    , RANK() OVER(PARTITION BY type ORDER BY count DESC) AS rnk
FROM count_table
WHERE country != 'Unknown'
ORDER BY rnk;

-- Q3. movie and tv shows over the years

WITH count_table AS (
    SELECT
        CASE WHEN release_year >= 2015 THEN 'Betwen 2015-2021'
            ELSE 'Before 2015' END AS year
        , [type]
        , COUNT(show_id) AS count
    FROM cleaned_table
    GROUP BY release_year, [type]
)

SELECT
    year
    , type
    , SUM(count) AS Total 
FROM count_table
GROUP BY year, type
UNION
SELECT
    'Total' + type AS year
    , type
    , SUM(count) AS Total
FROM count_table
GROUP BY type
ORDER BY type, Total

-- Q4. Most common rating for Movies and TV Shows

WITH count_table AS (
    SELECT [type], rating, COUNT(show_id) AS count
    FROM cleaned_table
    WHERE rating != 'Unknown'
    GROUP BY [type], rating
),
ranked_rating AS (
    SELECT [type]
        , rating
        , [count]
        , RANK() OVER(PARTITION BY type ORDER BY count DESC) AS Rnk
    FROM count_table
)
SELECT * FROm ranked_rating WHERE Rnk = 1;

-- Q5. How many movies and tv shows were added in the same year as they were released?

SELECT
    [type]
    , COUNT(show_id) AS count
FROM cleaned_table
WHERE YEAR(release_year) = YEAR(date_added)
GROUP BY [type]
UNION ALL
SELECT 'Total' AS TYPE
    , COUNT(show_id) AS count
FROM cleaned_table
WHERE YEAR(release_year) = YEAR(date_added)

-- Better solution

SELECT
    ISNULL([type], 'Total') AS [type],
    COUNT(show_id) AS count
FROM cleaned_table
WHERE YEAR(release_year) = YEAR(date_added)
GROUP BY ROLLUP([type]);

-- Q6. How many movies and TV shows were added late on Netflix?
-- Considering movies and Tv shows that were released after the first addition on Netflix

DECLARE @first_addition DATE;
SET @first_addition = (SELECT MIN(date_added) FROM cleaned_table);

SELECT ISNULL([type], 'Total') AS [type]
    , COUNT(show_id) AS count
FROM cleaned_table
WHERE release_year >= @first_addition
    AND YEAR(release_year) != YEAR(date_added)
GROUP BY ROLLUP([type]);

-- Better View to confirm the results

DECLARE @first_addition DATE;
SET @first_addition = (SELECT MIN(date_added) FROM cleaned_table);

WITH flagged_table AS (
    SELECT
        show_id
        , [type]
        , YEAR(release_year) AS release_year
        , YEAR(date_added) AS date_added
        , CASE WHEN YEAR(release_year) != YEAR(date_added) THEN 1 ELSE 0 END AS diff_year_flag
        , CASE WHEN YEAR(release_year) >= YEAR(@first_addition) THEN 1 ELSE 0 END AS after_year_flag
    FROM cleaned_table
)
SELECT
    [type]
    , diff_year_flag
    , after_year_flag
    , COUNT(show_id) AS count
FROM flagged_table
GROUP BY CUBE([type],diff_year_flag, after_year_flag);

-- Understanding the different Genres

-- Q1. Finding the distinct Genres

SELECT DISTINCT TRIM([value]) AS Genres
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',');

-- Q2. Top 10 Genres

SELECT TOP 10 TRIM([value]) AS Genres
        , COUNT(show_id) AS show_count
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',')
GROUP BY TRIM(value)
ORDER BY [show_count] DESC;

-- Q3. Top 5 Genres of the previous year

DECLARE @previous_year int;
SET @previous_year = (SELECT MAX(release_year) - 1 FROM cleaned_table)

SELECT TOP 5 TRIM([value]) AS Genres
    , release_year
        , COUNT(show_id) AS show_count
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',')
WHERE release_year = @previous_year
GROUP BY release_year, TRIM(value)
ORDER BY release_year DESC,[show_count] DESC;

-- Q4. Top 5 Movie Genre 

SELECT TOP 5 type,
    TRIM([value]) AS Genres
    , COUNT(show_id) AS show_count
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',')
WHERE [type] = 'Movie'
GROUP BY [type], TRIM(value)
ORDER BY [show_count] DESC;

-- Q5. Most common combination of Genres

SELECT TOP 1
    listed_in
    , COUNT(show_id) AS shows_count
FROM cleaned_table
GROUP BY listed_in
ORDER BY shows_count DESC;


-- Insights about the Directors and Casts

-- Q1. Finding list of all directors

SELECT
    DISTINCT(TRIM(value)) AS Director
FROM
    cleaned_table
CROSS APPLY string_split(director, ',')
WHERE director IS NOT NULL AND TRIM(value) != ''

--Q2. Directors with most movies in India

WITH full_list AS (
    SELECT
        show_id
        , (TRIM(value)) AS Director
    FROM
        cleaned_table
    CROSS APPLY string_split(director, ',')
    WHERE [type] = 'Movie' AND country = 'India' AND director != 'Unknown' AND TRIM(value) != ''
    )
SELECT Top 10
    Director
    , COUNT(show_id) AS Movies_count
FROM full_list
GROUP BY Director
ORDER BY Movies_count DESC;

-- Q3. Cast with most TV shows in USA

WITH full_list AS (
    SELECT
        show_id
        , (TRIM(value)) AS cast
    FROM
        cleaned_table
    CROSS APPLY string_split([cast], ',')
    WHERE [type] = 'TV Show' AND country = 'United States' AND [cast] != 'Unknown' AND TRIM(value) != ''
    )
SELECT Top 10
    [cast]
    , COUNT(DISTINCT show_id) AS tvshows_count
FROM full_list
GROUP BY [cast]
ORDER BY tvshows_count DESC;

-- Q4. Directors who have worked in different countries

WITH full_list AS (
    SELECT
        country
        , (TRIM(value)) AS Director
    FROM
        cleaned_table
    CROSS APPLY string_split(director, ',')
    WHERE director != 'Unknown' AND TRIM(value) != ''
    )
SELECT Top 5
    Director
    , COUNT(DISTINCT country) AS country_count
FROM full_list
GROUP BY Director
ORDER BY country_count DESC;

-- Q5. Top Cast whose movies have been added in the last month

DECLARE @last_added_date DATE;
SET @last_added_date = (SELECT MAX(date_added) FROM cleaned_table);

DECLARE @last_month_date DATE;
SET @last_month_date = DATEADD(MONTH, -1, @last_added_date);

WITH full_list AS (
SELECT
    show_id
    , date_added AS added_on
    , (TRIM(value)) AS cast
FROM
    cleaned_table
CROSS APPLY string_split([cast], ',')
WHERE cast != 'Unknown' AND cast is NOT NULL AND TRIM(value) != ''
    AND date_added >= @last_month_date
)
SELECT TOP 5
    [cast]
    , COUNT(DISTINCT show_id) AS show_count
FROM full_list
GROUP BY [cast]
ORDER BY show_count DESC;

--Q6. Top 3 cast in the stand-ups Genre and have released most shows after 2018

WITH full_list AS (
SELECT
    show_id
    , rating
    , TRIM(cast_value.[value]) AS cast
    , TRIM(listed_value.[value]) AS Genre
FROM cleaned_table
CROSS APPLY string_split([cast], ',') AS cast_value
CROSS APPLY string_split(listed_in, ',') AS listed_value
WHERE
    cast_value.value IS NOT NULL
    AND TRIM(cast_value.value) != ''
    AND listed_value.value IS NOT NULL
    AND TRIM(listed_value.value) != ''
    AND listed_value.[value] = 'Stand-Up Comedy'
)
SELECT TOP 3
    [cast]
    , COUNT(show_id) AS shows_count
FROM full_list
GROUP BY [cast]
ORDER BY shows_count DESC;


-- Understanding length of movie and tv shows

-- Q1. Average Duration of movies in South Korea

SELECT
    country
    , AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie' AND country = 'South Korea'
GROUP BY country


-- Q2. Total Movies Average duration

SELECT
    AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie'

-- Q3. How the average movie duration changed over the years in Australia

SELECT
    release_year
    , AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie' AND country = 'Australia'
GROUP BY release_year
ORDER BY release_year

-- Q4. TV shows with more than 7 seasons

SELECT
    show_id
    , title
    , CONCAT(time_value,' ' , time_unit) AS seasons
FROM cleaned_table
WHERE time_unit = 'Seasons' AND time_value > 7

--Q5. Average duration of movies in the Drama Gence in South Korea in the last 5 years

WITH full_list AS (
    SELECT
        [type]
        , country
        , release_year
        , TRIM(value) AS Genre
        , time_value
    FROM cleaned_table
    CROSS APPLY string_split(listed_in, ',')
    WHERE
        [type] = 'Movie' AND country = 'South Korea' 
        AND release_year > 2016
)
SELECT
    Genre
    , AVG(time_value) AS average_duration_in_minutes
FROM full_list
WHERE Genre = 'Dramas'
GROUP BY Genre;

-- Q6. List of Movies with duration between 70mins to 100mins in Action Genre in 'South Africa'

WITH full_list AS (
    SELECT
        [show_id]
        , country
        , title
        , TRIM(value) AS Genre
        , time_value
    FROM cleaned_table
    CROSS APPLY string_split(listed_in, ',')
    WHERE
        [type] = 'Movie' AND time_value BETWEEN 70 and 100
        AND country = 'South Africa'
)
SELECT
    show_id
    , title
    , Genre
    , country
FROM full_list
WHERE Genre = 'Action & Adventure';



-- Creating a stats for a Actor coming to a show

--Q1. Finding the Actor who has worked in most number of movies and shows

WITH extended_table AS (
    SELECT
        *
        , TRIM([value]) AS actor_name
    FROM cleaned_table
    CROSS APPLY string_split([cast], ',')
    WHERE [cast] != 'Unknown'
)
SELECT TOP 1 [actor_name]
FROM extended_table
GROUP BY [actor_name]
ORDER BY COUNT(DISTINCT show_id) DESC


--Q2. How many movies and tv shows has he worked in?
SELECT 
    COUNT(CASE WHEN [type] = 'Movie' THEN 1 END) AS movies_count
    , COUNT(CASE WHEN [type] = 'TV Show' THEN 1 END) AS tvshows_count
FROM cleaned_table 
WHERE cast LIKE '%Anupam Kher%';

-- Q3. In which all countryies he has worked in?

SELECT
    DISTINCT TRIM(value) AS country 
FROM cleaned_table
CROSS APPLY string_split(country, ',')
WHERE cast LIKE '%Anupam Kher%';

-- Q4. In which all genres he has worked in?

SELECT
    DISTINCT TRIM(value) AS genre
FROM cleaned_table
CROSS APPLY string_split(listed_in, ',')
WHERE cast LIKE '%Anupam Kher%';

-- Q5. For how many years has he worked in the industry?

SELECT
    CONVERT(INT, MAX(release_year)) - CONVERT(INT, MIN(release_year) ) AS yrs_in_industry
FROM cleaned_table
WHERE cast LIKE '%Anupam Kher%';

-- Q6. How many actors has he worked with?

SELECT COUNT(cast) - 1 AS co_stars_count
    FROM (
SELECT
    DISTINCT TRIM(value) as cast
FROM cleaned_table
CROSS APPLY string_split([cast], ',')
WHERE cast LIKE '%Anupam Kher%') T

-- Untilities for customers

-- Q1. Top 10 latest movies list

SELECT TOP 10
    title
    , date_added
FROM cleaned_table
WHERE [type] = 'Movie'
ORDER BY date_added DESC;

-- Q2. Top 5 latest TV Shows for Kids in India

SELECT TOP 5
    title
    , date_added
    , listed_in
FROM cleaned_table
WHERE type = 'TV Show'  AND country = 'India'
    AND listed_in LIKE '%Kid%'
ORDER BY date_added DESC;

-- Q3. List All TV Shows Released in a Specific Year (e.g 2020)

SELECT title
    , release_year
FROm cleaned_table
WHERE type = 'TV Show' AND release_year = '2020'

-- Q4. List All Movies that are Documentaries

SELECT show_id, title, listed_in, [type]
FROM cleaned_table
WHERE listed_in LIKE '%Documentaries%' AND [type] = 'Movie';

-- Q5. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

SELECT
    show_id
    , [type]
    , title
    , director
FROM cleaned_table
WHERE director LIKE '%Rajiv Chilaka';





-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- ENDED