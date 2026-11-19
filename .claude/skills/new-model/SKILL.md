---
name: new-model
description: Create or change a dbt model in this repo together with its schema.yml entry and tests, following the project conventions. Use when adding a staging model or a mart.
argument-hint: <model_name> <what it should contain>
disable-model-invocation: true
---

# New dbt model

Build the model described in: $ARGUMENTS

Read `CLAUDE.md` first for the architecture. This skill is the checklist for
adding a model. If the request is unclear about the grain (what one row means)
or the layer, ask before writing anything.

## 1. Branch

Cut a new branch from an up-to-date `duckdb`, named in lowercase snake_case
after the task (for example `add_monthly_revenue_by_payment_method_mart`).
One model per branch. Do not mix in unrelated changes.

## 2. Pick the layer and imitate an existing file

| Layer   | Location                    | Materialization | Imitate                                       |
|---------|-----------------------------|-----------------|-----------------------------------------------|
| Staging | `models/staging/stg_<x>.sql`| view            | `models/staging/stg_payments.sql`             |
| Mart    | `models/<name>.sql`         | table           | `models/monthly_revenue_by_payment_method.sql`|

Staging only renames columns and converts units. Anything that joins or
aggregates is a mart. Marts do not go in subfolders.

## 3. Write the SQL

- Shape: import CTEs first (`source` in staging), then `renamed` (staging) or
  `final` (mart), and end with `select * from final`.
- Names: lowercase snake_case, `<entity>_id` for keys, `stg_<entity>` for
  staging. `id` becomes `<entity>_id` and `user_id` becomes `customer_id`.
- Seeds stand in for sources, so staging uses `ref('raw_...')`.
- Joins: decide each join type on purpose and say why in a comment. A `left join`
  keeps unmatched rows with NULLs, so make sure a test would catch an unwanted NULL.
- Money: at most 2 decimals. Use `round(..., 2)` and `decimal(18, 2)`, not floats.
- Do not edit the rendered copies in `target/`.

## 4. Document it in `schema.yml`

Staging models go in `models/staging/schema.yml`, marts in `models/schema.yml`.

- A `description` for the model and for every column.
- Keys: `unique` and `not_null`.
- Categorical columns: `accepted_values`, with the values under `arguments:`
  (the style already used in this repo).
- Columns that must always be filled: `not_null`.
- Do not claim things the model does not do (for example a time zone the source
  date does not have).
- Adding a payment method means updating three places: the list in
  `models/orders.sql`, `accepted_values` in `models/staging/schema.yml`, and the
  column docs and tests in `models/schema.yml` (plus the mart's `accepted_values`
  if it has one).

## 5. Add tests

- Generic tests go in the `schema.yml` entry above.
- Add a singular test in `tests/`, named `assert_<what>.sql`. It passes when it
  returns zero rows. Start it with a comment saying what it checks and why.
- For a mart that aggregates, add a reconciliation test: its totals must equal
  the totals of the upstream model. Compare with `is distinct from`, never `!=`,
  because `NULL != x` is NULL and a failing row would be filtered out silently.
  Round money with `round(..., 2)` before comparing.
- Every test must be able to fail. Do not test something the model guarantees by
  construction, such as uniqueness of the columns it groups by.
- New money columns are added to `tests/assert_amounts_have_two_decimals.sql`.

## 6. Verify

```bash
dbt build --select +<model_name>
sqlfluff lint <files you touched>
```

Fix failures and warnings. If something fails, report the output instead of
working around it. Show the user the passing count when it is green.

## 7. Wrap up

- Update the architecture section of `CLAUDE.md` if the lineage or a convention changed.
- Findings that are real but outside this task go in `improvements.txt` as a new
  item (what / how / why / example). Do not fix them on this branch. Do not
  implement the proposals that `CLAUDE.md` says were deliberately left out.
- Commit with a short imperative subject (about 70 characters or less) and a
  body that gives the reason when it is not obvious. One logical change per
  commit.
- Pushing, opening a PR and merging follow the user's global Git workflow rules.
  Do not delete branches unless asked.

## Checklist

- [ ] New branch from up-to-date `duckdb`
- [ ] Right layer, imitates an existing model, CTE shape followed
- [ ] Snake_case names, money rounded to 2 decimals
- [ ] `schema.yml` entry with descriptions and tests
- [ ] Singular or reconciliation test that can fail and is NULL-safe
- [ ] `dbt build --select +<model>` green and `sqlfluff lint` clean
- [ ] `CLAUDE.md` and `improvements.txt` updated where needed
