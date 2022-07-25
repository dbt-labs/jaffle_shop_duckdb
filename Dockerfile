FROM mcr.microsoft.com/vscode/devcontainers/python:3.9

ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then groupmod --gid $USER_GID vscode && usermod --uid $USER_UID --gid $USER_GID vscode; fi

RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc-dev \
    unixodbc \
    libpq-dev

COPY requirements.txt /tmp/pip-tmp/
RUN python3 -m venv venv && \
    source venv/bin/activate && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip --disable-pip-version-check --use-deprecated=legacy-resolver --no-cache-dir install -r /tmp/pip-tmp/requirements.txt
RUN  rm -rf /tmp/pip-tmp

ENV DBT_PROFILES_DIR=/dbt
