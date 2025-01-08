"""Tests for the `replace-docs` subcommand."""

from argparse import ArgumentParser, Namespace
from subprocess import CalledProcessError

import pytest
import pytest_mock

from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform.terraform_docs_replace import (
    invoke_cli_app,
    populate_argument_parser,
    subprocess as replace_docs_subprocess_mod,
)


def test_arg_parser_populated() -> None:
    """Check that `replace-docs` populates its parser."""
    test_arg_parser = ArgumentParser()
    populate_argument_parser(test_arg_parser)
    assert test_arg_parser.get_default('dest') == 'README.md'


def test_check_is_deprecated() -> None:
    """Verify that `replace-docs` shows a deprecation warning."""
    deprecation_msg_regex = (
        r'^`terraform_docs_replace` hook is DEPRECATED\.'
        'For migration.*$'
    )
    with pytest.warns(UserWarning, match=deprecation_msg_regex):
        # not `pytest.deprecated_call()` due to this being a user warning
        invoke_cli_app(Namespace(filenames=[]))


@pytest.mark.parametrize(
    ('parsed_cli_args', 'expected_cmds'),
    (
        pytest.param(Namespace(filenames=[]), [], id='no-files'),
        pytest.param(
            Namespace(
                dest='SENTINEL.md',
                filenames=['some.tf'],
                sort=False,
            ),
            ['terraform-docs md ./ > .//SENTINEL.md'],
            id='one-file',
        ),
        pytest.param(
            Namespace(
                dest='SENTINEL.md',
                filenames=['some.tf', 'thing/weird.tfvars'],
                sort=True,
            ),
            [
                'terraform-docs --sort-by-required md ./ > .//SENTINEL.md',
                'terraform-docs --sort-by-required md ./thing '
                '> ./thing/SENTINEL.md',
            ],
            id='two-sorted-files',
        ),
        pytest.param(
            Namespace(filenames=['some.thing', 'un.supported']),
            [],
            id='invalid-files',
        ),
    ),
)
@pytest.mark.filterwarnings(
    'ignore:`terraform_docs_replace` hook is DEPRECATED.:UserWarning:'
    'pre_commit_terraform.terraform_docs_replace',
)
def test_control_flow_positive(
        expected_cmds: list[str],
        mocker: pytest_mock.MockerFixture,
        monkeypatch: pytest.MonkeyPatch,
        parsed_cli_args: Namespace,
) -> None:
    """Check that the subcommand's happy path works."""
    check_call_mock = mocker.Mock()
    monkeypatch.setattr(
        replace_docs_subprocess_mod,
        'check_call',
        check_call_mock,
    )

    assert ReturnCode.OK == invoke_cli_app(parsed_cli_args)

    executed_commands = [
        cmd for ((cmd, ), _shell) in check_call_mock.call_args_list
    ]

    assert len(expected_cmds) == check_call_mock.call_count
    assert expected_cmds == executed_commands


@pytest.mark.filterwarnings(
    'ignore:`terraform_docs_replace` hook is DEPRECATED.:UserWarning:'
    'pre_commit_terraform.terraform_docs_replace',
)
def test_control_flow_negative(
        mocker: pytest_mock.MockerFixture,
        monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Check that the subcommand's error processing works."""
    parsed_cli_args = Namespace(
        dest='SENTINEL.md',
        filenames=['some.tf'],
        sort=True,
    )
    expected_cmd = 'terraform-docs --sort-by-required md ./ > .//SENTINEL.md'

    check_call_mock = mocker.Mock(
        side_effect=CalledProcessError(ReturnCode.ERROR, expected_cmd),
    )
    monkeypatch.setattr(
        replace_docs_subprocess_mod,
        'check_call',
        check_call_mock,
    )

    assert ReturnCode.ERROR == invoke_cli_app(parsed_cli_args)

    check_call_mock.assert_called_once_with(expected_cmd, shell=True)
