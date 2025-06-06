"""Outer CLI layer of the app interface."""

import sys
from typing import cast as cast_to

from ._cli_parsing import initialize_argument_parser
from ._errors import (
    PreCommitTerraformBaseError,
    PreCommitTerraformExit,
    PreCommitTerraformRuntimeError,
)
from ._structs import ReturnCode
from ._types import CLIAppEntryPointCallableType, ReturnCodeType


def invoke_cli_app(cli_args: list[str]) -> ReturnCodeType:
    """Run the entry-point of the CLI app.

    Includes initializing parsers of all the sub-apps and
    choosing what to execute.

    Returns:
        ReturnCodeType: The return code of the app.

    Raises:
        PreCommitTerraformExit: If the app is exiting with error.
    """
    root_cli_parser = initialize_argument_parser()
    parsed_cli_args = root_cli_parser.parse_args(cli_args)
    invoke_cli_app = cast_to(
        # FIXME: attempt typing per https://stackoverflow.com/a/75666611/595220  # noqa: TD001, TD002, FIX001, E501 All these suppressions caused by "FIXME" comment
        'CLIAppEntryPointCallableType',
        parsed_cli_args.invoke_cli_app,
    )

    try:  # noqa: WPS225 - too many `except` cases
        return invoke_cli_app(parsed_cli_args)
    except PreCommitTerraformExit as exit_err:
        # T201,WPS421 - FIXME here and below - we will replace 'print'
        # with logging later
        print(f'App exiting: {exit_err!s}', file=sys.stderr)  # noqa: T201,WPS421
        raise
    except PreCommitTerraformRuntimeError as unhandled_exc:
        print(  # noqa: T201,WPS421
            f'App execution took an unexpected turn: {unhandled_exc!s}. '
            'Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR
    except PreCommitTerraformBaseError as unhandled_exc:
        print(  # noqa: T201,WPS421
            f'A surprising exception happened: {unhandled_exc!s}. Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR
    except KeyboardInterrupt as ctrl_c_exc:
        print(  # noqa: T201,WPS421
            f'User-initiated interrupt: {ctrl_c_exc!s}. Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR


__all__ = ('invoke_cli_app',)
