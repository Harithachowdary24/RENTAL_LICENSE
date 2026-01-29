select * from operator_staging;
select * from license_staging2;

describe operator_staging;
describe license_staging2;
#Step 1: Standardizing Data Formats
ALTER TABLE operator_staging 
MODIFY COLUMN X FLOAT, 
MODIFY COLUMN Y FLOAT, 
MODIFY COLUMN Longitude FLOAT, 
MODIFY COLUMN Latitude FLOAT, 
MODIFY COLUMN Operator_Email VARCHAR(255);

ALTER TABLE license_staging2 
MODIFY COLUMN Expiration_Date DATE, 
MODIFY COLUMN Application_Date DATE, 
MODIFY COLUMN Issue_Date DATE; #error

#1.1 check date format
SELECT DISTINCT Issue_Date 
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s') IS NULL;


SELECT Issue_Date
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s') IS NULL;

#1.2 find invalid datetime value rows
SELECT Issue_Date
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s') IS NULL
  AND STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NULL;#4rows returned with null
  
  
SELECT Issue_Date
FROM license_staging2
WHERE STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s') IS NULL
  AND STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NULL;
  
SELECT Issue_Date
FROM license_staging2
WHERE Issue_Date IS NULL OR TRIM(Issue_Date) = '';

SELECT Issue_Date
FROM license_staging2
WHERE Issue_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}';

#1.3 Convert DD-MM-YYYY HH:MM:SS to the standard format
UPDATE license_staging2
SET Issue_Date = STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s')
WHERE Issue_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}';

#1.4 Convert valid YYYY-MM-DD format to DATE
UPDATE license_staging2
SET Issue_Date = DATE(Issue_Date)
WHERE STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NOT NULL
  AND Issue_Date NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}';
 
 #1.5 Fix the rows with invalid datetime formats (without time)
UPDATE license_staging2
SET Issue_Date = '1970-01-01'
WHERE Issue_Date IS NOT NULL
  AND STR_TO_DATE(Issue_Date, '%Y-%m-%d %H:%i:%s') IS NULL
  AND STR_TO_DATE(Issue_Date, '%d-%m-%Y %H:%i:%s') IS NULL;


#Truncate time and modify the column  
UPDATE license_staging2
SET Issue_Date = DATE(Issue_Date);

#modify the column type to DATE
ALTER TABLE license_staging2
MODIFY COLUMN Issue_Date DATE;

#1.6 Handling Missing Values

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN License_Number IS NULL THEN 1 ELSE 0 END) AS missing_license_number,
    SUM(CASE WHEN Operator_Email IS NULL THEN 1 ELSE 0 END) AS missing_email
FROM operator_staging;#0

#1.7 Removing Duplicates
SELECT Operator_License_Number, COUNT(*) 
FROM operator_staging 
GROUP BY Operator_License_Number
HAVING COUNT(*) > 1;

DELETE FROM operator_staging 
WHERE Operator_License_Number IN (
    SELECT Operator_License_Number FROM (
        SELECT Operator_License_Number, ROW_NUMBER() OVER (PARTITION BY Operator_License_Number ORDER BY License_Number) AS row_num 
        FROM operator_staging
    ) t WHERE row_num > 1
);

#Joining Tables for Analysis
CREATE VIEW operator_license_data AS
SELECT 
    os.Operator_License_Number,
    os.License_Number,
    os.Operator_Name,
    os.Operator_Email,
    os.Longitude,
    os.Latitude,
    ls.Address,
    ls.License_Type,
    ls.Expiration_Date,
    ls.Application_Date,
    ls.Issue_Date
FROM operator_staging os
LEFT JOIN license_staging2 ls ON os.License_Number = ls.License_Number;

describe operator_license_data;

#2 EXPLORATORY DATA ANALYSIS

SELECT 
    COUNT(*) AS total_records, 
    COUNT(DISTINCT Operator_License_Number) AS unique_operators, 
    COUNT(DISTINCT License_Number) AS unique_licenses
FROM operator_license_data;

SELECT License_Type, COUNT(*) AS count 
FROM operator_license_data
GROUP BY License_Type
ORDER BY count DESC;

SELECT 
    SUM(CASE WHEN Address IS NULL THEN 1 ELSE 0 END) AS missing_addresses,
    SUM(CASE WHEN Expiration_Date IS NULL THEN 1 ELSE 0 END) AS missing_expiration_dates
FROM operator_license_data; #check missing values after transformation

# 2.1 FIND OUTLIER DETECTION
SELECT 
    MIN(Longitude) AS min_long, MAX(Longitude) AS max_long,
    MIN(Latitude) AS min_lat, MAX(Latitude) AS max_lat
FROM operator_license_data;  #find extreme values in Longitude and Latitude

SELECT 
    License_Number, 
    DATEDIFF(Expiration_Date, Issue_Date) AS validity_days
FROM operator_license_data
ORDER BY validity_days DESC
LIMIT 10; #Detect unusually long validity periods for licenses:

#2.2 License Expiration Analysis
SELECT 
    License_Number, Operator_Name, Expiration_Date 
FROM operator_license_data 
WHERE Expiration_Date < CURRENT_DATE;#Find licenses that are already expired

SELECT 
    License_Number, Operator_Name, Expiration_Date 
FROM operator_license_data 
WHERE Expiration_Date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY); #Find licenses expiring in the next 30 days

#2.3 Geographic Analysis
SELECT Address, COUNT(*) AS license_count 
FROM operator_license_data 
GROUP BY Address 
ORDER BY license_count DESC 
LIMIT 10;#Find the top locations with the most licenses

#2.4 Statistical Analysis
SELECT 
    Address, 
    AVG(DATEDIFF(Expiration_Date, Issue_Date)) AS avg_validity_days
FROM operator_license_data
GROUP BY Address
ORDER BY avg_validity_days DESC;#Check if certain areas have longer license validity

SELECT YEAR(Issue_Date) AS year, COUNT(*) AS total_licenses
FROM operator_license_data
GROUP BY YEAR(Issue_Date)
ORDER BY year DESC; #Check the number of licenses issued per year














