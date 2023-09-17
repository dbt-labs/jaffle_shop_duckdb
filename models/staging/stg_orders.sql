{{ config(
    materialized='view',
    post_hook=[ 
        "DROP VIEW {{ this }}",
        "ALTER TABLE {{ ref('stg_orders_wap') }} RENAME TO {{ this.identifier }}",
    ],
) }}

select * from {{ ref('stg_orders_wap') }}
