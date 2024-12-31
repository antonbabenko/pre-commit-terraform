import os
from argparse import Namespace
from subprocess import PIPE

from pre_commit_terraform.terraform_checkov import invoke_cli_app
from pre_commit_terraform.terraform_checkov import per_dir_hook_unique_part
from pre_commit_terraform.terraform_checkov import replace_git_working_dir_to_repo_root
from pre_commit_terraform.terraform_checkov import run_hook_on_whole_repo


# ?
# ? replace_git_working_dir_to_repo_root
# ?
def test_replace_git_working_dir_to_repo_root_empty():
    args = []
    result = replace_git_working_dir_to_repo_root(args)
    assert result == []


def test_replace_git_working_dir_to_repo_root_no_replacement():
    args = ['arg1', 'arg2']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', 'arg2']


def test_replace_git_working_dir_to_repo_root_single_replacement(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['arg1', '__GIT_WORKING_DIR__/arg2']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', '/current/working/dir/arg2']


def test_replace_git_working_dir_to_repo_root_multiple_replacements(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['__GIT_WORKING_DIR__/arg1', 'arg2', '__GIT_WORKING_DIR__/arg3']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['/current/working/dir/arg1', 'arg2', '/current/working/dir/arg3']


def test_replace_git_working_dir_to_repo_root_partial_replacement(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['arg1', '__GIT_WORKING_DIR__/arg2', 'arg3']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', '/current/working/dir/arg2', 'arg3']


# ?
# ? invoke_cli_app
# ?
def test_invoke_cli_app_no_color(mocker):
    mock_parsed_cli_args = Namespace(
        hook_config=[],
        files=['file1.tf', 'file2.tf'],
        args=['-d', '.'],
        env_vars=['ENV_VAR=value'],
    )
    mock_env_vars = {'ENV_VAR': 'value', 'PRE_COMMIT_COLOR': 'never'}

    mock_setup_logging = mocker.patch('pre_commit_terraform.terraform_checkov.setup_logging')
    mock_expand_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.expand_env_vars',
        return_value=['-d', '.'],
    )
    mock_parse_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.parse_env_vars',
        return_value=mock_env_vars,
    )
    mock_per_dir_hook = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.per_dir_hook',
        return_value=0,
    )
    mock_run_hook_on_whole_repo = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run_hook_on_whole_repo',
        return_value=0,
    )
    mocker.patch(
        'pre_commit_terraform.terraform_checkov.is_function_defined',
        return_value=True,
    )
    mocker.patch(
        'pre_commit_terraform.terraform_checkov.is_hook_run_on_whole_repo',
        return_value=False,
    )

    result = invoke_cli_app(mock_parsed_cli_args)

    mock_setup_logging.assert_called_once()
    mock_parse_env_vars.assert_called_once_with(mock_parsed_cli_args.env_vars)
    mock_expand_env_vars.assert_called_once_with(
        mock_parsed_cli_args.args,
        {**os.environ, **mock_env_vars},
    )
    mock_per_dir_hook.assert_called_once()
    mock_run_hook_on_whole_repo.assert_not_called()
    assert result == 0


def test_invoke_cli_app_run_on_whole_repo(mocker):
    mock_parsed_cli_args = Namespace(
        hook_config=[],
        files=['file1.tf', 'file2.tf'],
        args=['-d', '.'],
        env_vars=['ENV_VAR=value'],
    )
    mock_env_vars = {'ENV_VAR': 'value'}

    mock_setup_logging = mocker.patch('pre_commit_terraform.terraform_checkov.setup_logging')
    mock_expand_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.expand_env_vars',
        return_value=['-d', '.'],
    )
    mock_parse_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.parse_env_vars',
        return_value=mock_env_vars,
    )
    mock_per_dir_hook = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.per_dir_hook',
        return_value=0,
    )
    mock_run_hook_on_whole_repo = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run_hook_on_whole_repo',
        return_value=0,
    )
    mocker.patch(
        'pre_commit_terraform.terraform_checkov.is_function_defined',
        return_value=True,
    )
    mocker.patch(
        'pre_commit_terraform.terraform_checkov.is_hook_run_on_whole_repo',
        return_value=True,
    )

    result = invoke_cli_app(mock_parsed_cli_args)

    mock_setup_logging.assert_called_once()
    mock_parse_env_vars.assert_called_once_with(mock_parsed_cli_args.env_vars)
    mock_expand_env_vars.assert_called_once_with(
        mock_parsed_cli_args.args,
        {**os.environ, **mock_env_vars},
    )
    mock_run_hook_on_whole_repo.assert_called_once()
    mock_per_dir_hook.assert_not_called()
    assert result == 0


def test_invoke_cli_app_per_dir_hook(mocker):
    mock_parsed_cli_args = Namespace(
        hook_config=[],
        files=['file1.tf', 'file2.tf'],
        args=['-d', '.'],
        env_vars=['ENV_VAR=value'],
    )
    mock_env_vars = {'ENV_VAR': 'value'}

    mock_setup_logging = mocker.patch('pre_commit_terraform.terraform_checkov.setup_logging')
    mock_expand_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.expand_env_vars',
        return_value=['-d', '.'],
    )
    mock_parse_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.parse_env_vars',
        return_value=mock_env_vars,
    )
    mock_per_dir_hook = mocker.patch(
        'pre_commit_terraform.terraform_checkov.common.per_dir_hook',
        return_value=0,
    )
    mock_run_hook_on_whole_repo = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run_hook_on_whole_repo',
        return_value=0,
    )
    mocker.patch(
        'pre_commit_terraform.terraform_checkov.is_function_defined',
        return_value=False,
    )

    result = invoke_cli_app(mock_parsed_cli_args)

    mock_setup_logging.assert_called_once()
    mock_parse_env_vars.assert_called_once_with(mock_parsed_cli_args.env_vars)
    mock_expand_env_vars.assert_called_once_with(
        mock_parsed_cli_args.args,
        {**os.environ, **mock_env_vars},
    )
    mock_per_dir_hook.assert_called_once()
    mock_run_hook_on_whole_repo.assert_not_called()
    assert result == 0


# ?
# ? run_hook_on_whole_repo
# ?
def test_run_hook_on_whole_repo_success(mocker):
    mock_args = ['-d', '.']
    mock_env_vars = {'ENV_VAR': 'value'}
    mock_completed_process = mocker.MagicMock()
    mock_completed_process.returncode = 0
    mock_completed_process.stdout = 'Checkov output'

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run',
        return_value=mock_completed_process,
    )
    mock_sys_stdout_write = mocker.patch('sys.stdout.write')

    result = run_hook_on_whole_repo(mock_args, mock_env_vars)

    mock_run.assert_called_once_with(
        ['checkov', '-d', '.', *mock_args],
        env=mock_env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )
    mock_sys_stdout_write.assert_called_once_with('Checkov output')
    assert result == 0


def test_run_hook_on_whole_repo_failure(mocker):
    mock_args = ['-d', '.']
    mock_env_vars = {'ENV_VAR': 'value'}
    mock_completed_process = mocker.MagicMock()
    mock_completed_process.returncode = 1
    mock_completed_process.stdout = 'Checkov error output'

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run',
        return_value=mock_completed_process,
    )
    mock_sys_stdout_write = mocker.patch('sys.stdout.write')

    result = run_hook_on_whole_repo(mock_args, mock_env_vars)

    mock_run.assert_called_once_with(
        ['checkov', '-d', '.', *mock_args],
        env=mock_env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )
    mock_sys_stdout_write.assert_called_once_with('Checkov error output')
    assert result == 1


# ?
# ? per_dir_hook_unique_part
# ?
def test_per_dir_hook_unique_part_success(mocker):
    tf_path = '/usr/local/bin/terraform'
    dir_path = 'test_dir'
    args = ['-d', '.']
    env_vars = {'ENV_VAR': 'value'}
    mock_completed_process = mocker.MagicMock()
    mock_completed_process.returncode = 0
    mock_completed_process.stdout = 'Checkov output'

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run',
        return_value=mock_completed_process,
    )
    mock_sys_stdout_write = mocker.patch('sys.stdout.write')

    result = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)

    mock_run.assert_called_once_with(
        ['checkov', '-d', dir_path, *args],
        env=env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )
    mock_sys_stdout_write.assert_called_once_with('Checkov output')
    assert result == 0


def test_per_dir_hook_unique_part_failure(mocker):
    tf_path = '/usr/local/bin/terraform'
    dir_path = 'test_dir'
    args = ['-d', '.']
    env_vars = {'ENV_VAR': 'value'}
    mock_completed_process = mocker.MagicMock()
    mock_completed_process.returncode = 1
    mock_completed_process.stdout = 'Checkov error output'

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_checkov.run',
        return_value=mock_completed_process,
    )
    mock_sys_stdout_write = mocker.patch('sys.stdout.write')

    result = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)

    mock_run.assert_called_once_with(
        ['checkov', '-d', dir_path, *args],
        env=env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )
    mock_sys_stdout_write.assert_called_once_with('Checkov error output')
    assert result == 1
