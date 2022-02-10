#!/usr/bin/env bash
set -eo pipefail

# globals variables
# hook ID, see `- id` for details in .pre-commit-hooks.yaml file
# shellcheck disable=SC2034 # Unused var.
readonly HOOK_ID='infracost_breakdown'
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  # shellcheck disable=SC2153 # False positive
  infracost_breakdown_ "${HOOK_CONFIG[*]}" "${ARGS[*]}"
}

#######################################################################
# Wrapper around `infracost breakdown` tool which checks and compares
# infra cost based on provided hook_config
# Environment variables:
#   PRE_COMMIT_COLOR (string) If set to `never` - do not colorize output
# Arguments:
#   hook_config (string with array) arguments that configure hook behavior
#   args (string with array) arguments that configure wrapped tool behavior
# Outputs:
#   Print out hook checks status (Passed/Failed), total monthly cost and
#   diff, summary about infracost check (non-supported resources etc.)
#######################################################################
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
    # $hook_config receives string like '1 > 2; 3 == 4;' etc.
    # It gets split by `;` into array, which we're parsing here ('1 > 2' ' 3 == 4')
    # Next line removes leading spaces, just for fancy output reason.
    # shellcheck disable=SC2001 # Rule exception
    check=$(echo "$check" | sed 's/^[[:space:]]*//')

    # Drop quotes in hook args section. From:
    # -h ".totalHourlyCost > 0.1"
    # --hook-config='.currency == "USD"'
    # To:
    # -h .totalHourlyCost > 0.1
    # --hook-config=.currency == "USD"
    first_char=${check:0:1}
    last_char=${check: -1}
    if [ "$first_char" == "$last_char" ] && {
      [ "$first_char" == '"' ] || [ "$first_char" == "'" ]
    }; then
      check="${check:1:-1}"
    fi

    mapfile -t operations < <(echo "$check" | grep -oE '[!<>=]{1,2}')
    # Get the very last operator, that is used in comparison inside `jq` query.
    # From the example below we need to pick the `>` which is in between `add` and `1000`,
    # but not the `!=`, which goes earlier in the `jq` expression
    # [.projects[].diff.totalMonthlyCost | select (.!=null) | tonumber] | add > 1000
    operation=${operations[-1]}

    IFS="$operation" read -r -a jq_check <<< "$check"
    real_value="$(jq "${jq_check[0]}" <<< "$RESULTS")"
    compare_value="${jq_check[1]}${jq_check[2]}"
    # Check types
    jq_check_type="$(jq -r "${jq_check[0]} | type" <<< "$RESULTS")"
    compare_value_type="$(jq -r "$compare_value | type" <<< "$RESULTS")"
    # Fail if comparing different types
    if [ "$jq_check_type" != "$compare_value_type" ]; then
      common::colorify "yellow" "Warning: Comparing values with different types may give incorrect result"
      common::colorify "yellow" "         Expression: $check"
      common::colorify "yellow" "         Types in the expression: [$jq_check_type] $operation [$compare_value_type]"
      common::colorify "yellow" "         Use 'tonumber' filter when comparing costs (e.g. '.totalMonthlyCost|tonumber')"
      have_failed_checks=true
      continue
    fi
    # Fail if string is compared not with `==` or `!=`
    if [ "$jq_check_type" == "string" ] && {
      [ "$operation" != '==' ] && [ "$operation" != '!=' ]
    }; then
      common::colorify "yellow" "Warning: Wrong comparison operator is used in expression: $check"
      common::colorify "yellow" "         Use 'tonumber' filter when comparing costs (e.g. '.totalMonthlyCost|tonumber')"
      common::colorify "yellow" "         Use '==' or '!=' when comparing strings (e.g. '.currency == \"USD\"')."
      have_failed_checks=true
      continue
    fi

    # Compare values
    check_passed="$(echo "$RESULTS" | jq "$check")"

    status="Passed"
    color="green"
    if ! $check_passed; then
      status="Failed"
      color="red"
      have_failed_checks=true
    fi

    # Print check result
    common::colorify $color "$status: $check\t\t$real_value $operation $compare_value"
  done

  # Fancy informational output
  currency="$(jq -r '.currency' <<< "$RESULTS")"

  echo -e "\nSummary: $(jq -r '.summary' <<< "$RESULTS")"

  echo -e "\nTotal Monthly Cost:        $(jq -r .totalMonthlyCost <<< "$RESULTS") $currency"
  echo "Total Monthly Cost (diff): $(jq -r .projects[].diff.totalMonthlyCost <<< "$RESULTS") $currency"

  if $have_failed_checks; then
    exit 1
  fi
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
