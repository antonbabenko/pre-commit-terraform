from argparse import ArgumentParser
from argparse import Namespace

from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform._types import CLISubcommandModuleProtocol
from pre_commit_terraform._types import ReturnCodeType


def test_return_code_type():
    assert isinstance(ReturnCode.OK, ReturnCodeType)
    assert isinstance(ReturnCode.ERROR, ReturnCodeType)
    assert isinstance(0, ReturnCodeType)
    assert isinstance(1, ReturnCodeType)
    assert not isinstance(2.5, ReturnCodeType)
    assert not isinstance('string', ReturnCodeType)


def test_cli_subcommand_module_protocol():
    class MockSubcommandModule:
        HOOK_ID = 'mock_hook'

        def populate_argument_parser(self, subcommand_parser: ArgumentParser) -> None:
            pass

        def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
            return ReturnCode.OK

    assert isinstance(MockSubcommandModule(), CLISubcommandModuleProtocol)

    class InvalidSubcommandModule:
        HOOK_ID = 'invalid_hook'

        def populate_argument_parser(self, subcommand_parser: ArgumentParser) -> None:
            pass

    assert not isinstance(InvalidSubcommandModule(), CLISubcommandModuleProtocol)
