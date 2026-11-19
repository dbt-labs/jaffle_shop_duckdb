with orders as (

    select * from {{ ref('stg_orders') }}

),

order_months as (

    select
        order_id,
        customer_id,
        cast(date_trunc('month', order_date) as date) as order_month

    from orders

),

first_order_months as (

    select
        customer_id,
        min(order_month) as first_order_month

    from order_months

    group by 1

),

final as (

    select
        order_months.order_month,
        count(distinct order_months.customer_id) as number_of_active_customers,

        -- left join so an order without a customer_id still counts in number_of_orders;
        -- such an order is never counted as a new or returning customer
        count(distinct case
            when order_months.order_month = first_order_months.first_order_month
                then order_months.customer_id
        end) as number_of_new_customers,

        count(distinct case
            when order_months.order_month > first_order_months.first_order_month
                then order_months.customer_id
        end) as number_of_returning_customers,

        count(*) as number_of_orders

    from order_months

    left join first_order_months
        on order_months.customer_id = first_order_months.customer_id

    group by 1

)

select * from final
