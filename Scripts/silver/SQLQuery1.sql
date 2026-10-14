/*==============================================================================
  SILVER LAYER - EXPLORATION: CRM SALES QUALITY
  ------------------------------------------------------------------------------
  Purpose: The checks used to design the sales cleaning rules in
           silver/5_SALES_INFO.sql. Kept as a re-runnable QA script.

  It looks for the three defect classes the Silver layer repairs:
    - unusable date integers (NULL / 0 / not 8 digits)
    - NULL, zero or negative price / sales / quantity
    - rows where sales <> quantity * price
==============================================================================*/

SELECT * FROM bronze.crm_sales_details;

/*------------------------------------------------------------
  1. Unusable order dates
------------------------------------------------------------*/
SELECT
    NULLIF(sls_order_dt, 0) AS order_dt_nullified
FROM bronze.crm_sales_details
WHERE sls_order_dt = 0
   OR LEN(CAST(sls_order_dt AS VARCHAR(8))) <> 8;

/*------------------------------------------------------------
  2. Distinct price / quantity / sales combinations
------------------------------------------------------------*/
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details;

/*------------------------------------------------------------
  3. Rows needing correction + the corrected values
------------------------------------------------------------*/
SELECT DISTINCT
    ABS(sls_quantity) AS sls_quantity,

    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price,

    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales
FROM bronze.crm_sales_details
WHERE sls_price    <  0
   OR sls_sales    <  0
   OR sls_quantity <  0
   OR sls_price    IS NULL
   OR sls_sales    IS NULL
   OR sls_quantity IS NULL
   OR sls_sales    <> sls_quantity * sls_price;   -- arithmetic does not reconcile
GO
