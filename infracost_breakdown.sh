#!/usr/bin/env bash
set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  infracost_breakdown_ "${HOOK_CONFIG[*]}" "${ARGS[*]}" "${FILES[@]}"
}

# Colorify

function colorify {
  # Params start #
  local -r COLOR=$1
  local -r TEXT=$2
  # Params end #

  # shellcheck disable=SC2034 # used in eval
  local -r red="$(tput setaf 1)"
  # shellcheck disable=SC2034 # used in eval
  local -r green="$(tput setaf 2)"
  local -r reset="$(tput sgr0)"

  eval color='$'$COLOR
  echo "${color}${TEXT}${reset}"
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
  argv=$(getopt -o a: --long args:,hook-config: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        ARGS+=("$1")
        shift
        ;;
      --hook-config)
        shift
        HOOK_CONFIG+=("$1;")
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

function get_cost_w/o_quotes {
  local -r JQ_PATTERN=$1
  local -r INPUT=$2
  local -r CURRENCY=$3

  echo "$(echo "$(jq "$JQ_PATTERN" <<< $INPUT) $CURRENCY" | tr -d \")"
}

infracost_breakdown_() {
  local -r hook_config="$1"
  local args
  IFS=" " read -r -a args <<< "$2"
  shift 2
  local -a -r files=("$@") #? Useless?

  # Get hook settings
  IFS=";" read -r -a checks <<< "$hook_config"

  RESULTS="$(infracost breakdown "${args[@]}" --format json)"

  API_VERSION="$(jq .version <<< $RESULTS)"

  if [ ! "$API_VERSION" = '"0.2"' ]; then
    echo "WARNING: Hook supported Infracost API version \"0.2\", got $API_VERSION"
    echo "Some things could not works"
  fi

  local dir
  dir="$(jq '.projects[].metadata.vcsSubPath' <<< $RESULTS)"
  echo -e "\nRun in $dir"

  local have_failed_checks=false

  for check in "${checks[@]}"; do
    check_passed=$(jq "$check" <<< $RESULTS)

    status="Passed"
    color="green"
    if ! $check_passed; then
      status="Failed"
      color="red"
      have_failed_checks=true
    fi

    value="$(jq "$(echo $check | awk '{print $1}')" <<< $RESULTS)"

    colorify $color "$status: $check. Got value: $value"
  done

  # Fancy informational output
  currency="$(jq '.currency' <<< $RESULTS)"

  printf "\nSummary: $(jq '.summary' <<< $RESULTS)"

  printf "\nTotal Hourly Cost:        "
  get_cost_w/o_quotes '.totalHourlyCost' "$RESULTS" "$currency"
  printf "Total Hourly Cost (diff): "
  get_cost_w/o_quotes '.projects[].diff.totalHourlyCost' "$RESULTS" "$currency"

  printf "\nTotal Monthly Cost:        "
  get_cost_w/o_quotes '.totalMonthlyCost' "$RESULTS" "$currency"
  printf "Total Monthly Cost (diff): "
  get_cost_w/o_quotes '.projects[].diff.totalMonthlyCost' "$RESULTS" "$currency"

  if $have_failed_checks; then
    exit 1
  fi
}

# global arrays
declare -a ARGS=()
declare -a FILES=()
declare -a HOOK_CONFIG=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
