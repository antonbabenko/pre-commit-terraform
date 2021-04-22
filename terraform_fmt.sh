#!/usr/bin/env bash
set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"

  # If a specific terraform version was specified, switch to it. The tfenv lib will auto-restore on exit
  [ "$TFVER" != "" ] && . "$_SCRIPT_DIR/lib_tfenv" && switchTfEnv "$TFVER"

  terraform_fmt_ "${FILES[@]}"
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
  argv=$(getopt -o t: --long tf-version: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -t | --tf-version)
        shift
        TFVER="$1"
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

terraform_fmt_() {
  local -a -r files=("$@")
  declare -a paths
  declare -a tfvars_files

  index=0

  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    if [[ "$file_with_path" == *".tfvars" ]]; then
      tfvars_files+=("$file_with_path")
    fi

    let "index+=1"
  done

  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    pushd "$path_uniq" > /dev/null
    terraform fmt
    popd > /dev/null
  done

  # terraform.tfvars are excluded by `terraform fmt`
  for tfvars_file in "${tfvars_files[@]}"; do
    tfvars_file="${tfvars_file//__REPLACED__SPACE__/ }"

    terraform fmt "$tfvars_file"
  done
}

# global variables
declare TFVER=""
declare -a FILES=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
