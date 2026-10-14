/*==============================================================================
  SILVER LAYER - CRM CUSTOMER INFORMATION
  ------------------------------------------------------------------------------
  Table  : silver.crm_cust_info   (source: bronze.crm_cust_info)

  Cleaning rules:
    - De-duplicate on cst_id: the source keeps a history row per customer, so
      keep only the most recent one (flag_last = 1).
    - TRIM unwanted whitespace from the name columns.
    - Expand the single-letter codes: material status S/M, gender M/F.
    - Unknown codes are labelled 'n/a' rather than left NULL.

  NOTE: 'Singel' was a typo in the previous version of this script; the value
  written to the warehouse is 'Single'.
==============================================================================*/

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
    TRIM(cst_firstname)               AS cst_firstname,
    TRIM(cst_lastname)                AS cst_lastname,

    CASE
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END                               AS cst_material_status,

    CASE
        WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END                               AS cst_gender,

    cst_create_date
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
) AS t
WHERE flag_last = 1;
GO

SELECT * FROM silver.crm_cust_info;
GO
