from pathlib import Path

import pytest
import yaml

from pre_commit_terraform._run_on_whole_repo import is_function_defined
from pre_commit_terraform._run_on_whole_repo import is_hook_run_on_whole_repo


# ?
# ? is_function_defined
# ?
def test_is_function_defined_existing_function():
    def sample_function():
        pass

    scope = globals()
    scope['sample_function'] = sample_function

    assert is_function_defined('sample_function', scope) is True


def test_is_function_defined_non_existing_function():
    scope = globals()

    assert is_function_defined('non_existing_function', scope) is False


def test_is_function_defined_non_callable():
    non_callable = 'I am not a function'
    scope = globals()
    scope['non_callable'] = non_callable

    assert is_function_defined('non_callable', scope) is False


def test_is_function_defined_callable_object():
    class CallableObject:
        def __call__(self):
            pass

    callable_object = CallableObject()
    scope = globals()
    scope['callable_object'] = callable_object

    assert is_function_defined('callable_object', scope) is True


# ?
# ? is_hook_run_on_whole_repo
# ?
@pytest.fixture
def mock_git_ls_files():
    return [
        'environment/prd/backends.tf',
        'environment/prd/data.tf',
        'environment/prd/main.tf',
        'environment/prd/outputs.tf',
        'environment/prd/providers.tf',
        'environment/prd/variables.tf',
        'environment/prd/versions.tf',
        'environment/qa/backends.tf',
    ]


@pytest.fixture
def mock_hooks_config():
    return [{'id': 'example_hook_id', 'files': r'\.tf$', 'exclude': r'\.terraform/.*$'}]


def test_is_hook_run_on_whole_repo(mocker, mock_git_ls_files, mock_hooks_config):
    # Mock the return value of git ls-files
    mocker.patch('subprocess.check_output', return_value='\n'.join(mock_git_ls_files))
    # Mock the return value of reading the .pre-commit-hooks.yaml file
    mocker.patch('builtins.open', mocker.mock_open(read_data=yaml.dump(mock_hooks_config)))
    # Mock the Path object to return a specific path
    mock_path = mocker.patch('pathlib.Path.resolve')
    mock_path.return_value.parents.__getitem__.return_value = Path('/mocked/path')
    # Mock the read_text method of Path to return the hooks config
    mocker.patch('pathlib.Path.read_text', return_value=yaml.dump(mock_hooks_config))

    # Test case where files match the included pattern and do not match the excluded pattern
    files = [
        'environment/prd/backends.tf',
        'environment/prd/data.tf',
        'environment/prd/main.tf',
        'environment/prd/outputs.tf',
        'environment/prd/providers.tf',
        'environment/prd/variables.tf',
        'environment/prd/versions.tf',
        'environment/qa/backends.tf',
    ]
    assert is_hook_run_on_whole_repo('example_hook_id', files) is True

    # Test case where files do not match the included pattern
    files = ['environment/prd/README.md']
    assert is_hook_run_on_whole_repo('example_hook_id', files) is False

    # Test case where files match the excluded pattern
    files = ['environment/prd/.terraform/config.tf']
    assert is_hook_run_on_whole_repo('example_hook_id', files) is False

    # Test case where hook_id is not found
    with pytest.raises(
        ValueError,
        match='Hook ID "non_existing_hook_id" not found in .pre-commit-hooks.yaml',
    ):
        is_hook_run_on_whole_repo('non_existing_hook_id', files)


if __name__ == '__main__':
    pytest.main()
