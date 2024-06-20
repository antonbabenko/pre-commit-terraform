"""
Here located common functions for hooks.

It not executed directly, but imported by other hooks.
"""
from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Sequence

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

    Returns:
        None
    """
    log_level = {
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG,
    }[os.environ.get('PCT_LOG', 'warning').lower()]

    logging.basicConfig(level=log_level)


def parse_env_vars(env_var_strs: list[str]) -> dict[str, str]:
    """
    Expand environment variables definition into their values in '--args'.

    Args:
        env_var_strs (list[str]): A list of environment variable strings in the format "name=value".

    Returns:
        dict[str, str]: A dictionary mapping variable names to their corresponding values.
    """
    ret = {}
    for env_var_str in env_var_strs:
        name, env_var_value = env_var_str.split('=', 1)
        if env_var_value.startswith('"') and env_var_value.endswith('"'):
            env_var_value = env_var_value[1:-1]
        ret[name] = env_var_value
    return ret


def parse_cmdline(
    argv: Sequence[str] | None = None,
) -> tuple[list[str], list[str], list[str], list[str], dict[str, str]]:
    """
    Parse the command line arguments and return a tuple containing the parsed values.

    Args:
        argv (Sequence[str] | None): The command line arguments to parse.
            If None, the arguments from sys.argv will be used.

    Returns:
        tuple[list[str], list[str], list[str], list[str], dict[str, str]]:
            A tuple containing the parsed values:
            - args (list[str]): The parsed arguments.
            - hook_config (list[str]): The parsed hook configurations.
            - files (list[str]): The parsed files.
            - tf_init_args (list[str]): The parsed Terraform initialization arguments.
            - env_var_dict (dict[str, str]): The parsed environment variables as a dictionary.
    """

    parser = argparse.ArgumentParser(
        add_help=False,  # Allow the use of `-h` for compatibility with the Bash version of the hook
    )
    parser.add_argument('-a', '--args', action='append', help='Arguments')
    parser.add_argument('-h', '--hook-config', action='append', help='Hook Config')
    parser.add_argument('-i', '--init-args', '--tf-init-args', action='append', help='Init Args')
    parser.add_argument('-e', '--envs', '--env-vars', action='append', help='Environment Variables')
    parser.add_argument('FILES', nargs='*', help='Files')

    parsed_args = parser.parse_args(argv)

    args = parsed_args.args or []
    hook_config = parsed_args.hook_config or []
    files = parsed_args.FILES or []
    tf_init_args = parsed_args.init_args or []
    env_vars = parsed_args.envs or []

    env_var_dict = parse_env_vars(env_vars)

    if hook_config:
        raise NotImplementedError('TODO: implement: hook_config')

    if tf_init_args:
        raise NotImplementedError('TODO: implement: tf_init_args')

    return args, hook_config, files, tf_init_args, env_var_dict
