# Bronze Layer

The raw landing zone. Data arrives here exactly as the source systems sent it.

**Schema:** `bronze`

---

## Purpose

Bronze does one job: get the CSV files into SQL Server without changing them.
No cleaning, no type conversion, no de-duplication — every column is nullable and
dates stay as the raw `yyyymmdd` integers the files contain.

This keeps the load fast and, more importantly, keeps the original data intact.
If a Silver cleaning rule turns out to be wrong, you can re-derive from Bronze
without going back to the source files.

---

## Tables

| Table | Source file | Rows describe |
|---|---|---|
| `bronze.crm_cust_info` | `source_crm/cust_info.csv` | CRM customer master |
| `bronze.crm_prd_info` | `source_crm/prd_info.csv` | CRM product master |
| `bronze.crm_sales_details` | `source_crm/sales_details.csv` | Sales order lines |
| `bronze.erp_loc_a101` | `source_erp/LOC_A101.csv` | Customer country |
| `bronze.erp_cust_az12` | `source_erp/CUST_AZ12.csv` | Customer birth date + gender |
| `bronze.erp_px_cat_g1v2` | `source_erp/PX_CAT_G1V2.csv` | Product category lookup |

---

## Scripts

| File | What it does |
|---|---|
| `2_DDL_bronzeLayer.sql` | `CREATE TABLE` for all six tables |
| `3_dml_bronze_layer.sql` | `CREATE OR ALTER PROCEDURE bronze.load_bronze`, then runs it |

---

## Loading

```sql
EXEC bronze.load_bronze;
```

The procedure truncates each table, `BULK INSERT`s its CSV, and prints how long
each load took. It ends with a row count per table so you can confirm all six
loaded. Any failure aborts the whole batch and re-raises the error.

**Before the first run, update the `BULK INSERT` file paths** in
`3_dml_bronze_layer.sql` — they still point at the original dataset location.
The SQL Server service account also needs read access to that folder, or the
load fails with an operating-system error.

### BULK INSERT settings used

| Setting | Value | Why |
|---|---|---|
| `FIRSTROW` | `2` | Skip the CSV header row |
| `FIELDTERMINATOR` | `,` | Comma-separated |
| `ROWTERMINATOR` | `0x0a` | The files use LF only, not CRLF |
| `TABLOCK` | on | Faster load; safe because the table was just truncated |

---

## What Bronze deliberately does *not* do

Everything below is fixed in the Silver layer, not here:

- Dates stay as `INT` (`20240115`), not `DATE`
- Duplicate customers are kept — every history row loads
- `NULL` costs, negative prices and zero sales amounts are kept
- Gender and marital status stay as raw single letters
- ERP ids keep their `NAS` prefix and `AW-` formatting

See [`../silver/README.md`](../silver/README.md) for the rules that clean these up.
