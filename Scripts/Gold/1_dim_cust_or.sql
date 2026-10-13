SELECT * FROM Gold.fact_sales f
left join Gold.dim_customers c 
on c.customer_key = f.customer_key