#!/usr/bin/env bash
set -eo pipefail

# globals variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

insertion_marker_begin="<!-- BEGIN_TF_DOCS -->"
insertion_marker_end="<!-- END_TF_DOCS -->"
doc_header="# "

# Old markers used by the hook before the introduction of the terraform-docs markers
readonly old_insertion_marker_begin="<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->"
readonly old_insertion_marker_end="<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars
  # Support for setting relative PATH to .terraform-docs.yml config.
  for i in "${!ARGS[@]}"; do
    ARGS[i]=${ARGS[i]/--config=/--config=$(pwd)\/}
  done
  # shellcheck disable=SC2153 # False positive
  terraform_docs "${HOOK_CONFIG[*]}" "${ARGS[*]}" "${FILES[@]}"
}

#######################################################################
# Function to replace old markers with new markers affected files
# Globals:
#   insertion_marker_begin - Standard insertion marker at beginning
#   insertion_marker_end - Standard insertion marker at the end
#   old_insertion_marker_begin - Old insertion marker at beginning
#   old_insertion_marker_end - Old insertion marker at the end
# Arguments:
#   file (string) filename to check
#######################################################################
function replace_old_markers {
  local -r file=$1

  # Determine the appropriate sed command based on the operating system (GNU sed or BSD sed)
  sed --version &> /dev/null && SED_CMD=(sed -i) || SED_CMD=(sed -i '')
  "${SED_CMD[@]}" -e "s/^${old_insertion_marker_begin}$/${insertion_marker_begin//\//\\/}/" "$file"
  "${SED_CMD[@]}" -e "s/^${old_insertion_marker_end}$/${insertion_marker_end//\//\\/}/" "$file"
}

#######################################################################
# Wrapper around `terraform-docs` tool that checks and changes/creates
# (depending on provided hook_config) terraform documentation in
# Markdown
# Arguments:
#   hook_config (string with array) arguments that configure hook behavior
#   args (string with array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function terraform_docs {
  local -r hook_config="$1"
  local args="$2"
  shift 2
  local -a -r files=("$@")

  if [[ ! $(command -v terraform-docs) ]]; then
    echo "ERROR: terraform-docs is required by terraform_docs pre-commit hook but is not installed or in the system's PATH."
    exit 1
  fi

  local -a paths

  local index=0
  local file_with_path
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done

  #
  # Get hook settings
  #
  local output_file="README.md"
  local output_mode="inject"
  local use_path_to_file=false
  local add_to_existing=false
  local create_if_not_exist=false
  local use_standard_markers=true
  local have_config_flag=false

  IFS=";" read -r -a configs <<< "$hook_config"

  for c in "${configs[@]}"; do

    IFS="=" read -r -a config <<< "$c"
    # $hook_config receives string like '--foo=bar; --baz=4;' etc.
    # It gets split by `;` into array, which we're parsing here ('--foo=bar' ' --baz=4')
    # Next line removes leading spaces, to support >1 `--hook-config` args
    key="${config[0]## }"
    value=${config[1]}

    case $key in
      --path-to-file)
        output_file=$value
        use_path_to_file=true
        ;;
      --add-to-existing-file)
        add_to_existing=$value
        ;;
      --create-file-if-not-exist)
        create_if_not_exist=$value
        ;;
      --use-standard-markers)
        use_standard_markers=$value
        common::colorify "yellow" "WARNING: --use-standard-markers is deprecated and will be removed in the future."
        common::colorify "yellow" "         All needed changes already done by the hook, feel free to remove --use-standard-markers setting from your pre-commit config"
        ;;
      --custom-marker-begin)
        insertion_marker_begin=$value
        common::colorify "green" "INFO: --custom-marker-begin is used and the marker is set to \"$value\"."
        ;;
      --custom-marker-end)
        insertion_marker_end=$value
        common::colorify "green" "INFO: --custom-marker-end is used and the marker is set to \"$value\"."
        ;;
      --custom-doc-header)
        doc_header=$value
        common::colorify "green" "INFO: --custom-doc-header is used and the doc header is set to \"$value\"."
        ;;
    esac
  done

  if [[ $use_standard_markers == false ]]; then
    # update the insertion markers to those used by pre-commit-terraform before v1.93
    insertion_marker_begin="$old_insertion_marker_begin"
    insertion_marker_end="$old_insertion_marker_end"
  fi

  # Override formatter if no config file set
  if [[ "$args" != *"--config"* ]]; then
    local tf_docs_formatter="md"

  else
    have_config_flag=true
    # Enable extended pattern matching operators
    shopt -qp extglob || EXTGLOB_IS_NOT_SET=true && shopt -s extglob
    # Trim any args before the `--config` arg value
    local config_file=${args##*--config@(+([[:space:]])|=)}
    # Trim any trailing spaces and args (if any)
    config_file="${config_file%%+([[:space:]])?(--*)}"
    # Trim `--config` arg and its value from original args as we will
    # pass `--config` separately to allow whitespaces in its value
    args=${args/--config@(+([[:space:]])|=)$config_file*([[:space:]])/}
    # Restore state of `extglob` if we changed it
    [[ $EXTGLOB_IS_NOT_SET ]] && shopt -u extglob

    # Prioritize `.terraform-docs.yml` `output.file` over
    # `--hook-config=--path-to-file=` if it set
    local config_output_file
    # Get latest non-commented `output.file` from `.terraform-docs.yml`
    config_output_file=$(grep -A1000 -e '^output:$' "$config_file" 2> /dev/null | grep -E '^[[:space:]]+file:' | tail -n 1) || true

    if [[ $config_output_file ]]; then
      # Extract filename from `output.file` line
      config_output_file=$(echo "$config_output_file" | awk -F':' '{print $2}' | tr -d '[:space:]"' | tr -d "'")

      if [[ $use_path_to_file == true && "$config_output_file" != "$output_file" ]]; then
        common::colorify "yellow" "NOTE: You set both '--hook-config=--path-to-file=$output_file' and 'output.file: $config_output_file' in '$config_file'"
        common::colorify "yellow" "      'output.file' from '$config_file' will be used."
      fi

      output_file=$config_output_file
    fi

    # Use `.terraform-docs.yml` `output.mode` if it set
    local config_output_mode
    config_output_mode=$(grep -A1000 -e '^output:$' "$config_file" 2> /dev/null | grep -E '^[[:space:]]+mode:' | tail -n 1) || true
    if [[ $config_output_mode ]]; then
      # Extract mode from `output.mode` line
      output_mode=$(echo "$config_output_mode" | awk -F':' '{print $2}' | tr -d '[:space:]"' | tr -d "'")
    fi

    # Suppress terraform_docs color
    local config_file_no_color
    config_file_no_color="$config_file$(date +%s).yml"

    if [ "$PRE_COMMIT_COLOR" = "never" ] &&
      [[ $(grep -e '^formatter:' "$config_file") == *"pretty"* ]] &&
      [[ $(grep '  color: ' "$config_file") != *"false"* ]]; then

      cp "$config_file" "$config_file_no_color"
      echo -e "settings:\n  color: false" >> "$config_file_no_color"
      args=${args/$config_file/$config_file_no_color}
    fi
  fi

  local dir_path
  for dir_path in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    dir_path="${dir_path//__REPLACED__SPACE__/ }"

    pushd "$dir_path" > /dev/null || continue

    #
    # Create file if it not exist and `--create-if-not-exist=true` provided
    #
    if $create_if_not_exist && [[ ! -f "$output_file" ]]; then
      dir_have_tf_files="$(
        find . -maxdepth 1 -type f | sed 's|.*\.||' | sort -u | grep -oE '^tf$|^tfvars$' ||
          exit 0
      )"

      # if no TF files - skip dir
      [ ! "$dir_have_tf_files" ] && popd > /dev/null && continue

      dir="$(dirname "$output_file")"

      mkdir -p "$dir"

      # Use of insertion markers, where there is no existing README file
      {
        echo -e "${doc_header}${PWD##*/}\n"
        echo "$insertion_marker_begin"
        echo "$insertion_marker_end"
      } >> "$output_file"
    fi

    # If file still not exist - skip dir
    [[ ! -f "$output_file" ]] && popd > /dev/null && continue

    replace_old_markers "$output_file"

    #
    # If `--add-to-existing-file=false` (default behavior), check if "hook markers" exist in file,
    # and, if not, skip execution to avoid addition of terraform-docs section, as
    # terraform-docs in 'inject' mode adds markers by default if they are not present
    #
    if [[ $add_to_existing == false ]]; then
      have_marker=$(grep -o "$insertion_marker_begin" "$output_file") || unset have_marker
      [[ ! $have_marker ]] && popd > /dev/null && continue
    fi

    # shellcheck disable=SC2206
    # Need to pass $tf_docs_formatter and $args as separate arguments, not as single string
    local tfdocs_cmd=(
      terraform-docs
      --output-mode="$output_mode"
      --output-file="$output_file"
      $tf_docs_formatter
      $args
    )
    if [[ $have_config_flag == true ]]; then
      "${tfdocs_cmd[@]}" "--config=$config_file" ./ > /dev/null
    else
      "${tfdocs_cmd[@]}" ./ > /dev/null
    fi

    popd > /dev/null
  done

  # Cleanup
  rm -f "$config_file_no_color"
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
