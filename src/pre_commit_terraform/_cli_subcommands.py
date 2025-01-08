"""A CLI sub-commands organization module."""

from pre_commit_terraform import terraform_docs_replace
from pre_commit_terraform._types import CLISubcommandModuleProtocol

SUBCOMMAND_MODULES: tuple[CLISubcommandModuleProtocol, ...] = (terraform_docs_replace,)


__all__ = ('SUBCOMMAND_MODULES',)
