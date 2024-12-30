"""Composite types for annotating in-project code."""

from argparse import ArgumentParser, Namespace
from typing import Final, Protocol

from ._structs import ReturnCode


ReturnCodeType = ReturnCode | int


class CLISubcommandModuleProtocol(Protocol):
    """A protocol for the subcommand-implementing module shape."""

    CLI_SUBCOMMAND_NAME: Final[str]
    """This constant contains a CLI."""

    def populate_argument_parser(
            self, subcommand_parser: ArgumentParser,
    ) -> None:
        """Run a module hook for populating the subcommand parser."""

    def invoke_cli_app(
            self, parsed_cli_args: Namespace,
    ) -> ReturnCodeType | int:
        """Run a module hook implementing the subcommand logic."""
        ...  # pylint: disable=unnecessary-ellipsis


__all__ = ('CLISubcommandModuleProtocol', 'ReturnCodeType')
