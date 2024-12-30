# pylint: skip-file
import os
from os.path import join
from pathlib import Path

import pytest
import yaml

from pre_commit_terraform.common import BinaryNotFoundError
from pre_commit_terraform.common import _get_unique_dirs
from pre_commit_terraform.common import expand_env_vars
from pre_commit_terraform.common import get_tf_binary_path
from pre_commit_terraform.common import is_function_defined
from pre_commit_terraform.common import is_hook_run_on_whole_repo
from pre_commit_terraform.common import parse_cmdline
from pre_commit_terraform.common import parse_env_vars
from pre_commit_terraform.common import per_dir_hook


# ?
# ? get_unique_dirs
# ?
def test_get_unique_dirs_empty():
    files = []
    result = _get_unique_dirs(files)
    assert result == set()


def test_get_unique_dirs_single_file():
    files = [join('path', 'to', 'file1.tf')]
    result = _get_unique_dirs(files)
    assert result == {join('path', 'to')}


def test_get_unique_dirs_multiple_files_same_dir():
    files = [join('path', 'to', 'file1.tf'), join('path', 'to', 'file2.tf')]
    result = _get_unique_dirs(files)
    assert result == {join('path', 'to')}


def test_get_unique_dirs_multiple_files_different_dirs():
    files = [join('path', 'to', 'file1.tf'), join('another', 'path', 'file2.tf')]
    result = _get_unique_dirs(files)
    assert result == {join('path', 'to'), join('another', 'path')}


def test_get_unique_dirs_nested_dirs():
    files = [join('path', 'to', 'file1.tf'), join('path', 'to', 'nested', 'file2.tf')]
    result = _get_unique_dirs(files)
    assert result == {join('path', 'to'), join('path', 'to', 'nested')}


# ?
# ? per_dir_hook
# ?
@pytest.fixture
def mock_per_dir_hook_unique_part(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.per_dir_hook_unique_part')


def test_per_dir_hook_empty_files(mock_per_dir_hook_unique_part):
    hook_config = []
    files = []
    args = []
    env_vars = {}
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_not_called()


def test_per_dir_hook_single_file(mocker, mock_per_dir_hook_unique_part):
    hook_config = []
    files = [os.path.join('path', 'to', 'file1.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_called_once_with(
        mocker.ANY,  # Terraform binary path
        os.path.join('path', 'to'),
        args,
        env_vars,
    )


def test_per_dir_hook_multiple_files_same_dir(mocker, mock_per_dir_hook_unique_part):
    hook_config = []
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('path', 'to', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_called_once_with(
        mocker.ANY,  # Terraform binary path
        os.path.join('path', 'to'),
        args,
        env_vars,
    )


def test_per_dir_hook_multiple_files_different_dirs(mocker, mock_per_dir_hook_unique_part):
    hook_config = []
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('another', 'path', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 0
    expected_calls = [
        mocker.call(mocker.ANY, os.path.join('path', 'to'), args, env_vars),
        mocker.call(mocker.ANY, os.path.join('another', 'path'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


def test_per_dir_hook_nested_dirs(mocker, mock_per_dir_hook_unique_part):
    hook_config = []
    files = [
        os.path.join('path', 'to', 'file1.tf'),
        os.path.join('path', 'to', 'nested', 'file2.tf'),
    ]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 0
    expected_calls = [
        mocker.call(mocker.ANY, os.path.join('path', 'to'), args, env_vars),
        mocker.call(mocker.ANY, os.path.join('path', 'to', 'nested'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


def test_per_dir_hook_with_errors(mocker, mock_per_dir_hook_unique_part):
    hook_config = []
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('another', 'path', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.side_effect = [0, 1]
    result = per_dir_hook(hook_config, files, args, env_vars, mock_per_dir_hook_unique_part)
    assert result == 1
    expected_calls = [
        mocker.call(mocker.ANY, os.path.join('path', 'to'), args, env_vars),
        mocker.call(mocker.ANY, os.path.join('another', 'path'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


# ?
# ? parse_env_vars
# ?
def test_parse_env_vars_empty():
    env_var_strs = []
    result = parse_env_vars(env_var_strs)
    assert result == {}


def test_parse_env_vars_single():
    env_var_strs = ['VAR1=value1']
    result = parse_env_vars(env_var_strs)
    assert result == {'VAR1': 'value1'}


def test_parse_env_vars_multiple():
    env_var_strs = ['VAR1=value1', 'VAR2=value2']
    result = parse_env_vars(env_var_strs)
    assert result == {'VAR1': 'value1', 'VAR2': 'value2'}


def test_parse_env_vars_with_quotes():
    env_var_strs = ['VAR1="value1"', 'VAR2="value2"']
    result = parse_env_vars(env_var_strs)
    assert result == {'VAR1': 'value1', 'VAR2': 'value2'}


def test_parse_env_vars_with_equal_sign_in_value():
    env_var_strs = ['VAR1=value=1', 'VAR2=value=2']
    result = parse_env_vars(env_var_strs)
    assert result == {'VAR1': 'value=1', 'VAR2': 'value=2'}


def test_parse_env_vars_with_empty_value():
    env_var_strs = ['VAR1=', 'VAR2=']
    result = parse_env_vars(env_var_strs)
    assert result == {'VAR1': '', 'VAR2': ''}


def test_parse_cmdline_no_arguments():
    argv = []
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == []
    assert hook_config == []
    assert files == []
    assert tf_init_args == []
    assert env_vars_strs == []


def test_parse_cmdline_with_arguments():
    argv = ['-a', 'arg1', '-a', 'arg2', '-h', 'hook1', 'file1', 'file2']
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == ['arg1', 'arg2']
    assert hook_config == ['hook1']
    assert files == ['file1', 'file2']
    assert tf_init_args == []
    assert env_vars_strs == []


def test_parse_cmdline_with_env_vars():
    argv = ['-e', 'VAR1=value1', '-e', 'VAR2=value2']
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == []
    assert hook_config == []
    assert files == []
    assert tf_init_args == []
    assert env_vars_strs == ['VAR1=value1', 'VAR2=value2']


def test_parse_cmdline_with_tf_init_args():
    argv = ['-i', 'init1', '-i', 'init2']
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == []
    assert hook_config == []
    assert files == []
    assert tf_init_args == ['init1', 'init2']
    assert env_vars_strs == []


def test_parse_cmdline_with_files():
    argv = ['file1', 'file2']
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == []
    assert hook_config == []
    assert files == ['file1', 'file2']
    assert tf_init_args == []
    assert env_vars_strs == []


def test_parse_cmdline_with_hook_config():
    argv = ['-h', 'hook1', '-h', 'hook2']
    args, hook_config, files, tf_init_args, env_vars_strs = parse_cmdline(argv)
    assert args == []
    assert hook_config == ['hook1', 'hook2']
    assert files == []
    assert tf_init_args == []
    assert env_vars_strs == []


# ?
# ? expand_env_vars
# ?
def test_expand_env_vars_no_vars():
    args = ['arg1', 'arg2']
    env_vars = {}
    result = expand_env_vars(args, env_vars)
    assert result == ['arg1', 'arg2']


def test_expand_env_vars_single_var():
    args = ['arg1', '${VAR1}', 'arg3']
    env_vars = {'VAR1': 'value1'}
    result = expand_env_vars(args, env_vars)
    assert result == ['arg1', 'value1', 'arg3']


def test_expand_env_vars_multiple_vars():
    args = ['${VAR1}', 'arg2', '${VAR2}']
    env_vars = {'VAR1': 'value1', 'VAR2': 'value2'}
    result = expand_env_vars(args, env_vars)
    assert result == ['value1', 'arg2', 'value2']


def test_expand_env_vars_no_expansion():
    args = ['arg1', 'arg2']
    env_vars = {'VAR1': 'value1'}
    result = expand_env_vars(args, env_vars)
    assert result == ['arg1', 'arg2']


def test_expand_env_vars_partial_expansion():
    args = ['arg1', '${VAR1}', '${VAR2}']
    env_vars = {'VAR1': 'value1'}
    result = expand_env_vars(args, env_vars)
    assert result == ['arg1', 'value1', '${VAR2}']


def test_expand_env_vars_with_special_chars():
    args = ['arg1', '${VAR_1}', 'arg3']
    env_vars = {'VAR_1': 'value1'}
    result = expand_env_vars(args, env_vars)
    assert result == ['arg1', 'value1', 'arg3']


# ?
# ? get_tf_binary_path
# ?
def test_get_tf_binary_path_from_hook_config():
    hook_config = ['--tf-path=/custom/path/to/terraform']
    result = get_tf_binary_path(hook_config)
    assert result == '/custom/path/to/terraform'


def test_get_tf_binary_path_from_pct_tfpath_env_var(mocker):
    hook_config = []
    mocker.patch.dict(os.environ, {'PCT_TFPATH': '/env/path/to/terraform'})
    result = get_tf_binary_path(hook_config)
    assert result == '/env/path/to/terraform'


def test_get_tf_binary_path_from_terragrunt_tfpath_env_var(mocker):
    hook_config = []
    mocker.patch.dict(os.environ, {'TERRAGRUNT_TFPATH': '/env/path/to/terragrunt'})
    result = get_tf_binary_path(hook_config)
    assert result == '/env/path/to/terragrunt'


def test_get_tf_binary_path_from_system_path_terraform(mocker):
    hook_config = []
    mocker.patch('shutil.which', return_value='/usr/local/bin/terraform')
    result = get_tf_binary_path(hook_config)
    assert result == '/usr/local/bin/terraform'


def test_get_tf_binary_path_from_system_path_tofu(mocker):
    hook_config = []
    mocker.patch('shutil.which', side_effect=[None, '/usr/local/bin/tofu'])
    result = get_tf_binary_path(hook_config)
    assert result == '/usr/local/bin/tofu'


def test_get_tf_binary_path_not_found(mocker):
    hook_config = []
    mocker.patch('shutil.which', return_value=None)
    with pytest.raises(
        BinaryNotFoundError,
        match='Neither Terraform nor OpenTofu binary could be found. Please either set the "--tf-path"'
        + ' hook configuration argument, or set the "PCT_TFPATH" environment variable, or set the'
        + ' "TERRAGRUNT_TFPATH" environment variable, or install Terraform or OpenTofu globally.',
    ):
        get_tf_binary_path(hook_config)


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
