CREATE VIEW Gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY prd_start_dt, prd_key) AS product_key,
	pin.prd_id AS product_id,
	pin.prd_key AS product_number,
	pin.prd_name  AS product_name,
	pin.cat_id   AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintaince,
	pin.prd_cost AS cost,
	pin.prd_line AS product_line,
	pin.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pin
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pin.cat_id = pc.id
WHERE pin.prd_end_dt IS NULL -- filter out historical data 

