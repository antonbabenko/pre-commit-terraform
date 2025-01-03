from argparse import ArgumentParser

import pytest

from pre_commit_terraform._cli_parsing import attach_subcommand_parsers_to
from pre_commit_terraform._cli_parsing import initialize_argument_parser
from pre_commit_terraform._cli_parsing import populate_common_argument_parser


# ?
# ? populate_common_argument_parser
# ?
def test_populate_common_argument_parser(mocker):
    parser = ArgumentParser(add_help=False)
    populate_common_argument_parser(parser)
    args = parser.parse_args(
        ['-a', 'arg1', '-h', 'hook1', '-i', 'init1', '-e', 'env1', 'file1', 'file2'],
    )

    assert args.args == ['arg1']
    assert args.hook_config == ['hook1']
    assert args.tf_init_args == ['init1']
    assert args.env_vars_strs == ['env1']
    assert args.files == ['file1', 'file2']


def test_populate_common_argument_parser_defaults(mocker):
    parser = ArgumentParser(add_help=False)
    populate_common_argument_parser(parser)
    args = parser.parse_args([])

    assert args.args == []
    assert args.hook_config == []
    assert args.tf_init_args == []
    assert args.env_vars_strs == []
    assert args.files == []


def test_populate_common_argument_parser_multiple_values(mocker):
    parser = ArgumentParser(add_help=False)
    populate_common_argument_parser(parser)
    args = parser.parse_args(
        [
            '-a',
            'arg1',
            '-a',
            'arg2',
            '-h',
            'hook1',
            '-h',
            'hook2',
            '-i',
            'init1',
            '-i',
            'init2',
            '-e',
            'env1',
            '-e',
            'env2',
            'file1',
            'file2',
        ],
    )

    assert args.args == ['arg1', 'arg2']
    assert args.hook_config == ['hook1', 'hook2']
    assert args.tf_init_args == ['init1', 'init2']
    assert args.env_vars_strs == ['env1', 'env2']
    assert args.files == ['file1', 'file2']


# ?
# ? attach_subcommand_parsers_to
# ?
def test_attach_subcommand_parsers_to(mocker):
    parser = ArgumentParser(add_help=False)
    mock_subcommand_module = mocker.MagicMock()
    mock_subcommand_module.HOOK_ID = 'mock_hook'
    mock_subcommand_module.invoke_cli_app = mocker.Mock()
    mock_subcommand_module.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch('pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES', [mock_subcommand_module])

    attach_subcommand_parsers_to(parser)

    args = parser.parse_args(
        ['mock_hook', '-a', 'arg1', '-h', 'hook1', '-i', 'init1', '-e', 'env1', 'file1', 'file2'],
    )

    assert args.check_name == 'mock_hook'
    assert args.args == ['arg1']
    assert args.hook_config == ['hook1']
    assert args.tf_init_args == ['init1']
    assert args.env_vars_strs == ['env1']
    assert args.files == ['file1', 'file2']
    assert args.invoke_cli_app == mock_subcommand_module.invoke_cli_app

    mock_subcommand_module.populate_hook_specific_argument_parser.assert_called_once()


def test_attach_subcommand_parsers_to_no_args(mocker):
    parser = ArgumentParser(add_help=False)
    mock_subcommand_module = mocker.MagicMock()
    mock_subcommand_module.HOOK_ID = 'mock_hook'
    mock_subcommand_module.invoke_cli_app = mocker.Mock()
    mock_subcommand_module.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch('pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES', [mock_subcommand_module])

    attach_subcommand_parsers_to(parser)

    with pytest.raises(SystemExit):
        parser.parse_args([])


def test_attach_subcommand_parsers_to_multiple_subcommands(mocker):
    parser = ArgumentParser(add_help=False)
    mock_subcommand_module1 = mocker.MagicMock()
    mock_subcommand_module1.HOOK_ID = 'mock_hook1'
    mock_subcommand_module1.invoke_cli_app = mocker.Mock()
    mock_subcommand_module1.populate_hook_specific_argument_parser = mocker.Mock()

    mock_subcommand_module2 = mocker.MagicMock()
    mock_subcommand_module2.HOOK_ID = 'mock_hook2'
    mock_subcommand_module2.invoke_cli_app = mocker.Mock()
    mock_subcommand_module2.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch(
        'pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES',
        [mock_subcommand_module1, mock_subcommand_module2],
    )

    attach_subcommand_parsers_to(parser)

    args1 = parser.parse_args(['mock_hook1', '-a', 'arg1'])
    assert args1.check_name == 'mock_hook1'
    assert args1.args == ['arg1']
    assert args1.invoke_cli_app == mock_subcommand_module1.invoke_cli_app

    args2 = parser.parse_args(['mock_hook2', '-a', 'arg2'])
    assert args2.check_name == 'mock_hook2'
    assert args2.args == ['arg2']
    assert args2.invoke_cli_app == mock_subcommand_module2.invoke_cli_app

    mock_subcommand_module1.populate_hook_specific_argument_parser.assert_called_once()
    mock_subcommand_module2.populate_hook_specific_argument_parser.assert_called_once()


# ?
# ? initialize_argument_parser
# ?
def test_initialize_argument_parser(mocker):
    mock_subcommand_module = mocker.MagicMock()
    mock_subcommand_module.HOOK_ID = 'mock_hook'
    mock_subcommand_module.invoke_cli_app = mocker.Mock()
    mock_subcommand_module.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch('pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES', [mock_subcommand_module])

    parser = initialize_argument_parser()
    assert isinstance(parser, ArgumentParser)

    args = parser.parse_args(
        ['mock_hook', '-a', 'arg1', '-h', 'hook1', '-i', 'init1', '-e', 'env1', 'file1', 'file2'],
    )

    assert args.check_name == 'mock_hook'
    assert args.args == ['arg1']
    assert args.hook_config == ['hook1']
    assert args.tf_init_args == ['init1']
    assert args.env_vars_strs == ['env1']
    assert args.files == ['file1', 'file2']
    assert args.invoke_cli_app == mock_subcommand_module.invoke_cli_app

    mock_subcommand_module.populate_hook_specific_argument_parser.assert_called_once()


def test_initialize_argument_parser_no_args(mocker):
    mock_subcommand_module = mocker.MagicMock()
    mock_subcommand_module.HOOK_ID = 'mock_hook'
    mock_subcommand_module.invoke_cli_app = mocker.Mock()
    mock_subcommand_module.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch('pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES', [mock_subcommand_module])

    parser = initialize_argument_parser()
    assert isinstance(parser, ArgumentParser)

    with pytest.raises(SystemExit):
        parser.parse_args([])


def test_initialize_argument_parser_multiple_subcommands(mocker):
    mock_subcommand_module1 = mocker.MagicMock()
    mock_subcommand_module1.HOOK_ID = 'mock_hook1'
    mock_subcommand_module1.invoke_cli_app = mocker.Mock()
    mock_subcommand_module1.populate_hook_specific_argument_parser = mocker.Mock()

    mock_subcommand_module2 = mocker.MagicMock()
    mock_subcommand_module2.HOOK_ID = 'mock_hook2'
    mock_subcommand_module2.invoke_cli_app = mocker.Mock()
    mock_subcommand_module2.populate_hook_specific_argument_parser = mocker.Mock()

    mocker.patch(
        'pre_commit_terraform._cli_parsing.SUBCOMMAND_MODULES',
        [mock_subcommand_module1, mock_subcommand_module2],
    )

    parser = initialize_argument_parser()
    assert isinstance(parser, ArgumentParser)

    args1 = parser.parse_args(['mock_hook1', '-a', 'arg1'])
    assert args1.check_name == 'mock_hook1'
    assert args1.args == ['arg1']
    assert args1.invoke_cli_app == mock_subcommand_module1.invoke_cli_app

    args2 = parser.parse_args(['mock_hook2', '-a', 'arg2'])
    assert args2.check_name == 'mock_hook2'
    assert args2.args == ['arg2']
    assert args2.invoke_cli_app == mock_subcommand_module2.invoke_cli_app

    mock_subcommand_module1.populate_hook_specific_argument_parser.assert_called_once()
    mock_subcommand_module2.populate_hook_specific_argument_parser.assert_called_once()
