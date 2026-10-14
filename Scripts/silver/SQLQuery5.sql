/*==============================================================================
  SILVER LAYER - ERP PRODUCT CATEGORY DATA
  ------------------------------------------------------------------------------
  Table  : silver.erp_px_cat_g1v2   (source: bronze.erp_px_cat_g1v2)

  This lookup table arrives already clean, so it is copied as-is. It supplies
  the category / subcategory / maintenance attributes for Gold.dim_products.
==============================================================================*/

TRUNCATE TABLE silver.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintaince
)
SELECT
    id,
    cat,
    subcat,
    maintaince
FROM bronze.erp_px_cat_g1v2;
GO
