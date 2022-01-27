#!/usr/bin/env bash
set -eo pipefail

#######################################################################
# Wrapper function for hook. Determines run mode based on bool set by
# argparse, and triggers that run mode.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if successful, non-zero on error
#######################################################################
function main {
  parse_arguments "$@"
  # shellcheck disable=SC2153 # False positive
  if [[ ${CHANGE_DIRECTORY_SCAN} == true ]]; then
    # directories containing changed .tf files only
    directory_runner
  elif [[ ${CHANGE_FILE_SCAN} == true ]]; then
    # changed .tf files only
    file_runner
  else
    # whole repository
    checkov "${ARGS[@]}" -d .
  fi
}

#######################################################################
# Parses arguments provided to the hook to filter out changed files and
# args for the hook, set run mode (if present) and remove run mode toggles
# from the args as they're not valid for checkov. Enables backwards
# compatibility for those using checkov with no args, or without --args
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if successful, non-zero on error
#   Creates global arrays ARGS, FILES, may create a run mode global
#######################################################################
function parse_arguments {
  declare -a -g ARGS=()
  declare -a -g FILES=()

  argv=("$@")
  pattern='^.*\.tf$'

  for item in "${argv[@]}"; do
    if [[ $item =~ $pattern ]]; then
      FILES+=("$item")
    else
      case $item in
        --scan-change-directories)
          CHANGE_DIRECTORY_SCAN=true
          ;;
        --scan-change-files)
          CHANGE_FILE_SCAN=true
          ;;
        # -f filtered out to avoid duplicating
        -f | --file)
          :
          ;;
        *)
          ARGS+=("$item")
          ;;
      esac
    fi
  done
}

#######################################################################
# Identifies directories containing files that have changed in them, builds
# a command string from them, and then runs checkov against those dirs
# with args provided to hook.
# Globals:
#   FILES
#   ARGS
# Arguments:
#   None
# Returns:
#   0 if successful, non-zero on error
#######################################################################
function directory_runner {
  declare -a directories=()
  declare -a directory_command=()

  for file_with_path in "${FILES[@]}"; do
    directory=$(dirname "$file_with_path")
    directories+=("$directory")
  done

  for dir in $(echo "${directories[*]}" | tr ' ' '\n' | sort -u); do
    directory_command+=("-d")
    directory_command+=("$dir")
  done

  checkov "${ARGS[@]}" "${directory_command[@]}"
}

#######################################################################
# Builds a command string from the files provided, and runs checkov against
# those files with args provided to hook. This is the fastest run mode.
# Globals:
#   FILES
#   ARGS
# Arguments:
#   None
# Returns:
#   0 if successful, non-zero on error
#######################################################################
function file_runner {
  declare -a file_command=()

  for file in "${FILES[@]}"; do
    file_command+=("-f")
    file_command+=("$file")
  done

  checkov "${ARGS[@]}" "${file_command[@]}"
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
