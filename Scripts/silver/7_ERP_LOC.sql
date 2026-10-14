/*==============================================================================
  SILVER LAYER - ERP LOCATION DATA
  ------------------------------------------------------------------------------
  Table  : silver.erp_loc_a101   (source: bronze.erp_loc_a101)

  Cleaning rules:
    - cid   : arrives formatted as 'AW-00011000' - strip the dashes so it joins
              to the CRM customer number.
    - cntry : strip embedded CR/LF, map country codes to full names
              (DE -> Germany, US/USA/UNITED STATES -> United States) and
              label missing values 'n/a'.
==============================================================================*/

TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101
(
    cid,
    cntry
)
SELECT
    REPLACE(cid, '-', '') AS cid,

    CASE
        WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))) = 'DE'
            THEN 'Germany'

        WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')))
             IN ('US', 'USA', 'UNITED STATES')
            THEN 'United States'

        WHEN cntry IS NULL
          OR TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) = ''
            THEN 'n/a'

        ELSE TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))
    END AS cntry
FROM bronze.erp_loc_a101;
GO
