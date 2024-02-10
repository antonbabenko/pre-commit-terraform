#!/usr/bin/env bash
set -eo pipefail

# Hook ID, based on hook filename.
# Hook filename MUST BE same with `- id` in .pre-commit-hooks.yaml file
# shellcheck disable=SC2034 # Unused var.
HOOK_ID=${0##*/}
readonly HOOK_ID=${HOOK_ID%%.*}

# Used only when parallelism needed and flock is not available
readonly PARALLELISM_FALLBACK_LOCK_DIR="/tmp/TF_PLUGIN_CACHE_DIR_lock"

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
  ARGS=() HOOK_CONFIG=() FILES=()
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
          ARGS+=("$ARG")
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
      if [[ "$arg" =~ .*'${'[A-Z_][A-Z0-9_]+?'}'.* ]]; then
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
        ARGS[$arg_idx]=$arg
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
    all_files_that_can_be_checked=$(git ls-files | sort | grep -e "$included_files" | tr '\n' ' ')
  else
    all_files_that_can_be_checked=$(git ls-files | sort | grep -e "$included_files" | grep -v -e "$excluded_files" | tr '\n' ' ')
  fi

  if [ "$files_to_check" == "$all_files_that_can_be_checked" ]; then
    return 0
  else
    return 1
  fi
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
#   args_array_length (integer) Count of arguments in args array.
#   args (array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function common::per_dir_hook {
  local -r hook_id="$1"
  local -i args_array_length=$2
  shift 2
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

  # check is (optional) function defined
  if [ "$(type -t run_hook_on_whole_repo)" == function ] &&
    # check is hook run via `pre-commit run --all`
    common::is_hook_run_on_whole_repo "$hook_id" "${files[@]}"; then
    run_hook_on_whole_repo "${args[@]}"
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
  # Limit the number of parallel processes to the number of CPU cores -1
  # `nproc` - linux, `sysctl -n hw.ncpu` - macOS, `echo 1` - fallback
  local CPU
  CPU=$(nproc || sysctl -n hw.ncpu || echo 1)
  local parallelism_limit
  local parallelism_disabled=false

  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"
  for c in "${configs[@]}"; do
    IFS="=" read -r -a config <<< "$c"

    # $hook_config receives string like '--foo=bar; --baz=4;' etc.
    # It gets split by `;` into array, which we're parsing here ('--foo=bar' ' --baz=4')
    # Next line removes leading spaces, to support >1 `--hook-config` args
    # shellcheck disable=SC2001 # Rule exception
    key=$(sed 's/^[[:space:]]*//' <<< "${config[0]}")
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
        parallelism_limit=$((value))
        ;;
    esac
  done

  if [[ ! $parallelism_limit ]]; then
    parallelism_limit=$((CPU - 1))
  elif [[ $parallelism_limit -le 1 ]]; then
    parallelism_limit=1
    parallelism_disabled=true
  fi

  local final_exit_code=0
  local pids=()

  mapfile -t dir_paths_unique < <(echo "${dir_paths[@]}" | tr ' ' '\n' | sort -u)
  local length=${#dir_paths_unique[@]}
  local last_index=$((${#dir_paths_unique[@]} - 1))
  # run hook for each path in parallel
  for ((i = 0; i < length; i++)); do
    dir_path="${dir_paths_unique[$i]//__REPLACED__SPACE__/ }"
    {
      if [[ $change_dir_in_unique_part == false ]]; then
        pushd "$dir_path" > /dev/null
      fi

      per_dir_hook_unique_part "$dir_path" "$change_dir_in_unique_part" "$parallelism_disabled" "${args[@]}"
    } &
    pids+=("$!")

    if $parallelism_disabled ||
      [ "$i" -ne 0 ] && [ $((i % parallelism_limit)) -eq 0 ] || # don't stop on first iteration when parallelism_limit>1
      [ "$i" -eq $last_index ]; then

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
  local -r TEXT=$2
  # Params end #

  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    COLOR=$RESET
  fi

  echo -e "${COLOR}${TEXT}${RESET}"
}

#######################################################################
# Run terraform init command
# Arguments:
#   command_name (string) command that will tun after successful init
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
#   parallelism_disabled (bool) if true - skip lock mechanism
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

  local exit_code=0
  local init_output

  # Suppress terraform init color
  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    TF_INIT_ARGS+=("-no-color")
  fi

  if [ ! -d .terraform/modules ] || [ ! -d .terraform/providers ]; then
    # Plugin cache dir can't be written concurrently or read during write
    # https://github.com/hashicorp/terraform/issues/31964
    if [ -z "$TF_PLUGIN_CACHE_DIR" ] || $parallelism_disabled; then
      init_output=$(terraform init -backend=false "${TF_INIT_ARGS[@]}" 2>&1)
      exit_code=$?
    else

      if command -v flock &> /dev/null; then
        init_output=$(
          flock --exclusive "$TF_PLUGIN_CACHE_DIR" \
            terraform init -backend=false "${TF_INIT_ARGS[@]}" 2>&1
        )
        exit_code=$?
      # Fallback to a "simple-lock" mechanism if `flock` is not available
      else

        while true; do
          if mkdir "$PARALLELISM_FALLBACK_LOCK_DIR" 2> /dev/null; then
            init_output=$(terraform init -backend=false "${TF_INIT_ARGS[@]}" 2>&1)
            exit_code=$?
            rm -rf "$PARALLELISM_FALLBACK_LOCK_DIR"
            break
          fi
          sleep 1
        done

        common::colorify "green" "For better parallelism performance and stability install 'flock' - https://www.howtodojo.com/flock-command-not-found/"
        common::colorify "green" "Or disable parallelism by setting '--hook-config=--parallelism_limit=1'"
      fi
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
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done
}
