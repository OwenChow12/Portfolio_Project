/* 

Cleaning Data in SQL Queries using Airbnb Open Data from Kaggle


Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types, User-Defined Functions

Change to the excel file before transferring the file to SQL:
removed 3 columns: instant bookable, house rules and license
changed the last review column to short date format

*/


Select *
From AirbnbData

-----------------------------------------------------------------------------------------------------------------------

--Create Temp table to make changes
--Remove Unused Columns


Select *
INTO #tempbnb
From AirbnbData

Select*
From #tempbnb
ORDER BY id

--lat and long does not add any value as location is also mentioned by neighbourhood
--Country is only in United States and is also showed by country code

ALTER TABLE	#tempbnb
DROP COLUMN lat, long, country


---------------------------------------------------------------------------------------------------------------------------------------

--Identify and Delete Duplicates


SELECT id, [host id], COUNT(*)
FROM #tempbnb
GROUP BY id, [host id]
HAVING COUNT(*) > 1 


With RowNumCTE AS( 
Select * ,
	ROW_NUMBER() OVER(
	PARTITION BY [host id],
						  [host name],
						  [neighbourhood group],
						  [room type],
						  price,
						  [minimum nights],
						  [number of reviews],
						  [last review]
						  ORDER BY
						           id
								   ) row_num
From #tempbnb
)

Select* 
From RowNumCTE
WHERE row_num > 1
ORDER BY id

DELETE
From RowNumCTE
WHERE row_num > 1


Select *
From #tempbnb


-------------------------------------------------------------------------------------------------------------------------

--Create Function to remove unwanted characters like latin extended characters



CREATE FUNCTION [dbo].[RemoveNonASCII] 
(
    @in_string nvarchar(max)
)
RETURNS nvarchar(MAX)
AS
BEGIN
 
    DECLARE @Result nvarchar(MAX)
    SET @Result = ''
 
    DECLARE @character nvarchar(1)
    DECLARE @index int
 
    SET @index = 1
    WHILE @index <= LEN(@in_string)
    BEGIN
        SET @character = SUBSTRING(@in_string, @index, 1)
   
        IF (UNICODE(@character) between 32 and 127) or UNICODE(@character) in (10,11)
            SET @Result = @Result + @character
        SET @index = @index + 1
    END
 
    RETURN @Result
END


SELECT dbo.[RemoveNonASCII](NAME)
From #tempbnb

UPDATE #tempbnb
SET NAME = dbo.[RemoveNonASCII](NAME)
	[host name] = dbo.[RemoveNonASCII]([host name])


-----------------------------------------------------------------------------------------------------------------------------------

--Remove symbols 


Select REPLACE( REPLACE(price, '$', ''),  ',', ''),
	   REPLACE([service fee], '$', '')
From #tempbnb

UPDATE #tempbnb
SET price = REPLACE( REPLACE(price, '$', ''),  ',', ''),
	[service fee] = REPLACE([service fee], '$', '')
	


-------------------------------------------------------------------------------------------------------------------------------------

--Standardize price and service fee Format

Select price, [service fee]
From #tempbnb

UPDATE #tempbnb
SET price =	CONVERT (int, price),
	[service fee] = CONVERT (int, price)

SELECT CONVERT (int, price) 
FROM #tempbnb


--------------------------------------------------------------------------------------------------------------------------------------

--Correcting the entry name in neighbourhood group


Select [neighbourhood group]
From #tempbnb
GROUP BY [neighbourhood group]


UPDATE #tempbnb
SET [neighbourhood group] = REPLACE([neighbourhood group], 'brookln', 'Brooklyn')
	
UPDATE #tempbnb
SET	[neighbourhood group] = REPLACE([neighbourhood group], 'manhatan', 'Manhattan')


------------------------------------------------------------------------------------------------------------------------------------------

--Populate neighbour group data

Select [neighbourhood group], neighbourhood
From #tempbnb
GROUP BY [neighbourhood group], neighbourhood
order by neighbourhood

Select a.[neighbourhood group], a.neighbourhood, b.[neighbourhood group], b.neighbourhood, ISNULL(a.[neighbourhood group],b.[neighbourhood group])
From #tempbnb a
JOIN #tempbnb b
	on a.neighbourhood = b.neighbourhood
	AND a.id <> b.id
Where a.[neighbourhood group] is null

UPDATE a
SET [neighbourhood group] = ISNULL(a.[neighbourhood group],b.[neighbourhood group]) 
From #tempbnb a
JOIN #tempbnb b
	on a.neighbourhood = b.neighbourhood
	AND a.id <> b.id
Where a.[neighbourhood group] is null


---------------------------------------------------------------------------------------------------------------------------------------------------


--Replace null values


Select [room type]
From #tempbnb
WHERE [room type] IS NULL



UPDATE #tempbnb
SET NAME = ISNULL(NAME, 'Not available'), 
	host_identity_verified = ISNULL(host_identity_verified, 'unconfirmed'), 
	[host name] = ISNULL([host name], 'Not available'), 
	neighbourhood = ISNULL(neighbourhood, 'Not available'),
	[country code] = ISNULL([host name], 'US'),
	cancellation_policy = ISNULL(cancellation_policy, 'Not available')
	

----------------------------------------------------------------------------------------------------------------------------------------------------

--Check negative value

SELECT [minimum nights], SIGN([minimum nights])
FROM #tempbnb
WHERE SIGN([minimum nights]) < 1


--change to 0 or
SELECT [minimum nights],
	 CASE WHEN [minimum nights] < 1
		  THEN 0
		  ELSE [minimum nights]
	END as minimum_nights_fixed
From #tempbnb
WHERE [minimum nights] < 1

--change to positive
SELECT ABS([minimum nights])
From #tempbnb

Select *
From #tempbnb


---------------------------------------------------------------------------------------------------------------------------------------------------

--Make changes to the original table/ new table by copying the code above
--Then can be used for further data exploration and visualizations

----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
