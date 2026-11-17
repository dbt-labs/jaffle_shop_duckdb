with payments as (

    select * from {{ ref('stg_payments') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

final as (

    select
        -- payments carry no date, so the month comes from the order they belong to
        cast(date_trunc('month', orders.order_date) as date) as revenue_month,
        payments.payment_method,
        cast(round(sum(payments.amount), 2) as decimal(18, 2)) as revenue,
        count(*) as number_of_payments

    from payments

    inner join orders
        on payments.order_id = orders.order_id

    group by 1, 2

)

select * from final
