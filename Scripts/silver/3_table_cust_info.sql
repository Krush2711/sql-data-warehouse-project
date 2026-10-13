-- DATA CLEANING WITH SQL 
-- TASK B
 TRUNCATE TABLE silver.crm_cust_info;
-- remove duplicated pk from table customer
INSERT INTO silver.crm_cust_info
	(cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_material_status,
	cst_gender,
	cst_create_date
	)

SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) cst_firstname,
	TRIM(cst_lastname)cst_lastname,
	CASE 
		WHEN UPPER(cst_material_status) = 'S' THEN 'Singel'
		WHEN UPPER(cst_material_status) = 'M' THEN 'Married'
		ELSE 'n/a' 
	END 
	cst_material_status,
	CASE 
		WHEN UPPER(cst_gender) = 'M' THEN 'Male'
		WHEN UPPER(cst_gender) = 'F' THEN 'Female'
		ELSE 'n/a' 
	END 
	cst_gender,
	cst_create_date
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	FROM bronze.crm_cust_info
	) t
WHERE flag_last  = 1


SELECT * FROM silver.crm_cust_info