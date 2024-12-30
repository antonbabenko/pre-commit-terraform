"""A CLI sub-commands organization module."""

from argparse import Namespace
from typing import Callable

from ._structs import ReturnCode
from .terraform_docs_replace import (
    invoke_cli_app as invoke_replace_docs_cli_app,
)


SUBCOMMAND_MAP = {
    'replace-docs': invoke_replace_docs_cli_app,
}


def choose_cli_app(
        check_name: str,
        /,
) -> Callable[[Namespace], ReturnCode | int]:
    """Return a subcommand callable by CLI argument name."""
    try:
        return SUBCOMMAND_MAP[check_name]
    except KeyError as key_err:
        raise LookupError(
            f'{key_err !s}: Unable to find a callable for '
            f'the `{check_name !s}` subcommand',
        ) from key_err


__all__ = ('choose_cli_app',)
