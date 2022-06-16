## Testing dbt project: `jaffle_shop`

`jaffle_shop` is a fictional ecommerce store. This dbt project transforms raw data from an app database into a customers and orders model ready for analytics.

### What is this repo?
What this repo _is_:
- A self-contained playground dbt project, useful for testing out scripts, and communicating some of the core dbt concepts.

What this repo _is not_:
- A tutorial — check out the [Getting Started Tutorial](https://docs.getdbt.com/tutorial/setting-up) for that. Notably, this repo contains some anti-patterns to make it self-contained, namely the use of seeds instead of sources.
- A demonstration of best practices — check out the [dbt Learn Demo](https://github.com/dbt-labs/dbt-learn-demo) repo instead. We want to keep this project as simple as possible. As such, we chose not to implement:
    - our standard file naming patterns (which make more sense on larger projects, rather than this five-model project)
    - a pull request flow
    - CI/CD integrations
- A demonstration of using dbt for a high-complex project, or a demo of advanced features (e.g. macros, packages, hooks, operations) — we're just trying to keep things simple here!

### What's in this repo?
This repo contains [seeds](https://docs.getdbt.com/docs/building-a-dbt-project/seeds) that includes some (fake) raw data from a fictional app.

The raw data consists of customers, orders, and payments, with the following entity-relationship diagram:

![Jaffle Shop ERD](/etc/jaffle_shop_erd.png)

### Running this project
To get up and running with this project:

1. Clone this repository.

1. Change into the `jaffle_shop` directory from the command line:
    ```shell
    cd jaffle_shop
    ```

1. Install dbt and DuckDB in a virtual environment.
    ```shell
    python -m venv venv
    . venv/bin/activate
    python -m pip install dbt-duckdb
    . venv/bin/activate
    dbt --version
    ```

1. Use the database connection profile [local to this project](https://docs.getdbt.com/dbt-cli/configure-your-profile#advanced-customizing-a-profile-directory) (rather than the default profile located at `~/.dbt/profiles.yml`). This uses a local DuckDB database stored in `jaffle_shop.duckdb`.

    ```shell
    export DBT_PROFILES_DIR=.
    ```
    > **WARNING:** You'll want to run `unset DBT_PROFILES_DIR` after you're done with this demo or this will affect your other dbt projects 😅. You can dynamically load/unload environment variables using tools like [`direnv`](https://direnv.net/).

1. Ensure your profile is setup correctly from the command line:
    ```shell
    dbt debug
    ```

1. Load the CSVs with the demo data set, run the models, and test the output of the models:
    ```shell
    dbt build
    ```

1. Generate documentation for the project:
    ```shell
    dbt docs generate
    ```

1. View the documentation for the project:
    ```shell
    dbt docs serve
    ```

### Running `build` steps independently

1. Load the CSVs with the demo data set. This materializes the CSVs as tables in your target schema. Note that a typical dbt project **does not require this step** since dbt assumes your raw data is already in your warehouse.
    ```shell
    dbt seed
    ```

1. Run the models:
    ```shell
    dbt run
    ```

    > **NOTE:** If this steps fails, it might mean that you need to make small changes to the SQL in the models folder to adjust for the flavor of SQL of your target database. Definitely consider this if you are using a community-contributed adapter.

1. Test the output of the models:
    ```shell
    dbt test
    ```

### Browsing the data
Some options:
- [DuckDB CLI](https://duckdb.org/docs/installation/?environment=cli)
- [How to set up DBeaver SQL IDE for DuckDB](https://duckdb.org/docs/guides/sql_editors/dbeaver)

Easiest (and most fragile) -- just for demo purposes:
```shell
./D select 42 as answer from customers limit 1;
```

#### Troubleshooting

You may get an error like this, in which case you will need to disconnect from any sessions that are locking the database:
```
IO Error: Could not set lock on file "jaffle_shop.duckdb": Resource temporarily unavailable
```

This is a known issue in DuckDB. If you are using DBeaver, this means shutting down DBeaver (merely disconnecting didn't work for me).

Very worst-case, deleting the database file will get you back in action (BUT you will lose all your data).

### What is a jaffle?
A jaffle is a toasted sandwich with crimped, sealed edges. Invented in Bondi in 1949, the humble jaffle is an Australian classic. The sealed edges allow jaffle-eaters to enjoy liquid fillings inside the sandwich, which reach temperatures close to the core of the earth during cooking. Often consumed at home after a night out, the most classic filling is tinned spaghetti, while my personal favourite is leftover beef stew with melted cheese.

---
For more information on dbt:
- Read the [introduction to dbt](https://docs.getdbt.com/docs/introduction).
- Read the [dbt viewpoint](https://docs.getdbt.com/docs/about/viewpoint).
- Join the [dbt community](http://community.getdbt.com/).
---
