# Applying WAP to dbt project: `jaffle_shop`

> [!NOTE]
> Work in Progress

This [dbt](https://www.getdbt.com/) project demonstrates how to implement [Write-Audit-Publish (WAP)](https://lakefs.io/blog/data-engineering-patterns-write-audit-publish/) on table [materializations](https://docs.getdbt.com/docs/build/materializations) using "dummy" post-test-hooks. It applies the approach to the example [jaffle_shop_db](https://github.com/dbt-labs/jaffle_shop_duckdb) dbt project. This project uses the [dbt-duckdb](https://github.com/duckdb/dbt-duckdb) adapter but the approach can be applied to any other dbt adapters which have a process for renaming tables.

## Why WAP

dbt introduced [`dbt build`](https://docs.getdbt.com/reference/commands/build) in 2021. The dbt build command will:

- run models
- test tests
- snapshot snapshots
- seed seeds

In DAG order, for selected resources or an entire project. Tests on upstream resources will block downstream resources from running, and a test failure will cause those downstream resources to skip entirely.

`dbt build` is great because it ensures that "bad" data cannot impact and "pollute" downstream models. However the model(s) with failed tests will still be available to users. I wanted to ensure that **all** "bad" data was quarantined from users.

One remedy is to use WAP. From [Streamlining Data Quality in Apache Iceberg](https://www.dremio.com/blog/streamlining-data-quality-in-apache-iceberg-with-write-audit-publish-branching/):

> Write-Audit-Publish (WAP) is a data quality pattern commonly used in the data engineering workflow that helps us validate datasets by allowing us to write data to a non-production environment and fix any issues before finally committing the data to the production tables.

I found a few online resources about how to apply WAP with `dbt run` and `dbt test`. dbt published a [discourse](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349) about how to apply WAP with [dbt-snowflake](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349).

I couldn't find any online resources about how to apply WAP with `dbt build`. I can only assume this is because `dbt build` is more recent, or because restricting the "bad" data is good enough for most use cases. This was not the case for our data platform where data quality is a must. Hence I decided to come up with an alternative approach.

## Dummy post-test-hook

The ideal solution is a post-test-hook which would run after tests have completed successfully, the same way that dbt offers [post-hooks](https://docs.getdbt.com/reference/resource-configs/pre-hook-post-hook) which run after models have completed successfully. Unfortunately post-test-hooks are not available, and I needed a solution before we went live in one month's time. Hence the "dummy" post-test-hook approach:

1. Create a ‘wap’ version of your model:

```
--my_table_wap.sql
{{ config(
    materialized='table',
) }}

SELECT 1 AS id
```

2. Create a view model that references the wap model, and use a post-hook to delete the view and rename the wap table:

```
--my_table.sql
{{ config(
    materialized='view',
    post_hook=[ 
        "DROP VIEW {{ this }}",
        "ALTER TABLE {{this.schema}}.{{this.identifier}}_wap RENAME TO {{ this.identifier }}",
    ],
) }}

SELECT * FROM {{ref('my_table_wap')}}
```

As an example, I have applied the post_hook to all staging models in `models/staging/publish` by updating the model configs in `dbt_project.yml`. I have modified modified `seeds/raw_orders.csv`` so that it contains a null id. This causes the not_null_stg_orders_wap_order_id test to fail, and any downstream models to skip:

```
(venv) soumaya.mauthoor@MJ001216 jaffle_shop_duckdb_wap % dbt build
20:58:15  Running with dbt=1.5.0
20:58:15  Found 8 models, 20 tests, 0 snapshots, 0 analyses, 313 macros, 0 operations, 3 seed files, 0 sources, 0 exposures, 0 metrics, 2 groups
20:58:15  
20:58:15  Concurrency: 24 threads (target='dev')
20:58:15  
20:58:15  1 of 31 START seed file main.raw_customers ..................................... [RUN]
20:58:15  2 of 31 START seed file main.raw_orders ........................................ [RUN]
20:58:15  3 of 31 START seed file main.raw_payments ...................................... [RUN]
20:58:16  2 of 31 OK loaded seed file main.raw_orders .................................... [INSERT 99 in 0.21s]
20:58:16  1 of 31 OK loaded seed file main.raw_customers ................................. [INSERT 100 in 0.21s]
20:58:16  4 of 31 START sql table model main.stg_orders_wap .............................. [RUN]
20:58:16  5 of 31 START sql table model main.stg_customers_wap ........................... [RUN]
20:58:16  3 of 31 OK loaded seed file main.raw_payments .................................. [INSERT 113 in 0.21s]
20:58:16  6 of 31 START sql table model main.stg_payments_wap ............................ [RUN]
20:58:16  4 of 31 OK created sql table model main.stg_orders_wap ......................... [OK in 0.06s]
20:58:16  5 of 31 OK created sql table model main.stg_customers_wap ...................... [OK in 0.06s]
20:58:16  7 of 31 START test accepted_values_stg_orders_wap_status__placed__shipped__completed__return_pending__returned  [RUN]
20:58:16  8 of 31 START test not_null_stg_orders_wap_order_id ............................ [RUN]
20:58:16  9 of 31 START test unique_stg_orders_wap_order_id .............................. [RUN]
20:58:16  10 of 31 START test not_null_stg_customers_wap_customer_id ..................... [RUN]
20:58:16  11 of 31 START test unique_stg_customers_wap_customer_id ....................... [RUN]
20:58:16  6 of 31 OK created sql table model main.stg_payments_wap ....................... [OK in 0.04s]
20:58:16  12 of 31 START test accepted_values_stg_payments_wap_payment_method__credit_card__coupon__bank_transfer__gift_card  [RUN]
20:58:16  13 of 31 START test not_null_stg_payments_wap_payment_id ....................... [RUN]
20:58:16  14 of 31 START test unique_stg_payments_wap_payment_id ......................... [RUN]
20:58:16  7 of 31 PASS accepted_values_stg_orders_wap_status__placed__shipped__completed__return_pending__returned  [PASS in 0.07s]
20:58:16  8 of 31 FAIL 1 not_null_stg_orders_wap_order_id ................................ [FAIL 1 in 0.07s]
20:58:16  9 of 31 PASS unique_stg_orders_wap_order_id .................................... [PASS in 0.08s]
20:58:16  10 of 31 PASS not_null_stg_customers_wap_customer_id ........................... [PASS in 0.06s]
20:58:16  11 of 31 PASS unique_stg_customers_wap_customer_id ............................. [PASS in 0.06s]
20:58:16  15 of 31 SKIP relation main.stg_orders ......................................... [SKIP]
20:58:16  12 of 31 PASS accepted_values_stg_payments_wap_payment_method__credit_card__coupon__bank_transfer__gift_card  [PASS in 0.05s]
20:58:16  16 of 31 START sql view model main.stg_customers ............................... [RUN]
20:58:16  13 of 31 PASS not_null_stg_payments_wap_payment_id ............................. [PASS in 0.05s]
20:58:16  14 of 31 PASS unique_stg_payments_wap_payment_id ............................... [PASS in 0.05s]
20:58:16  17 of 31 START sql view model main.stg_payments ................................ [RUN]
20:58:16  17 of 31 OK created sql view model main.stg_payments ........................... [OK in 0.04s]
20:58:16  16 of 31 OK created sql view model main.stg_customers .......................... [OK in 0.07s]
20:58:16  18 of 31 SKIP relation main.orders ............................................. [SKIP]
20:58:16  19 of 31 SKIP relation main.customers .......................................... [SKIP]
20:58:16  20 of 31 SKIP test accepted_values_orders_status__placed__shipped__completed__return_pending__returned  [SKIP]
20:58:16  21 of 31 SKIP test not_null_orders_amount ...................................... [SKIP]
20:58:16  22 of 31 SKIP test not_null_orders_bank_transfer_amount ........................ [SKIP]
20:58:16  23 of 31 SKIP test not_null_orders_coupon_amount ............................... [SKIP]
20:58:16  24 of 31 SKIP test not_null_orders_credit_card_amount .......................... [SKIP]
20:58:16  25 of 31 SKIP test not_null_orders_customer_id ................................. [SKIP]
20:58:16  26 of 31 SKIP test not_null_orders_gift_card_amount ............................ [SKIP]
20:58:16  27 of 31 SKIP test not_null_orders_order_id .................................... [SKIP]
20:58:16  28 of 31 SKIP test unique_orders_order_id ...................................... [SKIP]
20:58:16  29 of 31 SKIP test not_null_customers_customer_id .............................. [SKIP]
20:58:16  30 of 31 SKIP test relationships_orders_customer_id__customer_id__ref_customers_  [SKIP]
20:58:16  31 of 31 SKIP test unique_customers_customer_id ................................ [SKIP]
```

Note that I could have achieved a similar outcome by treating the seeds as sources and applying source tests before running the rest of the pipeline. However I wanted to use a simple example to prove the concept.

## Restrict access to wap models 

dbt released [groups](https://docs.getdbt.com/docs/collaborate/govern/model-access) with v1.5 which enables you to designate certain models as having "private" access—for use exclusively within that group.

Setting wap models to "private" is not necessary, since any downstream models referencing the wap models will fail. However making the access level explicit means downstream models fail with a more useful error message. Set line 3 to `select * from {{ ref('stg_customers_wap') }}` and run `dbt build`:

```
Node model.jaffle_shop.customers attempted to reference node model.jaffle_shop.stg_customers_wap, which is not allowed because the referenced node is private to the staging group.
```

## Comparison

The "dummy" post-test-hook has the following advantages over the approach summarised in the [discourse](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349):

- You can re-run failed models without worrying about parent references
- You can be selective about which models to apply WAP to, and skip staging models for example
- You don’t have to identify and pass successful models, since the ref() does that for you
- You can publish tables as soon they have run, instead of waiting until your pipeline has completed
