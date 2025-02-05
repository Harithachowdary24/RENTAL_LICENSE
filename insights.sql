#Step 3: Insights & Next Steps (SQL Queries)

#1. What is the Distribution of License Types?
SELECT License_Type, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY License_Type
ORDER BY License_Count DESC;

#2. Which Regions Have the Most/Least Licenses?
SELECT Address, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY Address
ORDER BY License_Count DESC;#exac address

SELECT 
    SUBSTRING(Address, 1, 5) AS Region, 
    COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY Region
ORDER BY License_Count DESC;#city or region

# How Many Licenses Are Expired or Near Expiration?
SELECT 
    License_Number, 
    Operator_Name, 
    Expiration_Date
FROM operator_license_data
WHERE Expiration_Date < CURRENT_DATE;

SELECT 
    License_Number, 
    Operator_Name, 
    Expiration_Date
FROM operator_license_data
WHERE Expiration_Date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY);#near expiration

#4. Are Certain Locations More Prone to Expired Licenses?
SELECT 
    Address, 
    COUNT(*) AS Expired_Licenses
FROM operator_license_data
WHERE Expiration_Date < CURRENT_DATE
GROUP BY Address
ORDER BY Expired_Licenses DESC;

#What is the Trend of New Licenses Issued Over the Years?
SELECT 
    YEAR(Issue_Date) AS Year, 
    COUNT(*) AS Licenses_Issued
FROM operator_license_data
GROUP BY YEAR(Issue_Date)
ORDER BY Year DESC;









