with source as (

    {#-
    Normally we would select from the table here, but we are using seeds to load
    our data in this project
    #}
    select * from {{ source('raw_brewery_inventory') }}

),

renamed as (

    select
        id as inventory_id,
        beer_type,
        quantity,
        price

    from source

)

select * from renamed
