-- Customer Segmentation based on number of orders, lifetime value, and recency
with customers as (
    select * from {{ ref('customers') }}
),

-- Calculate percentile thresholds for dynamic value segmentation
percentiles as (
    select
        percentile_cont(0.75) within group (order by clv_net_returns) as p75_clv,
        percentile_cont(0.50) within group (order by clv_net_returns) as p50_clv
    from customers
    where clv_net_returns > 0
),

segmented as (
    select
        c.customer_id,
        c.number_of_orders,
        c.customer_lifetime_value,
        c.clv_net_returns,
        c.days_since_last_order,

        -- Order frequency segment
        case
            when c.number_of_orders > 10 then 'Frequent Buyer'
            when c.number_of_orders between 5 and 10 then 'Occasional Buyer'
            else 'Rare Buyer'
        end as order_frequency_segment,

        -- Value segment using dynamic percentile thresholds
        case
            when c.clv_net_returns >= p.p75_clv then 'High Value'
            when c.clv_net_returns >= p.p50_clv then 'Medium Value'
            else 'Low Value'
        end as value_segment,

        -- Recency segment based on days since last order
        case
            when c.days_since_last_order is null then 'Never Ordered'
            when c.days_since_last_order <= 30 then 'Active'
            when c.days_since_last_order <= 90 then 'Recent'
            when c.days_since_last_order <= 180 then 'Lapsing'
            else 'Dormant'
        end as recency_segment

    from customers c
    cross join percentiles p
)

select
    customer_id,
    number_of_orders,
    customer_lifetime_value,
    clv_net_returns,
    days_since_last_order,
    order_frequency_segment,
    value_segment,
    recency_segment,

    -- Marketing segment combining value and recency
    case
        when value_segment = 'High Value' and recency_segment in ('Active', 'Recent') then 'VIP Active'
        when value_segment = 'High Value' and recency_segment = 'Lapsing' then 'VIP At-Risk'
        when value_segment = 'High Value' and recency_segment = 'Dormant' then 'VIP Lost'
        when value_segment = 'Medium Value' and recency_segment in ('Active', 'Recent') then 'Growth Active'
        when value_segment = 'Medium Value' and recency_segment = 'Lapsing' then 'Growth At-Risk'
        when value_segment = 'Medium Value' and recency_segment = 'Dormant' then 'Growth Lost'
        when value_segment = 'Low Value' and recency_segment in ('Active', 'Recent') then 'Nurture Active'
        when value_segment = 'Low Value' and recency_segment = 'Lapsing' then 'Nurture At-Risk'
        when value_segment = 'Low Value' and recency_segment = 'Dormant' then 'Nurture Lost'
        else 'New/Unknown'
    end as marketing_segment

from segmented
