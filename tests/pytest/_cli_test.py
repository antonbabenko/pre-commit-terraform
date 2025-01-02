"""Tests for the high-level CLI entry point."""

from argparse import ArgumentParser, Namespace
import pytest

from pre_commit_terraform import _cli_parsing as _cli_parsing_mod
from pre_commit_terraform._cli import invoke_cli_app
from pre_commit_terraform._errors import (
    PreCommitTerraformExit,
    PreCommitTerraformBaseError,
    PreCommitTerraformRuntimeError,
)
from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform._types import ReturnCodeType


pytestmark = pytest.mark.filterwarnings(
    'ignore:`terraform_docs_replace` hook is DEPRECATED.:UserWarning:'
    'pre_commit_terraform.terraform_docs_replace',
)


@pytest.mark.parametrize(
    'raised_error',
    (
        # pytest.param(PreCommitTerraformExit('sentinel'), 'App exiting: sentinel', id='app-exit'),
        pytest.param(
            PreCommitTerraformRuntimeError('sentinel'),
            id='app-runtime-exc',
        ),
        pytest.param(
            PreCommitTerraformBaseError('sentinel'),
            id='app-base-exc',
        ),
        pytest.param(
            KeyboardInterrupt('sentinel'),
            id='ctrl-c',
        ),
    ),
)
def test_known_interrupts(
        monkeypatch: pytest.MonkeyPatch,
        raised_error: BaseException,
) -> None:
    """Check that known interrupts are turned into return code 1."""
    class CustomCmdStub:
        CLI_SUBCOMMAND_NAME = 'sentinel'

        def populate_argument_parser(
                self, subcommand_parser: ArgumentParser,
        ) -> None:
            return None

        def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
            raise raised_error

    monkeypatch.setattr(
        _cli_parsing_mod,
        'SUBCOMMAND_MODULES',
        [CustomCmdStub()],
    )

    assert ReturnCode.ERROR == invoke_cli_app(['sentinel'])


def test_app_exit(monkeypatch: pytest.MonkeyPatch) -> None:
    """Check that an exit exception is re-raised."""
    class CustomCmdStub:
        CLI_SUBCOMMAND_NAME = 'sentinel'

        def populate_argument_parser(
                self, subcommand_parser: ArgumentParser,
        ) -> None:
            return None

        def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
            raise PreCommitTerraformExit('sentinel')

    monkeypatch.setattr(
        _cli_parsing_mod,
        'SUBCOMMAND_MODULES',
        [CustomCmdStub()],
    )

    with pytest.raises(PreCommitTerraformExit, match='^sentinel$'):
        invoke_cli_app(['sentinel'])
