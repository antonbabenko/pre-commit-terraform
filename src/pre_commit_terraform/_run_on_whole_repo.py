"""Common functions to check if a hook is run on the whole repository."""

import logging
import re
import subprocess
from importlib.resources import files as access_artifacts_of

import yaml

logger = logging.getLogger(__name__)


def is_function_defined(func_name: str, scope: dict) -> bool:
    """
    Check if a function is defined in the global scope.

    Args:
        scope (dict): The scope (usually globals()) to check in.
        func_name (str): The name of the function to check.

    Returns:
        bool: True if the function is defined, False otherwise.
    """
    is_defined = func_name in scope
    is_callable = callable(scope[func_name]) if is_defined else False

    logger.debug(
        'Checking if "%s":\n1. Defined in hook: %s\n2. Is callable: %s',
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

    # Get the directory containing the packaged `.pre-commit-hooks.yaml` copy
    artifacts_root_path = access_artifacts_of('pre_commit_terraform') / '_artifacts'
    pre_commit_hooks_yaml_path = artifacts_root_path / '.pre-commit-hooks.yaml'

    logger.debug('Hook config path: %s', pre_commit_hooks_yaml_path)

    # Read the .pre-commit-hooks.yaml file
    pre_commit_hooks_yaml_txt = pre_commit_hooks_yaml_path.read_text(encoding='utf-8')
    hooks_config = yaml.safe_load(pre_commit_hooks_yaml_txt)

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
    # S607 disabled as we need to maintain ability to call git command no matter where it is located.
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
        'Files to check:\n%s\n\nAll files that can be checked:\n%s\n\nAre these lists identical: %s',
        file_paths_to_check,
        all_file_paths_that_can_be_checked,
        file_paths_to_check == all_file_paths_that_can_be_checked,
    )
    # Compare the sorted lists of files
    return file_paths_to_check == all_file_paths_that_can_be_checked
