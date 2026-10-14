/*==============================================================================
  BRONZE LAYER - TABLE DEFINITIONS (DDL)
  ------------------------------------------------------------------------------
  Creates the six raw landing tables, one per source system.

  Everything is deliberately permissive: all columns are nullable and dates are
  stored as the raw integers the CSV supplies. Bronze exists to land the data
  exactly as it arrived - all validation and typing happens in the Silver layer.

  Source systems:
    CRM : crm_cust_info, crm_prd_info, crm_sales_details
    ERP : erp_loc_a101, erp_cust_az12, erp_px_cat_g1v2
==============================================================================*/

/*------------------------------------------------------------
  CRM tables
------------------------------------------------------------*/
CREATE TABLE bronze.crm_cust_info
(
    cst_id               INT,
    cst_key              NVARCHAR(50),
    cst_firstname        NVARCHAR(50),
    cst_lastname         NVARCHAR(50),
    cst_material_status  NVARCHAR(50),
    cst_gender           NVARCHAR(50),
    cst_create_date      DATE
);
GO

CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num      NVARCHAR(50),
    sls_prd_key      NVARCHAR(50),
    sls_cust_id      INT,
    sls_order_dt     INT,   -- raw yyyymmdd, converted to DATE in Silver
    sls_ship_dt      INT,
    sls_due_dt       INT,
    sls_sales        INT,
    sls_quantity     INT,
    sls_price        INT
);
GO

CREATE TABLE bronze.crm_prd_info
(
    prd_id           INT,
    prd_key          NVARCHAR(50),
    prd_name         NVARCHAR(50),
    prd_cost         INT,
    prd_line         NVARCHAR(50),
    prd_start_dt     DATETIME,
    prd_end_dt       DATETIME
);
GO

/*------------------------------------------------------------
  ERP tables
------------------------------------------------------------*/
CREATE TABLE bronze.erp_loc_a101
(
    cid      NVARCHAR(50),
    cntry    NVARCHAR(50)
);
GO

CREATE TABLE bronze.erp_cust_az12
(
    cid      NVARCHAR(50),
    bdate    DATE,
    gen      NVARCHAR(50)
);
GO

CREATE TABLE bronze.erp_px_cat_g1v2
(
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintaince  NVARCHAR(50)
);
GO
