#!/usr/bin/env bash
set -euo pipefail

main() {
  parse_cmdline "$@"
  process_paths
}

initialize() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"
  while [[ -h $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" >/dev/null && pwd )"
    source="$(readlink "$source")"
     # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
}

check_for_commands() {
  declare -a missing_cmds=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing_cmds+=("$cmd")
  done
  if [[ ${#missing_cmds[@]} -gt 0 ]]; then
    exit_error "The following commands are required by this script: ${missing_cmds[*]}"
  fi
}

preflight_checks() {
  declare -a cmds_to_check=(
    realpath
    terraform
  )
  check_for_commands "${cmds_to_check[@]}"
}

function exit_error {
  local status
  if [[ -n $1 && $1 != *[!0-9]* && $1 -ge 2 ]]; then
    status=$1  # use error status given
    shift
  else
    status=2   # default error status
  fi
  write_stderr "Error" "$*"
  exit $status
}

function write_stderr {
  local category=$1 ; shift
  [[ -n $* ]] && printf "\n%s: %s\n\n" "$category" "$*" >&2
}

# display program usage
usage() {
  cat <<EOUSAGE

$_SCRIPT_NAME
  Validates all Terraform configuration files


Usage:
  $_SCRIPT_NAME [options]

Options:
  -h, -?, --help              Show this screen
  --var-file=VARFILE          Specify a var file to use with terraform validate

EOUSAGE
}

parse_cmdline() {
  local opt
  local OPTIND=1
  local long_optarg
    while (( OPTIND <= $# )); do
    if getopts ':h?-:' opt; then
      case $opt in
        h|\?) usage ; exit 0 ;;
        -)
          long_optarg="${OPTARG#*=}"
          case $OPTARG in
            help ) usage ; exit 0 ;;
            help* ) exit_error "No arg allowed for --$OPTARG option" ;;
            var-file=?* ) _OPTIONS+=("--var-file=$long_optarg") ;;
            var-file* ) exit_error "No arg for --$OPTARG option" ;;
            '' ) break ;; # "--" terminates argument processing
            * ) exit_error "Illegal option --$OPTARG" ;;
          esac
          ;;
        :) exit_error "No arg for -$OPTARG option" ;;
      esac
    else
      _POSITIONAL_ARGS+=("${!OPTIND}")
      OPTIND=$(((OPTIND+1)))
    fi
  done            
}

process_paths() {
  local file_with_path
  local index=0
  for file_with_path in "${_POSITIONAL_ARGS[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    _PATHS[index]=$(dirname "$file_with_path")
    (("index+=1"))
  done

  local path_uniq
  for path_uniq in $(echo "${_PATHS[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

      starting_path=$(realpath "$path_uniq")
      terraform_path="$path_uniq"

      # Find the relevant .terraform directory (indicating a 'terraform init'),
      # but fall through to the current directory.
      while [[ "$terraform_path" != "." ]]; do
        if [[ -d "$terraform_path/.terraform" ]]; then
          break
        else
          terraform_path=$(dirname "$terraform_path")
        fi
      done

      local validate_path
      validate_path="${path_uniq#"$terraform_path/"}"
      if [[ $validate_path == "$terraform_path" ]]; then
        validate_path=
      fi

      # Change to the directory that has been initialized, run validation, then
      # change back to the starting directory.
      cd "$(realpath "$terraform_path")"
      if ! terraform validate "${_OPTIONS[@]}" "$validate_path"; then
        error=1
        echo
        echo "Failed path: $path_uniq"
        echo "================================"
      fi
      cd "$starting_path"
    fi
  done

  if [[ "${error}" -ne 0 ]]; then
    exit 1
  fi
}

initialize
preflight_checks

# declare global hash
declare -a _OPTIONS=()
declare -a _PATHS=()
declare -a _POSITIONAL_ARGS=()
error=0

main "$@"

