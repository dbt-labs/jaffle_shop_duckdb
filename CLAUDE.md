# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A small, self-contained dbt project (`jaffle_shop`) running on a local DuckDB file. It is a playground for testing dbt scripts, not a best-practice reference: it deliberately uses seeds instead of sources. The default branch is `duckdb`.

## Commands

Setup needs Python >= 3.13. Run `uv sync` and activate the virtualenv it creates (`.venv`). Run everything from the repo root, where `profiles.yml` lives, so no `--profiles-dir` is needed.

```bash
dbt build                                   # seed + run + test, in DAG order
dbt build --select +customers               # a model plus everything upstream
dbt test --select stg_payments              # tests for one model
dbt test --select assert_average_order_value_not_negative   # one singular test, by file name
dbt docs generate && dbt docs serve
sqlfluff lint models                        # lint (config in .sqlfluff)
sqlfluff fix models                         # auto-fix layout
```

After changing a model, run `dbt build --select +<model>` and lint the files you touched.

## Architecture

Lineage is linear and three layers deep. Materializations are set in `dbt_project.yml`:

```
seeds/raw_*.csv  ->  models/staging/stg_*.sql  (views)  ->  models/customers.sql, models/orders.sql  (tables)
```

- **Seeds** stand in for a source database, so staging selects from them with `ref('raw_...')`.
- **Staging** only renames columns and converts units. Seeds hold amounts in cents, and `stg_payments` converts them to dollars.
- **`customers`** (`models/customers.sql`) reads all three staging models. Payments carry no customer key, so it joins `stg_payments` to `stg_orders` on `order_id` to reach `customer_id`. All joins are left joins, so customers without orders or payments stay in the output with NULL aggregates. The lifetime-value column is `customer_lifetime_value`. `average_order_value` is that value divided by `number_of_orders`, and is NULL (not 0) when the customer has no orders or no payments. `average_order_value_status` (`ok`, `no_orders`, `no_payments`, `total_paid_is_zero`, `total_paid_is_negative`) explains odd cases, and the tests in `tests/` act on it.
- **`orders`** pivots payments into one `<method>_amount` column per payment method with a Jinja loop over `payment_methods`, a list set at the top of `models/orders.sql` (marts sit directly in `models/`, not in subfolders). **Adding a payment method means changing that list, the `accepted_values` test in `models/staging/schema.yml`, and the column docs/tests in `models/schema.yml`.**
- **`monthly_revenue_by_payment_method`** (`models/monthly_revenue_by_payment_method.sql`) is long format, one row per `revenue_month` and `payment_method`, so a new payment method needs no change to the SQL. Payments have no date, so the month comes from the order via `stg_payments` joined to `stg_orders`. All orders count and refunds are included. It also has an `accepted_values` test on `payment_method` in `models/schema.yml`, which must list the new method too.
- **`monthly_customers`** (`models/monthly_customers.sql`) has one row per order month that has at least one order. Month comes from `stg_orders.order_date`, all order statuses count. A customer is active if they ordered in the month, new if it is their first order month, returning if they ordered in an earlier month. Months without orders have no row. It has no money columns. `tests/assert_monthly_customers_adds_up.sql` reconciles it with `stg_orders`.

## Conventions

- Staging renames `id` to `<entity>_id` (`customer_id`, `order_id`, `payment_id`) and `user_id` to `customer_id`, so downstream models join on matching names.
- Models are written as CTEs: imports first (`source` in staging), then `renamed`, and `final` in the marts. Follow that shape in new models.
- Money amounts always have at most 2 decimals, like real currencies. Round derived amounts with `round(..., 2)` and prefer `decimal(18, 2)` over floating point types. `tests/assert_amounts_have_two_decimals.sql` checks the amount columns of every layer (seeds hold cents, so they must be whole numbers); add new amount columns to it. `customer_lifetime_value` and the `orders` amounts are still `DOUBLE` (their values are clean to 2 decimals); only `average_order_value` is `decimal(18, 2)`.
- Generic tests live in the two `schema.yml` files. Singular tests live in `tests/`, are named `assert_<what>.sql`, and pass when they return zero rows. A test with `severity='warn'` prints a warning but does not fail the build.
- SQL files contain Jinja. Edit the source `.sql` files, never the rendered copies in `target/`.

## Known issues

- `models/schema.yml` documents a `customers` column `total_order_amount`, but the model outputs `customer_lifetime_value`.
- `etc/jaffle_shop_erd.png` is exported by hand from `etc/dbdiagram_definition.txt` at dbdiagram.io, so update the PNG manually after editing the text.
- `seeds/raw_orders.csv` uses Windows (CRLF) line endings, while the other two seeds use LF. Keep a file's existing line endings when editing or appending rows, because mixed endings make the seed fail to load.
- An order without any payment makes the `not_null` tests on the `orders` amount columns fail. That is stricter than a real "not paid yet" order may warrant, so raise it before changing those tests.
- `improvements.txt` still lists a proposal that was deliberately **not** applied: fixing the `total_order_amount` doc mismatch. Don't implement it unless asked. Its `relationships` proposal (item 6) is applied: `models/staging/schema.yml` tests `stg_orders.customer_id` against `stg_customers` and `stg_payments.order_id` against `stg_orders`, and `models/schema.yml` tests `orders.customer_id` against `customers`. Its reconciliation-test proposal is now mostly covered by `tests/assert_average_order_value_adds_up.sql`.
