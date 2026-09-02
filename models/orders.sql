with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('int_payments_pivoted_to_orders') }}

),

joined as (

    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,
        p.credit_card_amount,
        p.coupon_amount,
        p.bank_transfer_amount,
        p.gift_card_amount,
        p.amount

    from orders as o
    left join payments as p
        on p.order_id = o.order_id

)

select * from joined