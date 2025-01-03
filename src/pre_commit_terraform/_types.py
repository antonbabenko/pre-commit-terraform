"""Composite types for annotating in-project code."""

from argparse import ArgumentParser, Namespace
from collections.abc import Callable
from typing import Protocol, Union

from ._structs import ReturnCode


ReturnCodeType = Union[ReturnCode, int]  # Union instead of pipe for Python 3.9
CLIAppEntryPointCallableType = Callable[[Namespace], ReturnCodeType]


class CLISubcommandModuleProtocol(Protocol):
    """A protocol for the subcommand-implementing module shape."""

    CLI_SUBCOMMAND_NAME: str
    """This constant contains a CLI."""

    def populate_argument_parser(
            self, subcommand_parser: ArgumentParser,
    ) -> None:
        """Run a module hook for populating the subcommand parser."""

    def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
        """Run a module hook implementing the subcommand logic."""
        ...  # pylint: disable=unnecessary-ellipsis


__all__ = ('CLISubcommandModuleProtocol', 'ReturnCodeType')
