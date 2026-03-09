with customers as (

    select * from {{ ref('stg_customers') }}

),

demographics as (

    select
        gender,
        count(customer_id) as total_customers,
        avg(age) as average_age

    from customers

    group by gender

)

select * from demographics
