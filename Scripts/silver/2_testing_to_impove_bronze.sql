

--CHECKING PK 
SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1;

SELECT 
	* 
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	FROM bronze.crm_cust_info
	) t
WHERE flag_last  = 1

--unwanted spaces in cloumns strings 
SELECT 
	cst_firstname,
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM (cst_firstname) OR cst_lastname != TRIM(cst_lastname)


-- consitncyy and standarization of gender and marital status 
SELECT DISTINCT 
	cst_gender,
	CASE 
		WHEN cst_gender = 'M' THEN 'MALE'
		WHEN cst_gender = 'F' THEN 'FEMALE'
		ELSE NULL
	END 
FROM bronze.crm_cust_info

SELECT DISTINCT 
	cst_material_status
FROM bronze.crm_cust_info





--CHECKING PK 
SELECT 
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1;

SELECT 
	* 
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	FROM silver.crm_cust_info
	) t
WHERE flag_last  = 1

--unwanted spaces in cloumns strings 
SELECT 
	cst_firstname,
	cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM (cst_firstname) OR cst_lastname != TRIM(cst_lastname)


-- consitncyy and standarization of gender and marital status 
SELECT DISTINCT 
	cst_gender,
	CASE 
		WHEN cst_gender = 'M' THEN 'MALE'
		WHEN cst_gender = 'F' THEN 'FEMALE'
		ELSE NULL
	END 
FROM silver.crm_cust_info

SELECT DISTINCT 
	cst_material_status
FROM silver.crm_cust_in


-- ANOTHER COLUMN 
--PK DUPLICATE
SELECT 
	 prd_id, 
	 COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id = NULL
