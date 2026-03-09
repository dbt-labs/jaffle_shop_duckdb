# Soda Data Quality Checks

This directory contains Soda checks for data quality testing of dbt models.

## Setup

1. Install Soda Core for DuckDB:
```bash
pip install soda-core-duckdb
```

2. Build your dbt models first:
```bash
dbt run
```

## Running Checks

### Run all checks for stg_customers:
```bash
soda scan -d jaffle_shop -c checks/configuration.yml checks/stg_customers.yml
```

### Run checks and save results:
```bash
soda scan -d jaffle_shop -c checks/configuration.yml checks/stg_customers.yml --save-results
```

## Check Mappings

The following dbt tests were converted to Soda checks:

### stg_customers Model

| dbt Test | Soda Check | Description |
|----------|------------|-------------|
| `customer_id: unique` | `duplicate_count(customer_id) = 0` | Ensures no duplicate customer IDs |
| `customer_id: not_null` | `missing_count(customer_id) = 0` | Ensures customer_id is always present |
| `first_name: not_null` | `missing_count(first_name) = 0` | Ensures first_name is always present |
| `last_name: not_null` | `missing_count(last_name) = 0` | Ensures last_name is always present |
| `full_name: not_null` | `missing_count(full_name) = 0` | Ensures full_name is always present |

### Additional Checks

The Soda configuration includes additional data quality checks beyond the original dbt tests:
- **Row count validation**: Ensures table is not empty
- **String length validation**: Ensures names are not empty strings
- **Schema validation**: Confirms all expected columns exist
- **Custom SQL check**: Verifies full_name is correctly concatenated from first_name and last_name

## File Structure

```
checks/
├── README.md              # This file
├── configuration.yml      # Soda data source configuration
└── stg_customers.yml     # Data quality checks for stg_customers model
```

## Integration with CI/CD

You can integrate Soda checks into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Run Soda Checks
  run: |
    dbt run --select stg_customers
    soda scan -d jaffle_shop -c checks/configuration.yml checks/stg_customers.yml
```

## Documentation

- [Soda Documentation](https://docs.soda.io/)
- [Soda CL Reference](https://docs.soda.io/soda-cl/soda-cl-overview.html)
- [DuckDB Data Source](https://docs.soda.io/soda/connect-duckdb.html)
