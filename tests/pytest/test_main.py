import importlib
import sys


def test_main_success(mocker):
    mock_argv = ['__main__.py', 'arg1', 'arg2']
    mock_return_code = 0

    mocker.patch('sys.argv', mock_argv)
    mock_invoke_cli_app = mocker.patch(
        'pre_commit_terraform._cli.invoke_cli_app',
        return_value=mock_return_code,
    )
    mock_exit = mocker.patch('sys.exit')

    # Reload the module to trigger the main logic
    if 'pre_commit_terraform.__main__' in sys.modules:
        importlib.reload(sys.modules['pre_commit_terraform.__main__'])
    else:
        import pre_commit_terraform.__main__  # noqa: F401

    mock_invoke_cli_app.assert_called_once_with(mock_argv[1:])
    mock_exit.assert_called_once_with(mock_return_code)


def test_main_failure(mocker):
    mock_argv = ['__main__.py', 'arg1', 'arg2']
    mock_return_code = 1

    mocker.patch('sys.argv', mock_argv)
    mock_invoke_cli_app = mocker.patch(
        'pre_commit_terraform._cli.invoke_cli_app',
        return_value=mock_return_code,
    )
    mock_exit = mocker.patch('sys.exit')

    # Reload the module to trigger the main logic
    if 'pre_commit_terraform.__main__' in sys.modules:
        importlib.reload(sys.modules['pre_commit_terraform.__main__'])
    else:
        import pre_commit_terraform.__main__  # noqa: F401

    mock_invoke_cli_app.assert_called_once_with(mock_argv[1:])
    mock_exit.assert_called_once_with(mock_return_code)
