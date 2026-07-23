# hook-config-tool-version

## Purpose

TBD - capability for resolving a specific version of a hook's wrapped tool binary via `--hook-config=--tool-version=<version>`, including version-keyed caching, configurable cache root, precedence with locally-available tools, and delegation to existing per-tool installer scripts.

## Requirements

### Requirement: Opt-in tool version selection via hook-config
The system SHALL support resolving a specific version of a wrapped tool's binary when a hook is invoked with `--hook-config=--tool-version=<version>`, for hooks wrapping a tool distributed as a downloadable release binary.

#### Scenario: Version requested and not yet cached
- **WHEN** a hook runs with `--hook-config=--tool-version=1.7.5` and no matching cached binary exists
- **THEN** the system downloads version `1.7.5` of the wrapped tool, stores it in the cache, and uses it for that hook invocation

#### Scenario: Version requested and already cached
- **WHEN** a hook runs with `--hook-config=--tool-version=1.7.5` and a matching cached binary already exists
- **THEN** the system uses the cached binary directly without making any network request

### Requirement: Backward-compatible fallback when no version is requested
When a hook is invoked without a `--tool-version` hook-config value, the system SHALL fall back to existing tool-discovery behavior unchanged, except that a tool which is neither pinned nor found is now reported with an explicit, actionable error (see "Actionable error when a requested tool is neither pinned nor found on PATH" below) instead of being deferred to the tool's own later invocation failure.

#### Scenario: Existing configuration without --tool-version
- **WHEN** a hook runs with no `--hook-config=--tool-version=` argument present, and the tool it wraps resolves successfully via `PATH` lookup (or the existing `--tf-path`/environment-variable precedence for terraform/opentofu)
- **THEN** the system resolves the tool exactly as it did before this change, and no download is attempted

### Requirement: Version-keyed caching
The system SHALL cache each downloaded tool binary in a location keyed by tool name, version, operating system, and architecture, such that multiple versions of the same tool can coexist on disk simultaneously without overwriting one another.

#### Scenario: Two different pinned versions requested across separate hook invocations
- **WHEN** one hook invocation requests `--tool-version=1.7.5` and a separate hook invocation (or a separate entry for the same hook id) requests `--tool-version=1.9.0` for the same tool
- **THEN** both versions' binaries exist in the cache simultaneously, and each hook invocation uses only the version it requested

### Requirement: Configurable cache root
The system SHALL allow the cache root directory to be overridden via a `PCT_TOOL_CACHE_DIR` environment variable, which SHALL be used as the complete cache-root path exactly as given. When `PCT_TOOL_CACHE_DIR` is unset, the system SHALL default the cache root to `$XDG_CACHE_HOME/pre-commit-terraform` if `XDG_CACHE_HOME` is set, or `$HOME/.cache/pre-commit-terraform` otherwise.

#### Scenario: Neither PCT_TOOL_CACHE_DIR nor XDG_CACHE_HOME is set
- **WHEN** version resolution runs with neither `PCT_TOOL_CACHE_DIR` nor `XDG_CACHE_HOME` set in the environment
- **THEN** the system uses `$HOME/.cache/pre-commit-terraform` as the cache root

#### Scenario: XDG_CACHE_HOME is set but PCT_TOOL_CACHE_DIR is not
- **WHEN** `XDG_CACHE_HOME` is set and `PCT_TOOL_CACHE_DIR` is not set
- **THEN** the system uses `$XDG_CACHE_HOME/pre-commit-terraform` as the cache root

#### Scenario: PCT_TOOL_CACHE_DIR is set
- **WHEN** `PCT_TOOL_CACHE_DIR` is set in the environment, regardless of whether `XDG_CACHE_HOME` is also set
- **THEN** the system uses the value of `PCT_TOOL_CACHE_DIR` as the cache root, without appending a `pre-commit-terraform` subdirectory

### Requirement: Absolute path resolution without PATH mutation
The system SHALL resolve a requested tool version to an absolute filesystem path and SHALL NOT modify the `PATH` environment variable to make the resolved binary available.

#### Scenario: Hook invokes the resolved binary directly
- **WHEN** version resolution completes for a given `--tool-version` request
- **THEN** the hook script invokes the tool using the absolute path returned by the resolver, and the process `PATH` is left unchanged

### Requirement: Same hook usable multiple times with different pinned versions in one configuration
The system SHALL allow the same hook id to be declared more than once in a single `.pre-commit-config.yaml`, each with a different `--hook-config=--tool-version=` value, without either invocation's resolution interfering with the other.

#### Scenario: Same hook id configured twice with different pinned versions
- **WHEN** a `.pre-commit-config.yaml` declares the same hook id twice, once with `--hook-config=--tool-version=1.7.5` and once with `--hook-config=--tool-version=1.9.0`
- **THEN** running `pre-commit run` executes the tool at version `1.7.5` for the first entry and at version `1.9.0` for the second, independently and correctly

### Requirement: Warn and proceed on version mismatch
When a requested `--tool-version` differs from whatever version existing precedence (e.g. `PATH` lookup) would otherwise have resolved, the system SHALL emit a warning and SHALL still proceed using the requested pinned version.

#### Scenario: Requested version differs from what is already on PATH
- **WHEN** `--hook-config=--tool-version=1.7.5` is requested and a different version of the same tool is already available on `PATH`
- **THEN** the system prints a warning identifying the mismatch and uses version `1.7.5` (the requested, cached/downloaded version) for the hook invocation, without prompting for confirmation or aborting

### Requirement: Configurable precedence between pinned and locally-available versions
The system SHALL support a `--hook-config=--tool-version-mode=<mode>` value with two recognized modes, `strict` and `prefer-local`, defaulting to `strict` when unset or set to any other value.

#### Scenario: strict mode (default)
- **WHEN** `--tool-version-mode` is unset, or set to `strict`, and a tool version is requested while a different version is already on `PATH`
- **THEN** the system downloads/uses the pinned version, per the "Warn and proceed on version mismatch" requirement

#### Scenario: prefer-local mode, tool already resolvable locally
- **WHEN** `--tool-version-mode=prefer-local` is set and the tool already resolves via plain `PATH` lookup
- **THEN** the system uses that local binary directly, without attempting to resolve, cache, or download the pinned version

#### Scenario: prefer-local mode, tool not found locally
- **WHEN** `--tool-version-mode=prefer-local` is set and the tool does not resolve via plain `PATH` lookup
- **THEN** the system falls through to resolving the pinned version exactly as in `strict` mode

### Requirement: Downloads delegate to the existing per-tool installer script
The system SHALL obtain a requested tool version by invoking that tool's existing `tools/install/<tool>.sh` installer script, rather than maintaining a second, separate implementation of how to build that tool's download URL.

#### Scenario: Resolving a version for a tool with an existing installer script
- **WHEN** a version is requested for a tool that already has a `tools/install/<tool>.sh` script
- **THEN** the system invokes that script as a subprocess, with the tool's expected version environment variable and the `TARGETOS`/`TARGETARCH` values set appropriately, and with its working directory set to the target cache location for that version

### Requirement: GITHUB_TOKEN-aware authenticated requests
If a `GITHUB_TOKEN` environment variable is present, the system SHALL include it as a Bearer authorization header on GitHub API requests made during version resolution.

#### Scenario: GITHUB_TOKEN is set during a hook run that triggers a download
- **WHEN** `GITHUB_TOKEN` is present in the environment and a version resolution triggers a GitHub API request
- **THEN** the request includes an `Authorization: Bearer <token>` header

#### Scenario: GITHUB_TOKEN is not set
- **WHEN** `GITHUB_TOKEN` is not present in the environment and a version resolution triggers a GitHub API request
- **THEN** the request is made unauthenticated, exactly as the existing build-time mechanism already behaves by default

### Requirement: Scope limited to release-binary-distributed tools
The system SHALL apply tool-version resolution only to hooks wrapping tools distributed as directly downloadable release binaries, and SHALL NOT apply it to tools with a different distribution model (e.g. pip-distributed `checkov`).

#### Scenario: A hook wrapping a pip-distributed tool
- **WHEN** a `--hook-config=--tool-version=` value is set on a hook that wraps a pip-distributed tool
- **THEN** the value has no effect, since that hook does not invoke the version-resolution mechanism

### Requirement: Terraform version pinning via --tool-version is scoped to hooks that consume it
Because Terraform/OpenTofu binary path resolution runs unconditionally for every hook (regardless of which tool that hook wraps), the system SHALL only attempt to resolve a pinned Terraform version from the generic `--tool-version` key for hooks that actually consume that resolution's result, and SHALL leave `--tool-version` unaffected for all other hooks.

#### Scenario: A non-Terraform hook sets --tool-version
- **WHEN** a hook that wraps a different tool (e.g. tflint) and does not consume the Terraform binary path is configured with `--hook-config=--tool-version=<version>`
- **THEN** Terraform/OpenTofu binary path resolution for that same hook invocation is unaffected by that value, and does not attempt to resolve or download a Terraform version

#### Scenario: A hook that consumes the Terraform binary path sets --tool-version
- **WHEN** a hook that resolves and uses the Terraform/OpenTofu binary path (`terraform_validate`, `terraform_fmt`, or `terraform_providers_lock`) is configured with `--hook-config=--tool-version=<version>`
- **THEN** Terraform binary path resolution downloads/caches and resolves to that pinned Terraform version

### Requirement: Explicit terraform/opentofu selection via --tf-path combined with --tool-version
When both `--hook-config=--tf-path=<value>` and `--hook-config=--tool-version=<version>` are set on a hook that consumes the Terraform/OpenTofu binary path, the system SHALL treat `<value>` as an explicit tool selector rather than a literal binary path, accepting only `terraform`, `opentofu`, or `tofu` as valid values, and SHALL reject any other value with an error.

#### Scenario: --tf-path=terraform combined with --tool-version
- **WHEN** a hook is configured with `--hook-config=--tf-path=terraform` and `--hook-config=--tool-version=<version>`
- **THEN** the system downloads/caches and resolves to Terraform at that pinned version, regardless of what auto-detection based on `$PATH` would otherwise have picked

#### Scenario: --tf-path=opentofu or --tf-path=tofu combined with --tool-version
- **WHEN** a hook is configured with `--hook-config=--tf-path=opentofu` (or `--hook-config=--tf-path=tofu`) and `--hook-config=--tool-version=<version>`
- **THEN** the system downloads/caches and resolves to OpenTofu at that pinned version, regardless of what auto-detection based on `$PATH` would otherwise have picked

#### Scenario: --tf-path set to an actual binary path combined with --tool-version
- **WHEN** a hook is configured with `--hook-config=--tf-path=<value>` where `<value>` is not `terraform`, `opentofu`, or `tofu` (e.g. a literal filesystem path), and `--hook-config=--tool-version=<version>` is also set
- **THEN** the system exits with an error explaining that `--tf-path` combined with `--tool-version` must be `terraform`, `opentofu`, `tofu`, or unset

#### Scenario: --tf-path set to an actual binary path without --tool-version
- **WHEN** a hook is configured with `--hook-config=--tf-path=<value>` and no `--hook-config=--tool-version=` is set
- **THEN** the system uses `<value>` verbatim as the binary path, exactly as before this change (unaffected by the selector behavior above)

### Requirement: Actionable error when a requested tool is neither pinned nor found on PATH
When no `--tool-version` is requested for a hook and the wrapped tool does not resolve via `$PATH`, the system SHALL exit with an error identifying the missing tool and the hook, and suggesting `--hook-config=--tool-version=<version>` as a remedy, rather than silently returning the bare tool name for the hook's own invocation to fail on later.

#### Scenario: Tool not on PATH, no version pin requested
- **WHEN** a hook is invoked with no `--hook-config=--tool-version=` set, and the tool it wraps is not found via `$PATH`
- **THEN** the system exits with an error naming the missing tool and the hook, and suggesting `--hook-config=--tool-version=<version>` as a remedy

#### Scenario: Tool found on PATH, no version pin requested
- **WHEN** a hook is invoked with no `--hook-config=--tool-version=` set, and the tool it wraps is found via `$PATH`
- **THEN** the system resolves to the bare tool name unchanged, exactly as before this change
