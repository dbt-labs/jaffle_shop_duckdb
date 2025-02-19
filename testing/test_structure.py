import pytest
import glob2

@pytest.fixture
def parent_directory_structure_expected(): # TODO: add dim, fct, reports folders after testing
    return sorted(
        [
            'models/overview.md',
            'models/dimensions/dim_customers.sql',
            'models/dimensions/_models.sql',
            'models/facts/orders.sql',
            'models/facts/docs.md',
            'models/facts/_models.yml',
            'models/staging/_models.yml',
            'models/staging/stg_customers.sql', 
            'models/staging/stg_payments.sql',
            'models/staging/stg_orders.sql',
            'models/reports/_models.yml',
            'models/reports/rpt_finance.sql',
            'models/reports/rpt_sales.sql'
        ]
    )

def filter_string_list_by_substring(substring, string_list):
    return [str for str in string_list if substring in str]

def test_parent_directory_structure(parent_directory_structure_expected):
    parent_directory_structure_current = sorted(glob2.glob('models/**/*.*'))
    assert parent_directory_structure_expected == parent_directory_structure_current, \
        "Found an issue with the overall directory structure. If the issue is not shown in a more specific test when check which files are failing for more information."

def get_path_filters():
    path_filters = {
        "staging": "Found an issue with the staging directory structure. Ensure all staging models are located in a staging subdirectory and there is a _models.yml file present.",
        "reports": "Found an issue with the reports directory structure. Ensure you have both a rpt_finance and rpt_sales model as well as a _models.yml file.",
        "dimensions" : "Found an issue with dimensions folder. Ensure model is prefixed with dim_ and there is a _models.yml file present.",
        "facts" : "Found an issue with facts folder. Ensure model is prefixed with fct_ and there is a _models.yml file present."
    }
    for filter, error_message in path_filters.items():
            yield filter, error_message

@pytest.mark.parametrize(
    "path_filter_pair", get_path_filters(), ids=[i[0] for i in get_path_filters()]
)
def test_sub_directory_structure(parent_directory_structure_expected, path_filter_pair):
    path_filter, error_message = path_filter_pair
    expected_structure = filter_string_list_by_substring(path_filter, parent_directory_structure_expected)
    current_structure = sorted(glob2.glob(f'models/**/{path_filter}/**/*.*'))
    assert current_structure == expected_structure, error_message