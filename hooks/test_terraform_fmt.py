import os
from os.path import join

import pytest

from hooks.terraform_fmt import get_unique_dirs
from hooks.terraform_fmt import per_dir_hook

#
# get_unique_dirs
#


def test_get_unique_dirs_empty():
    files = []
    result = get_unique_dirs(files)
    assert result == set()


def test_get_unique_dirs_single_file():
    files = [join('path', 'to', 'file1.tf')]
    result = get_unique_dirs(files)
    assert result == {join('path', 'to')}


def test_get_unique_dirs_multiple_files_same_dir():
    files = [join('path', 'to', 'file1.tf'), join('path', 'to', 'file2.tf')]
    result = get_unique_dirs(files)
    assert result == {join('path', 'to')}


def test_get_unique_dirs_multiple_files_different_dirs():
    files = [join('path', 'to', 'file1.tf'), join('another', 'path', 'file2.tf')]
    result = get_unique_dirs(files)
    assert result == {join('path', 'to'), join('another', 'path')}


def test_get_unique_dirs_nested_dirs():
    files = [join('path', 'to', 'file1.tf'), join('path', 'to', 'nested', 'file2.tf')]
    result = get_unique_dirs(files)
    assert result == {join('path', 'to'), join('path', 'to', 'nested')}


#
# per_dir_hook
#


# from unittest.mock import patch, call


@pytest.fixture
def mock_per_dir_hook_unique_part(mocker):
    return mocker.patch('hooks.terraform_fmt.per_dir_hook_unique_part')


def test_per_dir_hook_empty_files(mock_per_dir_hook_unique_part):
    files = []
    args = []
    env_vars = {}
    result = per_dir_hook(files, args, env_vars)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_not_called()


def test_per_dir_hook_single_file(mock_per_dir_hook_unique_part):
    files = [os.path.join('path', 'to', 'file1.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(files, args, env_vars)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_called_once_with(
        os.path.join('path', 'to'),
        args,
        env_vars,
    )


def test_per_dir_hook_multiple_files_same_dir(mock_per_dir_hook_unique_part):
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('path', 'to', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(files, args, env_vars)
    assert result == 0
    mock_per_dir_hook_unique_part.assert_called_once_with(
        os.path.join('path', 'to'),
        args,
        env_vars,
    )


def test_per_dir_hook_multiple_files_different_dirs(mocker, mock_per_dir_hook_unique_part):
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('another', 'path', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(files, args, env_vars)
    assert result == 0
    expected_calls = [
        mocker.call(os.path.join('path', 'to'), args, env_vars),
        mocker.call(os.path.join('another', 'path'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


def test_per_dir_hook_nested_dirs(mocker, mock_per_dir_hook_unique_part):
    files = [
        os.path.join('path', 'to', 'file1.tf'),
        os.path.join('path', 'to', 'nested', 'file2.tf'),
    ]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.return_value = 0
    result = per_dir_hook(files, args, env_vars)
    assert result == 0
    expected_calls = [
        mocker.call(os.path.join('path', 'to'), args, env_vars),
        mocker.call(os.path.join('path', 'to', 'nested'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


def test_per_dir_hook_with_errors(mocker, mock_per_dir_hook_unique_part):
    files = [os.path.join('path', 'to', 'file1.tf'), os.path.join('another', 'path', 'file2.tf')]
    args = []
    env_vars = {}
    mock_per_dir_hook_unique_part.side_effect = [0, 1]
    result = per_dir_hook(files, args, env_vars)
    assert result == 1
    expected_calls = [
        mocker.call(os.path.join('path', 'to'), args, env_vars),
        mocker.call(os.path.join('another', 'path'), args, env_vars),
    ]
    mock_per_dir_hook_unique_part.assert_has_calls(expected_calls, any_order=True)


if __name__ == '__main__':
    pytest.main()
