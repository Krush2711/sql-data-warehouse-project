# Gold Layer

The presentation layer: a star schema of dimension and fact views, ready to query.

**Schema:** `Gold`

---

## Purpose

Gold is what analysts and BI tools read. It joins the cleaned Silver tables into a
classic star schema so that reporting queries never have to repeat the join logic
or the CRM-vs-ERP reconciliation rules.

Gold objects are **views**, not tables — they are computed on read, so there is
nothing to refresh. Create them once and they stay in step with Silver.

---

## The star schema

```
                    +------------------+          +------------------+
                    |  dim_customers   |          |   dim_products   |
                    +------------------+          +------------------+
                    | customer_key (SK)|          | product_key  (SK)|
                    | customer_id      |          | product_id       |
                    | customer_number  |          | product_number   |
                    | first_name       |          | product_name     |
                    | last_name        |          | category_id      |
                    | country          |          | category         |
                    | marital_status   |          | subcategory      |
                    | gender           |          | maintenance      |
                    | birthday         |          | cost             |
                    | create_date      |          | product_line     |
                    +--------+---------+          | start_date       |
                             |                    +--------+---------+
                             |                             |
                             +----------+   +--------------+
                                        v   v
                              +-----------------------+
                              |      fact_sales       |
                              +-----------------------+
                              | sales_order_number    |
                              | product_key      (FK) |
                              | customer_key     (FK) |
                              | order_date            |
                              | shipping_date         |
                              | due_date              |
                              | sales_amount          |
                              | quantity              |
                              | price                 |
                              +-----------------------+
```

---

## Objects

### `Gold.dim_customers` — `1_dim_cust.sql`

One row per customer. Combines all three customer sources:

- **CRM** (`silver.crm_cust_info`) — names, marital status, and the customer id
- **ERP** (`silver.erp_cust_az12`) — birth date, and gender *only as a fallback*
- **ERP** (`silver.erp_loc_a101`) — country

CRM is the system of record for gender; ERP fills in when CRM has `n/a`.

### `Gold.dim_products` — `2_dim_prd.sql`

One row per **current** product. Products with a `prd_end_dt` are historical versions
and are filtered out, so each product appears once.

- **CRM** (`silver.crm_prd_info`) — name, cost, product line, start date
- **ERP** (`silver.erp_px_cat_g1v2`) — category, subcategory, maintenance

### `Gold.fact_sales` — `3_fact_sales.sql`

One row per sales order line, with the product and customer surrogate keys looked up
from the two dimensions.

The `LEFT JOIN`s mean a sales line whose product or customer cannot be resolved is
still returned, with a NULL key rather than being dropped.

---

## Surrogate keys — read this before you rely on them

`customer_key` and `product_key` are generated at query time:

```sql
ROW_NUMBER() OVER (ORDER BY ...)
```

They are **stable within a single query but not across reloads** — adding or
removing a customer can renumber every key after it. Consequences:

- Safe: joining `fact_sales` to a dimension inside one query, as the views do.
- **Not safe:** storing a `customer_key` in another table, a report bookmark, or a
  saved dashboard filter and expecting it to still point at the same customer later.

For anything that must survive a refresh, use `customer_id` (CRM `cst_id`) or
`product_number`. Both are stable business keys.

If you need durable surrogate keys, persist the dimensions as tables with an
`IDENTITY` column and load them with a proper upsert.

---

## Supporting scripts

| File | Purpose |
|---|---|
| `1_dim_cust_or.sql` | **Orphan check.** Returns fact rows whose customer key does not resolve. Expect zero rows. |
| `SQLQuery3.sql` | **Gender reconciliation QA.** Lists every CRM/ERP gender combination and the value the dimension actually publishes. |

Run the orphan check after every reload. A non-empty result means a sales order was
booked against a customer that no longer exists in CRM — a data issue upstream, not
a bug in the view.

---

## Querying Gold

```sql
-- Total revenue by country
SELECT
    c.country,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_customers AS c ON c.customer_key = s.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;

-- Top 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_revenue
FROM Gold.fact_sales AS s
LEFT JOIN Gold.dim_products AS p ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;
```

A fuller set of business questions is in
[`../../Data_Analytics/1_steps.sql`](../../Data_Analytics/1_steps.sql).

---

## Notes and limitations

- **Views, not tables.** Every read re-runs the joins. Fine at this volume; if the
  fact grows large, materialise `fact_sales` into an indexed table.
- **No date dimension.** Time-based analysis groups on `order_date` directly. A
  proper `dim_date` would be the next addition.
- **`category_id` is exposed** on `dim_products` for tracing back to the ERP
  lookup, but is rarely useful in reports.
- **`maintenance` keeps its source spelling** (the ERP column is misspelled
  `maintaince`). It is aliased to the correct spelling in the view.
