"""Composite types for annotating in-project code."""

from argparse import ArgumentParser, Namespace
from collections.abc import Callable
from typing import Protocol

from ._structs import ReturnCode


ReturnCodeType = ReturnCode | int
CLIAppEntryPointCallableType = Callable[[Namespace], ReturnCodeType]


class CLISubcommandModuleProtocol(Protocol):
    """A protocol for the subcommand-implementing module shape."""

    # WPS115: "Require snake_case for naming class attributes".
    # This protocol describes module shapes and not regular classes.
    # It's a valid use case as then it's used as constants:
    # "CLI_SUBCOMMAND_NAME: Final[str] = 'hook-name'"" on top level
    CLI_SUBCOMMAND_NAME: str  # noqa: WPS115
    """This constant contains a CLI."""

    def populate_argument_parser(
        self,
        subcommand_parser: ArgumentParser,
    ) -> None:
        """Run a module hook for populating the subcommand parser."""

    def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
        """Run a module hook implementing the subcommand logic."""
        ...  # pylint: disable=unnecessary-ellipsis


__all__ = ('CLISubcommandModuleProtocol', 'ReturnCodeType')
