"""Argument parser initialization logic.

This defines helpers for setting up both the root parser and the parsers
of all the sub-commands.
"""

from argparse import ArgumentParser

from pre_commit_terraform._cli_subcommands import SUBCOMMAND_MODULES


def populate_common_argument_parser(parser: ArgumentParser) -> None:
    """
    Populate the argument parser with the common arguments.

    Args:
        parser (argparse.ArgumentParser): The argument parser to populate.
    """
    parser.add_argument(
        '-a',
        '--args',
        action='append',
        help='Arguments that configure wrapped tool behavior',
        default=[],
    )
    parser.add_argument(
        '-h',
        '--hook-config',
        action='append',
        help='Arguments that configure hook behavior',
        default=[],
    )
    parser.add_argument(
        '-i',
        '--tf-init-args',
        '--init-args',
        action='append',
        help='Arguments for `tf init` command',
        default=[],
    )
    parser.add_argument(
        '-e',
        '--env-vars',
        '--envs',
        action='append',
        help='Setup additional Environment Variables during hook execution',
        default=[],
    )
    parser.add_argument('files', nargs='*', help='Changed files paths')


def attach_subcommand_parsers_to(root_cli_parser: ArgumentParser, /) -> None:
    """Connect all sub-command parsers to the given one.

    This functions iterates over a mapping of subcommands to their
    respective population functions, executing them to augment the
    main parser.
    """
    subcommand_parsers = root_cli_parser.add_subparsers(
        dest='check_name',
        required=True,
    )
    for subcommand_module in SUBCOMMAND_MODULES:
        subcommand_parser = subcommand_parsers.add_parser(
            subcommand_module.HOOK_ID,
            add_help=False,
        )
        subcommand_parser.set_defaults(
            invoke_cli_app=subcommand_module.invoke_cli_app,
        )
        populate_common_argument_parser(subcommand_parser)
        subcommand_module.populate_hook_specific_argument_parser(subcommand_parser)


def initialize_argument_parser() -> ArgumentParser:
    """
    Parse the command line arguments and return the parsed arguments.

    Return the root argument parser with sub-commands.

    """
    root_cli_parser = ArgumentParser(prog=f'python -m {__package__ !s}')
    attach_subcommand_parsers_to(root_cli_parser)
    return root_cli_parser


__all__ = ('initialize_argument_parser',)
