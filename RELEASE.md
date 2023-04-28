# Release instructions

1. Install `pip-tools`:
    ```shell
    python -m pip install -r requirements-dev.txt
    ```
1. Run `pip-compile` to pin all the dependencies and update `requirements.txt`:
    ```shell
    pip-compile
    ```
1. Commit the result.
1. Open a PR.
