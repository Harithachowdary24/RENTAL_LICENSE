SELECT License_Type, COUNT(*) AS License_Count
FROM operator_license_data
GROUP BY License_Type
ORDER BY License_Count DESC;
