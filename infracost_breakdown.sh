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
        # Add support for multiline config by replacing `\n` from `.pre-commit-config.yaml` to `;`.
        # .pre-commit-config.yaml:
        # ```yaml
        # - --hook-config=
        #    .totalHourlyCost >  0.1
        #    .totalHourlyCost < 10
        # ````
        # Will be populated to `$1` as:
        # ` .totalHourlyCost > "0.1" .totalHourlyCost <= 1`
        # So, to replace `\n` from `.pre-commit-config.yaml` we should replace ` .` to `;.`.
        config="${1// ./;.}"
        # $config; - separate configs that have spaces one from another
        HOOK_CONFIG+=("$config;")
        shift
        ;;
    esac
  done
}

function get_cost_without_quotes {
  local -r JQ_PATTERN=$1
  local -r INPUT=$2
  local -r CURRENCY=$3

  echo "$(jq "$JQ_PATTERN" <<< "$INPUT") $CURRENCY" | tr -d '"'
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
    echo "WARNING: Hook supports Infracost API version \"0.2\", got \"$API_VERSION\""
    echo "Some things may not work as expected"
  fi

  local dir
  dir="$(jq '.projects[].metadata.vcsSubPath' <<< "$RESULTS")"
  echo -e "\nRunning in $dir"

  local have_failed_checks=false

  # Okay, folks, that is bad solution, but everything else I tried just didn't work.
  # Time spent on this part: 2h
  for check in "${checks[@]}"; do
    [ -z "$check" ] && continue
    # Unify incoming string
    # Remove spaces and quotes, which might be provided by users
    c="$(echo "${check//\"/}" | tr -d '[:space:]')"
    # Separate jq string, comparison operator and compared number
    real_value_path="$(echo "$c" | grep -oP '^\.[.\[\]\w]+')"
    operation="$(echo "$c" | grep -oE '[!<>=]+')"
    user_value="$(echo "$c" | grep -oE '[0-9.,]+$')"
    # Get value from infracost for comparison
    real_value="$(jq "$real_value_path | tonumber" <<< "$RESULTS")"
    # Compare values
    # Crutch to avoid redirection. Eg. `0.1 > 0.1111` will not compare
    # 2 numbers, but create file `0.1111` with `0.1` as its content.
    bash_operation="$(echo "$operation" | tr '>' '<')"

    if [ "$operation" == "$bash_operation" ]; then
      check_passed=$(awk "BEGIN { print $real_value $operation $user_value }")
    else
      check_passed=$(awk "BEGIN { print $user_value $bash_operation $real_value }")
    fi

    status="Passed"
    color="green"
    if [ "$check_passed" == "0" ]; then
      status="Failed"
      color="red"
      have_failed_checks=true
    fi
    # Print each check result
    common::colorify $color "$status: $check. $real_value $operation $user_value"
  done

  # Fancy informational output
  currency="$(jq '.currency' <<< "$RESULTS")"

  printf "\nSummary: $(jq '.summary' <<< "$RESULTS")"

  printf "\nTotal Hourly Cost:        "
  get_cost_without_quotes '.totalHourlyCost' "$RESULTS" "$currency"
  printf "Total Hourly Cost (diff): "
  get_cost_without_quotes '.projects[].diff.totalHourlyCost' "$RESULTS" "$currency"

  printf "\nTotal Monthly Cost:        "
  get_cost_without_quotes '.totalMonthlyCost' "$RESULTS" "$currency"
  printf "Total Monthly Cost (diff): "
  get_cost_without_quotes '.projects[].diff.totalMonthlyCost' "$RESULTS" "$currency"

  if $have_failed_checks; then
    exit 1
  fi
}

# global arrays
declare -a ARGS=()
declare -a HOOK_CONFIG=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
