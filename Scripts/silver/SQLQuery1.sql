SELECT 
* 
FROM bronze.crm_sales_details

-- CHECK INVALID DATES 
SELECT 
	NULLIF(sls_order_dt,0) sals_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt = 0 OR LEN(sls_order_dt) != 8

SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details


SELECT DISTINCT
	ABS(sls_quantity) sls_quantity,
	CASE 
		WHEN sls_price IS NULL OR sls_price <=0 
		THEN ABS(sls_sales) / sls_quantity
		ELSE sls_price
	END AS sls_price,
	CASE 
		WHEN sls_sales IS NULL OR sls_sales <=0 
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales
FROM bronze.crm_sales_details
WHERE sls_price < 0 OR  sls_sales < 0 OR sls_quantity < 0
OR sls_price IS NULL OR  sls_sales IS NULL OR sls_quantity IS NULL
OR sls_sales != sls_quantity * sls_price
