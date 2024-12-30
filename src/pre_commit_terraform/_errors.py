"""App-specific exceptions."""


class PreCommitTerraformBaseError(Exception):
    """Base exception for all the in-app errors."""


class PreCommitTerraformRuntimeError(
        PreCommitTerraformBaseError,
        RuntimeError,
):
    """An exception representing a runtime error condition."""


class PreCommitTerraformExit(PreCommitTerraformBaseError, SystemExit):
    """An exception for terminating execution from deep app layers."""
