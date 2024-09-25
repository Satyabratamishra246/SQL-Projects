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

Analyzed the distribution of movies and TV shows to understand content trends and preferences, providing insights into the types of content available on the platform.

</details>

<details>
<summary><strong>Understanding the Different Genres:</strong></summary>

Explored the various genres available in the dataset to identify popular genres and their distribution, aiding in content strategy and recommendation systems.

</details>

<details>
<summary><strong>Insights about the Directors and Casts:</strong></summary>

Investigated the directors and cast members, identifying prolific contributors and their impact on content popularity, which can inform talent acquisition and collaboration decisions.

</details>

<details>
<summary><strong>Understanding Length of Movies and TV Shows:</strong></summary>

Analyzed the duration of movies and TV shows, identifying patterns and inconsistencies. This helps in understanding content length preferences and standardizing duration data.

</details>

<details>
<summary><strong>Creating Stats for Actors Appearing in Shows:</strong></summary>

Developed detailed statistics for actors, including the number of shows they appear in, types of shows, and geographical distribution. This helps in talent evaluation and understanding actor popularity.

</details>

<details>
<summary><strong>Utilities for Customers:</strong></summary>

Created utilities such as the "Top 10 Latest Movies List" to enhance user experience by providing quick access to popular and recent content.

</details>





## Conclusion:
This project provides an in-depth analysis of the Netflix titles dataset, enhancing data quality and usability through thorough cleaning and standardization. It uncovers content trends, genre popularity, informing strategic content planning. Insights into directors, casts, and content duration help optimize talent acquisition and content curation. Additionally, actor statistics offer valuable information for talent evaluation. These findings can inform business strategies and enhance the overall user experience on the platform.