with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Aggregate payments per order, pivoting payment methods into separate columns
order_payments as (

    select
        order_id,

        sum(case when payment_method = 'credit_card' then amount else 0 end) as credit_card_amount,
        sum(case when payment_method = 'coupon' then amount else 0 end) as coupon_amount,
        sum(case when payment_method = 'bank_transfer' then amount else 0 end) as bank_transfer_amount,
        sum(case when payment_method = 'gift_card' then amount else 0 end) as gift_card_amount,

        sum(amount) as total_amount

    from payments

    group by order_id

),

-- Enrich orders with payment breakdowns and compute window-function metrics
enriched_orders as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,

        coalesce(order_payments.credit_card_amount, 0) as credit_card_amount,
        coalesce(order_payments.coupon_amount, 0) as coupon_amount,
        coalesce(order_payments.bank_transfer_amount, 0) as bank_transfer_amount,
        coalesce(order_payments.gift_card_amount, 0) as gift_card_amount,
        coalesce(order_payments.total_amount, 0) as order_total_amount,

        -- Running total of order amounts per customer over time
        sum(coalesce(order_payments.total_amount, 0)) over (
            partition by orders.customer_id
            order by orders.order_date, orders.order_id
            rows between unbounded preceding and current row
        ) as customer_running_total,

        -- Rank of this order within the customer's order history (by amount)
        rank() over (
            partition by orders.customer_id
            order by coalesce(order_payments.total_amount, 0) desc
        ) as order_amount_rank,

        -- Lag: previous order date for the same customer
        lag(orders.order_date) over (
            partition by orders.customer_id
            order by orders.order_date, orders.order_id
        ) as previous_order_date

    from orders

    left join order_payments
        on orders.order_id = order_payments.order_id

),

-- Customer-level aggregates plus cohort month
customer_metrics as (

    select
        customer_id,

        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(order_id) as number_of_orders,

        sum(order_total_amount) as total_order_amount,

        -- Days between first and most recent order (tenure)
        datediff(
            'day',
            min(order_date),
            max(order_date)
        ) as customer_tenure_days,

        -- Average order value
        avg(order_total_amount) as average_order_value,

        -- Running total at the time of the most recent order (lifetime value)
        max(customer_running_total) as customer_lifetime_value,

        -- Cohort month (month of first order)
        strftime(min(order_date), '%Y-%m') as cohort_month

    from enriched_orders

    group by customer_id

),

-- Payment-method mix per customer (conditional aggregation across joined tables)
customer_payment_mix as (

    select
        orders.customer_id,

        sum(case when payments.payment_method = 'credit_card' then payments.amount else 0 end) as credit_card_total,
        sum(case when payments.payment_method = 'coupon' then payments.amount else 0 end) as coupon_total,
        sum(case when payments.payment_method = 'bank_transfer' then payments.amount else 0 end) as bank_transfer_total,
        sum(case when payments.payment_method = 'gift_card' then payments.amount else 0 end) as gift_card_total,

        sum(payments.amount) as total_paid

    from orders

    left join payments
        on payments.order_id = orders.order_id

    group by orders.customer_id

),

-- Orders with inter-order gap (window function) and a flag for high-value orders
enriched_orders_final as (

    select
        *,

        case
            when order_total_amount > average_order_value * 2 then 'high_value'
            else 'standard'
        end as order_tier,

        datediff(
            'day',
            previous_order_date,
            order_date
        ) as days_since_previous_order

    from enriched_orders

    -- Attach the customer average order value for the tier comparison
    left join (
        select
            customer_id,
            avg(order_total_amount) as average_order_value
        from enriched_orders
        group by customer_id
    ) as customer_avg
        on enriched_orders.customer_id = customer_avg.customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,

        customer_metrics.first_order_date,
        customer_metrics.most_recent_order_date,
        customer_metrics.number_of_orders,
        customer_metrics.customer_tenure_days,
        customer_metrics.average_order_value,
        customer_metrics.customer_lifetime_value,
        customer_metrics.cohort_month,

        coalesce(customer_payment_mix.credit_card_total, 0) as credit_card_total,
        coalesce(customer_payment_mix.coupon_total, 0) as coupon_total,
        coalesce(customer_payment_mix.bank_transfer_total, 0) as bank_transfer_total,
        coalesce(customer_payment_mix.gift_card_total, 0) as gift_card_total,
        coalesce(customer_payment_mix.total_paid, 0) as total_paid

    from customers

    left join customer_metrics
        on customers.customer_id = customer_metrics.customer_id

    left join customer_payment_mix
        on customers.customer_id = customer_payment_mix.customer_id

)

select * from final
order by customer_lifetime_value desc, most_recent_order_date desc