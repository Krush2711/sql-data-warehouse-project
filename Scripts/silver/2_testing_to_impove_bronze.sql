/*==============================================================================
  SILVER LAYER - DATA QUALITY TESTING
  ------------------------------------------------------------------------------
  Purpose: The exploratory checks used to decide what the Silver cleaning rules
           needed to handle, kept as a re-runnable QA script.

  Run the same set against bronze (raw) and silver (cleaned) to confirm the
  cleaning actually fixed the problems:

    1. Duplicate primary keys            -> expect 0 rows in Silver
    2. Whitespace in name columns        -> expect 0 rows in Silver
    3. Gender / marital status values    -> expect only clean labels in Silver

  NOTE: fixed a typo ('silver.crm_cust_in') and an always-false predicate
  ('prd_id = NULL' -> 'prd_id IS NULL') in the previous version.
==============================================================================*/

/*------------------------------------------------------------
  1. Duplicate primary keys - CRM customers
------------------------------------------------------------*/
SELECT
    'bronze.crm_cust_info' AS checked_table,
    cst_id,
    COUNT(*)               AS occurrences
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

SELECT
    'silver.crm_cust_info' AS checked_table,
    cst_id,
    COUNT(*)               AS occurrences
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
  2. De-duplication preview - what the "keep newest" rule selects
------------------------------------------------------------*/
SELECT *
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

/*------------------------------------------------------------
  3. Unwanted whitespace in name columns
------------------------------------------------------------*/
SELECT
    cst_firstname,
    cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname  <> TRIM(cst_lastname);

SELECT
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname  <> TRIM(cst_lastname);

/*------------------------------------------------------------
  4. Consistency and standardisation of gender + marital status
------------------------------------------------------------*/
SELECT DISTINCT
    cst_gender,
    CASE
        WHEN cst_gender = 'M' THEN 'Male'
        WHEN cst_gender = 'F' THEN 'Female'
        ELSE NULL
    END AS standardised_gender
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_material_status FROM bronze.crm_cust_info;

-- Silver should expose only the cleaned labels
SELECT DISTINCT cst_gender          FROM silver.crm_cust_info;
SELECT DISTINCT cst_material_status FROM silver.crm_cust_info;

/*------------------------------------------------------------
  5. Duplicate primary keys - CRM products
------------------------------------------------------------*/
SELECT
    prd_id,
    COUNT(*) AS occurrences
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;   -- 'prd_id = NULL' would never match anything
GO
