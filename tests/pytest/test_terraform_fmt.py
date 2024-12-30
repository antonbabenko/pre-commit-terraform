# pylint: skip-file
import os
import sys
from subprocess import PIPE

import pytest

from pre_commit_terraform.terraform_fmt import main
from pre_commit_terraform.terraform_fmt import per_dir_hook_unique_part


@pytest.fixture
def mock_setup_logging(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.setup_logging')


@pytest.fixture
def mock_parse_cmdline(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.common.parse_cmdline')


@pytest.fixture
def mock_parse_env_vars(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.common.parse_env_vars')


@pytest.fixture
def mock_expand_env_vars(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.common.expand_env_vars')


@pytest.fixture
def mock_per_dir_hook(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.common.per_dir_hook')


@pytest.fixture
def mock_run(mocker):
    return mocker.patch('pre_commit_terraform.terraform_fmt.run')


def test_main(
    mocker,
    mock_setup_logging,
    mock_parse_cmdline,
    mock_parse_env_vars,
    mock_expand_env_vars,
    mock_per_dir_hook,
):
    mock_parse_cmdline.return_value = (['arg1'], ['hook1'], ['file1'], [], ['VAR1=value1'])
    mock_parse_env_vars.return_value = {'VAR1': 'value1'}
    mock_expand_env_vars.return_value = ['expanded_arg1']
    mock_per_dir_hook.return_value = 0

    mocker.patch.object(sys, 'argv', ['terraform_fmt.py'])
    exit_code = main(sys.argv)
    assert exit_code == 0

    mock_setup_logging.assert_called_once()
    mock_parse_cmdline.assert_called_once_with(['terraform_fmt.py'])
    mock_parse_env_vars.assert_called_once_with(['VAR1=value1'])
    mock_expand_env_vars.assert_called_once_with(['arg1'], {**os.environ, 'VAR1': 'value1'})
    mock_per_dir_hook.assert_called_once_with(
        ['hook1'],
        ['file1'],
        ['expanded_arg1'],
        {**os.environ, 'VAR1': 'value1'},
        mocker.ANY,
    )


def test_main_with_no_color(
    mocker,
    mock_setup_logging,
    mock_parse_cmdline,
    mock_parse_env_vars,
    mock_expand_env_vars,
    mock_per_dir_hook,
):
    mock_parse_cmdline.return_value = (['arg1'], ['hook1'], ['file1'], [], ['VAR1=value1'])
    mock_parse_env_vars.return_value = {'VAR1': 'value1'}
    mock_expand_env_vars.return_value = ['expanded_arg1']
    mock_per_dir_hook.return_value = 0

    mocker.patch.dict(os.environ, {'PRE_COMMIT_COLOR': 'never'})
    mocker.patch.object(sys, 'argv', ['terraform_fmt.py'])
    exit_code = main(sys.argv)
    assert exit_code == 0

    mock_setup_logging.assert_called_once()
    mock_parse_cmdline.assert_called_once_with(['terraform_fmt.py'])
    mock_parse_env_vars.assert_called_once_with(['VAR1=value1'])
    mock_expand_env_vars.assert_called_once_with(
        ['arg1', '-no-color'],
        {**os.environ, 'VAR1': 'value1'},
    )
    mock_per_dir_hook.assert_called_once_with(
        ['hook1'],
        ['file1'],
        ['expanded_arg1'],
        {**os.environ, 'VAR1': 'value1'},
        mocker.ANY,
    )


def test_per_dir_hook_unique_part(mocker, mock_run):
    tf_path = '/path/to/terraform'
    dir_path = '/path/to/dir'
    args = ['arg1', 'arg2']
    env_vars = {'VAR1': 'value1'}

    mock_completed_process = mocker.MagicMock()
    mock_completed_process.stdout = 'output'
    mock_completed_process.returncode = 0
    mock_run.return_value = mock_completed_process

    exit_code = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)
    assert exit_code == 0

    mock_run.assert_called_once_with(
        ['/path/to/terraform', 'fmt', 'arg1', 'arg2', '/path/to/dir'],
        env=env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )


def test_per_dir_hook_unique_part_with_error(mocker, mock_run):
    tf_path = '/path/to/terraform'
    dir_path = '/path/to/dir'
    args = ['arg1', 'arg2']
    env_vars = {'VAR1': 'value1'}

    mock_completed_process = mocker.MagicMock()
    mock_completed_process.stdout = 'error output'
    mock_completed_process.returncode = 1
    mock_run.return_value = mock_completed_process

    exit_code = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)
    assert exit_code == 1

    mock_run.assert_called_once_with(
        ['/path/to/terraform', 'fmt', 'arg1', 'arg2', '/path/to/dir'],
        env=env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )


if __name__ == '__main__':
    pytest.main()
