INSERT INTO silver.erp_loc_a101(cid, cntry)

SELECT 
	REPLACE(cid , '-', '') cid,
	CASE
    WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))) = 'DE'
        THEN 'Germany'

    WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')))
         IN ('US', 'USA', 'UNITED STATES')
        THEN 'United States'

    WHEN cntry IS NULL
         OR TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) = ''
        THEN 'n/a'

    ELSE TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))
END AS cntry
FROM bronze.erp_loc_a101
