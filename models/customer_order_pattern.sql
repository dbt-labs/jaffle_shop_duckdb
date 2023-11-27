-- Analyzing Order Patterns
SELECT
    customer_id,
    first_order,
    most_recent_order,
    number_of_orders,
    DATEDIFF('day', first_order, most_recent_order) AS days_active,
    DATEDIFF('day', first_order, most_recent_order) / NULLIF(number_of_orders - 1, 0) AS avg_days_between_orders
FROM {{ ref('customers') }}
