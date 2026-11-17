-- Singular dbt test: passes when this query returns zero rows.
-- The monthly revenue mart must have exactly one row per month and payment method.
-- (dbt_utils is not installed, so this replaces unique_combination_of_columns.)

select
    revenue_month,
    payment_method,
    count(*) as number_of_rows
from {{ ref('monthly_revenue_by_payment_method') }}
group by revenue_month, payment_method
having count(*) > 1
