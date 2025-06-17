"""Terraform Docs Replace Hook.

This hook is deprecated and will be removed in the future.
Please, use 'terraform_docs' hook instead.
"""

import os

# S404 - Allow importing 'subprocess' module to call external tools
# needed by these hooks. FIXME - should be moved to separate module
# when more hooks will be introduced
import subprocess  # noqa: S404
import warnings
from argparse import ArgumentParser, Namespace
from typing import Final
from typing import cast as cast_to

from ._structs import ReturnCode
from ._types import ReturnCodeType


CLI_SUBCOMMAND_NAME: Final[str] = 'replace-docs'


def populate_argument_parser(subcommand_parser: ArgumentParser) -> None:
    """Populate the parser for the subcommand."""
    subcommand_parser.description = (
        'Run terraform-docs on a set of files. Follows the standard '
        'convention of pulling the documentation from main.tf in order to '
        'replace the entire README.md file each time.'
    )
    subcommand_parser.add_argument(
        '--dest',
        dest='dest',
        default='README.md',
    )
    subcommand_parser.add_argument(
        '--sort-inputs-by-required',
        dest='sort',
        action='store_true',
        help='[deprecated] use --sort-by-required instead',
    )
    subcommand_parser.add_argument(
        '--sort-by-required',
        dest='sort',
        action='store_true',
    )
    subcommand_parser.add_argument(
        '--with-aggregate-type-defaults',
        dest='aggregate',
        action='store_true',
        help='[deprecated]',
    )
    subcommand_parser.add_argument(
        'filenames',
        nargs='*',
        help='Filenames to check.',
    )


# WPS231 - Found function with too much cognitive complexity
# We will not spend time on fixing complexity in deprecated hook
def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:  # noqa: WPS231
    """Run the entry-point of the CLI app.

    Returns:
        ReturnCodeType: The return code of the app.
    """
    warnings.warn(
        '`terraform_docs_replace` hook is DEPRECATED.'
        'For migration instructions see '
        'https://github.com/antonbabenko/pre-commit-terraform/issues/248'
        '#issuecomment-1290829226',
        category=UserWarning,
        stacklevel=1,  # It's should be 2, but tests are failing w/ values >1.
        # As it's deprecated hook, it's safe to leave it as is w/o fixing it.
    )

    dirs: list[str] = []
    for filename in cast_to('list[str]', parsed_cli_args.filenames):
        if os.path.realpath(filename) not in dirs and (
            filename.endswith(('.tf', '.tfvars'))
        ):
            # PTH120 - It should use 'pathlib', but this hook is deprecated and
            # we don't want to spent time on testing fixes for it
            dirs.append(os.path.dirname(filename))  # noqa: PTH120

    retval = ReturnCode.OK

    for directory in dirs:
        try:  # noqa: WPS229 - ignore as it's deprecated hook
            proc_args = []
            proc_args.append('terraform-docs')
            if cast_to('bool', parsed_cli_args.sort):
                proc_args.append('--sort-by-required')
            proc_args.extend(
                (
                    'md',
                    f'./{directory}',
                    '>',
                    './{dir}/{dest}'.format(
                        dir=directory,
                        dest=cast_to('str', parsed_cli_args.dest),
                    ),
                ),
            )
            # S602 - 'shell=True' is insecure, but this hook is deprecated and
            # we don't want to spent time on testing fixes for it
            subprocess.check_call(' '.join(proc_args), shell=True)  # noqa: S602
        # PERF203 - try-except shouldn't be in a loop, but it's deprecated
        # hook, so leave as is
        # WPS111 - Too short var name, but it's deprecated hook, so leave as is
        except subprocess.CalledProcessError as e:  # noqa: PERF203,WPS111
            # T201,WPS421 - Leave print statement as is, as this is
            # deprecated hook
            print(e)  # noqa: T201,WPS421,WPS111
            retval = ReturnCode.ERROR
    return retval
