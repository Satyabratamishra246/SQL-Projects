# Netflix Movies and TV Shows Analysis using SQL

![alt text](https://github.com/Satyabratamishra246/SQL-Projects/blob/main/netflix-sql-project/logo.png)

## Project Overview: Comprehensive Analysis of Netflix Titles

This project focuses on performing a detailed analysis of the Netflix titles dataset. The goal is to derive meaningful insights and create utilities that enhance both business decision-making and user experience. The key steps and analyses performed in this project are as follows:

##### 1. Understanding Null/Missing/Unknown Values:
* Conducted a thorough investigation into columns with null, missing, or unknown values to assess data quality and identify areas requiring data cleaning
##### 2. Creating a Cleaned View for Better Analysis:
* Developed a cleaned view of the dataset by addressing inconsistencies and standardizing the data, enabling more accurate and efficient analysis
##### 3. Understanding Movies & TV Shows Distribution:
* Analyzed the distribution of movies and TV shows to understand content trends and preferences, providing insights into the types of content available on the platform
##### 4.Understanding the Different Genres:
* Explored the various genres available in the dataset to identify popular genres and their distribution, aiding in content strategy and recommendation systems
##### 5. Insights about the Directors and Casts:
* Investigated the directors and cast members, identifying prolific contributors and their impact on content popularity, which can inform talent acquisition and collaboration decisions
##### 6. Understanding Length of Movies and TV Shows:
* Analyzed the duration of movies and TV shows, identifying patterns and inconsistencies. This helps in understanding content length preferences and standardizing duration data
##### 7. Creating Stats for The Top Actor:
* Developed detailed statistics for the top actor, including the number of shows they appear in, types of shows, and geographical distribution. This helps in talent evaluation and understanding actor popularity
##### 8. Utilities for Customers:
* Created utilities such as the "Top 10 Latest Movies List" to enhance user experience by providing quick access to popular and recent content

## Detailed Analysis


<details>
<summary><strong>Understanding Null/Missing/Unknown Values:</strong></summary>

* For director column
```sql
    SELECT director, COUNT(*) AS null_count 
    FROM netflix_titles
    WHERE director IS NULL OR director = 'Unknown' OR TRIM([director]) = ''
    GROUP BY director;
```
Result \
![Null values in director](https://github.com/Satyabratamishra246/SQL-Projects/blob/b0c850a89c9109d42054afae579840c4364caaae/netflix-sql-project/result-images/image1.png)

The director column has 2634 null values

```sql
    SELECT TOP 10 DISTINCT director 
    FROM netflix_titles;
```
Result \
![ Random 10 directors](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image1.1.png)

The director column has multiple values in the same column separated by commas.



* For cast column
```sql
    SELECT [cast], COUNT(*) AS null_count 
    FROM netflix_titles
    WHERE [cast] IS NULL OR [cast] = 'Unknown' OR TRIM([cast]) = ''
    GROUP BY [cast];
```
Result \
![null value in cast column](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image2.png)

The cast column has 825 null values
```sql
    SELECT TOP 10 [cast]
    FROM netflix_titles;
```
Result \
![Random 10 values from cast column](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image2.1.png)

The cast column has multiple values in the same column separated by commas.


* For title column
```sql
SELECT type, title, director
FROM netflix_titles
WHERE [title] IS NULL OR [title] = 'Unknown' OR TRIM([title]) = '';
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image3.png)

Title has an unknown value? No it's actually the name of the movie 'Unknown'. Hehehe

* For Country column
```sql
SELECT COUNT(*) as Null_count
FROM netflix_titles
WHERE [country] IS NULL OR [country] = 'Unknown' OR TRIM([country]) = '';
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image4.png)
The country column has 831 null values.

```sql
SELECT TOP 10 country
FROM netflix_titles;
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image4.1.png)

The country column has multiple values in the same column separated by commas.

* For rating column
```sql
    SELECT DISTINCT rating 
    FROM netflix_titles;
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image5.png)

The rating column has some invalid data as duration in minutes and some categories can be combined to reduce no. of categories.

* For duration column
```sql
    SELECT COUNT(*) as Null_count
    FROM netflix_titles
    WHERE [duration] IS NULL OR [duration] = 'Unknown' OR TRIM([duration]) = '';
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/image6.png)

The duration column has 3 null values.

```sql
    SELECT TOP 10
        [type]
        , duration
    FROM netflix_titles;
```
Result \
![result](https://github.com/Satyabratamishra246/SQL-Projects/blob/89da772b08db3f40f21728e2135bd5718e7db79d/netflix-sql-project/result-images/images7.png)

The values in duration column is inconsistent as in for the movies duration is in min and for tv shows it is in seasons. To confirm this you can run the below two queries:

```sql
SELECT DISTINCT duration FROM netflix_titles WHERE [type] = 'Movie';
```
```sql
SELECT DISTINCT duration FROM netflix_titles WHERE [type] = 'TV Show';
```

</details>

<details>
<summary><strong>Creating a Cleaned View for Better Analysis:</strong></summary>

1. **Handling Null Values**: 
   - Replaced nulls in the `cast` column with 'Unknown' to ensure complete data for actor analyses.

2. **Standardizing Country Values**: 
   - Trimmed spaces and replaced empty strings in the `country` column with 'Unknown'. Extracted the first country from multi-country entries for accurate regional analysis.

3. **Converting Date Formats**: 
   - Converted `date_added` to a `date` type for easier time-based analyses.

4. **Correcting Data Types**: 
   - Cast `release_year` to a 4-character string for consistency in representation.

5. **Standardizing Ratings**: 
   - Grouped ratings into broader categories, simplifying the understanding of content suitability.

6. **Extracting and Standardizing Duration**: 
   - Created `time_value` to extract numeric values and defined `time_unit` to specify whether durations are in minutes or seasons.

7. **Direct Selection of Key Columns**: 
   - Selected essential columns to retain critical information while keeping the dataset manageable.

### Conclusion
These transformations enhance data quality and usability, enabling deeper insights into content trends and user preferences for informed decision-making.






Query:

```sql

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

```



Developed a cleaned view of the dataset by addressing inconsistencies and standardizing the data, enabling more accurate and efficient analysis.

</details>

<details>
<summary><strong>Understanding Movies & TV Shows Distribution:</strong></summary>

Q1. Total Movies vs TV shows

```sql

SELECT type, COUNT(show_id) AS count
FROM cleaned_table
GROUP BY type
UNION
SELECT 'Total' AS type, COUNT(show_id) AS count
FROM cleaned_table
ORDER BY [count]

```

Q2. Ranking countries based on count of movies and tv shows
```sql

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

```
Q3. movie and tv shows over the years

```sql
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

```
Q4. Most common rating for Movies and TV Shows

```sql
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

```
Q5. How many movies and tv shows were added in the same year as they were released?
```sql

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

```
-- Better solution
```sql

SELECT
    ISNULL([type], 'Total') AS [type],
    COUNT(show_id) AS count
FROM cleaned_table
WHERE YEAR(release_year) = YEAR(date_added)
GROUP BY ROLLUP([type]);

```
Q6. How many movies and TV shows were added late on Netflix?
-- Considering movies and Tv shows that were released after the first addition on Netflix

```sql
DECLARE @first_addition DATE;
SET @first_addition = (SELECT MIN(date_added) FROM cleaned_table);

SELECT ISNULL([type], 'Total') AS [type]
    , COUNT(show_id) AS count
FROM cleaned_table
WHERE release_year >= @first_addition
    AND YEAR(release_year) != YEAR(date_added)
GROUP BY ROLLUP([type]);
```
Better View to confirm the results
```sql

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

```

</details>

<details>
<summary><strong>Understanding the Different Genres:</strong></summary>

Q1. Finding the distinct Genres

```sql
SELECT DISTINCT TRIM([value]) AS Genres
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',');
```

Q2. Top 10 Genres

```sql
SELECT TOP 10 TRIM([value]) AS Genres
        , COUNT(show_id) AS show_count
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',')
GROUP BY TRIM(value)
ORDER BY [show_count] DESC;

```
Q3. Top 5 Genres of the previous year

```sql
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
```

Q4. Top 5 Movie Genre 
```sql

SELECT TOP 5 type,
    TRIM([value]) AS Genres
    , COUNT(show_id) AS show_count
FROM netflix_titles
CROSS APPLY string_split(listed_in, ',')
WHERE [type] = 'Movie'
GROUP BY [type], TRIM(value)
ORDER BY [show_count] DESC;

```
Q5. Most common combination of Genres
```sql

SELECT TOP 1
    listed_in
    , COUNT(show_id) AS shows_count
FROM cleaned_table
GROUP BY listed_in
ORDER BY shows_count DESC;

```

Explored the various genres available in the dataset to identify popular genres and their distribution, aiding in content strategy and recommendation systems.

</details>

<details>
<summary><strong>Insights about the Directors and Casts:</strong></summary>

Q1. Finding list of all directors

```sql
SELECT
    DISTINCT(TRIM(value)) AS Director
FROM
    cleaned_table
CROSS APPLY string_split(director, ',')
WHERE director IS NOT NULL AND TRIM(value) != ''

```
Q2. Directors with most movies in India

```sql
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

```
Q3. Cast with most TV shows in USA

```sql
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

```
Q4. Directors who have worked in different countries

```sql
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

```
Q5. Top Cast whose movies have been added in the last month

```sql
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

```
Q6. Top 3 cast in the stand-ups Genre and have released most shows after 2018

```sql
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

```

Investigated the directors and cast members, identifying prolific contributors and their impact on content popularity, which can inform talent acquisition and collaboration decisions.

</details>

<details>
<summary><strong>Understanding Length of Movies and TV Shows:</strong></summary>

Q1. Average Duration of movies in South Korea
```sql

SELECT
    country
    , AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie' AND country = 'South Korea'
GROUP BY country;
```


Q2. Total Movies Average duration

```sql
SELECT
    AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie'

```
Q3. How the average movie duration changed over the years in Australia

```sql
SELECT
    release_year
    , AVG(time_value) AS average_movie_duration
FROM cleaned_table
WHERE type = 'Movie' AND country = 'Australia'
GROUP BY release_year
ORDER BY release_year;

```
Q4. TV shows with more than 7 seasons
```sql

SELECT
    show_id
    , title
    , CONCAT(time_value,' ' , time_unit) AS seasons
FROM cleaned_table
WHERE time_unit = 'Seasons' AND time_value > 7;
```

Q5. Average duration of movies in the Drama Gence in South Korea in the last 5 years

```sql
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

```
Q6. List of Movies with duration between 70mins to 100mins in Action Genre in 'South Africa'
```sql

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
```


Analyzed the duration of movies and TV shows, identifying patterns and inconsistencies. This helps in understanding content length preferences and standardizing duration data.

</details>

<details>
<summary><strong>Creating Stats for The Top Actor:</strong></summary>

Q1. Finding the Actor who has worked in most number of movies and shows
```sql

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
ORDER BY COUNT(DISTINCT show_id) DESC;
```

Q2. How many movies and tv shows has he worked in?
```sql
SELECT 
    COUNT(CASE WHEN [type] = 'Movie' THEN 1 END) AS movies_count
    , COUNT(CASE WHEN [type] = 'TV Show' THEN 1 END) AS tvshows_count
FROM cleaned_table 
WHERE cast LIKE '%Anupam Kher%';

```
Q3. In which all countryies he has worked in?
```sql

SELECT
    DISTINCT TRIM(value) AS country 
FROM cleaned_table
CROSS APPLY string_split(country, ',')
WHERE cast LIKE '%Anupam Kher%';

```
Q4. In which all genres he has worked in?

```sql
SELECT
    DISTINCT TRIM(value) AS genre
FROM cleaned_table
CROSS APPLY string_split(listed_in, ',')
WHERE cast LIKE '%Anupam Kher%';
```

Q5. For how many years has he worked in the industry?

```sql
SELECT
    CONVERT(INT, MAX(release_year)) - CONVERT(INT, MIN(release_year) ) AS yrs_in_industry
FROM cleaned_table
WHERE cast LIKE '%Anupam Kher%';

```
Q6. How many actors and directors has he worked with?
```sql

SELECT COUNT(cast) - 1 AS co_stars_count
    FROM (
SELECT
    DISTINCT TRIM(value) as cast
FROM cleaned_table
CROSS APPLY string_split([cast], ',')
WHERE cast LIKE '%Anupam Kher%') T;
```


Developed detailed statistics for actors, including the number of shows they appear in, types of shows, and geographical distribution. This helps in talent evaluation and understanding actor popularity.

</details>

<details>
<summary><strong>Utilities for Customers:</strong></summary>


Q1. Top 10 latest movies list

```sql
SELECT TOP 10
    title
    , date_added
FROM cleaned_table
WHERE [type] = 'Movie'
ORDER BY date_added DESC;

```
Q2. Top 5 latest TV Shows for Kids in India

```sql
SELECT TOP 5
    title
    , date_added
    , listed_in
FROM cleaned_table
WHERE type = 'TV Show'  AND country = 'India'
    AND listed_in LIKE '%Kid%'
ORDER BY date_added DESC;

```
Q3. List All TV Shows Released in a Specific Year (e.g 2020)
```sql

SELECT title
    , release_year
FROm cleaned_table
WHERE type = 'TV Show' AND release_year = '2020';
```

Q4. List All Movies that are Documentaries

```sql
SELECT show_id, title, listed_in, [type]
FROM cleaned_table
WHERE listed_in LIKE '%Documentaries%' AND [type] = 'Movie';

```
Q5. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT
    show_id
    , [type]
    , title
    , director
FROM cleaned_table
WHERE director LIKE '%Rajiv Chilaka';

```

Created utilities such as the "Top 10 Latest Movies List" to enhance user experience by providing quick access to popular and recent content.

</details>


## Few Descriptive Insights

| Category   | Insight |
| -------- | ------- |
| Movie & TV Shows distribution   | The data shows that the number of movies and TV shows on the platform has increased significantly since 2015. While the number of movies has increased by around 90%, the number of TV shows has seen a more dramatic increase of approximately 460%. This suggests that the platform has been actively expanding its TV show content   |
|  Movie & TV Shows distribution |    The data shows that the United States dominates the streaming market with the highest number of movies and TV shows, while countries like India, South Korea, and Japan have a significant presence in both categories. Emerging markets like Nigeria, Mexico, and Australia are also gradually increasing their influence  |
| Rating for Movie & TV Show |  The data shows that the majority of movies and TV shows on the platform are rated "Restricted/Adult" and "Parents Strongly Cautioned," indicating a significant portion of the content is intended for mature audiences. While there are a smaller number of movies and TV shows rated "General Audience" and "Parental Guidance Suggested," the content on the platform leans towards a more mature demographic  |
Genre | Netflix offers a diverse range of content, with a strong focus on international movies and TV shows. Popular genres include dramas, comedies, and documentaries, catering to various viewer preferences. This strategy helps attract and retain a broad audience base |
Top Actor Stats | The analysis reveals that Anupam Kher has been a prominent figure in the entertainment industry for 29 years. He has worked in 42 movies and 1 TV shows across various countries, including India, Canada and United States. His versatile career has spanned 14 diverse genres, including Crime, comedy, Musical, Sci-fi fantasy and others, and he has collaborated with 273 actors |
Cast | The top 3 comedians who have appeared in the most stand-up comedy shows on Netflix after 2018 are Jeff Dunham, Kevin Hart, and Katt Williams |


## Conclusion:
This project provides an in-depth analysis of the Netflix titles dataset, enhancing data quality and usability through thorough cleaning and standardization. It uncovers content trends, genre popularity, informing strategic content planning. Insights into directors, casts, and content duration help optimize talent acquisition and content curation. Additionally, actor statistics offer valuable information for talent evaluation. These findings can inform business strategies and enhance the overall user experience on the platform.