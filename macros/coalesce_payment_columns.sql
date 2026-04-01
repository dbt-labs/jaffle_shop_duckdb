{% macro coalesce_payment_columns(methods) %}
    {% for method in methods %}
    coalesce(order_payments.{{ method }}_amount, 0) as {{ method }}_amount,
    {% endfor %}
    coalesce(order_payments.total_amount, 0) as total_amount
{% endmacro %}