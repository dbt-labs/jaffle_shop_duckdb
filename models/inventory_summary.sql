with inventory as (

    select * from {{ ref('stg_brewery_inventory') }}

),

summary as (

    select
        beer_type,
        sum(quantity) as total_quantity,
        sum(quantity * price) as total_value

    from inventory

    group by beer_type

)

select * from summary
