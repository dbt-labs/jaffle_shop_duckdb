venv-activate:
	python3 -m venv venv && source venv/bin/activate

install-deps: venv-activate
	. venv/bin/activate && pip install -r requirements.txt

dbt-deps: 
	. venv/bin/activate && dbt deps

run-dbt-project-evaluator:
	. venv/bin/activate && dbt deps && dbt --warn-error build --select package:dbt_project_evaluator dbt_project_evaluator_exceptions --store-failures