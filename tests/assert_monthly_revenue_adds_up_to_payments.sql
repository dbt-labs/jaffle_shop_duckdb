-- Singular dbt test: passes when this query returns zero rows.
-- The monthly revenue mart must not lose or double count payments:
-- its total revenue has to equal the total of stg_payments.

with mart_total as (

    select sum(revenue) as total_revenue
    from {{ ref('monthly_revenue_by_payment_method') }}

),

source_total as (

    select sum(amount) as total_revenue
    from {{ ref('stg_payments') }}

)

select
    mart_total.total_revenue as mart_value,
    source_total.total_revenue as source_value
from mart_total
cross join source_total
where round(mart_total.total_revenue, 2) is distinct from round(source_total.total_revenue, 2)
