{{ config(
    materialized='view',
    seeds__quote_columns=False
) }}

select
    id,
    user_id,
    order_date,
    status
from {{ source('jaffle_shop_duckdb', 'raw_orders.csv') }}