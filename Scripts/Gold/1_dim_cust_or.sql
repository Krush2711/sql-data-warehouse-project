/*==============================================================================
  GOLD LAYER - REFERENTIAL INTEGRITY CHECK (ORPHANS)
  ------------------------------------------------------------------------------
  Purpose : Find fact rows that do not resolve to a customer.
            LEFT JOIN + "dimension key IS NULL" returns every sales line whose
            sls_cust_id has no match in Gold.dim_customers.

  Expected result: no rows. Any row returned is a data quality issue upstream
  (a sales order booked against a customer that no longer exists in CRM).

  Swap the join to dim_products / product_key to run the same check for
  products.
==============================================================================*/

SELECT
    s.sales_order_number,
    s.order_date,
    s.customer_key,
    s.sales_amount
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c
       ON c.customer_key = s.customer_key
WHERE c.customer_key IS NULL;
GO
