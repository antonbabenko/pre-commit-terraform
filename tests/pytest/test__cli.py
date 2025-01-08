import pytest

from pre_commit_terraform._cli import invoke_cli_app
from pre_commit_terraform._errors import PreCommitTerraformBaseError
from pre_commit_terraform._errors import PreCommitTerraformExit
from pre_commit_terraform._errors import PreCommitTerraformRuntimeError
from pre_commit_terraform._structs import ReturnCode


def test_invoke_cli_app_success(mocker):
    mock_parsed_args = mocker.MagicMock()
    mock_parsed_args.invoke_cli_app.return_value = ReturnCode.OK

    mock_initialize_argument_parser = mocker.patch(
        'pre_commit_terraform._cli.initialize_argument_parser',
    )
    mock_initialize_argument_parser.return_value.parse_args.return_value = mock_parsed_args

    result = invoke_cli_app(['mock_arg'])

    assert result == ReturnCode.OK
    mock_parsed_args.invoke_cli_app.assert_called_once_with(mock_parsed_args)


def test_invoke_cli_app_pre_commit_terraform_exit(mocker):
    mock_parsed_args = mocker.MagicMock()
    mock_parsed_args.invoke_cli_app.side_effect = PreCommitTerraformExit('Exit error')

    mock_initialize_argument_parser = mocker.patch(
        'pre_commit_terraform._cli.initialize_argument_parser',
    )
    mock_initialize_argument_parser.return_value.parse_args.return_value = mock_parsed_args

    with pytest.raises(PreCommitTerraformExit):
        invoke_cli_app(['mock_arg'])

    mock_parsed_args.invoke_cli_app.assert_called_once_with(mock_parsed_args)


def test_invoke_cli_app_pre_commit_terraform_runtime_error(mocker):
    mock_parsed_args = mocker.MagicMock()
    mock_parsed_args.invoke_cli_app.side_effect = PreCommitTerraformRuntimeError('Runtime error')

    mock_initialize_argument_parser = mocker.patch(
        'pre_commit_terraform._cli.initialize_argument_parser',
    )
    mock_initialize_argument_parser.return_value.parse_args.return_value = mock_parsed_args

    result = invoke_cli_app(['mock_arg'])

    assert result == ReturnCode.ERROR
    mock_parsed_args.invoke_cli_app.assert_called_once_with(mock_parsed_args)


def test_invoke_cli_app_pre_commit_terraform_base_error(mocker):
    mock_parsed_args = mocker.MagicMock()
    mock_parsed_args.invoke_cli_app.side_effect = PreCommitTerraformBaseError('Base error')

    mock_initialize_argument_parser = mocker.patch(
        'pre_commit_terraform._cli.initialize_argument_parser',
    )
    mock_initialize_argument_parser.return_value.parse_args.return_value = mock_parsed_args

    result = invoke_cli_app(['mock_arg'])

    assert result == ReturnCode.ERROR
    mock_parsed_args.invoke_cli_app.assert_called_once_with(mock_parsed_args)


def test_invoke_cli_app_keyboard_interrupt(mocker):
    mock_parsed_args = mocker.MagicMock()
    mock_parsed_args.invoke_cli_app.side_effect = KeyboardInterrupt('Interrupt')

    mock_initialize_argument_parser = mocker.patch(
        'pre_commit_terraform._cli.initialize_argument_parser',
    )
    mock_initialize_argument_parser.return_value.parse_args.return_value = mock_parsed_args

    result = invoke_cli_app(['mock_arg'])

    assert result == ReturnCode.ERROR
    mock_parsed_args.invoke_cli_app.assert_called_once_with(mock_parsed_args)
