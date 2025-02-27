"""Outer CLI layer of the app interface."""

import sys
from typing import cast as cast_to

from ._cli_parsing import initialize_argument_parser
from ._errors import PreCommitTerraformBaseError
from ._errors import PreCommitTerraformExit
from ._errors import PreCommitTerraformRuntimeError
from ._structs import ReturnCode
from ._types import CLIAppEntryPointCallableType
from ._types import ReturnCodeType


def invoke_cli_app(cli_args: list[str]) -> ReturnCodeType:
    """Run the entry-point of the CLI app.

    Includes initializing parsers of all the sub-apps and
    choosing what to execute.

    Returns:
        ReturnCodeType: The return code of the app.

    """
    root_cli_parser = initialize_argument_parser()
    parsed_cli_args = root_cli_parser.parse_args(cli_args)
    invoke_cli_app = cast_to(
        # FIXME: attempt typing per https://stackoverflow.com/a/75666611/595220  # noqa: TD001, TD002, TD003, FIX001, E501
        'CLIAppEntryPointCallableType',
        parsed_cli_args.invoke_cli_app,
    )

    try:
        return invoke_cli_app(parsed_cli_args)
    except PreCommitTerraformExit as exit_err:
        print(f'App exiting: {exit_err !s}', file=sys.stderr)  # noqa: T201 FIXME
        raise
    except PreCommitTerraformRuntimeError as unhandled_exc:
        print(  # noqa: T201 FIXME
            f'App execution took an unexpected turn: {unhandled_exc !s}. Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR
    except PreCommitTerraformBaseError as unhandled_exc:
        print(  # noqa: T201 FIXME
            f'A surprising exception happened: {unhandled_exc !s}. Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR
    except KeyboardInterrupt as ctrl_c_exc:
        print(  # noqa: T201 FIXME
            f'User-initiated interrupt: {ctrl_c_exc !s}. Exiting...',
            file=sys.stderr,
        )
        return ReturnCode.ERROR


__all__ = ('invoke_cli_app',)
