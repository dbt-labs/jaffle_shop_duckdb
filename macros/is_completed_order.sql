{% macro is_completed_order(status_column='status') %}
    case 
        when {{ status_column }} = 'completed' then true
        else false
    end
{% endmacro %}