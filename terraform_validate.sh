#!/usr/bin/env bash
set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  terraform_validate_
}

initialize_() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"
  while [[ -L $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$(cd -P "$(dirname "$source")" > /dev/null && pwd)"
    source="$(readlink "$source")"
    # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_DIR="$(dirname "$source")"

  # source getopt function
  # shellcheck source=lib_getopt
  . "$_SCRIPT_DIR/lib_getopt"
}

parse_cmdline_() {
  declare argv
  argv=$(getopt -o e:a: --long envs:,args: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        ARGS+=("$1")
        shift
        ;;
      -e | --envs)
        shift
        ENVS+=("$1")
        shift
        ;;
      --)
        shift
        FILES=("$@")
        break
        ;;
    esac
  done
}

terraform_validate_() {

  # Setup environment variables
  local var var_name var_value
  for var in "${ENVS[@]}"; do
    var_name="${var%%=*}"
    var_value="${var#*=}"
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done

  declare -a paths
  local index=0
  local error=0

  local file_with_path
  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")
    ((index += 1))
  done

  local path_uniq
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

      local starting_path
      starting_path=$(realpath "$path_uniq")
      local terraform_path
      terraform_path="$path_uniq"

      # Find the relevant .terraform directory (indicating a 'terraform init'),
      # but fall through to the current directory.
      while [[ $terraform_path != "." ]]; do
        if [[ -d $terraform_path/.terraform ]]; then
          break
        else
          terraform_path=$(dirname "$terraform_path")
        fi
      done

      local validate_path
      validate_path="${path_uniq#"$terraform_path"}"

      # Change to the directory that has been initialized, run validation, then
      # change back to the starting directory.
      cd "$(realpath "$terraform_path")"
      if ! terraform validate "${ARGS[@]}" "$validate_path"; then
        error=1
        echo
        echo "Failed path: $path_uniq"
        echo "================================"
      fi
      cd "$starting_path"
    fi
  done

  if [[ $error -ne 0 ]]; then
    exit 1
  fi
}

# global arrays
declare -a ARGS
declare -a ENVS
declare -a FILES

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
