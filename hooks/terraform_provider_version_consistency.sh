#!/usr/bin/env bash
set -eo pipefail

# globals variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"

  # Default patterns
  local version_file_pattern="versions.tf"
  local exclude_pattern='.terraform/'

  # Parse hook-specific config
  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"
  for c in "${configs[@]}"; do
    IFS="=" read -r -a config <<< "$c"
    key="${config[0]## }"
    local value=${config[1]}

    case $key in
      --version-file-pattern)
        version_file_pattern="$value"
        ;;
      --exclude-pattern)
        exclude_pattern="$value"
        ;;
    esac
  done

  check_provider_version_consistency "$version_file_pattern" "$exclude_pattern"
}

#######################################################################
# Check that provider version constraints are consistent across all
# versions.tf files in the repository
# Arguments:
#   version_file_pattern (string) Pattern for version files (default: versions.tf)
#   exclude_pattern (string) Pattern to exclude (default: .terraform/)
# Outputs:
#   If inconsistent - print out which files have different versions
#######################################################################
function check_provider_version_consistency {
  local -r version_file_pattern="$1"
  local -r exclude_pattern="$2"

  # Find all version files, excluding specified pattern
  local version_files
  version_files=$(find . -name "$version_file_pattern" -type f ! -path "*${exclude_pattern}*" 2>/dev/null | sort)

  if [[ -z "$version_files" ]]; then
    common::colorify "yellow" "No $version_file_pattern files found"
    return 0
  fi

  local file_count
  file_count=$(echo "$version_files" | wc -l | tr -d ' ')

  if [[ "$file_count" -eq 1 ]]; then
    common::colorify "green" "Only one $version_file_pattern file found, skipping consistency check"
    return 0
  fi

  # Extract all unique provider version constraint lines
  local all_versions
  # shellcheck disable=SC2086 # Word splitting is intentional
  all_versions=$(grep -hE '^\s*version\s*=' $version_files 2>/dev/null | \
    sed 's/^[[:space:]]*//' | sort -u)

  # Handle case where no provider version constraints found
  if [[ -z "$all_versions" ]]; then
    common::colorify "yellow" "No provider version constraints found in $version_file_pattern files"
    return 0
  fi

  local unique_count
  unique_count=$(echo "$all_versions" | wc -l | tr -d ' ')

  if [[ "$unique_count" -eq 1 ]]; then
    common::colorify "green" "All provider versions are consistent across $file_count files"
    return 0
  fi

  # Versions are inconsistent - report details
  common::colorify "red" "Inconsistent provider versions found across $file_count files:"
  echo ""

  local file
  # shellcheck disable=SC2086 # Word splitting is intentional
  for file in $version_files; do
    echo "--- $file"
    grep -E '^\s*version\s*=' "$file" 2>/dev/null | sed 's/^/  /'
  done

  echo ""
  common::colorify "yellow" "Found $unique_count different version constraints:"
  echo "$all_versions" | sed 's/^/  /'

  return 1
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
