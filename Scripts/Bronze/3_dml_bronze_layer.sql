/*==============================================================================
  STORED PROCEDURE: LOAD BRONZE LAYER  (Files -> Bronze)
  ------------------------------------------------------------------------------
  Object : bronze.load_bronze

  What it does:
    Truncates and reloads the six Bronze tables from the CRM / ERP CSV files
    using BULK INSERT, printing the duration of each load and of the batch as
    a whole. Any failure aborts the batch and re-raises the error.

  Load order:
    CRM : crm_cust_info, crm_prd_info, crm_sales_details
    ERP : erp_loc_a101, erp_cust_az12, erp_px_cat_g1v2

  !! CONFIGURE BEFORE RUNNING !!
    The BULK INSERT paths below point at the original dataset location. Update
    them to wherever the CSV files live on your machine (and make sure the SQL
    Server service account can read that folder), otherwise the load will fail
    with an operating-system error.

  Usage:
      EXEC bronze.load_bronze;
==============================================================================*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @start_time        DATETIME,
        @end_time          DATETIME,
        @batch_start_time  DATETIME,
        @batch_end_time    DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        /*------------------------------------------------------------
          CRM Tables
        ------------------------------------------------------------*/
        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -- 1. CRM Customer Information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH
        (
            FIRSTROW       = 2,        -- skip the header row
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',  -- LF only; the files have no CR
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        -- 2. CRM Product Information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        -- 3. CRM Sales Details
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        /*------------------------------------------------------------
          ERP Tables
        ------------------------------------------------------------*/
        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        -- 4. ERP Location Data
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        -- 5. ERP Customer Data
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        -- 6. ERP Product Category Data
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\Sql\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';


        /*------------------------------------------------------------
          Verification - row counts per table
        ------------------------------------------------------------*/
        SELECT 'crm_cust_info'      AS table_name, COUNT(*) AS total_rows FROM bronze.crm_cust_info
        UNION ALL
        SELECT 'crm_prd_info',                      COUNT(*) FROM bronze.crm_prd_info
        UNION ALL
        SELECT 'crm_sales_details',                 COUNT(*) FROM bronze.crm_sales_details
        UNION ALL
        SELECT 'erp_loc_a101',                      COUNT(*) FROM bronze.erp_loc_a101
        UNION ALL
        SELECT 'erp_cust_az12',                     COUNT(*) FROM bronze.erp_cust_az12
        UNION ALL
        SELECT 'erp_px_cat_g1v2',                   COUNT(*) FROM bronze.erp_px_cat_g1v2;


        /*------------------------------------------------------------
          Batch summary
        ------------------------------------------------------------*/
        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer Completed';
        PRINT '>> Total Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State  : ' + CAST(ERROR_STATE()  AS NVARCHAR(20));
        PRINT 'Error Line   : ' + CAST(ERROR_LINE()   AS NVARCHAR(20));
        PRINT '================================================';

        THROW;   -- surface the error to the caller
    END CATCH
END;
GO

-- Execute the stored procedure
EXEC bronze.load_bronze;
GO
