/*==============================================================================
  DATA ANALYTICS - EXPLORATION AND BUSINESS QUESTIONS
  ------------------------------------------------------------------------------
  Database : DataWarehouse
  Model    : Gold.dim_customers | Gold.dim_products | Gold.fact_sales
  Sources  : CRM (customers, products, sales) + ERP (birth date, gender,
             country, product category)

  How to read this file
  ---------------------
  Every block opens with a business QUESTION written out in full, followed by
  the query that answers it. Questions are grouped by theme:

     A. Database exploration   - what objects exist
     B. Dimension exploration  - what values the dimensions hold
     C. Date range             - how far back the data goes
     D. Magnitude              - headline totals
     E. Ranking                - best and worst performers
     F. CRM analytics          - answered from CRM data
     G. ERP analytics          - answered from ERP data
     H. Cross-system analytics - needs CRM and ERP joined together

  Prerequisite: the Bronze, Silver and Gold scripts must have been run.
==============================================================================*/


/*==============================================================================
  A. DATABASE EXPLORATION
==============================================================================*/

-- QUESTION: What tables and views exist in the warehouse, and which schema
--           does each one belong to?
SELECT
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- QUESTION: What columns does each object expose, what data type is each
--           column, and is it nullable?
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
GO


/*==============================================================================
  B. DIMENSION EXPLORATION
==============================================================================*/

-- QUESTION: Which countries do our customers live in?
SELECT DISTINCT country
FROM Gold.dim_customers
ORDER BY country;
GO

-- QUESTION: What is the full product hierarchy we sell - every category,
--           subcategory and product name combination?
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM Gold.dim_products
ORDER BY category, subcategory, product_name;
GO

-- QUESTION: What product lines and maintenance flags exist in the catalogue?
SELECT DISTINCT
    product_line,
    maintenance
FROM Gold.dim_products
ORDER BY product_line, maintenance;
GO


/*==============================================================================
  C. DATE RANGE EXPLORATION
==============================================================================*/

-- QUESTION: What period does the sales history cover - what was the first
--           order, the last order, and how many years and months is that?
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(YEAR,  MIN(order_date), MAX(order_date)) AS order_range_years,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM Gold.fact_sales;
GO

-- QUESTION: How old is our customer base - what are the oldest and youngest
--           birth dates on record, and what ages do they correspond to?
SELECT
    MIN(birthday) AS oldest_birthdate,
    MAX(birthday) AS youngest_birthdate,
    DATEDIFF(YEAR, MIN(birthday), GETDATE()) AS oldest_age_years,
    DATEDIFF(YEAR, MAX(birthday), GETDATE()) AS youngest_age_years
FROM Gold.dim_customers;
GO


/*==============================================================================
  D. MAGNITUDE - HIGH LEVEL TOTALS
==============================================================================*/

-- QUESTION: What are the total sales value and the average value of a single
--           sales order line?
SELECT
    SUM(sales_amount) AS total_sales,
    AVG(sales_amount) AS avg_sales_per_line
FROM Gold.fact_sales;
GO

-- QUESTION: How many units have we sold in total, and what is the average
--           quantity per order line?
SELECT
    SUM(quantity) AS total_quantity,
    AVG(quantity) AS avg_quantity_per_line
FROM Gold.fact_sales;
GO

-- QUESTION: How many sales order lines are there, and how many distinct sales
--           orders do those lines belong to?
SELECT
    COUNT(sales_order_number)          AS total_order_lines,
    COUNT(DISTINCT sales_order_number) AS total_distinct_orders
FROM Gold.fact_sales;
GO

-- QUESTION: How many distinct products, and how many distinct customers, have
--           actually generated sales?
SELECT
    COUNT(DISTINCT product_key)  AS total_products_sold,
    COUNT(DISTINCT customer_key) AS total_customers_bought
FROM Gold.fact_sales;
GO


/*==============================================================================
  E. RANKING - BEST AND WORST PERFORMERS
==============================================================================*/

-- QUESTION: Which five products generated the most revenue?
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products AS p ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY SUM(s.sales_amount) DESC;
GO

-- QUESTION: Which five products generated the least revenue?
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products AS p ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY SUM(s.sales_amount) ASC;
GO

-- QUESTION: Which ten customers placed the most orders?
SELECT TOP 10
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT s.sales_order_number) AS total_orders
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY COUNT(DISTINCT s.sales_order_number) DESC;
GO


/*==============================================================================
  F. CRM ANALYTICS
==============================================================================*/

-- QUESTION: How many customers do we have in each country?
SELECT
    country,
    COUNT(*) AS total_customers
FROM Gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;
GO

-- QUESTION: How are our customers split by gender?
SELECT
    gender,
    COUNT(*) AS total_customers
FROM Gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;
GO

-- QUESTION: How are our customers split by marital status?
SELECT
    marital_status,
    COUNT(*) AS total_customers
FROM Gold.dim_customers
GROUP BY marital_status
ORDER BY total_customers DESC;
GO

-- QUESTION: How many new customers did we acquire in each year?
SELECT
    YEAR(create_date) AS acquisition_year,
    COUNT(*)          AS new_customers
FROM Gold.dim_customers
GROUP BY YEAR(create_date)
ORDER BY acquisition_year;
GO

-- QUESTION: What is the total revenue and the total quantity sold per country?
SELECT
    c.country,
    SUM(s.sales_amount) AS total_revenue,
    SUM(s.quantity)     AS total_quantity
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;
GO

-- QUESTION: Who are the top ten customers by total revenue?
SELECT TOP 10
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC;
GO

-- QUESTION: How much revenue does each product category generate?
SELECT
    p.category,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products AS p ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
GO


/*==============================================================================
  G. ERP ANALYTICS
==============================================================================*/

-- QUESTION: How many products are there in each category and subcategory, and
--           what is the average cost within each combination?
SELECT
    category,
    subcategory,
    COUNT(*)  AS total_products,
    AVG(cost) AS avg_cost
FROM Gold.dim_products
GROUP BY category, subcategory
ORDER BY category, subcategory;
GO

-- QUESTION: How many customers have a birth date on record from ERP, and how
--           are they distributed by decade of birth?
SELECT
    (YEAR(birthday) / 10) * 10 AS birth_decade,
    COUNT(*)                   AS total_customers
FROM Gold.dim_customers
WHERE birthday IS NOT NULL
GROUP BY (YEAR(birthday) / 10) * 10
ORDER BY birth_decade;
GO

-- QUESTION: How many customers have no country recorded in ERP (shown as
--           'n/a'), and what share of the customer base is that?
SELECT
    SUM(CASE WHEN country = 'n/a' THEN 1 ELSE 0 END) AS customers_without_country,
    COUNT(*)                                         AS total_customers,
    CAST(
        100.0 * SUM(CASE WHEN country = 'n/a' THEN 1 ELSE 0 END)
              / COUNT(*) AS DECIMAL(5,2)
    )                                               AS pct_without_country
FROM Gold.dim_customers;
GO

-- QUESTION: How many products require maintenance, and how many do not?
SELECT
    maintenance,
    COUNT(*) AS total_products
FROM Gold.dim_products
GROUP BY maintenance
ORDER BY total_products DESC;
GO


/*==============================================================================
  H. CROSS-SYSTEM ANALYTICS (CRM + ERP)
==============================================================================*/

-- QUESTION: Do CRM and ERP agree on customer gender - how many customers
--           needed the ERP fallback because CRM had no gender recorded?
SELECT
    CASE
        WHEN ca.gen IS NULL THEN 'No ERP record'
        ELSE 'ERP record present'
    END      AS erp_gender_available,
    COUNT(*) AS total_customers
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid
GROUP BY CASE
             WHEN ca.gen IS NULL THEN 'No ERP record'
             ELSE 'ERP record present'
         END;
GO

-- QUESTION: For every combination of CRM gender and ERP gender in the data,
--           which value does the customer dimension actually publish?
SELECT DISTINCT
    ci.cst_gender AS crm_gender,
    ca.gen        AS erp_gender,
    CASE
        WHEN ci.cst_gender <> 'n/a' THEN ci.cst_gender
        ELSE COALESCE(ca.gen, 'n/a')
    END           AS published_gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid;
GO

-- QUESTION: Are there sales lines whose customer cannot be resolved against
--           the customer dimension? (Referential integrity check - expect no rows.)
SELECT
    s.sales_order_number,
    s.order_date,
    s.customer_key,
    s.sales_amount
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
WHERE c.customer_key IS NULL;
GO

-- QUESTION: Are there sales lines whose product cannot be resolved against the
--           product dimension? (Expect no rows.)
SELECT
    s.sales_order_number,
    s.order_date,
    s.product_key,
    s.sales_amount
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products AS p ON p.product_key = s.product_key
WHERE p.product_key IS NULL;
GO

-- QUESTION: What is the revenue for each product line, broken down by the
--           country the customer lives in?
SELECT
    p.product_line,
    c.country,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products  AS p ON p.product_key  = s.product_key
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
GROUP BY p.product_line, c.country
ORDER BY p.product_line, total_revenue DESC;
GO
