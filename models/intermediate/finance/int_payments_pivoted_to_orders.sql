WITH payments AS (
    SELECT * FROM {{ ref('stg_payments') }}
)


, payments_pivot AS (
SELECT order_id,  
              SUM(CASE WHEN payment_method = 'credit_card' THEN amount ELSE 0 END) AS credit_card_amount,
              SUM(CASE WHEN payment_method = 'coupon' THEN amount ELSE 0 END) AS coupon_amount,
              SUM(CASE WHEN payment_method = 'bank_transfer' THEN amount ELSE 0 END) AS bank_transfer_amount,
              SUM(CASE WHEN payment_method = 'gift_card' THEN amount ELSE 0 END) AS gift_card_amount,
              SUM(amount) AS amount

FROM payments
GROUP BY order_id
)

SELECT * FROM payments_pivot
