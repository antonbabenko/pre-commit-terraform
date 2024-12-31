"""Outer CLI layer of the app interface."""

from sys import stderr

from pre_commit_terraform._cli_parsing import initialize_argument_parser
from pre_commit_terraform._errors import PreCommitTerraformBaseError
from pre_commit_terraform._errors import PreCommitTerraformExit
from pre_commit_terraform._errors import PreCommitTerraformRuntimeError
from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform._types import ReturnCodeType


def invoke_cli_app(cli_args: list[str]) -> ReturnCodeType:
    """Run the entry-point of the CLI app.

    Includes initializing parsers of all the sub-apps and
    choosing what to execute.
    """
    root_cli_parser = initialize_argument_parser()
    parsed_cli_args = root_cli_parser.parse_args(cli_args)

    try:
        return parsed_cli_args.invoke_cli_app(parsed_cli_args)
    except PreCommitTerraformExit as exit_err:
        print(f'App exiting: {exit_err !s}', file=stderr)
        raise
    except PreCommitTerraformRuntimeError as unhandled_exc:
        print(
            f'App execution took an unexpected turn: {unhandled_exc !s}. Exiting...',
            file=stderr,
        )
        return ReturnCode.ERROR
    except PreCommitTerraformBaseError as unhandled_exc:
        print(
            f'A surprising exception happened: {unhandled_exc !s}. Exiting...',
            file=stderr,
        )
        return ReturnCode.ERROR
    except KeyboardInterrupt as ctrl_c_exc:
        print(
            f'User-initiated interrupt: {ctrl_c_exc !s}. Exiting...',
            file=stderr,
        )
        return ReturnCode.ERROR


__all__ = ('invoke_cli_app',)
