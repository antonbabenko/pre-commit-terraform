"""A runpy-style CLI entry-point module."""

from sys import argv, exit as exit_with_return_code

from ._cli import invoke_cli_app


return_code = invoke_cli_app(argv[1:])
exit_with_return_code(return_code)
