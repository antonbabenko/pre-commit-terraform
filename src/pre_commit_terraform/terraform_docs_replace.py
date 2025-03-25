"""`terraform_docs_replace` hook. Deprecated."""

import os
import subprocess  # noqa: S404. We invoke cli tools
import warnings
from argparse import ArgumentParser, Namespace
from typing import cast as cast_to

from ._structs import ReturnCode
from ._types import ReturnCodeType


CLI_SUBCOMMAND_NAME: str = 'replace-docs'


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


def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:
    """Run the entry-point of the CLI app.

    Returns:
        ReturnCodeType: The return code of the app.

    """
    warnings.warn(  # noqa: B028. that's user warning, no need to show stacktrace etc.
        '`terraform_docs_replace` hook is DEPRECATED.'
        'For migration instructions see '
        'https://github.com/antonbabenko/pre-commit-terraform/issues/248'
        '#issuecomment-1290829226',
        category=UserWarning,
    )

    dirs: list[str] = []
    for filename in cast_to('list[str]', parsed_cli_args.filenames):
        if os.path.realpath(filename) not in dirs and (
            filename.endswith(('.tf', '.tfvars'))
        ):
            dirs.append(os.path.dirname(filename))  # noqa: PTH120. Legacy hook, no need to refactor

    retval = ReturnCode.OK

    for directory in dirs:
        try:
            proc_args = []
            proc_args.append('terraform-docs')
            if cast_to('bool', parsed_cli_args.sort):
                proc_args.append('--sort-by-required')
            proc_args.extend(
                (
                    'md',
                    f'./{directory}',
                    '>',
                    f"./{directory}/{cast_to('bool', parsed_cli_args.dest)}",
                ),
            )
            # We call cli tools, of course we use shell=True
            subprocess.check_call(' '.join(proc_args), shell=True)  # noqa: S602
        # Legacy hook, no need to refactor
        except subprocess.CalledProcessError as e:  # noqa: PERF203
            print(e)  # noqa: T201
            retval = ReturnCode.ERROR
    return retval
