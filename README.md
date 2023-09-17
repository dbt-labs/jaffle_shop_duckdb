# Applying WAP to dbt project: `jaffle_shop`

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

I found a few online resources about how to apply WAP with `dbt run` and `dbt test`:
- Calogica summarised how they applied WAP with [dbt-bigquery](https://github.com/dbt-labs/dbt-bigquery) [here](https://calogica.com/assets/wap_dbt_bigquery.pdf). This requires running parts of your dags again once tests have passed, which is not ideal
- dbt published a [discourse](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349) about how to apply WAP with [dbt-snowflake](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349). This requires all tests to pass before publishing any idea, which is not ideal either.

I couldn't find any online resources about how to apply WAP with `dbt build`. I can only assume this is because `dbt build` is more recent, or because it's good enough for most use cases.

## Dummy post-test-hook

The ideal solution is a post-test-hook which would run after tests have completed successfully, the same way that dbt offers [post-hooks](https://docs.getdbt.com/reference/resource-configs/pre-hook-post-hook) which run after models have completed successfully. Unfortunately this is not available as yet, and I needed a solution before I went live in one month's time. Hence the "dummy" solution:

1. Create a ‘wap’ version of your model:

```
--my_table_wap.sql
{{ config(
    materialized='table',
) }}

SELECT 1 AS id
```

2. Create a view model that references the wap model, and then deletes the view and renames the wap table as post-hook:

```
--my_table.sql
{{ config(
    materialized='view',
    post_hook=[ 
        "DROP VIEW {{ this }}",
        "ALTER TABLE {{ ref('stg_payments_wap') }} RENAME TO {{ this.identifier }}",
    ],
) }}

SELECT * FROM {{ref('my_table_wap')}}
```

## Review

The "dummy" post-test-hook the following advantages over the approach summarised in the [discourse](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349):

- You can re-run failed models without worrying about parent references
- You can be selective about which models to apply WAP to, and skip staging models for example
- You don’t have to identify and pass successful models, since the ref() does that for you
- You can publish tables as soon they have run, instead of waiting until your pipeline has completed.


