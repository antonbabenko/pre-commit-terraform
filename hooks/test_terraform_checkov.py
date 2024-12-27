import pytest

from hooks.terraform_checkov import replace_git_working_dir_to_repo_root

# FILE: hooks/test_terraform_checkov.py


def test_replace_git_working_dir_to_repo_root_empty():
    args = []
    result = replace_git_working_dir_to_repo_root(args)
    assert result == []


def test_replace_git_working_dir_to_repo_root_no_replacement():
    args = ['arg1', 'arg2']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', 'arg2']


def test_replace_git_working_dir_to_repo_root_single_replacement(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['arg1', '__GIT_WORKING_DIR__/arg2']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', '/current/working/dir/arg2']


def test_replace_git_working_dir_to_repo_root_multiple_replacements(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['__GIT_WORKING_DIR__/arg1', 'arg2', '__GIT_WORKING_DIR__/arg3']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['/current/working/dir/arg1', 'arg2', '/current/working/dir/arg3']


def test_replace_git_working_dir_to_repo_root_partial_replacement(mocker):
    mocker.patch('os.getcwd', return_value='/current/working/dir')
    args = ['arg1', '__GIT_WORKING_DIR__/arg2', 'arg3']
    result = replace_git_working_dir_to_repo_root(args)
    assert result == ['arg1', '/current/working/dir/arg2', 'arg3']


if __name__ == '__main__':
    pytest.main()
