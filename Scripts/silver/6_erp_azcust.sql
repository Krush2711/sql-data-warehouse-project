
INSERT INTO bronze.erp_cust_az12 ( cid , bdate, gen)
SELECT 
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4, LEN(cid))
		ELSE cid
	END AS ci	d,
	CASE 
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS
	bdate,
	 CASE
        WHEN TRIM(gen) LIKE '%Female%' THEN 'Female'
        WHEN TRIM(gen) LIKE '%Male%' THEN 'Male'
        WHEN TRIM(gen) LIKE '%F%' THEN 'Female'
        WHEN TRIM(gen) LIKE '%M%' THEN 'Male'
        ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12


