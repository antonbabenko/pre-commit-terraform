import os
import subprocess
from argparse import Namespace

import pytest

from pre_commit_terraform.terraform_fmt import invoke_cli_app
from pre_commit_terraform.terraform_fmt import per_dir_hook_unique_part


@pytest.fixture
def mock_parsed_cli_args():
    return Namespace(
        hook_config=[],
        files=['file1.tf', 'file2.tf'],
        args=['-diff'],
        env_vars=['ENV_VAR=value'],
    )


@pytest.fixture
def mock_env_vars():
    return {'ENV_VAR': 'value', 'PRE_COMMIT_COLOR': 'always'}


def test_invoke_cli_app(mocker, mock_parsed_cli_args, mock_env_vars):
    mock_setup_logging = mocker.patch('pre_commit_terraform.terraform_fmt.setup_logging')
    mock_expand_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_fmt.common.expand_env_vars',
        return_value=['-diff'],
    )
    mock_parse_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_fmt.common.parse_env_vars',
        return_value=mock_env_vars,
    )
    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_fmt.run',
        return_value=subprocess.CompletedProcess(
            args=['terraform', 'fmt'],
            returncode=0,
            stdout='Formatted output',
        ),
    )

    result = invoke_cli_app(mock_parsed_cli_args)

    mock_setup_logging.assert_called_once()
    mock_parse_env_vars.assert_called_once_with(mock_parsed_cli_args.env_vars)
    mock_expand_env_vars.assert_called_once_with(
        mock_parsed_cli_args.args,
        {**os.environ, **mock_env_vars},
    )
    mock_run.assert_called_once()

    assert result == 0


def test_per_dir_hook_unique_part(mocker):
    tf_path = '/usr/local/bin/terraform'
    dir_path = 'test_dir'
    args = ['-diff']
    env_vars = {'ENV_VAR': 'value'}

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_fmt.run',
        return_value=subprocess.CompletedProcess(args, 0, stdout='Formatted output'),
    )

    result = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)

    expected_cmd = [tf_path, 'fmt', *args, dir_path]
    mock_run.assert_called_once_with(
        expected_cmd,
        env=env_vars,
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )

    assert result == 0


def test_invoke_cli_app_no_color(mocker, mock_parsed_cli_args, mock_env_vars):
    mock_env_vars['PRE_COMMIT_COLOR'] = 'never'
    mock_setup_logging = mocker.patch('pre_commit_terraform.terraform_fmt.setup_logging')
    mock_expand_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_fmt.common.expand_env_vars',
        return_value=['-diff'],
    )
    mock_parse_env_vars = mocker.patch(
        'pre_commit_terraform.terraform_fmt.common.parse_env_vars',
        return_value=mock_env_vars,
    )
    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_fmt.run',
        return_value=subprocess.CompletedProcess(
            args=['terraform', 'fmt'],
            returncode=0,
            stdout='Formatted output',
        ),
    )

    result = invoke_cli_app(mock_parsed_cli_args)

    mock_setup_logging.assert_called_once()
    mock_parse_env_vars.assert_called_once_with(mock_parsed_cli_args.env_vars)
    mock_expand_env_vars.assert_called_once_with(
        mock_parsed_cli_args.args,
        {**os.environ, **mock_env_vars},
    )
    mock_run.assert_called_once()

    assert result == 0


def test_per_dir_hook_unique_part_failure(mocker):
    tf_path = '/usr/local/bin/terraform'
    dir_path = 'test_dir'
    args = ['-diff']
    env_vars = {'ENV_VAR': 'value'}

    mock_run = mocker.patch(
        'pre_commit_terraform.terraform_fmt.run',
        return_value=subprocess.CompletedProcess(args, 1, stdout='Error output'),
    )

    result = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)

    expected_cmd = [tf_path, 'fmt', *args, dir_path]
    mock_run.assert_called_once_with(
        expected_cmd,
        env=env_vars,
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )

    assert result == 1
