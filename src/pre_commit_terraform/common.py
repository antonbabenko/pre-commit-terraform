"""
Here located common functions for hooks.

It not executed directly, but imported by other hooks.
"""

from __future__ import annotations

import argparse
import logging
import os
import re
import shutil
import subprocess
from collections.abc import Sequence
from pathlib import Path
from typing import Callable

import yaml

logger = logging.getLogger(__name__)


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

    Raises:
        ValueError: If no files are provided.
    """
    parser = argparse.ArgumentParser(
        add_help=False,  # Allow the use of `-h` for compatibility with the Bash version of the hook
    )
    parser.add_argument('-a', '--args', action='append', help='Arguments', default=[])
    parser.add_argument('-h', '--hook-config', action='append', help='Hook Config', default=[])
    parser.add_argument(
        '-i',
        '--tf-init-args',
        '--init-args',
        action='append',
        help='TF Init Args',
        default=[],
    )
    parser.add_argument(
        '-e',
        '--env-vars',
        '--envs',
        action='append',
        help='Environment Variables',
        default=[],
    )
    parser.add_argument('files', nargs='*', help='Files')

    parsed_args = parser.parse_args(argv)

    if parsed_args.files is None:
        raise ValueError('No files provided')

    logger.debug(
        'Parsed values:\nargs: %r\nhook_config: %r\nfiles: %r\ntf_init_args: %r\nenv_vars: %r',
        parsed_args.args,
        parsed_args.hook_config,
        parsed_args.files,
        parsed_args.tf_init_args,
        parsed_args.env_vars,
    )

    return (
        parsed_args.args,
        parsed_args.hook_config,
        parsed_args.files,
        parsed_args.tf_init_args,
        parsed_args.env_vars,
    )


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
    hook_config: list[str],
    files: list[str],
    args: list[str],
    env_vars: dict[str, str],
    per_dir_hook_unique_part: Callable[[str, str, list[str], dict[str, str]], int],  # noqa: WPS221
) -> int:
    """
    Run hook boilerplate logic which is common to hooks, that run on per dir basis.

    Args:
        hook_config: Arguments that configure hook behavior.
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

    tf_path = get_tf_binary_path(hook_config)

    logger.debug(
        'Iterate per_dir_hook_unique_part with values:'
        + '\ntf_path: %s\nunique_dirs: %r\nargs: %r\nenv_vars: %r',
        tf_path,
        unique_dirs,
        args,
        env_vars,
    )
    final_exit_code = 0
    for dir_path in unique_dirs:
        exit_code = per_dir_hook_unique_part(tf_path, dir_path, args, env_vars)

        if exit_code != 0:
            final_exit_code = exit_code

    return final_exit_code


class BinaryNotFoundError(Exception):
    """Exception raised when neither Terraform nor OpenTofu binary could be found."""


def get_tf_binary_path(hook_config: list[str]) -> str:
    """
    Get Terraform/OpenTofu binary path.

    Allows user to set the path to custom Terraform or OpenTofu binary.

    Args:
        hook_config (list[str]): Arguments that configure hook behavior.

    Environment Variables:
        PCT_TFPATH: Path to Terraform or OpenTofu binary.
        TERRAGRUNT_TFPATH: Path to Terraform or OpenTofu binary provided by Terragrunt.

    Returns:
        str: The path to the Terraform or OpenTofu binary.

    Raises:
        BinaryNotFoundError: If neither Terraform nor OpenTofu binary could be found.

    """
    hook_config_tf_path = None

    for config in hook_config:
        if config.startswith('--tf-path='):
            hook_config_tf_path = config.split('=', 1)[1].rstrip(';')
            break

    # direct hook config, has the highest precedence
    if hook_config_tf_path:
        return hook_config_tf_path

    # environment variable
    pct_tfpath = os.getenv('PCT_TFPATH')
    if pct_tfpath:
        return pct_tfpath

    # Maybe there is a similar setting for Terragrunt already
    terragrunt_tfpath = os.getenv('TERRAGRUNT_TFPATH')
    if terragrunt_tfpath:
        return terragrunt_tfpath

    # check if Terraform binary is available
    terraform_path = shutil.which('terraform')
    if terraform_path:
        return terraform_path

    # finally, check if Tofu binary is available
    tofu_path = shutil.which('tofu')
    if tofu_path:
        return tofu_path

    # If no binary is found, raise an exception
    raise BinaryNotFoundError(
        'Neither Terraform nor OpenTofu binary could be found. Please either set the "--tf-path"'
        + ' hook configuration argument, or set the "PCT_TFPATH" environment variable, or set the'
        + ' "TERRAGRUNT_TFPATH" environment variable, or install Terraform or OpenTofu globally.',
    )


# ?
# ? Related to run_hook_on_whole_repo functions
# ?
def is_function_defined(func_name: str, scope: dict) -> bool:
    """
    Check if a function is defined in the global scope.

    Args:
        func_name (str): The name of the function to check.
        scope (dict): The scope (usually globals()) to check in.

    Returns:
        bool: True if the function is defined, False otherwise.
    """
    is_defined = func_name in scope
    is_callable = callable(scope[func_name]) if is_defined else False

    logger.debug(
        'Checking if "%s":\n1. Defined in hook: %s\n2. Is it callable: %s',
        func_name,
        is_defined,
        is_callable,
    )

    return is_defined and is_callable


def is_hook_run_on_whole_repo(hook_id: str, file_paths: list[str]) -> bool:
    """
    Check if the hook is run on the whole repository.

    Args:
        hook_id (str): The ID of the hook.
        file_paths: The list of files paths.

    Returns:
        bool: True if the hook is run on the whole repository, False otherwise.

    Raises:
        ValueError: If the hook ID is not found in the .pre-commit-hooks.yaml file.
    """
    logger.debug('Hook ID: %s', hook_id)

    # Get the directory containing `.pre-commit-hooks.yaml` file
    git_repo_root = Path(__file__).resolve().parents[5]
    hook_config_path = os.path.join(git_repo_root, '.pre-commit-hooks.yaml')

    logger.debug('Hook config path: %s', hook_config_path)

    # Read the .pre-commit-hooks.yaml file
    with open(hook_config_path, 'r', encoding='utf-8') as pre_commit_hooks_yaml:
        hooks_config = yaml.safe_load(pre_commit_hooks_yaml)

    # Get the included and excluded file patterns for the given hook_id
    for hook in hooks_config:
        if hook['id'] == hook_id:
            included_pattern = re.compile(hook.get('files', ''))
            excluded_pattern = re.compile(hook.get('exclude', ''))
            break
    else:
        raise ValueError(f'Hook ID "{hook_id}" not found in .pre-commit-hooks.yaml')

    logger.debug(
        'Included files pattern: %s\nExcluded files pattern: %s',
        included_pattern,
        excluded_pattern,
    )
    # S607 disabled as we need to maintain ability to call git command no matter where it located.
    git_ls_files_cmd = ['git', 'ls-files']  # noqa: S607
    # Get the sorted list of all files that can be checked using `git ls-files`
    git_ls_file_paths = subprocess.check_output(git_ls_files_cmd, text=True).splitlines()

    if excluded_pattern:
        all_file_paths_that_can_be_checked = [
            file_path
            for file_path in git_ls_file_paths
            if included_pattern.search(file_path) and not excluded_pattern.search(file_path)
        ]
    else:
        all_file_paths_that_can_be_checked = [
            file_path for file_path in git_ls_file_paths if included_pattern.search(file_path)
        ]

    # Get the sorted list of files passed to the hook
    file_paths_to_check = sorted(file_paths)
    logger.debug(
        'Files to check:\n%s\n\nAll files that can be checked:\n%s\n\nIdentical lists: %s',
        file_paths_to_check,
        all_file_paths_that_can_be_checked,
        file_paths_to_check == all_file_paths_that_can_be_checked,
    )
    # Compare the sorted lists of file
    return file_paths_to_check == all_file_paths_that_can_be_checked
