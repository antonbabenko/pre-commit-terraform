"""Tests for the high-level CLI entry point."""

from argparse import ArgumentParser
from argparse import Namespace

import pytest

from pre_commit_terraform import _cli_parsing as _cli_parsing_mod
from pre_commit_terraform._cli import invoke_cli_app
from pre_commit_terraform._errors import PreCommitTerraformBaseError
from pre_commit_terraform._errors import PreCommitTerraformExit
from pre_commit_terraform._errors import PreCommitTerraformRuntimeError
from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform._types import ReturnCodeType


pytestmark = pytest.mark.filterwarnings(
    'ignore:`terraform_docs_replace` hook is DEPRECATED.:UserWarning:'
    'pre_commit_terraform.terraform_docs_replace',
)


@pytest.mark.parametrize(
    ('raised_error', 'expected_stderr'),
    [
        pytest.param(
            PreCommitTerraformRuntimeError('sentinel'),
            'App execution took an unexpected turn: sentinel. Exiting...',
            id='app-runtime-exc',
        ),
        pytest.param(
            PreCommitTerraformBaseError('sentinel'),
            'A surprising exception happened: sentinel. Exiting...',
            id='app-base-exc',
        ),
        pytest.param(
            KeyboardInterrupt('sentinel'),
            'User-initiated interrupt: sentinel. Exiting...',
            id='ctrl-c',
        ),
    ],
)
def test_known_interrupts(
    capsys: pytest.CaptureFixture[str],
    expected_stderr: str,
    monkeypatch: pytest.MonkeyPatch,
    raised_error: BaseException,
) -> None:
    """Check that known interrupts are turned into return code 1."""

    class CustomCmdStub:
        CLI_SUBCOMMAND_NAME = 'sentinel'

        @staticmethod
        def populate_argument_parser(subcommand_parser: ArgumentParser) -> None:  # noqa: ARG004
            return None

        @staticmethod
        def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:  # noqa: ARG004
            raise raised_error

    monkeypatch.setattr(
        _cli_parsing_mod,
        'SUBCOMMAND_MODULES',
        [CustomCmdStub()],
    )

    assert invoke_cli_app(['sentinel']) == ReturnCode.ERROR

    captured_outputs = capsys.readouterr()
    assert captured_outputs.err == f'{expected_stderr !s}\n'


def test_app_exit(
    capsys: pytest.CaptureFixture[str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Check that an exit exception is re-raised."""

    class CustomCmdStub:
        CLI_SUBCOMMAND_NAME = 'sentinel'

        @staticmethod
        def populate_argument_parser(subcommand_parser: ArgumentParser) -> None:  # noqa: ARG004
            return None

        @staticmethod
        def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:  # noqa: ARG004
            err = 'sentinel'
            raise PreCommitTerraformExit(err)

    monkeypatch.setattr(
        _cli_parsing_mod,
        'SUBCOMMAND_MODULES',
        [CustomCmdStub()],
    )

    with pytest.raises(PreCommitTerraformExit, match=r'^sentinel$'):
        invoke_cli_app(['sentinel'])

    captured_outputs = capsys.readouterr()
    assert captured_outputs.err == 'App exiting: sentinel\n'
