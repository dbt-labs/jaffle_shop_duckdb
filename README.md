# Jaffle Shop - dbt Project

> Extended from the [official dbt Jaffle Shop tutorial](https://github.com/dbt-labs/jaffle_shop_duckdb) with custom macros, incremental models, and dynamic SQL generation.

A demonstration dbt project using DuckDB, showcasing data transformation best practices for an e-commerce analytics use case.

## Project Structure
```
├── models/
│   ├── staging/          # Clean, standardized source data
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   └── stg_payments.sql
│   ├── intermediate/
│   │   └── placeholder
│   └── marts/            # Business logic layer
│       ├── customers.sql     # Customer dimension with lifetime metrics
│       ├── orders.sql        # Order fact table with payment aggregations
│       └── daily_order_summary.sql  # Incremental daily metrics
├── macros/               # Reusable SQL functions
│   ├── cents_to_dollars.sql
│   ├── pivot_payment_methods.sql
│   ├── coalesce_payment_columns.sql
│   └── is_completed_order.sql
└── seeds/                # Static reference data
    ├── raw_customers.csv
    ├── raw_orders.csv
    └── raw_payments.csv
```

## Key Features

### Dynamic Payment Method Pivoting
Uses `dbt_utils.get_column_values()` to automatically detect payment methods and generate pivot columns - no hardcoded values needed.

### Incremental Models
`daily_order_summary` uses incremental materialization with `delete+insert` strategy to efficiently process only new dates.

### Reusable Macros
- **`pivot_payment_methods`**: Generates SUM/CASE statements for each payment type
- **`coalesce_payment_columns`**: Ensures NULL-safe column handling
- **`cents_to_dollars`**: Standardizes currency conversion logic

### Data Quality Tests
- Uniqueness and not-null constraints on primary keys
- Referential integrity checks across staging models
- Custom business logic validation

## Running the Project
```bash
# Install dependencies
dbt deps

# Load seed data
dbt seed

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Technologies
- **dbt Core** 1.11.7
- **DuckDB** (dbt-duckdb adapter 1.10.1)
- **dbt_utils** package for advanced macros