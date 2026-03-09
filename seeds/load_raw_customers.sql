{{ config(
    materialized='view',
    seeds__quote_columns=False
) }}

select
    id,
    first_name,
    last_name
from {{ source('jaffle_shop_duckdb', 'raw_customers.csv') }}
