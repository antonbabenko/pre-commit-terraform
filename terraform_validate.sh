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

    echo "====================="
    echo "PATH UNIQUE = $path_uniq"

    if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

      local terraform_path
      terraform_path="$path_uniq"
      local ran_terraform_init
      ran_terraform_init=0

      # Find the relevant .terraform directory (indicating a 'terraform init'),
      # but fall through to the current directory.
      while [[ $terraform_path != "." ]]; do
        if [[ -d $terraform_path/.terraform ]]; then
          ran_terraform_init=1
          break
        else
          terraform_path=$(dirname "$terraform_path")
        fi
      done

      local validate_path
      validate_path="${path_uniq#"$terraform_path"}"

      echo "ran_terraform_init = $ran_terraform_init"
      echo "PUSHD = $(realpath "$terraform_path")"

      # Change to the directory that has been initialized, run validation, then
      # change back to the starting directory.
      pushd "$(realpath "$terraform_path")" > /dev/null

      set +e
      echo "VALIDATE COMMAND = terraform validate ${ARGS[@]} $validate_path 2>&1"
      validate_output=$(terraform validate "${ARGS[@]}" "$validate_path" 2>&1)
      validate_code=$?
      set -e

      echo "VALIDATE CODE = $validate_code"

      if [[ $validate_code == 0 ]]; then
        echo "Validation passed: $path_uniq"
        echo "$validate_output"
        echo
        break
      elif [[ $validate_code != 0 && $ran_terraform_init == 1 ]]; then
        error=1
        echo "Validation failed: $path_uniq"
        echo "$validate_output"
        echo
        break
      else

        set +e
        pushd "$validate_path" > /dev/null
        init_output=$(terraform init -backend=false 2>&1)
        init_code=$?
        set -e

        if [[ $init_code != 0 ]]; then
          error=1
          echo "Init failed: $path_uniq"
          echo "$init_output"
          echo
          echo "Validation failed: $path_uniq"
          echo "$validate_output"
          echo
          break
        fi

        set +e
        validate_output=$(terraform validate "${ARGS[@]}")
        validate_code=$?
        set -e

        if [[ $validate_code != 0 ]]; then
          error=1
          echo "Validation failed (after init): $path_uniq"
          echo "$validate_output"
          echo
        fi
      fi

      popd > /dev/null
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
