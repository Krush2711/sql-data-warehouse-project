/*==============================================================================
  GOLD LAYER - PRODUCT DIMENSION
  ------------------------------------------------------------------------------
  Object : Gold.dim_products  (view)
  Sources: silver.crm_prd_info     -> product master (keys, cost, line, dates)
           silver.erp_px_cat_g1v2  -> category / subcategory / maintenance

  Business rules:
    - product_key : surrogate key generated at read time. Not stable across
                    reloads - use product_number for durable references.
    - product_number : prd_key with the category prefix stripped (CRM side).
    - Only the *current* version of each product is kept
      (prd_end_dt IS NULL); historical versions are filtered out.
    - cost : NULL costs were already replaced with 0 in the Silver layer.

  Used by : Gold.fact_sales  (join on product_number)
==============================================================================*/

CREATE OR ALTER VIEW Gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pin.prd_start_dt, pin.prd_key) AS product_key,   -- surrogate key
    pin.prd_id                                                 AS product_id,    -- natural key (CRM)
    pin.prd_key                                                AS product_number,-- business key (shared with ERP)
    pin.prd_name                                               AS product_name,
    pin.cat_id                                                 AS category_id,
    pc.cat                                                     AS category,
    pc.subcat                                                  AS subcategory,
    pc.maintaince                                              AS maintenance,
    pin.prd_cost                                               AS cost,
    pin.prd_line                                               AS product_line,
    pin.prd_start_dt                                           AS start_date
FROM silver.crm_prd_info AS pin
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
       ON pin.cat_id = pc.id
WHERE pin.prd_end_dt IS NULL;   -- keep only the current product version
GO
