# Maintainer's manual

## Structure

This folder is what's called an [importable package]. It's a top-level folder
that ends up being installed into `site-packages/` of virtualenvs.

When the Git repository is `pip install`ed, this [import package] becomes
available for use within respective Python interpreter instance. It can be
imported and sub-modules can be imported through the dot-syntax. Additionally,
the modules within can import the neighboring ones using relative imports that
have a leading dot in them.

It additionally implements a [runpy interface], meaning that its name can
be passed to `python -m` to invoke the CLI. This is the primary method of
integration with the [`pre-commit` framework] and local development/testing.

The layout allows for having several Python modules wrapping third-party tools,
each having an argument parser and being a subcommand for the main CLI
interface.

## Control flow

When `python -m pre_commit_terraform` is executed, it imports `__main__.py`.
Which in turn, performs the initialization of the main argument parser and the
parsers of subcommands, followed by executing the logic defined in dedicated
subcommand modules.

## Integrating a new subcommand

1. Create a new module called `subcommand_x.py`.
2. Within that module, define two functions —
   `invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType | int` and
   `populate_argument_parser(subcommand_parser: ArgumentParser) -> None`.
   Additionally, define a module-level constant
   `CLI_SUBCOMMAND_NAME: Final[str] = 'subcommand-x'`.
3. Edit [`_cli_subcommands.py`], importing `subcommand_x` as a relative module
   and add it into the `SUBCOMMAND_MODULES` list.
4. Edit [`.pre-commit-hooks.yaml`], adding a new hook that invokes
   `python -m pre_commit_terraform subcommand-x`.

## Manual testing

Usually, having a development virtualenv where you `pip install -e .` is enough
to make it possible to invoke the CLI app. Do so first. Most source code
updates do not require running it again. But sometimes, it's needed.

Once done, you can run `python -m pre_commit_terraform` and/or
`python -m pre_commit_terraform subcommand-x` to see how it behaves. There's
`--help` and all other typical conventions one would usually expect from a
POSIX-inspired CLI app.

## DX/UX considerations

Since it's an app that can be executed outside the [`pre-commit` framework],
it is useful to check out and follow these [CLI guidelines][clig].

## Subcommand development

`populate_argument_parser()` accepts a regular instance of
[`argparse.ArgumentParser`]. Call its methods to extend the CLI arguments that
would be specific for the subcommand you are creating. Those arguments will be
available later, as an argument to the `invoke_cli_app()` function — through an
instance of [`argparse.Namespace`]. For the `CLI_SUBCOMMAND_NAME` constant,
choose `kebab-space-sub-command-style`, it does not need to be `snake_case`.

Make sure to return a `ReturnCode` instance or an integer from
`invoke_cli_app()`. Returning a non-zero value will result in the CLI app
exiting with a return code typically interpreted as an error while zero means
success. You can `import errno` to use typical POSIX error codes through their
human-readable identifiers.

Another way to interrupt the CLI app control flow is by raising an instance of
one of the in-app errors. `raise PreCommitTerraformExit` for a successful exit,
but it can be turned into an error outcome via
`raise PreCommitTerraformExit(1)`.
`raise PreCommitTerraformRuntimeError('The world is broken')` to indicate
problems within the runtime. The framework will intercept any exceptions
inheriting `PreCommitTerraformBaseError`, so they won't be presented to the
end-users.

[`.pre-commit-hooks.yaml`]: ../../.pre-commit-hooks.yaml
[`_cli_parsing.py`]: ./_cli_parsing.py
[`_cli_subcommands.py`]: ./_cli_subcommands.py
[`argparse.ArgumentParser`]:
https://docs.python.org/3/library/argparse.html#argparse.ArgumentParser
[`argparse.Namespace`]:
https://docs.python.org/3/library/argparse.html#argparse.Namespace
[clig]: https://clig.dev
[importable package]: https://docs.python.org/3/tutorial/modules.html#packages
[import package]: https://packaging.python.org/en/latest/glossary/#term-Import-Package
[`pre-commit` framework]: https://pre-commit.com
[runpy interface]: https://docs.python.org/3/library/__main__.html
