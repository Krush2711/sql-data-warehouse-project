-- STORED PROCDURE 
CREATE OR ALTER PROCEDURE bronze.load_bronze  AS 
BEGIN 

    PRINT('LOADING THE BRONZE LAYER')
    -- 1. Load Customer Information
    TRUNCATE TABLE bronze.crm_cust_info;

    BULK INSERT bronze.crm_cust_info
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 2. Load Product Information
    TRUNCATE TABLE bronze.crm_prd_info;

    BULK INSERT bronze.crm_prd_info
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 3. Load Sales Details
    TRUNCATE TABLE bronze.crm_sales_details;

    BULK INSERT bronze.crm_sales_details
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 4. Verify record counts
    SELECT 'crm_cust_info' AS table_name, COUNT(*) AS total_rows
    FROM bronze.crm_cust_info

    UNION ALL

    SELECT 'crm_prd_info', COUNT(*)
    FROM bronze.crm_prd_info

    UNION ALL

    SELECT 'crm_sales_details', COUNT(*)
    FROM bronze.crm_sales_details;



    -- 4. Load ERP Location Data
    TRUNCATE TABLE bronze.erp_loc_a101;

    BULK INSERT bronze.erp_loc_a101
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 5. Load ERP Customer Data
    TRUNCATE TABLE bronze.erp_cust_az12;

    BULK INSERT bronze.erp_cust_az12
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 6. Load ERP Product Category Data
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    BULK INSERT bronze.erp_px_cat_g1v2
    FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );

    -- 7. Verify ERP record counts
    SELECT 'erp_loc_a101' AS table_name, COUNT(*) AS total_rows
    FROM bronze.erp_loc_a101
    UNION ALL
    SELECT 'erp_cust_az12', COUNT(*)
    FROM bronze.erp_cust_az12
    UNION ALL
    SELECT 'erp_px_cat_g1v2', COUNT(*)
    FROM bronze.erp_px_cat_g1v2;
END 