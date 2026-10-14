/*==============================================================================
  SILVER LAYER - CRM SALES DETAILS
  ------------------------------------------------------------------------------
  Table  : silver.crm_sales_details   (source: bronze.crm_sales_details)

  Cleaning rules:
    - Dates arrive as yyyymmdd integers. Anything that is NULL, 0, or not
      exactly 8 characters is unusable -> NULL. Valid values are converted with
      TRY_CONVERT(..., 112) so a malformed value can never abort the load.
    - Unit price: rebuild from sales / quantity when NULL, zero or negative.
    - Sales amount: rebuild from quantity * price when NULL, zero or negative.
      ABS() guards against a negative source price.
==============================================================================*/

INSERT INTO silver.crm_sales_details
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    -- order date
    CASE
        WHEN sls_order_dt IS NULL
          OR sls_order_dt = 0
          OR LEN(CAST(sls_order_dt AS VARCHAR(8))) <> 8
            THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_order_dt AS CHAR(8)), 112)
    END AS sls_order_dt,

    -- shipping date
    CASE
        WHEN sls_ship_dt IS NULL
          OR sls_ship_dt = 0
          OR LEN(CAST(sls_ship_dt AS VARCHAR(8))) <> 8
            THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_ship_dt AS CHAR(8)), 112)
    END AS sls_ship_dt,

    -- due date
    CASE
        WHEN sls_due_dt IS NULL
          OR sls_due_dt = 0
          OR LEN(CAST(sls_due_dt AS VARCHAR(8))) <> 8
            THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_due_dt AS CHAR(8)), 112)
    END AS sls_due_dt,

    -- sales amount
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    -- unit price
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;
GO
