
CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '========================================';
    PRINT 'LOADING SILVER LAYER';
    PRINT '========================================';

    BEGIN TRY

        -- ==========================================
        -- 1. Load Customer Information
        -- ==========================================
        PRINT '>> Loading silver.crm_cust_info';

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info
        (
            cst_id,
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
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE
                WHEN UPPER(TRIM(cst_material_status)) = 'S'
                    THEN 'Single'
                WHEN UPPER(TRIM(cst_material_status)) = 'M'
                    THEN 'Married'
                ELSE 'n/a'
            END,
            CASE
                WHEN UPPER(TRIM(cst_gender)) = 'M'
                    THEN 'Male'
                WHEN UPPER(TRIM(cst_gender)) = 'F'
                    THEN 'Female'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM
        (
            SELECT *,
                ROW_NUMBER() OVER
                (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
        ) AS t
        WHERE flag_last = 1;


        -- ==========================================
        -- 2. Load Product Information
        -- ==========================================
        PRINT '>> Loading silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info
        (
            prd_id,
            cat_id,
            prd_key,
            prd_name,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_name,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M'
                    THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R'
                    THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S'
                    THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T'
                    THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                DATEADD
                (
                    DAY,
                    -1,
                    LEAD(prd_start_dt) OVER
                    (
                        PARTITION BY prd_key
                        ORDER BY prd_start_dt
                    )
                ) AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;


        -- ==========================================
        -- 3. Load Sales Details
        -- ==========================================
        PRINT '>> Loading silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_price,
            sls_quantity,
            sls_sales
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            CASE
                WHEN sls_order_dt IS NULL
                  OR sls_order_dt = 0
                  OR LEN(CAST(sls_order_dt AS VARCHAR(8))) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_order_dt AS CHAR(8)), 112
                )
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt IS NULL
                  OR sls_ship_dt = 0
                  OR LEN(CAST(sls_ship_dt AS VARCHAR(8))) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_ship_dt AS CHAR(8)), 112
                )
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt IS NULL
                  OR sls_due_dt = 0
                  OR LEN(CAST(sls_due_dt AS VARCHAR(8))) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_due_dt AS CHAR(8)), 112
                )
            END AS sls_due_dt,

            -- Correct invalid unit price
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price,

            sls_quantity,

            -- Correct invalid sales amount
            CASE
                WHEN sls_sales IS NULL OR sls_sales <= 0
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales

        FROM bronze.crm_sales_details;


        -- ==========================================
        -- 4. Load ERP Customer Data
        -- ==========================================
        PRINT '>> Loading silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) LIKE '%FEMALE%'
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) LIKE '%MALE%'
                    THEN 'Male'
                WHEN UPPER(TRIM(gen)) LIKE '%F%'
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) LIKE '%M%'
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;


        -- ==========================================
        -- 5. Load ERP Product Category Data
        -- ==========================================
        PRINT '>> Loading silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2
        (
            id,
            cat,
            subcat,
            maintaince
        )
        SELECT
            id,
            cat,
            subcat,
            maintaince
        FROM bronze.erp_px_cat_g1v2;


        -- ==========================================
        -- 6. Load ERP Location Data
        -- ==========================================
        PRINT '>> Loading silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,

            CASE
                WHEN UPPER(TRIM(REPLACE(REPLACE(
                    cntry, CHAR(13), ''), CHAR(10), ''))) = 'DE'
                    THEN 'Germany'

                WHEN UPPER(TRIM(REPLACE(REPLACE(
                    cntry, CHAR(13), ''), CHAR(10), '')))
                    IN ('US', 'USA', 'UNITED STATES')
                    THEN 'United States'

                WHEN cntry IS NULL
                  OR TRIM(REPLACE(REPLACE(
                      cntry, CHAR(13), ''), CHAR(10), '')) = ''
                    THEN 'n/a'

                ELSE TRIM(REPLACE(REPLACE(
                    cntry, CHAR(13), ''), CHAR(10), ''))
            END AS cntry

        FROM bronze.erp_loc_a101;


        -- ==========================================
        -- 7. Verify Silver Record Counts
        -- ==========================================
        PRINT '========================================';
        PRINT 'SILVER LAYER LOADING COMPLETED';
        PRINT '========================================';

        SELECT 'crm_cust_info' AS table_name,
               COUNT(*) AS total_rows
        FROM silver.crm_cust_info

        UNION ALL

        SELECT 'crm_prd_info', COUNT(*)
        FROM silver.crm_prd_info

        UNION ALL

        SELECT 'crm_sales_details', COUNT(*)
        FROM silver.crm_sales_details

        UNION ALL

        SELECT 'erp_cust_az12', COUNT(*)
        FROM silver.erp_cust_az12

        UNION ALL

        SELECT 'erp_px_cat_g1v2', COUNT(*)
        FROM silver.erp_px_cat_g1v2

        UNION ALL

        SELECT 'erp_loc_a101', COUNT(*)
        FROM silver.erp_loc_a101;

    END TRY

    BEGIN CATCH
        PRINT '========================================';
        PRINT 'ERROR OCCURRED WHILE LOADING SILVER';
        PRINT ERROR_MESSAGE();
        PRINT '========================================';

        THROW;
    END CATCH
END;
GO
EXEC silver.load_silver
