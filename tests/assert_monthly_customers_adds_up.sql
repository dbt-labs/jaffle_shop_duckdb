-- Singular dbt test: passes when this query returns zero rows.
-- The monthly customers mart must reconcile with stg_orders:
--   1. its orders add up to all orders (no order lost or double counted),
--   2. its new customers add up to all distinct customers with an order
--      (a customer is new in exactly one month),
--   3. in every month, active = new + returning.
-- Each failing check returns one row.

with mart as (

    select
        sum(number_of_orders) as total_orders,
        sum(number_of_new_customers) as total_new_customers
    from {{ ref('monthly_customers') }}

),

source as (

    select
        count(*) as total_orders,
        count(distinct customer_id) as total_customers
    from {{ ref('stg_orders') }}

),

totals_check as (

    select
        'totals' as failed_check,
        mart.total_orders as mart_value,
        source.total_orders as source_value
    from mart
    cross join source
    where mart.total_orders is distinct from source.total_orders

    union all

    select
        'new_customers' as failed_check,
        mart.total_new_customers as mart_value,
        source.total_customers as source_value
    from mart
    cross join source
    where mart.total_new_customers is distinct from source.total_customers

),

month_check as (

    select
        'active_is_new_plus_returning' as failed_check,
        number_of_active_customers as mart_value,
        number_of_new_customers + number_of_returning_customers as source_value
    from {{ ref('monthly_customers') }}
    where
        number_of_active_customers
        is distinct from number_of_new_customers + number_of_returning_customers

)

select * from totals_check
union all
select * from month_check
