{% macro pivot_payment_methods(methods) %}
    {% for method in methods %}
    sum(case when payment_method = '{{ method }}' then amount else 0 end) as {{ method }}_amount
    {{- "," if not loop.last else "" }}
    {% endfor %}
{% endmacro %}