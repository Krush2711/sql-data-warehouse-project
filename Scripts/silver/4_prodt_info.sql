/*==============================================================================
  SILVER LAYER - CRM PRODUCT INFORMATION
  ------------------------------------------------------------------------------
  Table  : silver.crm_prd_info   (source: bronze.crm_prd_info)

  Cleaning rules:
    1. Split prd_key into a category id and a product number.
         'CO_AC-1234'  ->  cat_id = 'CO_AC',  prd_key = '1234'
    2. Replace NULL cost with 0.
    3. Expand the product line code (M/R/S/T) into a readable name.
    4. Derive prd_end_dt: a product version is valid until the day before the
       next version of the same product starts (LEAD over prd_key).
==============================================================================*/

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

    -- category id = first 5 characters of the key, '-' normalised to '_'
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

    -- product number = everything after the 'XX-XXX-' prefix
    SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key,

    prd_name,
    ISNULL(prd_cost, 0)                         AS prd_cost,

    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,

    CAST(prd_start_dt AS DATE) AS prd_start_dt,

    CAST(
        LEAD(prd_start_dt) OVER
        (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1 AS DATE
    ) AS prd_end_dt
FROM bronze.crm_prd_info;
GO

/*------------------------------------------------------------
  Checks
------------------------------------------------------------*/
-- Keys present in the sales table that the product table must be able to serve
SELECT sls_prd_key FROM bronze.crm_sales_details;

SELECT * FROM bronze.crm_prd_info;
SELECT * FROM silver.crm_prd_info;

-- Validity windows that come out inverted (end date before start date).
-- Should return 0 rows once the LEAD logic is right.
SELECT
    *,
    LEAD(prd_start_dt) OVER
    (
        PARTITION BY prd_key
        ORDER BY prd_start_dt
    ) - 1 AS prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;
GO
