/*==============================================================================
  GOLD LAYER - EXPLORATION: GENDER RECONCILIATION (CRM vs ERP)
  ------------------------------------------------------------------------------
  Purpose : Draft/QA query behind the gender logic in Gold.dim_customers.

  It lists every combination of CRM gender and ERP gender found across the
  joined customer tables, and shows which value the dimension will actually
  publish. Use it to confirm the "CRM wins, ERP is only a fallback" rule is
  behaving as expected after a reload.
==============================================================================*/

SELECT DISTINCT
    ci.cst_gender                        AS crm_gender,
    ca.gen                               AS erp_gender,
    CASE
        WHEN ci.cst_gender <> 'n/a' THEN ci.cst_gender
        ELSE COALESCE(ca.gen, 'n/a')
    END                                  AS final_gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS cla ON ci.cst_key = cla.cid;
GO
