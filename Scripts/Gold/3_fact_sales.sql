/*==============================================================================
  GOLD LAYER - SALES FACT
  ------------------------------------------------------------------------------
  Object : Gold.fact_sales  (view)
  Source : silver.crm_sales_details  (one row per sales order line)

  Business rules:
    - product_key / customer_key are looked up from the Gold dimensions, so the
      fact table always reports against the *current* dimension members.
    - Rows whose product or customer cannot be resolved keep a NULL key; see
      Gold/1_dim_cust_or.sql for the orphan check.
    - sales_amount / quantity / price were already cleaned in the Silver layer
      (zero and negative values corrected), so no recalculation happens here.
==============================================================================*/

CREATE OR ALTER VIEW Gold.fact_sales AS
SELECT
    sls.sls_ord_num    AS sales_order_number,
    pr.product_key     AS product_key,
    c.customer_key     AS customer_key,
    sls.sls_order_dt   AS order_date,
    sls.sls_ship_dt    AS shipping_date,
    sls.sls_due_dt     AS due_date,
    sls.sls_sales      AS sales_amount,
    sls.sls_quantity   AS quantity,
    sls.sls_price      AS price
FROM silver.crm_sales_details AS sls
LEFT JOIN Gold.dim_products  AS pr ON pr.product_number = sls.sls_prd_key
LEFT JOIN Gold.dim_customers AS c  ON c.customer_id    = sls.sls_cust_id;
GO
