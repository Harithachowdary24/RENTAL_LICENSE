# Rental License Data Analysis Project

## 📌 Overview
This project analyzes rental license data to clean raw records, transform data into analytical tables, and generate insights for reporting and decision-making.

The goal is to demonstrate end-to-end SQL-based data analysis including data cleaning, transformation, aggregation, and reporting.

---

## 🧰 Tools & Technologies
- SQL
- MySQL / PostgreSQL (mention which one you used)
- GitHub

---

## 📂 Dataset
Rental license dataset containing information such as:
- License ID  
- Property address  
- City  
- State  
- License type  
- Issue date  
- Expiration date  

(Replace or adjust based on your columns)

---

## 🔄 Project Workflow

1. Data Cleaning  
2. Data Transformation  
3. Analytical Modeling  
4. Reporting Tables  
5. Insights Generation  

---

## 🧹 Data Cleaning
Performed tasks such as:
- Removing duplicate records  
- Handling NULL values  
- Standardizing date formats  
- Validating license status  

Scripts:
- cleaning_table1.sql  
- cleaning_table2.sql  

---

## 🔁 Data Transformation
- Created derived columns  
- Standardized city and license categories  
- Joined multiple tables where required  

Script:
- data_transformation.sql  

---

## 📊 Reporting
Created reporting tables for:
- Active vs expired licenses  
- Licenses by city  
- Licenses by type  

Script:
- reporting.sql  

---

## 🔍 Insights
Generated analytical insights such as:
- Cities with highest number of rental licenses  
- Distribution of license types  
- Trend of license issuance over time  

Script:
- insights.sql  

---

## 📈 Sample Query

```sql
SELECT city, COUNT(*) AS total_licenses
FROM rental_licenses
GROUP BY city
ORDER BY total_licenses DESC;
