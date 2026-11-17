-- Singular dbt test: passes when this query returns zero rows (severity: error).
-- Each returned row is an order whose amount in `orders` differs from the sum of
-- that order's payments in `stg_payments`, which are the two places the same money is held.
-- It catches payments lost or counted twice in the pivot in orders.sql.
-- The allowed difference is half a cent, which only absorbs floating point noise.
-- An order without payments counts as 0 here. Whether that is allowed is decided by
-- the not_null tests on orders.amount, not by this test.

with payments as (

    select
        order_id,
        sum(amount) as payments_total
    from {{ ref('stg_payments') }}
    group by order_id

)

select
    orders.order_id,
    orders.amount,
    payments.payments_total
from {{ ref('orders') }} as orders
left join payments
    on orders.order_id = payments.order_id
where abs(coalesce(orders.amount, 0) - coalesce(payments.payments_total, 0)) > 0.005
