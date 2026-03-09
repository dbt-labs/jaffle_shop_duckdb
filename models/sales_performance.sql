with orders as (

    select * from {{ ref('stg_orders') }}

),

sales as (

    select
        beer_type,
        count(order_id) as total_orders,
        sum(case when status = 'completed' then 1 else 0 end) as completed_orders

    from orders

    group by beer_type

)

select * from sales
