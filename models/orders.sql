{% set payment_methods = dbt_utils.get_column_values(
    table=ref('stg_payments'),
    column='payment_method'
) %}

with orders as (

    select * from {{ ref('stg_orders') }}

),

order_payments as (
    select
        order_id,
        {{ pivot_payment_methods(payment_methods) }},
        sum(amount) as total_amount
    from {{ ref('stg_payments') }}
    group by order_id
),

final as (
    select
        orders.*,
        {{ coalesce_payment_columns(payment_methods) }}

    from orders
    left join order_payments on orders.order_id = order_payments.order_id

)

select * from final
