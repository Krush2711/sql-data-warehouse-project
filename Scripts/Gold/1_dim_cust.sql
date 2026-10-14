/*==============================================================================
  GOLD LAYER - CUSTOMER DIMENSION
  ------------------------------------------------------------------------------
  Object : Gold.dim_customers  (view)
  Sources: silver.crm_cust_info   -> master customer record (names, marital status)
           silver.erp_cust_az12   -> birthday + gender fallback
           silver.erp_loc_a101    -> country

  Business rules:
    - customer_key : surrogate key generated at read time. It is NOT stable
                     across reloads - use customer_id / customer_number for
                     anything that has to survive a refresh.
    - customer_id  : natural key from CRM (cst_id).
    - country      : ERP location; unknown locations fall back to 'n/a'.
    - gender       : CRM is the system of record. ERP gender is only used when
                     CRM gender is missing ('n/a').

  Used by : Gold.fact_sales            (join on customer_id)
            Gold.dim_customers         (reporting joins on customer_key)
==============================================================================*/

CREATE OR ALTER VIEW Gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id)   AS customer_key,      -- surrogate key
    ci.cst_id                                AS customer_id,       -- natural key (CRM)
    ci.cst_key                               AS customer_number,   -- business key (shared with ERP)
    ci.cst_firstname                         AS first_name,
    ci.cst_lastname                          AS last_name,
    COALESCE(cla.cntry, 'n/a')               AS country,
    ci.cst_material_status                   AS marital_status,
    CASE
        WHEN ci.cst_gender <> 'n/a' THEN ci.cst_gender
        ELSE COALESCE(ca.gen, 'n/a')
    END                                      AS gender,
    ca.bdate                                 AS birthday,
    ci.cst_create_date                       AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS cla ON ci.cst_key = cla.cid;
GO
