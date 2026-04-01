{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='order_date'
    )
}}

with orders as (
    select * from {{ ref('orders') }}
),

daily_metrics as (
    select
        order_date,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(total_amount) as total_revenue,
        sum(case when {{ is_completed_order() }} then 1 else 0 end) as completed_orders,
        sum(case when not {{ is_completed_order() }} then 1 else 0 end) as returned_orders,
        avg(total_amount) as avg_order_value
    from orders
    
    {% if is_incremental() %}
    where order_date > (select max(order_date) from {{ this }})
    {% endif %}
    
    group by order_date
)

select * from daily_metrics