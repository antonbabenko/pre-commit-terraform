"""
Here located common functions for hooks.

It not executed directly, but imported by other hooks.
"""

from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Sequence
from typing import Callable

logger = logging.getLogger(__name__)


def setup_logging() -> None:
    """
    Set up the logging configuration based on the value of the 'PCT_LOG' environment variable.

    The 'PCT_LOG' environment variable determines the logging level to be used.
    The available levels are:
    - 'error': Only log error messages.
    - 'warn' or 'warning': Log warning messages and above.
    - 'info': Log informational messages and above.
    - 'debug': Log debug messages and above.

    If the 'PCT_LOG' environment variable is not set or has an invalid value,
    the default logging level is 'warning'.
    """
    log_level = {
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG,
    }[os.environ.get('PCT_LOG', 'warning').lower()]

    log_format = '%(levelname)s:%(funcName)s:%(message)s'
    if log_level == logging.DEBUG:
        log_format = (
            '\n%(levelname)s:\t%(asctime)s.%(msecs)03d %(filename)s:%(lineno)s -> %(funcName)s()'
            + '\n%(message)s'
        )

    logging.basicConfig(level=log_level, format=log_format, datefmt='%H:%M:%S')


def parse_env_vars(env_var_strs: list[str]) -> dict[str, str]:
    """
    Expand environment variables definition into their values in '--args'.

    Args:
        env_var_strs (list[str]): A list of environment variable strings in the format "name=value".

    Returns:
        dict[str, str]: A dictionary mapping variable names to their corresponding values.
    """
    env_var_dict = {}

    for env_var_str in env_var_strs:
        name, value = env_var_str.split('=', 1)  # noqa: WPS110 # 'value' is valid var name here
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]  # noqa: WPS110 # 'value' is valid var name here
        env_var_dict[name] = value

    return env_var_dict


def parse_cmdline(
    argv: Sequence[str] | None = None,
) -> tuple[list[str], list[str], list[str], list[str], list[str]]:  # noqa: WPS221
    """
    Parse the command line arguments and return a tuple containing the parsed values.

    Args:
        argv (Sequence[str] | None): The command line arguments to parse.
            If None, the arguments from sys.argv will be used.

    Returns:
        A tuple containing the parsed values:
        - args (list[str]): Arguments that configure wrapped tool behavior.
        - hook_config (list[str]): Arguments that configure hook behavior.
        - files (list[str]): File paths on which we should run the hook.
        - tf_init_args (list[str]): Arguments for `terraform init` command.
        - env_vars (list[str]): Custom environment variable strings in the format "name=value".
    """
    parser = argparse.ArgumentParser(
        add_help=False,  # Allow the use of `-h` for compatibility with the Bash version of the hook
    )
    parser.add_argument('-a', '--args', action='append', help='Arguments')
    parser.add_argument('-h', '--hook-config', action='append', help='Hook Config')
    parser.add_argument('-i', '--tf-init-args', '--init-args', action='append', help='Init Args')
    parser.add_argument('-e', '--env-vars', '--envs', action='append', help='Environment Variables')
    parser.add_argument('FILES', nargs='*', help='Files')

    parsed_args = parser.parse_args(argv)

    args = parsed_args.args or []
    hook_config = parsed_args.hook_config or []
    files = parsed_args.FILES or []
    tf_init_args = parsed_args.tf_init_args or []
    env_vars = parsed_args.env_vars or []

    logger.debug(
        'Parsed values:\nargs: %r\nhook_config: %r\nfiles: %r\ntf_init_args: %r\nenv_vars: %r',
        args,
        hook_config,
        files,
        tf_init_args,
        env_vars,
    )

    return args, hook_config, files, tf_init_args, env_vars


def _get_unique_dirs(files: list[str]) -> set[str]:
    """
    Get unique directories from a list of files.

    Args:
        files: list of file paths.

    Returns:
        Set of unique directories.
    """
    unique_dirs = set()

    for file_path in files:
        dir_path = os.path.dirname(file_path)
        unique_dirs.add(dir_path)

    return unique_dirs


def expand_env_vars(args: list[str], env_vars: dict[str, str]) -> list[str]:
    """
    Expand environment variables definition into their values in '--args'.

    Support expansion only for ${ENV_VAR} vars, not $ENV_VAR.

    Args:
        args: The arguments to expand environment variables in.
        env_vars: The environment variables to expand.

    Returns:
        The arguments with expanded environment variables.
    """
    expanded_args = []

    for arg in args:
        for env_var_name, env_var_value in env_vars.items():
            if f'${{{env_var_name}}}' in arg:
                logger.info('Expanding ${%s} in "%s"', env_var_name, arg)
                arg = arg.replace(f'${{{env_var_name}}}', env_var_value)
                logger.debug('After ${%s} expansion: "%s"', env_var_name, arg)

        expanded_args.append(arg)

    return expanded_args


def per_dir_hook(
    files: list[str],
    args: list[str],
    env_vars: dict[str, str],
    per_dir_hook_unique_part: Callable[[str, list[str], dict[str, str]], int],  # noqa: WPS221
) -> int:
    """
    Run hook boilerplate logic which is common to hooks, that run on per dir basis.

    Args:
        files: The list of files to run the hook against.
        args: The arguments to pass to the hook.
        env_vars: The environment variables to pass to the hook.
        per_dir_hook_unique_part: Function with unique part that is specific to running hook.

    Returns:
        The exit code of the hook execution for all directories.
    """
    # consume modified files passed from pre-commit so that
    # hook runs against only those relevant directories
    unique_dirs = _get_unique_dirs(files)

    final_exit_code = 0
    for dir_path in unique_dirs:
        exit_code = per_dir_hook_unique_part(dir_path, args, env_vars)

        if exit_code != 0:
            final_exit_code = exit_code

    return final_exit_code
