/*==============================================================================
  SILVER LAYER - ERP CUSTOMER DATA
  ------------------------------------------------------------------------------
  Table  : silver.erp_cust_az12   (source: bronze.erp_cust_az12)

  Cleaning rules:
    - cid   : ERP prefixes some ids with 'NAS' - strip it so the id matches the
              CRM customer number and can be joined.
    - bdate : a birth date in the future is a data error -> NULL.
    - gen   : collapse the free-text gender values to 'Male' / 'Female' / 'n/a'.

  NOTE: this script previously inserted back into bronze.erp_cust_az12, which
  re-loaded the raw table from itself. It now targets the Silver table.
==============================================================================*/

TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12
(
    cid,
    bdate,
    gen
)
SELECT
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    CASE
        WHEN UPPER(TRIM(gen)) LIKE '%FEMALE%' THEN 'Female'
        WHEN UPPER(TRIM(gen)) LIKE '%MALE%'   THEN 'Male'
        WHEN UPPER(TRIM(gen)) LIKE '%F%'      THEN 'Female'
        WHEN UPPER(TRIM(gen)) LIKE '%M%'      THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;
GO
