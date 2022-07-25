FROM mcr.microsoft.com/vscode/devcontainers/python:3.9

ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then groupmod --gid $USER_GID vscode && usermod --uid $USER_UID --gid $USER_GID vscode; fi

RUN pip3 install --upgrade pip
RUN pip3 --disable-pip-version-check --use-deprecated=legacy-resolver --no-cache-dir install \
    'duckcli==0.0.1' \
    'dbt-duckdb>=1.1.2,<1.2.0' \
    'git+https://github.com/dbt-labs/dbt-core.git@experiment/local-profiles-1.1.1#subdirectory=core' \
    'git+https://github.com/dbt-labs/dbt-core.git@experiment/local-profiles-1.1.1#subdirectory=plugins/postgres'

ENV DBT_PROFILES_DIR=/workspaces/jaffle_shop_duckdb
