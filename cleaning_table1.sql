use project;
SHOW TABLES;
select * from license;

create table license_staging like license;

insert license_staging 
select * from license;

select * from license_staging 

SELECT VERSION();
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY License_number, Address, License_Type ORDER BY License_number) AS row_num
FROM license_staging;

WITH TOFIND AS(
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY License_number, Address, License_Type,Residential_Subtype,Expiration_Date,Application_Date,Issue_Date,Reference_Code,Link ORDER BY License_number) AS row_num

FROM license_staging
)
SELECT *
FROM TOFIND
WHERE row_num >1;

CREATE TABLE `license_staging2` (
  `License_Number` text,
  `Address` text,
  `License_Type` text,
  `Residential_Subtype` text,
  `Expiration_Date` text,
  `Application_Date` text,
  `Issue_Date` text,
  `Reference_Code` text,
  `Link` text,
   row_num int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from license_staging2
where row_num>1;

insert into license_staging2
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY License_number, Address, License_Type,Residential_Subtype,Expiration_Date,Application_Date,Issue_Date,Reference_Code,Link ORDER BY License_number) AS row_num

FROM license_staging;
 
delete  
from license_staging2
where row_num > 1;

select * from license_staging2;

SET SQL_SAFE_UPDATES = 0;

#STANDARDIZING DATA

SELECT TRIM(ADDRESS),TRIM(LICENSE_TYPE)
FROM LICENSE_STAGING2;

UPDATE LICENSE_STAGING2
SET ADDRESS = TRIM(ADDRESS);

UPDATE LICENSE_STAGING2
SET LICENSE_TYPE = TRIM(LICENSE_TYPE);

#WORKED SELECT STR_TO_DATE('01/18/2025 02:30:45 PM', '%m/%d/%Y %r');
/*UPDATE LICENSE_STAGING2
SET APPLICATION_DATE = 
    CASE
        WHEN APPLICATION_DATE LIKE '%AM' OR APPLICATION_DATE LIKE '%PM' THEN STR_TO_DATE(APPLICATION_DATE, '%m/%d/%Y %r')
        ELSE STR_TO_DATE(APPLICATION_DATE, '%m-%d-%Y %H:%i')
    END
WHERE APPLICATION_DATE IS NOT NULL AND APPLICATION_DATE != ''; */
/*Summary:
The UPDATE query will go through all rows in the LICENSE_STAGING2 table and check the format of the APPLICATION_DATE.
If APPLICATION_DATE contains "AM" or "PM", it will be interpreted as a 12-hour time and converted to a DATETIME field.
If APPLICATION_DATE doesn't have "AM" or "PM", it will be treated as a 24-hour time and converted to a DATETIME field.*/

UPDATE LICENSE_STAGING2
SET 

    EXPIRATION_DATE = 
        CASE
            WHEN EXPIRATION_DATE LIKE '%AM' OR EXPIRATION_DATE LIKE '%PM' THEN STR_TO_DATE(EXPIRATION_DATE, '%m/%d/%Y %r')
            ELSE STR_TO_DATE(EXPIRATION_DATE, '%m-%d-%Y %H:%i')
        END,
    ISSUE_DATE = 
        CASE
            WHEN ISSUE_DATE LIKE '%AM' OR ISSUE_DATE LIKE '%PM' THEN STR_TO_DATE(ISSUE_DATE, '%m/%d/%Y %r')
            ELSE STR_TO_DATE(ISSUE_DATE, '%m-%d-%Y %H:%i')
        END
WHERE 
	EXPIRATION_DATE IS NOT NULL AND EXPIRATION_DATE != ''
    AND ISSUE_DATE IS NOT NULL AND ISSUE_DATE != '';
SELECT  * FROM LICENSE_STAGING2;

#CHECK FOR NULLS OR INVALID ENTRIES IN MULTIPLE COLUMNS
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'LICENSE_STAGING2' AND TABLE_SCHEMA = 'PROJECT';

SELECT *
FROM LICENSE_STAGING2
WHERE 
   License_Number  IS NULL OR
   License_Type    IS NULL OR
   Link            IS NULL OR
   Reference_Code  IS NULL OR
   Residential_Subtype IS NULL OR
   row_num             IS NULL ;
   
    #Extract and Clean Data from URLs
   UPDATE LICENSE_STAGING2
   SET REFERENCE_CODE = SUBSTRING_INDEX(SUBSTRING_INDEX(REFERENCE_CODE, '=', -1), ' ', 1);

   
#Fix Inconsistent Column Entries
UPDATE LICENSE_STAGING2
SET LICENSE_TYPE = CASE 
    WHEN LICENSE_TYPE = 'Short Term Rental Commercial Owner' THEN 'Short Term Rental - Commercial Owner'
    ELSE LICENSE_TYPE 
END;

#Update Inconsistent Address Formatting
UPDATE LICENSE_STAGING2
SET address = REPLACE(address, 'St ', 'Street ')
WHERE address LIKE '%St%';

#CHECK FOR BLANK VALUES
SELECT *
FROM LICENSE_STAGING2
WHERE column_name = '';

#-------------- NULL VALUES/BLANKS------
#CHECK BLANKS
SELECT *
FROM  LICENSE_STAGING2
WHERE    
   License_Number = '' OR
   License_Type  =  '' OR
   Link      =   '' OR
   Reference_Code = '' OR 
   Residential_Subtype = '' OR
   row_num  = '' ;

#--------REMOVE COLUMN-----
ALTER TABLE LICENSE_STAGING2
DROP COLUMN LINK;



use project;
SELECT * FROM LICENSE_STAGING2;

UPDATE LICENSE_STAGING2
SET address = REPLACE(address, ' Apt ', ', Apt ')
WHERE address LIKE '% Apt%';

UPDATE LICENSE_STAGING2
SET Residential_subtype = NULL
WHERE Residential_subtype = 'N/A';

ALTER TABLE license_staging2
MODIFY COLUMN expiration_date DATETIME,  
MODIFY COLUMN application_date DATETIME,  
MODIFY COLUMN issue_date DATETIME;

DESCRIBE license_staging2; -- MySQL  

UPDATE  license_staging2
SET Expiration_Date = STR_TO_DATE(Expiration_Date, '%Y-%m-%d %H:%i:%s'),
    Application_Date = STR_TO_DATE(Application_Date, '%Y-%m-%d %H:%i:%s'),
    Issue_Date = STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s');

SELECT * 
FROM license_staging2
WHERE Application_Date = '' OR Application_Date IS NULL
   OR Expiration_Date = '' OR Expiration_Date IS NULL
   OR Issue_Date = '' OR Issue_Date IS NULL;
   
UPDATE license_staging2  
SET Expiration_Date = NULLIF(Expiration_Date, ''),  
    Application_Date = NULLIF(Application_Date, ''),  
    Issue_Date = NULLIF(Issue_Date, '');
    
UPDATE license_staging2  
SET Expiration_Date = STR_TO_DATE(Expiration_Date, '%Y-%m-%d %H:%i:%s'),  
    Application_Date = STR_TO_DATE(Application_Date, '%Y-%m-%d %H:%i:%s'),  
    Issue_Date = STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s')  
WHERE Expiration_Date IS NOT NULL  
  AND Application_Date IS NOT NULL  
  AND Issue_Date IS NOT NULL;

ALTER TABLE license_staging2  
MODIFY COLUMN Expiration_Date DATETIME,  
MODIFY COLUMN Application_Date DATETIME,  
MODIFY COLUMN Issue_Date DATETIME;

UPDATE license_staging2  
SET Expiration_Date = STR_TO_DATE(Expiration_Date, '%m/%d/%Y %h:%i:%s %p'),
    Application_Date = STR_TO_DATE(Application_Date, '%m/%d/%Y %h:%i:%s %p'),
    Issue_Date = STR_TO_DATE(Issue_Date, '%m/%d/%Y %h:%i:%s %p')
WHERE Expiration_Date LIKE '%AM' OR Expiration_Date LIKE '%PM'
   OR Application_Date LIKE '%AM' OR Application_Date LIKE '%PM'
   OR Issue_Date LIKE '%AM' OR Issue_Date LIKE '%PM';


SELECT Expiration_Date  
FROM license_staging2  
WHERE Expiration_Date LIKE '%AM' OR Expiration_Date LIKE '%PM';

UPDATE license_staging2  
SET Expiration_Date = CASE 
                        WHEN Expiration_Date LIKE '%AM' OR Expiration_Date LIKE '%PM' 
                        THEN STR_TO_DATE(Expiration_Date, '%m/%d/%Y %h:%i:%s %p')
                        ELSE Expiration_Date
                      END,
    Application_Date = CASE 
                        WHEN Application_Date LIKE '%AM' OR Application_Date LIKE '%PM' 
                        THEN STR_TO_DATE(Application_Date, '%m/%d/%Y %h:%i:%s %p')
                        ELSE Application_Date
                      END,
    Issue_Date = CASE 
                  WHEN Issue_Date LIKE '%AM' OR Issue_Date LIKE '%PM' 
                  THEN STR_TO_DATE(Issue_Date, '%m/%d/%Y %h:%i:%s %p')
                  ELSE Issue_Date
                END;


ALTER TABLE license_staging2  
MODIFY COLUMN Expiration_Date DATETIME,  
MODIFY COLUMN Application_Date DATETIME,  
MODIFY COLUMN Issue_Date DATETIME;

SELECT * 
FROM license_staging2
WHERE Issue_Date LIKE '%-%-% %:%' AND LENGTH(Issue_Date) = 16;
 
UPDATE license_staging2
SET Issue_Date = CONCAT(Issue_Date, ':00')
WHERE Issue_Date LIKE '%-%-% %:%' AND LENGTH(Issue_Date) = 16;

select * from license_staging2;

UPDATE license_staging2  
SET Expiration_Date = STR_TO_DATE(Expiration_Date, '%m/%d/%Y %h:%i:%s %p'),
    Application_Date = STR_TO_DATE(Application_Date, '%m/%d/%Y %h:%i:%s %p'),
    Issue_Date = STR_TO_DATE(Issue_Date, '%m/%d/%Y %h:%i:%s %p')
WHERE Expiration_Date LIKE '%AM' OR Expiration_Date LIKE '%PM'
   OR Application_Date LIKE '%AM' OR Application_Date LIKE '%PM'
   OR Issue_Date LIKE '%AM' OR Issue_Date LIKE '%PM';
   
SELECT HEX(Issue_Date) 
FROM license_staging2 
WHERE Issue_Date = '07-06-2023 15:09:00';

UPDATE license_staging2
SET Issue_Date = TRIM(Issue_Date)
WHERE Issue_Date = '07-06-2023 15:09:00';

UPDATE license_staging2  
SET Issue_Date = STR_TO_DATE(Issue_Date, '%m/%d/%Y %h:%i:%s %p')
WHERE LENGTH(Issue_Date) = 16;

UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(TRIM(Issue_Date), '%m-%d-%Y %H:%i:%s')
WHERE LENGTH(Issue_Date) = 19;

SELECT HEX(Issue_Date)
FROM license_staging2
WHERE Issue_Date = '2024-09-17 10:28:06';

UPDATE license_staging2
SET Issue_Date = TRIM(REPLACE(Issue_Date, CHAR(13), ''))
WHERE Issue_Date = '2024-09-17 10:28:06';

UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(TRIM(Issue_Date), '%m/%d/%Y %H:%i:%s')
WHERE LENGTH(Issue_Date) = 19;

UPDATE license_staging2
SET Issue_Date = '2024-09-17 10:28:06'
WHERE Issue_Date = '2024-09-17 10:28:06';



SELECT Issue_Date
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NOT NULL;

SELECT Issue_Date
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NULL;

UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(Issue_Date, '%m-%d-%Y %H:%i:%s')
WHERE LENGTH(Issue_Date) = 19 AND Issue_Date LIKE '%-%';

UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(Issue_Date, '%m-%d-%Y %H:%i:%s')
WHERE LENGTH(Issue_Date) = 19
AND Issue_Date NOT LIKE '%-%-%-%';  -- Exclude valid YYYY-MM-DD format

UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(Issue_Date, '%m-%d-%Y %H:%i:%s')
WHERE Issue_Date LIKE '%-%-%-%'  -- Ensure this matches MM-DD-YYYY HH:MM:SS pattern
AND Issue_Date NOT LIKE '%-%-%-%-%';  -- Exclude valid YYYY-MM-DD format

SELECT Issue_Date
FROM license_staging2
WHERE LENGTH(Issue_Date) = 19
AND Issue_Date NOT LIKE '%-%-%-%';

SELECT Issue_Date
FROM license_staging2
WHERE LENGTH(Issue_Date) = 19
AND Issue_Date NOT LIKE '%-%-%-%';

DELETE FROM license_staging2  
WHERE License_Number NOT IN (  
    SELECT License_Number FROM temp_license  
);

UPDATE license_staging2
SET address = CONCAT(UCASE(LEFT(address, 1)), LCASE(SUBSTRING(address, 2)));

DROP TEMPORARY TABLE temp_license;

UPDATE license_staging2
SET Address = REPLACE(Address, ',,', ',')
WHERE Address LIKE '%,,%';

SELECT Address
FROM license_staging2
WHERE Address LIKE '%,,%';


select * from license_staging2;

UPDATE license_staging2
SET Address = CONCAT(
    UPPER(SUBSTRING(Address, 1, 1)), 
    LOWER(SUBSTRING(Address, 2, LENGTH(Address) - 1))
)
WHERE Address LIKE '%st%' OR Address LIKE '%ave%' OR Address LIKE '%street%';

UPDATE license_staging2
SET Expiration_Date = STR_TO_DATE(Expiration_Date, '%Y-%m-%d %H:%i:%s'),
    Application_Date = STR_TO_DATE(Application_Date, '%Y-%m-%d %H:%i:%s'),
    Issue_Date = STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s')
WHERE Expiration_Date LIKE '%-%' AND Application_Date LIKE '%-%' AND Issue_Date LIKE '%-%';


CREATE TEMPORARY TABLE temp_license AS
SELECT MIN(License_Number) AS License_Number
FROM license_staging2
GROUP BY Address, Expiration_Date, Application_Date, License_Type;


DELETE FROM license_staging2
WHERE License_Number NOT IN (  
    SELECT License_Number FROM temp_license  
);

DROP TEMPORARY TABLE temp_license;

SELECT * FROM license_staging2
WHERE Residential_Subtype NOT LIKE 'N/A';

SELECT Address FROM license_staging2 WHERE Address LIKE '%,,%';

UPDATE license_staging2
SET Address = REPLACE(Address, ',,', ',')
WHERE Address LIKE '%,,%';

SELECT * FROM license_staging2 LIMIT 10;

UPDATE license_staging2
SET Address = CONCAT(
    UPPER(SUBSTRING(Address, 1, 1)), 
    LOWER(SUBSTRING(Address, 2, LENGTH(Address) - 1))
)
WHERE Address LIKE '%st%' OR Address LIKE '%ave%' OR Address LIKE '%street%';

UPDATE license_staging2
SET Address = REPLACE(Address, 'tchoupitoulas st', 'Tchoupitoulas St')
WHERE Address LIKE '%tchoupitoulas st%';

UPDATE license_staging2
SET Address = REPLACE(Address, 'street charles ave,', 'Street Charles Ave,')
WHERE Address LIKE '%street charles ave,%';

UPDATE license_staging2
SET Address = REPLACE(Address, 'street charles ave,', 'Street Charles Ave,')
WHERE Address LIKE '%street charles ave,%';

mysql -u username -p database_name < backup_file.sql



UPDATE license_staging2
SET Address = REPLACE(Address, ',,', ',')
WHERE Address LIKE '%,,%';












use project;

DESCRIBE license_staging2;

















   SET SQL_SAFE_UPDATES = 0;

   
   




















