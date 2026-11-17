-- Singular dbt test: passes when this query returns zero rows (severity: error).
-- Project rule: money amounts have at most 2 decimals, like real currencies.
-- It checks every layer that holds a money amount:
--   seeds     raw_payments.amount is in CENTS, so it must be a whole number (0 decimals).
--             A fractional cent here would become more than 2 decimals once converted to dollars.
--   staging   stg_payments.amount is in dollars (2 decimals).
--   marts     customers and orders amounts are in dollars (2 decimals).
-- A row is returned for every amount whose value changes when rounded to its allowed decimals.
-- The tiny tolerance (1e-9) only absorbs floating point storage noise on DOUBLE columns.
-- When you add a new amount column to any layer, add it below.

with amounts as (

    select
        'seeds' as layer,
        'raw_payments.amount (cents)' as column_name,
        id as row_id,
        amount,
        0 as decimals_allowed
    from {{ ref('raw_payments') }}

    union all

    select
        'staging' as layer,
        'stg_payments.amount' as column_name,
        payment_id as row_id,
        amount,
        2 as decimals_allowed
    from {{ ref('stg_payments') }}

    union all

    select
        'marts' as layer,
        'customers.customer_lifetime_value' as column_name,
        customer_id as row_id,
        customer_lifetime_value as amount,
        2 as decimals_allowed
    from {{ ref('customers') }}

    union all

    select
        'marts' as layer,
        'customers.average_order_value' as column_name,
        customer_id as row_id,
        average_order_value as amount,
        2 as decimals_allowed
    from {{ ref('customers') }}

    union all

    select
        'marts' as layer,
        'orders.amount' as column_name,
        order_id as row_id,
        amount,
        2 as decimals_allowed
    from {{ ref('orders') }}

    union all

    select
        'marts' as layer,
        'orders.credit_card_amount' as column_name,
        order_id as row_id,
        credit_card_amount as amount,
        2 as decimals_allowed
    from {{ ref('orders') }}

    union all

    select
        'marts' as layer,
        'orders.coupon_amount' as column_name,
        order_id as row_id,
        coupon_amount as amount,
        2 as decimals_allowed
    from {{ ref('orders') }}

    union all

    select
        'marts' as layer,
        'orders.bank_transfer_amount' as column_name,
        order_id as row_id,
        bank_transfer_amount as amount,
        2 as decimals_allowed
    from {{ ref('orders') }}

    union all

    select
        'marts' as layer,
        'orders.gift_card_amount' as column_name,
        order_id as row_id,
        gift_card_amount as amount,
        2 as decimals_allowed
    from {{ ref('orders') }}

    union all

    select
        'marts' as layer,
        'monthly_revenue_by_payment_method.revenue' as column_name,
        row_number() over () as row_id,
        revenue as amount,
        2 as decimals_allowed
    from {{ ref('monthly_revenue_by_payment_method') }}

)

select
    layer,
    column_name,
    row_id,
    amount
from amounts
where abs(amount - round(amount, decimals_allowed)) > 0.000000001
