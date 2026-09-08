# dbt CLI Commands — Reference

Compiled from Week 4 hands-on work on `jaffle_shop_duckdb`. Commands actually used tonight, plus close relatives worth knowing.

## Core build commands

### `dbt seed`
Loads CSV files from `seeds/` into the warehouse as real tables. Reads the CSV, creates a table matching its columns, inserts every row. Only for small, static, git-tracked reference data in a real project — in this project, used as a stand-in for "raw data already extracted," per the project's own convention.

### `dbt run`
Compiles and executes model `.sql` files — resolves every `ref()`/`source()` to real table names, wraps the result in `CREATE VIEW` or `CREATE TABLE` depending on the configured materialization, sends it to the warehouse. Does **not** run tests. Does **not** show query results — only reports pass/fail per model.

### `dbt test`
Runs the data tests defined in `.yml` files (`unique`, `not_null`, `accepted_values`, `relationships`, and any custom ones) against tables that already exist. Does not build anything — if the underlying model hasn't been run yet, the test will fail because the table doesn't exist.

### `dbt build`
Runs seeds, models, and tests together, **in dependency order**, in a single command. Preferred over running `seed`/`run`/`test` separately, because it respects the DAG automatically — if a seed fails, dependent models don't attempt to build on broken data.

## Targeting specific models

### `--select <model_name>`
Restricts a command to one model (and, depending on the command, its relevant scope) instead of the whole project. Used constantly while iterating on a single new file — e.g. `dbt run --select int_payments_pivoted_to_orders` — to avoid rebuilding everything just to test one change.

### `--select staging+`
The `+` after a name/folder means "this, and everything downstream of it in the DAG." Selects the staging layer plus every model that depends on it, directly or indirectly. Useful after fresh source data lands and everything built on top of it needs refreshing.

## Inspecting and debugging

### `dbt debug`
Tests the connection defined in `profiles.yml` — confirms dbt can actually reach the warehouse before attempting to build anything. Good first command when something's failing and it's unclear whether it's a connection problem or a model problem.

### `dbt parse`
Checks that all `.sql` and `.yml` files are syntactically valid and that every `ref()`/`source()` call resolves to something real — without actually running any SQL against the warehouse. Fast way to catch a broken reference or invalid YAML before attempting a real build.

### `dbt compile`
Resolves all Jinja (`ref()`, `source()`, macros) into plain SQL and writes the result to `target/compiled/`, without executing it against the warehouse. This is how to see exactly what SQL a model actually sends to the database — the file that demystifies what `{{ ref(...) }}` turns into.

### `dbt docs generate`
Builds the project's documentation site — reads every model, its columns, descriptions, and tests, and assembles the lineage graph (the DAG) from every `ref()`/`source()` call in the project.

### `dbt docs serve`
Starts a local web server hosting the docs generated above, viewable in a browser. Runs until manually stopped (Ctrl+C) — it's a live server, not a one-shot command.

## Version and environment

### `dbt --version`
Reports the installed dbt-core version and any registered adapter plugins (e.g. `duckdb`). Good sanity check that the correct venv is active and the install succeeded.

## Flags used alongside these commands

### `--full-refresh`
Forces a model to be completely rebuilt from scratch, ignoring any incremental logic. Not yet used this week — relevant starting Week 6, when incremental models are introduced.

## What none of these commands do

- **None of them touch git.** dbt has no awareness of version control; commands run identically whether the project is tracked by git or not.
- **`dbt run` and `dbt build` never print row-level query results.** To see actual data, connect to the warehouse directly — for this project, the DuckDB CLI (`duckdb jaffle_shop.duckdb`), then a plain `SELECT`.
- **None of them can run while another process holds a lock on the DuckDB file.** Exit any open `duckdb` CLI session (`.exit`) before running a dbt command against the same database file.

---
*Compiled during Week 4, AE Spine — jaffle_shop_duckdb hands-on work.*
