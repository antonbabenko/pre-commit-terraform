#!/usr/bin/env bash
set -eo pipefail

# `terraform validate` requires this env variable to be set
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

main() {
  initialize_
  parse_cmdline_ "$@"
  terraform_validate_
}

to_abs_path() {
    local target="$1"

    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
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
  argv=$(getopt -o e:a:x:d --long envs:,args:,exclude-path:,use-temp-data-dir -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -d | --use-temp-data-dir)
        USE_TEMP_DATA_DIR=1
        shift
        ;;
      -x | --exclude-path)
        shift
        EXCLUDED_PATHS+=("$(to_abs_path $1)")
        shift
        ;;
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

    if [[ "${EXCLUDED_PATHS[@]}" =~ "$(dirname "$file_with_path")" ]]; then
      continue
    fi

    paths[index]=$(dirname "$file_with_path")
    ((index += 1))
  done

  local path_uniq
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

      pushd "$(realpath "$path_uniq")" > /dev/null

      if [[ $USE_TEMP_DATA_DIR != 0 ]]; then
        export TF_DATA_DIR=$(mktemp -d)
        dot_terraform_path=${TF_DATA_DIR}
      else
        dot_terraform_path=.terraform
      fi

      if [[ ! -d ${dot_terraform_path} ]] || [[ $USE_TEMP_DATA_DIR != 0 ]]; then
        set +e
        init_output=$(terraform init -backend=false 2>&1)
        init_code=$?
        set -e

        if [[ $init_code != 0 ]]; then
          error=1
          if [[ "${TF_DATA_DIR}" != "" ]]; then
            rm -rf ${TF_DATA_DIR}
            unset TF_DATA_DIR
          fi
          echo "Init before validation failed: $path_uniq"
          echo "$init_output"
          popd > /dev/null
          continue
        fi
      fi

      set +e
      validate_output=$(terraform validate "${ARGS[@]}" 2>&1)
      validate_code=$?
      set -e

      if [[ "${TF_DATA_DIR}" != "" ]]; then
        rm -rf ${TF_DATA_DIR}
        unset TF_DATA_DIR
      fi

      if [[ $validate_code != 0 ]]; then
        error=1
        echo "Validation failed: $path_uniq"
        echo "$validate_output"
        echo
      fi

      popd > /dev/null
    fi
  done

  if [[ $error -ne 0 ]]; then
    exit 1
  fi
}

# global arrays
declare -a ARGS
declare -a ENVS
declare -a FILES

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
