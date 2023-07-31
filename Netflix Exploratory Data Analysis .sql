SELECT * 
FROM netflix_titles$

/* DATA CLEANING PART */

-- Check for duplicates for show_id column

SELECT show_id, COUNT(*)
FROM netflix_titles$
GROUP BY show_id
HAVING COUNT(*) > 1

-- No duplicates

-- Check Null Values

SELECT
  COUNT(CASE WHEN show_id IS NULL THEN 1 END) AS id_null_count,
  COUNT(CASE WHEN type IS NULL THEN 1 END) AS type_null_count,
  COUNT(CASE WHEN title IS NULL THEN 1 END) AS title_null_count,
  COUNT(CASE WHEN director IS NULL THEN 1 END) AS director_null_count,
  COUNT(CASE WHEN cast IS NULL THEN 1 END) AS cast_null_count,
  COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_null_count,
  COUNT(CASE WHEN date_added IS NULL THEN 1 END) AS date_added_null_count,
  COUNT(CASE WHEN release_year IS NULL THEN 1 END) AS release_year_null_count,
  COUNT(CASE WHEN rating IS NULL THEN 1 END) AS rating_null_count,
  COUNT(CASE WHEN duration IS NULL THEN 1 END) AS duration_null_count,
  COUNT(CASE WHEN listed_in IS NULL THEN 1 END) AS listedin_null_count,
  COUNT(CASE WHEN description IS NULL THEN 1 END) AS description_null_count
FROM netflix_titles$

-- Null Values in director(2634), cast(825), country(831), date_added(10), rating(4) and duration(3)
-- Deal with Null Values in director and cast


SELECT *
FROM netflix_titles$
WHERE director IS NULL

SELECT
   count(1) as TotalAll,
   count(director) as TotalNotNull,
   count(1) - count(director) as TotalNull,
   100.0 * count(director) / count(1) as PercentNotNull
FROM netflix_titles$

SELECT
   count(1) as TotalAll,
   count(cast) as TotalNotNull,
   count(1) - count(cast) as TotalNull,
   100.0 * count(cast) / count(1) as PercentNotNull
FROM netflix_titles$


-- There are 30% Null for director
-- 10% Null for cast
-- Large amount of Null Values and cannot populate from other columns directly 
-- Replace with "Unknown"

UPDATE netflix_titles$
SET director = COALESCE(director, 'Unknown')
WHERE director IS NULL

UPDATE netflix_titles$
SET cast = COALESCE(cast, 'Unknown')
WHERE cast IS NULL

-- Deal with country

SELECT
   count(*) as TotalAll,
   count(country) as TotalNotNull,
   count(*) - count(country) as TotalNull,
   100.0 * count(country) / count(*) as PercentNotNull
FROM
netflix_titles$

-- Also 10% of Null Values for country
-- Replace with Unknown
-- Not to replace Null Values with mode values as the percentage is too high


UPDATE netflix_titles$
SET country = COALESCE(country, 'Unknown')
WHERE country IS NULL

-- Deal with date added
-- Only 10 Null Values
-- It is diffcult to find out the date the TV show/ movies added to netflix from internet 
-- Drop the columns

SELECT * 
FROM netflix_titles$
Where date_added IS NULL

DELETE FROM netflix_titles$
WHERE date_added IS NULL

-- Deal with rating and duration
-- Both with very little Null Values (4 & 3)
-- Search online to replace the Null Values

SELECT * 
FROM netflix_titles$
Where rating IS NULL

SELECT rating, COUNT(rating)
FROM netflix_titles$
GROUP BY rating

-- Based on the information on IMDB for each Movies/ TV Shows, the rating are replaced 

UPDATE netflix_titles$
SET rating = 
	CASE 
		WHEN show_id = 's5990' THEN 'PG'
		WHEN show_id = 's6828' THEN 'TV-14'
		WHEN show_id = 's7313' THEN 'TV-MA'
		WHEN show_id = 's7538' THEN 'PG-13'
		ELSE 'N/A'
	END
WHERE rating IS NULL

-- Deal with duration

SELECT * 
FROM netflix_titles$
Where duration IS NULL

SELECT type, duration, COUNT(duration)
FROM netflix_titles$
GROUP BY type, duration
ORDER BY duration


-- The duration part is entered mistakely into the rating part 
	
UPDATE netflix_titles$
SET duration = 
	CASE 
		WHEN show_id = 's5795' THEN '84 min'
		WHEN show_id = 's5814' THEN '66 min'
		WHEN show_id = 's5542' THEN '74 min'
		ELSE 'N/A'
	END
WHERE duration IS NULL

-- Correct the rating part for this 3 Movies 
	
SELECT *
FROM netflix_titles$
WHERE show_id IN ('s5795', 's5814', 's5542')

UPDATE netflix_titles$
SET rating = 'TV-MA'
WHERE show_id IN ('s5795', 's5814', 's5542')

SELECT
  COUNT(CASE WHEN show_id IS NULL THEN 1 END) AS id_null_count,
  COUNT(CASE WHEN type IS NULL THEN 1 END) AS type_null_count,
  COUNT(CASE WHEN title IS NULL THEN 1 END) AS title_null_count,
  COUNT(CASE WHEN director IS NULL THEN 1 END) AS director_null_count,
  COUNT(CASE WHEN cast IS NULL THEN 1 END) AS cast_null_count,
  COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_null_count,
  COUNT(CASE WHEN date_added IS NULL THEN 1 END) AS date_added_null_count,
  COUNT(CASE WHEN release_year IS NULL THEN 1 END) AS release_year_null_count,
  COUNT(CASE WHEN rating IS NULL THEN 1 END) AS rating_null_count,
  COUNT(CASE WHEN duration IS NULL THEN 1 END) AS duration_null_count,
  COUNT(CASE WHEN listed_in IS NULL THEN 1 END) AS listedin_null_count,
  COUNT(CASE WHEN description IS NULL THEN 1 END) AS description_null_count
FROM netflix_titles$

-- ALL missing values dealt with

/*  DATA EXPLORATION  */

-- Fix the country data
-- There are data where multiple countries are within a single entry
-- Create a new column just collecting the first country in the entry

ALTER TABLE netflix_titles$
ADD country_new varchar(255)

UPDATE netflix_titles$
SET country_new = SUBSTRING(country, 1, CHARINDEX(',', country + ',') - 1) 

SELECT *
FROM netflix_titles$

-- Add new columns for date_added

ALTER TABLE netflix_titles$	
ADD month_added VARCHAR(255),
    year_added INT

UPDATE netflix_titles$
SET month_added = SUBSTRING(date_added, 1, CHARINDEX(' ', date_added) - 1),
    year_added= CAST(SUBSTRING(date_added, CHARINDEX(',', date_added) + 2, LEN(date_added) - CHARINDEX(',', date_added) - 1) AS INT)

SELECT date_added
FROM netflix_titles$

SELECT *
FROM netflix_titles$

-- Add a Genre Column to store the genres in JSON arrays

ALTER TABLE netflix_titles$
ADD Genre NVARCHAR(255);

UPDATE netflix_titles$
SET Genre = (
    SELECT JSON_QUERY('[' + STRING_AGG('"' + TRIM(value) + '"', ',') + ']')
    FROM (
        SELECT value
        FROM STRING_SPLIT(listed_in, ',')
    ) AS split_values
)

ALTER TABLE netflix_titles$
ALTER COLUMN Genre NVARCHAR(MAX)

-- Identify target audience based on the rating of the TV show/ Movie

ALTER TABLE netflix_titles$
ADD Target_Audience VARCHAR(255)

SELECT rating, COUNT(rating)
FROM netflix_titles$
GROUP BY rating

UPDATE netflix_titles$
SET Target_Audience = 
    CASE rating
        WHEN 'G' THEN 'Kids'
        WHEN 'TV-G' THEN 'Kids'
		WHEN 'TV-Y' THEN 'Kids'
        WHEN 'PG' THEN 'Older Kids'
		WHEN 'TV-Y7' THEN 'Older Kids'
		WHEN 'TV-Y7-FV' THEN 'Older Kids'
		WHEN 'TV-PG' THEN 'Older Kids'
		WHEN 'PG-13' THEN 'Teens'
		WHEN 'TV-14' THEN ' Young Adults'
		WHEN 'NC-17' THEN 'Adult'
		WHEN 'NR' THEN 'Adult'
		WHEN 'R' THEN 'Adult'
		WHEN 'UR' THEN 'Adult'
        WHEN 'TV-MA' THEN 'Adult'
        ELSE NULL 
    END

SELECT *
FROM netflix_titles$

-- Space in 'Young Adults'
	
UPDATE netflix_titles$
SET Target_Audience = TRIM(Target_Audience)
WHERE Target_Audience = ' Young Adults'


-- Drop the description column as its not likely to be used in the viz
	
ALTER TABLE netflix_titles$
DROP COLUMN description


-- Transfer the data to Tableau to create visualisations



-- Check Data Type
SELECT *, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'netflix_titles$'
