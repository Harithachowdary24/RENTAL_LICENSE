USE PROJECT;
SHOW TABLES;
SELECT * FROM OPERATOR;

create table operator_staging like operator;

USE PROJECT;
insert operator_staging 
select * from  operator;

select * from OPERATOR_STAGING;

SELECT TRIM(lICENSE_HOLDER_NAME)
FROM OPERATOR_STAGING;

/*1. Geographic Validity
Longitude values represent positions on the east-west axis of the globe and are valid only between -180 (west) and 180 (east).
Latitude values represent positions on the north-south axis of the globe and are valid only between -90 (south) and 90 (north).
Values outside these ranges are mathematically or geographically impossible and would lead to errors in mapping, visualization, or location-based calculations.
*/
CREATE TABLE Cleaned_Dat AS
SELECT
    Operator_License_Number,
    CASE
        WHEN Longitude BETWEEN -180 AND 180 THEN Longitude
        ELSE NULL
    END AS Longitude,
    CASE
        WHEN Latitude BETWEEN -90 AND 90 THEN Latitude
        ELSE NULL
    END AS Latitude
FROM Operator_Staging;

select * from operator_staging;

SELECT *
FROM OPERATOR_STAGING
WHERE 
   Operator_License_Number  IS NULL OR
   License_Number   IS NULL OR
   License_Holder_Name           IS NULL OR
   Operator_Name  IS NULL OR
   Operator_Phone IS NULL OR
   Operator_Email IS NULL OR 
   X IS NULL OR
   y IS NULL  OR
   Longitude IS  NULL OR
   Latitude IS NULL OR
   Location IS NULL;
   
SELECT *
FROM OPERATOR_STAGING
WHERE 
   Operator_License_Number = '' OR
   License_Number  = '' OR
   License_Holder_Name   =    ''  OR
   Operator_Name =  '' OR
   Operator_Phone = '' OR
   Operator_Email  ='' OR 
   X = '' OR 
   y = ''  OR
   Longitude = '' OR
   Latitude = '' OR
   Location = '';

UPDATE Operator_Staging
SET OPERATOR_NAME = NULL,
    OPERATOR_LICENSE_NUMBER = NULL,
    OPERATOR_PHONE = NULL,
    OPERATOR_EMAIL = NULL
WHERE OPERATOR_NAME = '' 
   OR OPERATOR_LICENSE_NUMBER = ''
   OR OPERATOR_PHONE = ''
   OR OPERATOR_EMAIL = '';

DELETE FROM OPERATOR_STAGING
WHERE 
   Operator_License_Number  IS NULL OR
   License_Number   IS NULL OR
   License_Holder_Name           IS NULL OR
   Operator_Name  IS NULL OR
   Operator_Phone IS NULL OR
   Operator_Email IS NULL OR 
   X IS NULL OR
   y IS NULL  OR
   Longitude IS  NULL OR
   Latitude IS NULL OR
   Location IS NULL;
SET SQL_SAFE_UPDATES = 0;

USE PROJECT;
SELECT * FROM Operator_Staging;

#UPDATE LICENSENUMBER IN A FORMAT

UPDATE OPERATOR_STAGING
SET OPERATOR_LICENSE_NUMBER = REPLACE(REPLACE(REPLACE(REPLACE(OPERATOR_LICENSE_NUMBER, '(', ''), ')', ''), '-', ''), ' ', '') 
WHERE OPERATOR_LICENSE_NUMBER IS NOT NULL;

UPDATE OPERATOR_STAGING
SET OPERATOR_PHONE = CONCAT('(', SUBSTRING(OPERATOR_PHONE, 1, 3), ')-', SUBSTRING(OPERATOR_PHONE, 4, 3), '-', SUBSTRING(OPERATOR_PHONE, 7, 4))
WHERE OPERATOR_PHONE IS NOT NULL
  AND LENGTH(OPERATOR_PHONE) = 10;  -- Ensuring only 10-digit phone numbers are formatted

UPDATE OPERATOR_STAGING
SET OPERATOR_PHONE = CONCAT('(', SUBSTRING(OPERATOR_PHONE, 1, 3), ')-', SUBSTRING(OPERATOR_PHONE, 5, 3), '-', SUBSTRING(OPERATOR_PHONE, 9, 4))
WHERE OPERATOR_PHONE IS NOT NULL
  AND LENGTH(OPERATOR_PHONE) = 12;  -- Ensuring the phone number is in the ###-###-#### format

SET SQL_SAFE_UPDATES = 0;

#TO KEEP PHNO IN A FORMAT(###)-###-####
UPDATE OPERATOR_STAGING
SET OPERATOR_PHONE = CONCAT('(', SUBSTRING(OPERATOR_PHONE, 1, 3), ')-', SUBSTRING(OPERATOR_PHONE, 4, 3), '-', SUBSTRING(OPERATOR_PHONE, 7, 4))
WHERE OPERATOR_PHONE IS NOT NULL AND LENGTH(OPERATOR_PHONE) = 11;

#Remove or Standardize Emails Removing spaces from the email addresses.
#Checking for malformed emails or duplicates.
#Standardizing case (e.g., converting all emails to lowercase)For example:
#john doe@example.com would become johndoe@example.com.
UPDATE OPERATOR_STAGING
SET OPERATOR_EMAIL = TRIM(REPLACE(OPERATOR_EMAIL,'',''))
WHERE  OPERATOR_EMAIL IS NOT NULL ;

/*Normalize Coordinates
The coordinates seem to be in the correct format (POINT (longitude latitude)). You might want to make sure:

The coordinates are valid and are not null.
If your table has latitude and longitude in separate columns, you can extract these from the POINT column and clean them.*/

UPDATE OPERATOR_STAGING
SET Longitude = ST_X(Location),
    Latitude = ST_Y(Location)
WHERE Location IS NOT NULL;

#Error Code: 3548. There's no spatial reference system with SRID 1313427280.	0.016 sec
SELECT ST_SRID(Location) 
FROM OPERATOR_STAGING
LIMIT 1;
DESCRIBE OPERATOR_STAGING;

UPDATE OPERATOR_STAGING
SET Operator_Name = 'Unknown'
WHERE Operator_Name IS NULL OR TRIM(Operator_Name) = '';

UPDATE OPERATOR_STAGING
SET Operator_Phone = TRIM(Operator_Phone),
    Operator_Email = TRIM(Operator_Email)
WHERE Operator_Phone IS NOT NULL OR Operator_Email IS NOT NULL;

UPDATE OPERATOR_STAGING
SET OPERATOR_NAME = 'Unknown'
WHERE OPERATOR_NAME IS NULL OR OPERATOR_NAME = '';

/*Verify Numerical Values
Check that numerical columns such as OPERATOR_LICENSE_NUMBER, X, Y, etc., are not storing invalid or incorrect data (e.g., negative values, extremely large values, etc.).

For example, you can check if there are negative values in X and Y coordinates (if they shouldn’t be negative):*/

UPDATE OPERATOR_STAGING
SET X = ABS(X)
WHERE X < 0;

UPDATE OPERATOR_STAGING
SET Y = ABS(Y)
WHERE Y < 0;

USE PROJECT;

#REMOVE DUPLICATES 




-- Step 1: Create a temporary table with unique OPERATOR_PHONE values
CREATE TEMPORARY TABLE TempPhones AS
SELECT MIN(OPERATOR_PHONE) AS OPERATOR_PHONE
FROM OPERATOR_STAGING
GROUP BY OPERATOR_PHONE;

-- Check if the temporary table was created by running the following:
SHOW TABLES;  -- Check if TempPhones is listed

-- Step 2: Delete duplicates from OPERATOR_STAGING that are not in the temporary table
DELETE FROM OPERATOR_STAGING
WHERE OPERATOR_PHONE NOT IN (SELECT OPERATOR_PHONE FROM TempPhones);

-- Step 3: Drop the temporary table if it exists
DROP TEMPORARY TABLE IF EXISTS TempPhones;

UPDATE OPERATOR_STAGING
SET OPERATOR_PHONE = CONCAT(
    '(', 
    SUBSTRING(OPERATOR_PHONE, 1, 3), 
    ') ',
    SUBSTRING(OPERATOR_PHONE, 4, 3), 
    '-',
    SUBSTRING(OPERATOR_PHONE, 7, 4)
)
WHERE OPERATOR_PHONE REGEXP '^[0-9]{10}$';

#IMPROPER EMAIL This query will return email addresses that do not match the general pattern of a valid email address.
SELECT Operator_Email
FROM OPERATOR_STAGING
WHERE Operator_Email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

DELETE FROM OPERATOR_STAGING
WHERE Operator_Email LIKE '%@%' = 0;  -- Deletes rows that are missing the '@' symbol

DELETE FROM OPERATOR_STAGING
WHERE Operator_Email LIKE '%bearequityandrentals.com%'
   OR Operator_Email LIKE '%neworleans.com%'
   OR Operator_Email LIKE '%samerllc%'
   OR Operator_Email LIKE '%544 Warrington Dr%';
  
#This will standardize phone numbers to the format (###) ###-####.
UPDATE OPERATOR_STAGING
SET Operator_Phone = CONCAT('(', 
                            SUBSTRING(REGEXP_REPLACE(Operator_Phone, '[^0-9]', ''), 1, 3), ') ',
                            SUBSTRING(REGEXP_REPLACE(Operator_Phone, '[^0-9]', ''), 4, 3), '-',
                            SUBSTRING(REGEXP_REPLACE(Operator_Phone, '[^0-9]', ''), 7, 4))
WHERE LENGTH(REGEXP_REPLACE(Operator_Phone, '[^0-9]', '')) = 10;

#check invalid emails
SELECT *
FROM OPERATOR_STAGING
WHERE Operator_Email NOT LIKE '%_@__%.__%' OR Operator_Email IS NULL;#jcaguilera01@gmail,com

DELETE FROM OPERATOR_STAGING
WHERE Operator_Email NOT LIKE '%_@__%.__%' OR Operator_Email IS NULL;


UPDATE OPERATOR_STAGING
SET Operator_Email = 'charlotte@gmail.com'
WHERE Operator_Email = 'chawlotte@gmail.com'; 

update operator_staging
set Operator_Email = lower(Operator_Email);

#REPLACE CORRECT PHONE NOS WITH WRONG ONES
ALTER TABLE operator_staging
DROP COLUMN operator_phone ;  -- Adjust the length as needed

DELETE  FROM operator_staging
WHERE Operator_license_number NOT LIKE '%0%' 
  AND Operator_license_number NOT LIKE '%1%' 
  AND Operator_license_number NOT LIKE '%2%' 
  AND Operator_license_number NOT LIKE '%3%' 
  AND Operator_license_number NOT LIKE '%4%' 
  AND Operator_license_number NOT LIKE '%5%' 
  AND Operator_license_number NOT LIKE '%6%' 
  AND Operator_license_number NOT LIKE '%7%' 
  AND Operator_license_number NOT LIKE '%8%' 
  AND Operator_license_number NOT LIKE '%9%';
  
DELETE FROM OPERATOR_STAGING
WHERE operator_license_number REGEXP '^[a-zA-Z]+$';

DELETE FROM operator_staging
WHERE operator_license_number = 'â€­5624009828â€¬';

DELETE FROM  operator_staging
WHERE operator_license_number = 'â€ª5042641962â€¬';

DELETE FROM operator_staging
WHERE operator_license_number REGEXP '[^0-9]';

DELETE FROM operator_staging
WHERE LENGTH(operator_license_number) > 10;

UPDATE operator_staging
SET operator_name = TRIM(operator_name);

UPDATE operator_staging
SET license_holder_name= TRIM(license_holder_name);

UPDATE operator_staging
SET License_Holder_name = UPPER(License_Holder_name);

UPDATE operator_staging
SET operator_name = UPPER(operator_name);

UPDATE operator_staging
SET operator_email = UPPER(operator_email);


  
  SELECT * FROM OPERATOR_STAGING;
  SET SQL_SAFE_UPDATES = 0;








-- Insert your original phone numbers into the TempPhones table




use project;
select * from operator_staging;







select * from operator_staging;

   
DELETE  FROM OPERATOR_STAGING
WHERE Operator_Email IS NULL OR Operator_Email = '';






SELECT * FROM OPERATOR_STAGING;

describe operator_staging;

DELETE FROM OPERATOR_STAGING
WHERE Operator_Email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

UPDATE operator_staging
SET operator_email = LOWER(TRIM(operator_email))
WHERE operator_email IS NOT NULL;

UPDATE operator_staging
SET geo_coordinates = ST_GeomFromText(CONCAT('POINT(', longitude, ' ', latitude, ')'))
WHERE geo_coordinates IS NULL;

use project;
UPDATE operator_staging
SET Operator_Email = LOWER(TRIM(Operator_Email))
WHERE Operator_Email IS NOT NULL;

UPDATE operator_staging
SET Latitude = NULL
WHERE Latitude < -90 OR Latitude > 90;

UPDATE operator_staging
SET Longitude = NULL
WHERE Longitude < -180 OR Longitude > 180;

UPDATE operator_staging
SET Location = TRIM(REPLACE(Location, ',', ' '))
WHERE Location IS NOT NULL;

UPDATE operator_staging
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2)))
WHERE License_Holder_Name IS NOT NULL;

UPDATE operator_staging
SET Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)))
WHERE Operator_Name IS NOT NULL;

DELETE FROM operator_staging
WHERE License_Number NOT IN (
    SELECT MIN(License_Number)
    FROM operator_staging
    GROUP BY License_Number, Operator_Name
);

-- Step 1: Create a temporary table to hold the minimum License_Number for each group
CREATE TEMPORARY TABLE temp_table AS
SELECT MIN(License_Number) AS License_Number
FROM operator_staging
GROUP BY License_Number, Operator_Name;

-- Step 2: Delete records from operator_staging that don't match the minimum License_Number
DELETE FROM operator_staging
WHERE License_Number NOT IN (SELECT License_Number FROM temp_table);

-- Step 3: Drop the temporary table after deletion
DROP TEMPORARY TABLE temp_table;

#Using a JOIN for Deleting Duplicates
DELETE o
FROM operator_staging o
JOIN (
    SELECT MIN(License_Number) AS License_Number
    FROM operator_staging
    GROUP BY License_Number, Operator_Name
) AS t
ON o.License_Number = t.License_Number
WHERE o.License_Number != t.License_Number;

DELETE o
FROM operator_staging o
JOIN (
    SELECT MIN(License_Number) AS License_Number, Operator_Name
    FROM operator_staging
    GROUP BY Operator_Name
) AS t
ON o.License_Number != t.License_Number
AND o.Operator_Name = t.Operator_Name;

select * from operator_staging;

UPDATE operator_staging
SET License_Holder_Name = INITCAP(License_Holder_Name),
    Operator_Name = INITCAP(Operator_Name);
    
UPDATE operator_staging
SET Location = ST_GeomFromText(CONCAT('POINT(', Longitude, ' ', Latitude, ')'));

UPDATE operator_staging 
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2))),
    Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)));

UPDATE operator_staging
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2))),
    Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)));
    
UPDATE operator_staging
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2))),
    Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)));


UPDATE operator_staging 
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2))),
    Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)));

SELECT * 
FROM operator_staging 
WHERE Longitude < -180 OR Longitude > 180 
   OR Latitude < -90 OR Latitude > 90;
   
SELECT * 
FROM operator_staging
WHERE Operator_Email NOT LIKE '%@%.%';

select * from operator_staging;
SELECT * 
FROM operator_staging 
WHERE Longitude REGEXP '[^0-9.-]' 
   OR Latitude REGEXP '[^0-9.-]';
   
UPDATE operator_staging
SET Longitude = REPLACE(Longitude, 'invalid_characters', '')
WHERE Longitude LIKE '%invalid_characters%';

UPDATE operator_staging
SET Latitude = REPLACE(Latitude, 'invalid_characters', '')
WHERE Latitude LIKE '%invalid_characters%';

ALTER TABLE operator_staging
MODIFY COLUMN Location POINT NOT NULL;

SELECT * 
FROM operator_staging
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL 
  AND Longitude BETWEEN -180 AND 180
  AND Latitude BETWEEN -90 AND 90;
  

SELECT Longitude, Latitude
FROM operator_staging
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL
  AND (Longitude < -180 OR Longitude > 180 OR Latitude < -90 OR Latitude > 90);


UPDATE operator_staging
SET Location = ST_GeomFromText(CONCAT('POINT(', CAST(Longitude AS DECIMAL(10, 6)), ' ', CAST(Latitude AS DECIMAL(10, 6)), ')'))
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
  AND Longitude BETWEEN -180 AND 180
  AND Latitude BETWEEN -90 AND 90;
  
SELECT Longitude, Latitude
FROM operator_staging
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL
  AND (Longitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$' OR Latitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$');

UPDATE operator_staging
SET Longitude = REGEXP_REPLACE(Longitude, '[^0-9.-]', ''),
    Latitude = REGEXP_REPLACE(Latitude, '[^0-9.-]', '')
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL;
  
SELECT Longitude, Latitude, HEX(Longitude), HEX(Latitude)
FROM operator_staging
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL;
  
UPDATE operator_staging
SET Longitude = REGEXP_REPLACE(Longitude, '[^0-9.-]', ''),
    Latitude = REGEXP_REPLACE(Latitude, '[^0-9.-]', '')
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL;
  
  DESCRIBE operator_staging;
  
ALTER TABLE operator_staging
MODIFY COLUMN Location POINT NOT NULL;

SELECT Longitude, Latitude, HEX(Longitude), HEX(Latitude)
FROM operator_staging
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL;
  
UPDATE operator_staging
SET Longitude = REGEXP_REPLACE(Longitude, '[^0-9.-]', ''),
    Latitude = REGEXP_REPLACE(Latitude, '[^0-9.-]', '')
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL;
  
  DESCRIBE operator_staging;
  
UPDATE operator_staging
SET License_Holder_Name = INITCAP(License_Holder_Name),
    Operator_Name = INITCAP(Operator_Name);
    
UPDATE operator_staging
SET License_Holder_Name = CONCAT(UPPER(SUBSTRING(License_Holder_Name, 1, 1)), LOWER(SUBSTRING(License_Holder_Name, 2))),
    Operator_Name = CONCAT(UPPER(SUBSTRING(Operator_Name, 1, 1)), LOWER(SUBSTRING(Operator_Name, 2)));
    
SELECT * 
FROM operator_staging
WHERE Operator_Email NOT LIKE '%@%.%';

SELECT * 
FROM operator_staging 
WHERE Longitude REGEXP '[^0-9.-]' 
   OR Latitude REGEXP '[^0-9.-]';
   
UPDATE operator_staging
SET Longitude = REPLACE(Longitude, 'invalid_characters', '')
WHERE Longitude LIKE '%invalid_characters%';

UPDATE operator_staging
SET Latitude = REPLACE(Latitude, 'invalid_characters', '')
WHERE Latitude LIKE '%invalid_characters%';

ALTER TABLE operator_staging
MODIFY COLUMN Location POINT NOT NULL;

SELECT License_Number, Location 
FROM operator_staging 
WHERE NOT ST_IsValid(ST_GeomFromText(Location));

SELECT License_Number, Longitude, Latitude
FROM operator_staging
WHERE Longitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$'
   OR Latitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$';
   
SELECT License_Number, Longitude, Latitude
FROM operator_staging
WHERE Longitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$'
   OR Latitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$';

UPDATE operator_staging
SET Longitude = NULL, Latitude = NULL
WHERE Longitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$'
   OR Latitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$';
   
SELECT License_Number, Longitude, Latitude
FROM operator_staging
WHERE LENGTH(Longitude) != LENGTH(ASCII(Longitude))
   OR LENGTH(Latitude) != LENGTH(ASCII(Latitude));
   
UPDATE operator_staging
SET Longitude = NULL, Latitude = NULL
WHERE LENGTH(Longitude) != LENGTH(ASCII(Longitude))
   OR LENGTH(Latitude) != LENGTH(ASCII(Latitude));

DELETE FROM operator_staging
WHERE LENGTH(Longitude) != LENGTH(ASCII(Longitude))
   OR LENGTH(Latitude) != LENGTH(ASCII(Latitude));
   
SELECT License_Number, Longitude, Latitude
FROM operator_staging
WHERE Longitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$'
   OR Latitude NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$';

UPDATE operator_staging
SET Location = ST_GeomFromText(CONCAT('POINT(', Longitude, ' ', Latitude, ')'))
WHERE Longitude IS NOT NULL
  AND Latitude IS NOT NULL
  AND Longitude BETWEEN -180 AND 180
  AND Latitude BETWEEN -90 AND 90;
  
SELECT License_Number, Location
FROM operator_staging
WHERE Location IS NOT NULL;

UPDATE operator_staging
SET Longitude = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(Location, '(', -1), ' ', 1) AS DECIMAL(10, 6)),
    Latitude = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(Location, ' ', -1), ')', 1) AS DECIMAL(10, 6))
WHERE Location IS NOT NULL;

SELECT License_Number, Longitude, Latitude, Location
FROM operator_staging
WHERE Location IS NOT NULL;


use project;
select  * from operator_staging;

  











  
SELECT Longitude, Latitude, CONCAT('POINT(', Longitude, ' ', Latitude, ')') AS LocationText
FROM operator_staging
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL;

ALTER TABLE operator_staging
MODIFY COLUMN Location POINT;



  
  
ALTER TABLE operator_staging
MODIFY COLUMN Location POINT NOT NULL;


































SELECT * FROM OPERATOR_STAGING;






SELECT * FROM OPERATOR_STAGING;












