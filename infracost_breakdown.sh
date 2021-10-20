#!/usr/bin/env bash
set -eo pipefail

main() {
  common::initialize
  common::parse_cmdline "$@"
  infracost_breakdown_ "${HOOK_CONFIG[*]}" "${ARGS[*]}"
}

function common::colorify {
  # Colors. Provided as first string to first arg of function.
  # shellcheck disable=SC2034
  local -r red="$(tput setaf 1)"
  # shellcheck disable=SC2034
  local -r green="$(tput setaf 2)"
  # shellcheck disable=SC2034
  local -r yellow="$(tput setaf 3)"
  # Color reset
  local -r RESET="$(tput sgr0)"

  # Params start #
  local COLOR="${!1}"
  local -r TEXT=$2
  # Params end #

  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    COLOR=$RESET
  fi

  echo -e "${COLOR}${TEXT}${RESET}"
}

function common::initialize {
  local SCRIPT_DIR
  # get directory containing this script
  SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

  # source getopt function
  # shellcheck source=lib_getopt
  . "$SCRIPT_DIR/lib_getopt"
}

function common::parse_cmdline {
  local argv
  argv=$(getopt -o a:,h: --long args:,hook-config: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        ARGS+=("$1")
        shift
        ;;
      -h | --hook-config)
        shift
        HOOK_CONFIG+=("$1;")
        shift
        ;;
    esac
  done
}

function infracost_breakdown_ {
  local -r hook_config="$1"
  local args
  read -r -a args <<< "$2"

  # Get hook settings
  IFS=";" read -r -a checks <<< "$hook_config"

  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    args+=("--no-color")
  fi

  local RESULTS
  RESULTS="$(infracost breakdown "${args[@]}" --format json)"
  local API_VERSION
  API_VERSION="$(jq -r .version <<< "$RESULTS")"

  if [ "$API_VERSION" != "0.2" ]; then
    common::colorify "yellow" "WARNING: Hook supports Infracost API version \"0.2\", got \"$API_VERSION\""
    common::colorify "yellow" "         Some things may not work as expected"
  fi

  local dir
  dir="$(jq '.projects[].metadata.vcsSubPath' <<< "$RESULTS")"
  echo -e "\nRunning in $dir"

  local have_failed_checks=false

  for check in "${checks[@]}"; do
    check=$(echo "$check" | sed 's/^[[:space:]]*//')
    # Compare values
    check_passed="$(echo "$RESULTS" | jq "$check")"

    status="Passed"
    color="green"
    if ! $check_passed; then
      status="Failed"
      color="red"
      have_failed_checks=true
    fi

    # Print each check result
    operation="$(echo "$check" | grep -oE '[!<>=]+')"
    IFS="$operation" read -r -a jq_check <<< "$check"
    real_value="$(jq "${jq_check[0]}" <<< "$RESULTS")"
    compare_value="${jq_check[1]}${jq_check[2]}"

    common::colorify $color "$status: $check\t\t$real_value $operation $compare_value"
  done

  # Fancy informational output
  currency="$(jq -r '.currency' <<< "$RESULTS")"

  echo -e "\nSummary: $(jq -r '.summary' <<< "$RESULTS")"

  echo -e "\nTotal Hourly Cost:        $(jq -r .totalHourlyCost <<< "$RESULTS") $currency"
  echo "Total Hourly Cost (diff): $(jq -r .projects[].diff.totalHourlyCost <<< "$RESULTS") $currency"

  echo -e "\nTotal Monthly Cost:        $(jq -r .totalMonthlyCost <<< "$RESULTS") $currency"
  echo "Total Monthly Cost (diff): $(jq -r .projects[].diff.totalMonthlyCost <<< "$RESULTS") $currency"

  if $have_failed_checks; then
    exit 1
  fi
}

# global arrays
declare -a ARGS=()
declare -a HOOK_CONFIG=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
