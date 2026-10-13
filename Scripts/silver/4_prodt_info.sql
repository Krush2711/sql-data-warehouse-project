--SELECT DISTINCT cat_id FROM

/*==============================================================
  Silver Layer: CRM Product Information
  Purpose:
    1. Standardize category and product keys.
    2. Handle missing product costs.
    3. Normalize product line descriptions.
    4. Derive product validity end dates.
==============================================================*/


INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_name,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt)
		(SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, 
			prd_name,
			ISNULL(prd_cost , 0) AS prd_cost,
			CASE 
				WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
				WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
				WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
				WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			CAST(prd_start_dt AS DATE) prd_start_dt,
			CAST (LEAD(prd_start_dt)  OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info) 
--WHERE cat_id  IN (SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2)

SELECT sls_prd_key FROM bronze.crm_sales_details
--SELECT SUBSTRING(prd_key, 7, LEN(prd_key)) FROM bronze.crm_prd_info
SELECT * FROM bronze.crm_prd_info
SELECT * FROM silver.crm_prd_info

-- null valuses 0 
SELECT  * ,
LEAD(prd_start_dt)  OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt

-- 