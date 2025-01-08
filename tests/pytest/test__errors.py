import pytest

from pre_commit_terraform._errors import PreCommitTerraformBaseError
from pre_commit_terraform._errors import PreCommitTerraformExit
from pre_commit_terraform._errors import PreCommitTerraformRuntimeError


def test_pre_commit_terraform_base_error():
    with pytest.raises(PreCommitTerraformBaseError):
        raise PreCommitTerraformBaseError('Base error occurred')


def test_pre_commit_terraform_runtime_error():
    with pytest.raises(PreCommitTerraformRuntimeError):
        raise PreCommitTerraformRuntimeError('Runtime error occurred')


def test_pre_commit_terraform_exit():
    with pytest.raises(PreCommitTerraformExit):
        raise PreCommitTerraformExit('Exit error occurred')
