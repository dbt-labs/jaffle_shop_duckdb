{{ config(
    materialized='view',
    seeds__quote_columns=False
) }}

select
    id,
    order_id,
    payment_method,
    amount
from {{ source('jaffle_shop_duckdb', 'raw_payments.csv') }}