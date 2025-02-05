#1. Verify Data Integrity in SQL
-- Check for missing values in key columns (e.g., License_Number, Expiration_Date, Issue_Date)
SELECT 
    COUNT(*) AS Missing_License_Number
FROM operator_license_data
WHERE License_Number IS NULL;

SELECT 
    COUNT(*) AS Missing_Expiration_Date
FROM operator_license_data
WHERE Expiration_Date IS NULL;

SELECT 
    COUNT(*) AS Missing_Issue_Date
FROM operator_license_data
WHERE Issue_Date IS NULL;

#handling inconsistencies
-- Example: Find rows where the `Expiration_Date` is earlier than the `Issue_Date` (which should not happen)
SELECT License_Number, Expiration_Date, Issue_Date
FROM operator_license_data
WHERE Expiration_Date < Issue_Date;

-- Count of licenses by License Type
SELECT License_Type, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY License_Type
ORDER BY License_Count DESC;

-- Count of licenses by Address
SELECT Address, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY Address
ORDER BY License_Count DESC;

#Organize Results for Presentation in SQL

-- Distribution of License Types
CREATE TEMPORARY TABLE License_Type_Distribution AS
SELECT License_Type, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY License_Type
ORDER BY License_Count DESC;

-- Query the summary table
SELECT * FROM License_Type_Distribution;


#      REPORTING
-- Summary report with License Type distribution and expired licenses
CREATE TEMPORARY TABLE License_Summary_Report AS
SELECT 
    License_Type, 
    COUNT(*) AS License_Count,
    SUM(CASE WHEN Expiration_Date < CURRENT_DATE THEN 1 ELSE 0 END) AS Expired_Licenses,
    YEAR(Issue_Date) AS Year_Issued
FROM operator_license_data
GROUP BY License_Type, YEAR(Issue_Date)
ORDER BY Year_Issued DESC;

-- Check for non-null Expiration_Date values
SELECT COUNT(*)
FROM operator_license_data
WHERE Expiration_Date IS NOT NULL;

-- Check for any empty or invalid Expiration_Date values
SELECT COUNT(*)
FROM operator_license_data
WHERE Expiration_Date = '' OR Expiration_Date IS NULL;

-- Check if Expiration_Date is in a recognizable date format
SELECT License_Number, Expiration_Date, CAST(Expiration_Date AS DATE) AS Expiration_Date_Cast
FROM operator_license_data
LIMIT 10;

-- Check the data type of Expiration_Date
DESCRIBE operator_license_data;

-- Check if Expiration_Date is in a recognizable date format by casting it to date
SELECT License_Number, Expiration_Date, 
       CAST(Expiration_Date AS DATE) AS Expiration_Date_Cast
FROM operator_license_data
LIMIT 10;

-- Find expired licenses (where Expiration_Date is less than today's date)
SELECT License_Number, Expiration_Date
FROM operator_license_data
WHERE CAST(Expiration_Date AS DATE) < CURRENT_DATE;

-- Find licenses expiring within the next 30 days
SELECT License_Number, Expiration_Date
FROM operator_license_data
WHERE CAST(Expiration_Date AS DATE) BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
ORDER BY Expiration_Date;

-- Check today's date and the expired licenses for comparison
SELECT CURRENT_DATE;

-- Manually check a few rows to compare the expiration dates
SELECT License_Number, Expiration_Date
FROM operator_license_data
WHERE License_Number IN ('23-NSTR-14503', '23-NSTR-15969')  -- or any sample rows
ORDER BY Expiration_Date;

-- Summarize licenses expiring soon by address or region
SELECT Address, COUNT(*) AS Expiring_Licenses
FROM operator_license_data
WHERE CAST(Expiration_Date AS DATE) BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY Address
ORDER BY Expiring_Licenses DESC;


use project;
#summarize key findings

#1.What is the distribution of different license types in the dataset?
SELECT License_Type, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY License_Type
ORDER BY License_Count DESC;

#2.How many licenses are expiring within the next 30 days?
SELECT License_Number, Expiration_Date, Address
FROM operator_license_data
WHERE CAST(Expiration_Date AS DATE) BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY);



#3.How many licenses have already expired?
SELECT License_Number, Expiration_Date, Address
FROM operator_license_data
WHERE CAST(Expiration_Date AS DATE) < CURRENT_DATE;

#4.Which regions have the highest and lowest number of licenses??
SELECT Address, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY Address
ORDER BY License_Count DESC
LIMIT 10;  -- Top 10 regions with most licenses



#5.How has the number of licenses issued changed over time?
SELECT YEAR(Issue_Date) AS Year, COUNT(*) AS Licenses_Issued
FROM operator_license_data
GROUP BY YEAR(Issue_Date)
ORDER BY Year;

#------------------------------------------- Organize and Document Findings-----------------------------------------------------
-- Summary Table: License Type Distribution and Expiration Data
CREATE TEMPORARY TABLE License_Summary AS
SELECT 
    License_Type, 
    COUNT(*) AS Total_Licenses,
    SUM(CASE WHEN Expiration_Date < CURRENT_DATE THEN 1 ELSE 0 END) AS Expired_Licenses,
    SUM(CASE WHEN Expiration_Date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS Expiring_Soon
FROM operator_license_data
GROUP BY License_Type;

SELECT * FROM License_Summary;


























