# Silver Layer

The cleaning layer. Data is standardised, typed and de-duplicated here — this is
where every data quality rule lives.

**Schema:** `silver`

---

## Purpose

Bronze deliberately lands the CSV data untouched. Silver's job is to turn that raw
feed into something a report can trust: consistent labels, real date types,
no duplicates, and no silent arithmetic errors.

```sql
EXEC silver.load_silver;
```

The procedure truncates and reloads all six tables in dependency order, then prints
a row count per table. Any failure aborts the batch and re-raises the error.

> **Full reload.** There is no incremental load — Silver is rebuilt from Bronze on
> every run. Re-running is safe because each table is truncated first.

---

## Tables and cleaning rules

### `silver.crm_cust_info` — customers

| Rule | Detail |
|---|---|
| De-duplicate | The source keeps a history row per customer. `ROW_NUMBER() PARTITION BY cst_id ORDER BY cst_create_date DESC` keeps only the newest. |
| Trim names | `TRIM()` on first and last name. |
| Marital status | `S` → `Single`, `M` → `Married`, anything else → `n/a`. |
| Gender | `M` → `Male`, `F` → `Female`, anything else → `n/a`. |

### `silver.crm_prd_info` — products

| Rule | Detail |
|---|---|
| Split the key | `CO_AC-1234` becomes `cat_id = 'CO_AC'` and `prd_key = '1234'`. The category joins to ERP. |
| Cost | `NULL` → `0`. |
| Product line | `M`/`R`/`S`/`T` → `Mountain` / `Road` / `Other Sales` / `Touring`, else `n/a`. |
| Validity window | `prd_end_dt` is the day before the next version's `prd_start_dt` (`LEAD` over `prd_key`). A NULL end date means "still current". |

### `silver.crm_sales_details` — sales

| Rule | Detail |
|---|---|
| Dates | The source stores `yyyymmdd` integers. Values that are NULL, `0`, or not exactly 8 digits become NULL; the rest convert via `TRY_CONVERT(..., 112)`. |
| Price | Rebuilt as `sales / quantity` when NULL, zero or negative. |
| Sales amount | Rebuilt as `quantity * ABS(price)` when NULL, zero or negative. |

`TRY_CONVERT` matters here — a single malformed date would otherwise abort the whole load.

### `silver.erp_cust_az12` — customer birth date and gender

| Rule | Detail |
|---|---|
| Customer id | Strip the `NAS` prefix so the id joins to CRM. |
| Birth date | A date in the future is a data error → NULL. |
| Gender | Free-text values collapsed to `Male` / `Female` / `n/a`. |

### `silver.erp_px_cat_g1v2` — product category

Copied as-is. The source is already clean; it supplies `category`, `subcategory`
and `maintenance` for `Gold.dim_products`.

### `silver.erp_loc_a101` — country

| Rule | Detail |
|---|---|
| Customer id | `AW-00011000` → dashes stripped. |
| Country | Embedded CR/LF stripped; `DE` → Germany, `US`/`USA`/`UNITED STATES` → United States; missing → `n/a`. |

---

## Scripts

| File | What it does |
|---|---|
| `1_ddl_for_silver.sql` | `CREATE TABLE` for all six tables (re-runnable, drops first) |
| `2_testing_to_impove_bronze.sql` | Data quality checks — run against Bronze and Silver |
| `3_table_cust_info.sql` | Loads customers |
| `4_prodt_info.sql` | Loads products plus validity-window checks |
| `5_SALES_INFO.sql` | Loads sales |
| `6_erp_azcust.sql` | Loads ERP customer data |
| `7_ERP_LOC.sql` | Loads ERP country data |
| `SQLQuery5.sql` | Loads ERP product category data |
| `8_final_Store_procdure.sql` | `silver.load_silver` — loads all six in order |

Prefer `8_final_Store_procdure.sql` (the procedure) over the individual scripts. The
per-table scripts are kept because they document each rule on its own.

> The file `2_testing_to_impove_bronze.sql` has a typo in its name (`impove`). It is
> left as-is so existing references keep working.

---

## Bugs fixed in this layer

| File | Was | Now |
|---|---|---|
| `6_erp_azcust.sql` | `INSERT INTO bronze.erp_cust_az12 ... FROM bronze.erp_cust_az12` — reloaded the raw table from itself, so Silver never received the data | Inserts into `silver.erp_cust_az12` |
| `6_erp_azcust.sql` | A tab character inside the alias `ci` + TAB + `d` | `cid` |
| `3_table_cust_info.sql` | Wrote the typo `'Singel'` | `'Single'` |
| `2_testing_to_impove_bronze.sql` | Referenced `silver.crm_cust_in` (table does not exist) | `silver.crm_cust_info` |
| `2_testing_to_impove_bronze.sql` | `HAVING COUNT(*) > 1 OR prd_id = NULL` — `= NULL` is always false | `prd_id IS NULL` |
| `8_final_Store_procdure.sql` | File contained a single stray character, `d` | Full `silver.load_silver` procedure restored |

---

## Verifying a load

After `EXEC silver.load_silver;` the procedure prints a row count per table. To check
the cleaning worked, rather than just that rows exist:

```sql
-- Should return no rows: no duplicate customers survive
SELECT cst_id, COUNT(*) FROM silver.crm_cust_info
GROUP BY cst_id HAVING COUNT(*) > 1;

-- Should show only Male / Female / n/a
SELECT DISTINCT cst_gender FROM silver.crm_cust_info;

-- Should show only Single / Married / n/a
SELECT DISTINCT cst_material_status FROM silver.crm_cust_info;

-- Should return no rows: no unusable order dates left
SELECT * FROM silver.crm_sales_details WHERE sls_order_dt IS NULL;
```

See [`../Gold/README.md`](../Gold/README.md) for the star schema built on top.
