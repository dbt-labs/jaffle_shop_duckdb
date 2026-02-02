with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

customer_orders as (

    select
        customer_id,
        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders
    from orders
    group by customer_id

),

-- Total payments including returns (original CLV calculation)
customer_payments as (

    select
        orders.customer_id,
        sum(amount)::bigint as total_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    group by orders.customer_id

),

-- Net payments excluding returned and return_pending orders
customer_payments_net as (

    select
        orders.customer_id,
        sum(amount)::bigint as net_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    where orders.status not in ('returned', 'return_pending')

    group by orders.customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        customer_payments.total_amount as customer_lifetime_value,
        coalesce(customer_payments_net.net_amount, 0) as clv_net_returns,
        datediff('day', customer_orders.most_recent_order, current_date) as days_since_last_order

    from customers

    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

    left join customer_payments
        on customers.customer_id = customer_payments.customer_id

    left join customer_payments_net
        on customers.customer_id = customer_payments_net.customer_id

)

select * from final
