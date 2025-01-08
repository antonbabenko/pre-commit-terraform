import pytest

from pre_commit_terraform._structs import ReturnCode


def test_return_code_values():
    assert ReturnCode.OK == 0
    assert ReturnCode.ERROR == 1


def test_return_code_names():
    assert ReturnCode(0).name == 'OK'
    assert ReturnCode(1).name == 'ERROR'


def test_return_code_invalid_value():
    with pytest.raises(ValueError):
        ReturnCode(2)
