#!/usr/bin/env bash
set -eo pipefail

if [[ $PCT_LOG == trace ]]; then

  echo "BASH path: '$BASH'"
  echo "BASH_VERSION: $BASH_VERSION"
  echo "BASHOPTS: $BASHOPTS"
  echo "OSTYPE: $OSTYPE"

  # ${FUNCNAME[*]} - function calls in reversed order. Each new function call is appended to the beginning
  # ${BASH_SOURCE##*/} - get filename
  # $LINENO - get line number
  export PS4='\e[2m
trace: ${FUNCNAME[*]}
       ${BASH_SOURCE##*/}:$LINENO: \e[0m'

  set -x
fi
# Hook ID, based on hook filename.
# Hook filename MUST BE same with `- id` in .pre-commit-hooks.yaml file
# shellcheck disable=SC2034 # Unused var.
HOOK_ID=${0##*/}
readonly HOOK_ID=${HOOK_ID%%.*}

#######################################################################
# Init arguments parser
# Arguments:
#   script_dir - absolute path to hook dir location
#######################################################################
function common::initialize {
  local -r script_dir=$1
  # source getopt function
  # shellcheck source=../lib_getopt
  . "$script_dir/../lib_getopt"
}

#######################################################################
# Parse args and filenames passed to script and populate respective
# global variables with appropriate values
# Globals (init and populate):
#   ARGS (array) arguments that configure wrapped tool behavior
#   HOOK_CONFIG (array) arguments that configure hook behavior
#   TF_INIT_ARGS (array) arguments for `terraform init` command
#   ENV_VARS (array) environment variables will be available
#     for all 3rd-party tools executed by a hook.
#   FILES (array) filenames to check
# Arguments:
#   $@ (array) all specified in `hooks.[].args` in
#     `.pre-commit-config.yaml` and filenames.
#######################################################################
function common::parse_cmdline {
  # common global arrays.
  # Populated via `common::parse_cmdline` and can be used inside hooks' functions
  ARGS=()
  HOOK_CONFIG=()
  FILES=()
  # Used inside `common::terraform_init` function
  TF_INIT_ARGS=()
  # Used inside `common::export_provided_env_vars` function
  ENV_VARS=()

  local argv
  # TODO: Planned breaking change: remove `init-args`, `envs` as not self-descriptive
  argv=$(getopt -o a:,h:,i:,e: --long args:,hook-config:,init-args:,tf-init-args:,envs:,env-vars: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        # `argv` is an string from array with content like:
        #     ('provider aws' '--version "> 0.14"' '--ignore-path "some/path"')
        #   where each element is the value of each `--args` from hook config.
        # `echo` prints contents of `argv` as an expanded string
        # `xargs` passes expanded string to `printf`
        # `printf` which splits it into NUL-separated elements,
        # NUL-separated elements read by `read` using empty separator
        #     (`-d ''` or `-d $'\0'`)
        #     into an `ARGS` array

        # This allows to "rebuild" initial `args` array of sort of grouped elements
        # into a proper array, where each element is a standalone array slice
        # with quoted elements being treated as a standalone slice of array as well.
        while read -r -d '' ARG; do
          # Also replace any occurrence of `__GIT_WORKING_DIR__` with
          # actual path to Git working dir (repo root)
          ARGS+=("${ARG//__GIT_WORKING_DIR__/$PWD}")
        done < <(echo "$1" | xargs printf '%s\0')
        shift
        ;;
      -h | --hook-config)
        shift
        HOOK_CONFIG+=("$1;")
        shift
        ;;
      # TODO: Planned breaking change: remove `--init-args` as not self-descriptive
      -i | --init-args | --tf-init-args)
        shift
        TF_INIT_ARGS+=("$1")
        shift
        ;;
      # TODO: Planned breaking change: remove `--envs` as not self-descriptive
      -e | --envs | --env-vars)
        shift
        ENV_VARS+=("$1")
        shift
        ;;
      --)
        shift
        # shellcheck disable=SC2034 # Variable is used
        FILES=("$@")
        break
        ;;
    esac
  done
}

#######################################################################
# Scrub GIT_* vars inherited from a linked Git worktree that would
# leak the parent repo location into child Git processes
# (see https://git-scm.com/docs/git#_environment_variables).
#
# pre-commit scrubs GIT_* only for its own internal Git calls, not for
# hook subprocesses - hook authors must handle it themselves:
# https://github.com/pre-commit/pre-commit/issues/1849
#
# This is a targeted denylist, NOT a mirror of pre-commit's
# allowlist-based no_git_env helper. We unset only the vars that leak
# the parent repository's location into child Git processes:
#
#   GIT_DIR               makes child Git operate on the parent repo
#   GIT_INDEX_FILE        proximate cause of the failure above
#   GIT_OBJECT_DIRECTORY  redirects child object writes into the
#                         parent object database
#   GIT_WORK_TREE         pairs with GIT_DIR
#######################################################################
function common::scrub_git_env {
  local -ra git_env_vars=(
    GIT_DIR
    GIT_INDEX_FILE
    GIT_OBJECT_DIRECTORY
    GIT_WORK_TREE
  )
  unset -v "${git_env_vars[@]}" || true
}

#######################################################################
# Expand environment variables definition into their values in '--args'.
# Support expansion only for ${ENV_VAR} vars, not $ENV_VAR.
# Globals (modify):
#   ARGS (array) arguments that configure wrapped tool behavior
#######################################################################
function common::parse_and_export_env_vars {
  local arg_idx

  for arg_idx in "${!ARGS[@]}"; do
    local arg="${ARGS[$arg_idx]}"

    # Repeat until all env vars will be expanded
    while true; do
      # Check if at least 1 env var exists in `$arg`
      # shellcheck disable=SC2016 # '${' should not be expanded
      if [[ "$arg" =~ '${'[A-Z_][A-Za-z0-9_]*'}' ]]; then
        # Get `ENV_VAR` from `.*${ENV_VAR}.*`
        local env_var_name=${arg#*$\{}
        env_var_name=${env_var_name%%\}*}
        local env_var_value="${!env_var_name}"
        # shellcheck disable=SC2016 # '${' should not be expanded
        common::colorify "green" 'Found ${'"$env_var_name"'} in:        '"'$arg'"
        # Replace env var name with its value.
        # `$arg` will be checked in `if` conditional, `$ARGS` will be used in the next functions.
        # shellcheck disable=SC2016 # '${' should not be expanded
        arg=${arg/'${'$env_var_name'}'/$env_var_value}
        ARGS[arg_idx]=$arg
        # shellcheck disable=SC2016 # '${' should not be expanded
        common::colorify "green" 'After ${'"$env_var_name"'} expansion: '"'$arg'\n"
        continue
      fi
      break
    done
  done
}

#######################################################################
# This is a workaround to improve performance when all files are passed
# See: https://github.com/antonbabenko/pre-commit-terraform/issues/309
# Arguments:
#   hook_id (string) hook ID, see `- id` for details in .pre-commit-hooks.yaml file
#   files (array) filenames to check
# Outputs:
#   Return 0 if `-a|--all` arg was passed to `pre-commit`
#######################################################################
function common::is_hook_run_on_whole_repo {
  local -r hook_id="$1"
  shift
  local -a -r files=("$@")
  # get directory containing `.pre-commit-hooks.yaml` file
  local -r root_config_dir="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)")"
  # get included and excluded files from .pre-commit-hooks.yaml file
  local -r hook_config_block=$(sed -n "/^- id: $hook_id$/,/^$/p" "$root_config_dir/.pre-commit-hooks.yaml")
  local -r included_files=$(awk '$1 == "files:" {print $2; exit}' <<< "$hook_config_block")
  local -r excluded_files=$(awk '$1 == "exclude:" {print $2; exit}' <<< "$hook_config_block")
  # sorted string with the files passed to the hook by pre-commit
  local -r files_to_check=$(printf '%s\n' "${files[@]}" | sort | tr '\n' ' ')
  # git ls-files sorted string
  local all_files_that_can_be_checked

  if [ -z "$excluded_files" ]; then
    all_files_that_can_be_checked=$(git ls-files | sort | grep -E -- "$included_files" | tr '\n' ' ')
  else
    all_files_that_can_be_checked=$(git ls-files | sort | grep -E -- "$included_files" | grep -v -E -- "$excluded_files" | tr '\n' ' ')
  fi

  if [ "$files_to_check" == "$all_files_that_can_be_checked" ]; then
    return 0
  else
    return 1
  fi
}

#######################################################################
# Get the number of CPU logical cores available for pre-commit to use
#
# CPU quota should be calculated as `cpu.cfs_quota_us / cpu.cfs_period_us`
# For K8s see: https://docs.kernel.org/scheduler/sched-bwc.html
# For Docker see: https://docs.docker.com/engine/containers/resource_constraints/#configure-the-default-cfs-scheduler
#
# Arguments:
#  parallelism_ci_cpu_cores (string) Used in edge cases when number of
#    CPU cores can't be derived automatically
# Outputs:
#   Returns number of CPU logical cores, rounded down to nearest integer
#######################################################################
function common::get_cpu_num {
  local -r parallelism_ci_cpu_cores=$1

  local cpu_quota cpu_period cpu_num

  local -r wslinterop_path="/proc/sys/fs/binfmt_misc/WSLInterop"

  if [[ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us &&
    (! -f "${wslinterop_path}" && ! -f "${wslinterop_path}-late" && ! -f "/run/WSL") ]]; then # WSL has cfs_quota_us, but WSL should be checked as usual Linux host
    # Inside K8s pod or DinD in K8s
    cpu_quota=$(< /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
    cpu_period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us 2> /dev/null || echo "$cpu_quota")

    if [[ $cpu_quota -eq -1 || $cpu_period -lt 1 ]]; then
      # K8s no limits or in DinD
      if [[ -n $parallelism_ci_cpu_cores ]]; then
        if [[ ! $parallelism_ci_cpu_cores =~ ^[[:digit:]]+$ ]]; then
          common::colorify "yellow" "--parallelism-ci-cpu-cores set to" \
            "'$parallelism_ci_cpu_cores' which is not a positive integer.\n" \
            "To avoid possible harm, parallelism is disabled.\n" \
            "To re-enable it, change corresponding value in config to positive integer"

          echo 1
          return
        fi

        echo "$parallelism_ci_cpu_cores"
        return
      fi

      common::colorify "yellow" "Unable to derive number of available CPU cores.\n" \
        "Running inside K8s pod without limits or inside DinD without limits propagation.\n" \
        "To avoid possible harm, parallelism is disabled.\n" \
        "To re-enable it, set corresponding limits, or set the following for the current hook:\n" \
        "  args:\n" \
        "    - --hook-config=--parallelism-ci-cpu-cores=N\n" \
        "where N is the number of CPU cores to allocate to pre-commit."

      echo 1
      return
    fi

    cpu_num=$((cpu_quota / cpu_period))
    [[ $cpu_num -lt 1 ]] && echo 1 || echo $cpu_num
    return
  fi

  if [[ -f /sys/fs/cgroup/cpu.max ]]; then
    # Inside Linux (Docker?) container
    cpu_quota=$(cut -d' ' -f1 /sys/fs/cgroup/cpu.max)
    cpu_period=$(cut -d' ' -f2 /sys/fs/cgroup/cpu.max)

    if [[ $cpu_quota == max || $cpu_period -lt 1 ]]; then
      # No limits
      nproc 2> /dev/null || echo 1
      return
    fi

    cpu_num=$((cpu_quota / cpu_period))
    [[ $cpu_num -lt 1 ]] && echo 1 || echo $cpu_num
    return
  fi

  # On host machine or any other case
  # `nproc` - Linux/FreeBSD/WSL, `sysctl -n hw.ncpu` - macOS/BSD, `echo 1` - fallback
  nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 1
}

#######################################################################
# Hook execution boilerplate logic which is common to hooks, that run
# on per dir basis.
# 1. Because hook runs on whole dir, reduce file paths to uniq dir paths
# 2. Run for each dir `per_dir_hook_unique_part`, on all paths
# 2.1. If at least 1 check failed - change exit code to non-zero
# 3. Complete hook execution and return exit code
# Arguments:
#   hook_id (string) hook ID, see `- id` for details in .pre-commit-hooks.yaml file
#   tool_name (string) name of the wrapped tool, used to resolve its path
#   args_array_length (integer) Count of arguments in args array.
#   args (array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function common::per_dir_hook {
  local -r hook_id="$1"
  local -r tool_name="$2"
  local -i args_array_length=$3
  shift 3
  local -a args=()
  # Expand args to a true array.
  # Based on https://stackoverflow.com/a/10953834
  while ((args_array_length-- > 0)); do
    args+=("$1")
    shift
  done
  # assign rest of function's positional ARGS into `files` array,
  # despite there's only one positional ARG left
  local -a -r files=("$@")

  local -r tool_version=$(common::get_hook_config_value "--tool-version")
  local tool_path
  tool_path=$(common::resolve_tool_path "$tool_name" "$tool_version") || exit $?
  readonly tool_path

  # check is (optional) function defined
  if [ "$(type -t run_hook_on_whole_repo)" == function ] &&
    # check is hook run via `pre-commit run --all`
    common::is_hook_run_on_whole_repo "$hook_id" "${files[@]}"; then
    run_hook_on_whole_repo "$tool_path" "${args[@]}"
    exit 0
  fi

  # consume modified files passed from pre-commit so that
  # hook runs against only those relevant directories
  local index=0
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    dir_paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done

  # Lookup hook-config for modifiers that impact common behavior
  local change_dir_in_unique_part=false

  local parallelism_limit
  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"
  for c in "${configs[@]}"; do
    IFS="=" read -r -a config <<< "$c"

    # $hook_config receives string like '--foo=bar; --baz=4;' etc.
    # It gets split by `;` into array, which we're parsing here ('--foo=bar' ' --baz=4')
    # Next line removes leading spaces, to support >1 `--hook-config` args
    key="${config[0]## }"
    value=${config[1]}

    case $key in
      --delegate-chdir)
        # this flag will skip pushing and popping directories
        # delegating the responsibility to the hooked plugin/binary
        if [[ ! $value || $value == true ]]; then
          change_dir_in_unique_part="delegate_chdir"
        fi
        ;;
      --parallelism-limit)
        # this flag will limit the number of parallel processes
        parallelism_limit="$value"
        ;;
      --parallelism-ci-cpu-cores)
        # Used in edge cases when number of CPU cores can't be derived automatically
        parallelism_ci_cpu_cores="$value"
        ;;
    esac
  done

  CPU=$(common::get_cpu_num "$parallelism_ci_cpu_cores")
  # parallelism_limit can include reference to 'CPU' variable
  local parallelism_disabled=false

  if [[ ! $parallelism_limit ]]; then
    # Could evaluate to 0
    parallelism_limit=$((CPU - 1))
  elif [[ $parallelism_limit -eq 1 ]]; then
    parallelism_disabled=true
  else
    # Could evaluate to <1
    parallelism_limit=$((parallelism_limit))
  fi

  if [[ $parallelism_limit -lt 1 ]]; then
    # Suppress warning for edge cases when only 1 CPU available or
    # when `--parallelism-ci-cpu-cores=1` and `--parallelism_limit` unset
    if [[ $CPU -ne 1 ]]; then

      common::colorify "yellow" "Observed Parallelism limit '$parallelism_limit'." \
        "To avoid possible harm, parallelism set to '1'"
    fi

    parallelism_limit=1
    parallelism_disabled=true
  fi

  local pids=()

  # shellcheck disable=SC2207 # More readable way
  local -a dir_paths_unique=($(printf '%s\n' "${dir_paths[@]}" | sort -u))

  local length=${#dir_paths_unique[@]}
  local last_index=$((${#dir_paths_unique[@]} - 1))

  local final_exit_code=0
  # preserve errexit status
  shopt -qo errexit && ERREXIT_IS_SET=true
  # allow hook to continue if exit_code is greater than 0
  set +e
  # run hook for each path in parallel
  for ((i = 0; i < length; i++)); do
    dir_path="${dir_paths_unique[$i]//__REPLACED__SPACE__/ }"
    {
      if [[ $change_dir_in_unique_part == false ]]; then
        pushd "$dir_path" > /dev/null
      fi

      per_dir_hook_unique_part "$dir_path" "$change_dir_in_unique_part" "$parallelism_disabled" "$tool_path" "${args[@]}"
    } &
    pids+=("$!")

    if [[ $parallelism_disabled == true ]] ||
      [[ $i -ne 0 && $((i % parallelism_limit)) -eq 0 ]] || # don't stop on first iteration when parallelism_limit>1
      [[ $i -eq $last_index ]]; then

      for pid in "${pids[@]}"; do
        # Get the exit code from the background process
        local exit_code=0
        wait "$pid" || exit_code=$?

        if [ $exit_code -ne 0 ]; then
          final_exit_code=$exit_code
        fi
      done
      # Reset pids for next iteration
      unset pids
    fi

  done

  # restore errexit if it was set before the "for" loop
  [[ $ERREXIT_IS_SET ]] && set -e
  # return the hook final exit_code
  exit $final_exit_code
}

#######################################################################
# Colorize provided string and print it out to stdout
# Environment variables:
#   PRE_COMMIT_COLOR (string) If set to `never` - do not colorize output
# Arguments:
#   COLOR (string) Color name that will be used to colorize
#   TEXT (string)
# Outputs:
#   Print out provided text to stdout
#######################################################################
function common::colorify {
  # shellcheck disable=SC2034
  local -r red="\x1b[0m\x1b[31m"
  # shellcheck disable=SC2034
  local -r green="\x1b[0m\x1b[32m"
  # shellcheck disable=SC2034
  local -r yellow="\x1b[0m\x1b[33m"
  # Color reset
  local -r RESET="\x1b[0m"

  # Params start #
  local COLOR="${!1}"
  shift
  local -r TEXT="$*"
  # Params end #

  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    COLOR=$RESET
  fi

  echo -e "${COLOR}${TEXT}${RESET}" >&2
}

#######################################################################
# Look up a single `--hook-config=--key=value` entry's value.
# Globals:
#   HOOK_CONFIG (array) arguments that configure hook behavior
# Arguments:
#   key (string) hook-config key to look up, including its leading `--`
#     (e.g. "--tool-version")
# Outputs:
#   Prints the value if the key is present in $HOOK_CONFIG, prints
#   nothing otherwise
#######################################################################
function common::get_hook_config_value {
  local -r key="$1"
  local config value

  for config in "${HOOK_CONFIG[@]}"; do
    if [[ $config == "$key"=* ]]; then
      value=${config#*=}
      value=${value%;}
      break
    fi
  done

  echo "$value"
}

#######################################################################
# Detect current OS/architecture using the same naming convention
# `tools/install/*.sh` expects (normally provided automatically by
# Docker buildx as TARGETOS/TARGETARCH build args; outside of a Docker
# build they don't exist and must be derived here instead).
# Globals (init and populate):
#   TARGETOS (string)
#   TARGETARCH (string)
#######################################################################
function common::detect_os_arch {
  TARGETOS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  TARGETARCH="$(uname -m)"

  case "$TARGETARCH" in
    x86_64) TARGETARCH="amd64" ;;
    aarch64 | arm64) TARGETARCH="arm64" ;;
  esac

  export TARGETOS TARGETARCH
}

#######################################################################
# Resolve a specific version of a wrapped tool's binary, downloading
# and caching it on demand if it isn't already cached.
#
# Reuses the existing `tools/install/<tool>.sh` installer scripts
# instead of re-implementing per-tool download logic.
# Requires a downloadable release binary to resolve.
#
# Environment variables:
#   PCT_TOOL_CACHE_DIR (string) if set, used as the complete cache
#     root path as-is
#   XDG_CACHE_HOME (string) if set (and PCT_TOOL_CACHE_DIR is not),
#     "$XDG_CACHE_HOME/pre-commit-terraform" is used as the cache root
#   GITHUB_TOKEN (string) forwarded automatically, since it's read
#     directly by the invoked installer script
# Arguments:
#   tool (string) tool name:
#     - matching a `tools/install/<tool>.sh` file and its expected
#           `${TOOL^^}_VERSION` environment variable name;
#     - "tf" for Terraform/OpenTofu, resolved via `common::get_tf_binary_path`
#     - empty for hooks with no resolvable binary (e.g. checkov)
#   version (string) exact version requested (e.g. "1.7.5"), or empty
#     if no `--tool-version` was requested
# Outputs:
#   Prints the absolute path to the resolved binary, or the bare $tool
#   name unchanged if no version was requested (empty string if $tool
#   itself is also empty). If a download is attempted and fails - exit
#   1 with an error message.
#######################################################################
function common::resolve_tool_path {
  local -r tool_name="$1"
  local -r version="$2"

  #
  # Check if configuration is valid
  #

  # No resolvable tool name (e.g. checkov, which is pip-distributed);
  # keeps "--tool-version" a documented no-op for it instead of erroring on an empty tool name.
  [[ ! $tool_name ]] && return

  # "tf" is a placeholder, not a real tool. Delegate to
  # `common::get_tf_binary_path`, which applies the extra precedence rules
  # (--tf-path, PCT_TFPATH/TERRAGRUNT_TFPATH, terraform-vs-opentofu choice)
  # then calls back here with the concrete name - which no longer matches
  # "tf", so it falls through below instead of recursing.
  if [[ $tool_name == "tf" ]]; then
    common::get_tf_binary_path "$version"
    return
  fi

  if [[ ! $version ]]; then
    # Check if the tool discoverable in the system's PATH
    if ! command -v "$tool_name" > /dev/null; then
      common::colorify "red" \
        "ERROR: '$tool_name' is required by '$HOOK_ID' pre-commit hook but it is not discoverable in the system's PATH.\n" \
        "Since '--hook-config=--tool-version=…' was not specified, no version resolution was attempted.\n\n" \
        "Please install '$tool_name' manually or specify in .pre-commit-config.yaml a version to download and cache via:\n" \
        "args:\n" \
        "  - --hook-config=--tool-version=<version>"
      exit 1
    fi

    echo "$tool_name"
    return
  fi

  #
  # Choose whether to prefer the local $PATH version of a tool over a requested version, if both exist.
  #
  local -r tool_version_mode=$(common::get_hook_config_value "--tool-version-mode")

  if command -v "$tool_name" &> /dev/null; then
    if [[ $tool_version_mode == "prefer-local" ]]; then
      common::colorify "green" \
        "NOTE: version '$version' was requested for '$tool_name', but '--tool-version-mode=prefer-local' " \
        "is set and '$tool_name' is already found on \$PATH - using that instead."
      command -v "$tool_name"
      return
    fi

    common::colorify "green" \
      "NOTE: The requested '$tool_name' version '$version' will be downloaded/used instead of whatever is on \$PATH."
  fi

  #
  # Check if the requested version is already cached
  #

  # opentofu.sh renames its binary from "opentofu" back to "tofu" after
  # common::install_from_gh_release completes (see tools/install/opentofu.sh)
  local resolved_bin_name="$tool_name"
  [[ $tool_name == "opentofu" ]] && resolved_bin_name="tofu"

  local -r cache_root="${PCT_TOOL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pre-commit-terraform}"
  local -r cache_dir="$cache_root/$tool_name/$version"
  local -r cached_bin="$cache_dir/$resolved_bin_name"

  if [[ -x $cached_bin ]]; then
    echo "$cached_bin"
    return
  fi

  #
  # Download and cache the requested version
  #

  local -r script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local -r installer_script="$script_dir/../tools/install/${tool_name}.sh"

  if [[ ! -f $installer_script ]]; then
    common::colorify "red" "ERROR: pinning a version is not supported for '$tool_name' (no installer found at '$installer_script')."
    exit 1
  fi

  common::colorify "green" "Downloading '$tool_name' version '$version'..."

  common::detect_os_arch

  local env_var_name="${tool_name//-/_}"
  env_var_name="${env_var_name^^}_VERSION"

  mkdir -p "$cache_dir"

  # Redirect the installer's own stdout to stderr: this function's stdout is
  # a contract (the resolved path, captured via "$(...)" by every caller),
  # and installers like terraform.sh/tflint.sh call bare `unzip` (no `-q`),
  # which prints "Archive: ... inflating: ..." to stdout by default -
  # harmless noise in a Docker build log, but it would otherwise corrupt
  # the path this function returns.
  if ! (
    cd "$cache_dir" || exit 1
    export "$env_var_name=$version"
    "$installer_script" 1>&2
  ); then
    common::colorify "red" "ERROR: Failed to download '$tool_name' version '$version' via '$installer_script'."
    exit 1
  fi

  if [[ ! -x $cached_bin ]]; then
    common::colorify "red" "ERROR: '$tool_name' installer completed but expected binary was not found at '$cached_bin'."
    exit 1
  fi

  echo "$cached_bin"
}

#######################################################################
# Get Terraform/OpenTofu binary path
# Allows user to set the path to custom Terraform or OpenTofu binary
# Arguments:
#   tool_version (string) value of a requested `--tool-version`
#     hook-config, or empty if none was requested
# Globals (init and populate):
#   HOOK_CONFIG (array) arguments that configure hook behavior
#   PCT_TFPATH (string) user defined env var with path to Terraform/OpenTofu binary
#   TERRAGRUNT_TFPATH (string) user defined env var with path to Terraform/OpenTofu binary
# Outputs:
#   If failed - exit 1 with error message about missing Terraform/OpenTofu binary
#######################################################################
function common::get_tf_binary_path {
  local -r tool_version="$1"

  local -r hook_config_tf_path=$(common::get_hook_config_value "--tf-path")

  # direct hook config, has the highest precedence - but only when NOT
  # combined with --tool-version. When it IS also set, --tf-path is
  # reinterpreted below as an explicit terraform/opentofu selector
  # rather than a literal binary path.
  if [[ $hook_config_tf_path && ! $tool_version ]]; then
    echo "$hook_config_tf_path"
    return

  # '--hook-config=--tool-version=X.Y.Z': download/cache a pinned
  # Terraform/OpenTofu version on demand.
  elif [[ $tool_version ]]; then
    local tf_tool
    case "$hook_config_tf_path" in
      terraform)
        tf_tool="terraform"
        ;;
      opentofu | tofu)
        tf_tool="opentofu"
        ;;
      "")
        # Terraform preferred; opentofu only if terraform isn't on $PATH but tofu is).
        tf_tool="terraform"
        ! command -v terraform &> /dev/null && command -v tofu &> /dev/null && tf_tool="opentofu"
        ;;
      *)
        common::colorify "red" \
          "ERROR: '--tf-path=$hook_config_tf_path' combined with '--tool-version' is not a valid value.\n" \
          "'--tf-path=' must be either 'terraform', 'opentofu'/'tofu', or unset."
        exit 1
        ;;
    esac

    common::resolve_tool_path "$tf_tool" "$tool_version"
    return

  # environment variable
  elif [[ $PCT_TFPATH ]]; then
    echo "$PCT_TFPATH"
    return

  # Maybe there is a similar setting for Terragrunt already
  elif [[ $TERRAGRUNT_TFPATH ]]; then
    echo "$TERRAGRUNT_TFPATH"
    return

  # check if Terraform binary is available
  elif command -v terraform &> /dev/null; then
    command -v terraform
    return

  # finally, check if Tofu binary is available
  elif command -v tofu &> /dev/null; then
    command -v tofu
    return

  else
    common::colorify "red" \
      'Neither Terraform nor OpenTofu binary could be found. Please do one of the following:\n' \
      '- set the "--tf-path" hook configuration argument, along with "--tool-version" (to download and cache) or without it (to use already installed one)\n' \
      '- set the "PCT_TFPATH" environment variable\n' \
      '- set the "TERRAGRUNT_TFPATH" environment variable\n' \
      '- install Terraform or OpenTofu yourself and run "pre-commit" again'
    exit 1
  fi
}

#######################################################################
# Run terraform init command
# Arguments:
#   command_name (string) command that will tun after successful init
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
#   parallelism_disabled (bool) if true - skip lock mechanism
#  tf_path (string) PATH to Terraform/OpenTofu binary
# Globals (init and populate):
#   TF_INIT_ARGS (array) arguments for `terraform init` command
#   TF_PLUGIN_CACHE_DIR (string) user defined env var with name of the directory
#     which can't be R/W concurrently
# Outputs:
#   If failed - print out terraform init output
#######################################################################
# TODO: v2.0: Move it inside terraform_validate.sh
function common::terraform_init {
  local -r command_name=$1
  local -r dir_path=$2
  local -r parallelism_disabled=$3
  local -r tf_path=$4

  local exit_code=0
  local init_output

  # Suppress terraform init color
  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    TF_INIT_ARGS+=("-no-color")
  fi

  recreate_modules=$([[ ! -d .terraform/modules ]] && echo true || echo false)
  recreate_providers=$([[ ! -d .terraform/providers ]] && echo true || echo false)

  if [[ $recreate_modules == true || $recreate_providers == true ]]; then
    # Plugin cache dir can't be written concurrently or read during write
    # https://github.com/hashicorp/terraform/issues/31964
    if [[ -z $TF_PLUGIN_CACHE_DIR || $parallelism_disabled == true ]]; then
      init_output=$("$tf_path" init -backend=false "${TF_INIT_ARGS[@]}" 2>&1)
      exit_code=$?
    else
      # Locking just doesn't work, and the below works quicker instead. Details:
      # https://github.com/hashicorp/terraform/issues/31964#issuecomment-1939869453
      for i in {1..10}; do
        init_output=$("$tf_path" init -backend=false "${TF_INIT_ARGS[@]}" 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ]; then
          break
        fi
        sleep 1

        common::colorify "green" "Race condition detected. Retrying 'terraform init' command [retry $i]: $dir_path."
        [[ $recreate_modules == true ]] && rm -rf .terraform/modules
        [[ $recreate_providers == true ]] && rm -rf .terraform/providers
      done
    fi

    if [ $exit_code -ne 0 ]; then
      common::colorify "red" "'terraform init' failed, '$command_name' skipped: $dir_path"
      echo -e "$init_output\n\n"
    else
      common::colorify "green" "Command 'terraform init' successfully done: $dir_path"
    fi
  fi

  return $exit_code
}

#######################################################################
# Export provided K/V as environment variables.
# Arguments:
#   env_vars (array)  environment variables will be available
#     for all 3rd-party tools executed by a hook.
#######################################################################
function common::export_provided_env_vars {
  local -a -r env_vars=("$@")

  local var
  local var_name
  local var_value

  for var in "${env_vars[@]}"; do
    var_name="${var%%=*}"
    var_value="${var#*=}"
    # Drop enclosing double quotes
    if [[ $var_value =~ ^\" && $var_value =~ \"$ ]]; then
      var_value="${var_value#\"}"
      var_value="${var_value%\"}"
    fi
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done
}

#######################################################################
# Check if the given Terragrunt binary's version is >=0.78.0 or not
#
# This function helps to determine which terragrunt subcomand to use
# based on Terragrunt version
#
# Arguments:
#   tool_path (string) resolved path to the terragrunt binary to check
#     (the actually resolved/pinned binary, NOT whatever's on $PATH -
#     those can differ once --tool-version is in play)
# Returns:
#   - 0 if version >= 0.78.0
#   - 1 if version < 0.78.0
#    Defaults to 0 if version cannot be determined
#######################################################################
# TODO: Drop after May 2027. Two years to upgrade is more than enough.
function common::terragrunt_version_ge_0.78 {
  local -r tool_path="$1"
  local terragrunt_version

  # Extract version number (e.g., "terragrunt version v0.80.4" -> "0.80")
  terragrunt_version=$("$tool_path" --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+')
  # If we can't parse version, default to newer command
  [[ ! $terragrunt_version ]] && return 0

  local major minor
  IFS='.' read -r major minor <<< "$terragrunt_version"

  # New subcommands added in v0.78.0 (May 2025)
  if [[ $major -gt 0 || ($major -eq 0 && $minor -ge 78) ]]; then
    return 0
  else
    return 1
  fi
}
