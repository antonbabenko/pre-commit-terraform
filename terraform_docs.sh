#!/usr/bin/env bash
set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  terraform_docs_ "${ARGS[*]}" "${FILES[@]}"
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
  argv=$(getopt -o a: --long args: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        ARGS+=("$1")
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

terraform_docs_() {
  local -r args="$1"
  shift
  local -a -r files=("$@")

  local hack_terraform_docs
  hack_terraform_docs=$(terraform version | sed -n 1p | grep -c 0.12) || true

  if [[ ! $(command -v terraform-docs) ]]; then
    echo "ERROR: terraform-docs is required by terraform_docs pre-commit hook but is not installed or in the system's PATH."
    exit 1
  fi

  local is_old_terraform_docs
  is_old_terraform_docs=$(terraform-docs version | grep -o "v0.[1-7]\." | tail -1) || true

  if [[ -z "$is_old_terraform_docs" ]]; then # Using terraform-docs 0.8+ (preferred)

    terraform_docs "0" "$args" "${files[@]}"

  elif [[ "$hack_terraform_docs" == "1" ]]; then # Using awk script because terraform-docs is older than 0.8 and terraform 0.12 is used

    if [[ ! $(command -v awk) ]]; then
      echo "ERROR: awk is required for terraform-docs hack to work with Terraform 0.12."
      exit 1
    fi

    local tmp_file_awk
    tmp_file_awk=$(mktemp "${TMPDIR:-/tmp}/terraform-docs-XXXXXXXXXX")
    terraform_docs_awk "$tmp_file_awk"
    terraform_docs "$tmp_file_awk" "$args" "${files[@]}"
    rm -f "$tmp_file_awk"

  else # Using terraform 0.11 and no awk script is needed for that

    terraform_docs "0" "$args" "${files[@]}"

  fi
}

terraform_docs() {
  local -r terraform_docs_awk_file="$1"
  local -r args="$2"
  shift 2
  local -a -r files=("$@")

  declare -a paths
  declare -a tfvars_files

  local index=0
  local file_with_path
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    if [[ "$file_with_path" == *".tfvars" ]]; then
      tfvars_files+=("$file_with_path")
    fi

    ((index += 1))
  done

  local -r tmp_file=$(mktemp)
  local -r text_file="README.md"

  local path_uniq
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    pushd "$path_uniq" > /dev/null

    if [[ ! -f "$text_file" ]]; then
      popd > /dev/null
      continue
    fi

    if [[ "$terraform_docs_awk_file" == "0" ]]; then
      # shellcheck disable=SC2086
      terraform-docs md $args ./ > "$tmp_file"
    else
      # Can't append extension for mktemp, so renaming instead
      local tmp_file_docs
      tmp_file_docs=$(mktemp "${TMPDIR:-/tmp}/terraform-docs-XXXXXXXXXX")
      mv "$tmp_file_docs" "$tmp_file_docs.tf"
      local tmp_file_docs_tf
      tmp_file_docs_tf="$tmp_file_docs.tf"

      awk -f "$terraform_docs_awk_file" ./*.tf > "$tmp_file_docs_tf"
      # shellcheck disable=SC2086
      terraform-docs md $args "$tmp_file_docs_tf" > "$tmp_file"
      rm -f "$tmp_file_docs_tf"
    fi

    # Replace content between markers with the placeholder - https://stackoverflow.com/questions/1212799/how-do-i-extract-lines-between-two-line-delimiters-in-perl#1212834
    perl -i -ne 'if (/BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/../END OF PRE-COMMIT-TERRAFORM DOCS HOOK/) { print $_ if /BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/; print "I_WANT_TO_BE_REPLACED\n$_" if /END OF PRE-COMMIT-TERRAFORM DOCS HOOK/;} else { print $_ }' "$text_file"

    # Replace placeholder with the content of the file
    perl -i -e 'open(F, "'"$tmp_file"'"); $f = join "", <F>; while(<>){if (/I_WANT_TO_BE_REPLACED/) {print $f} else {print $_};}' "$text_file"

    rm -f "$tmp_file"

    popd > /dev/null
  done
}

terraform_docs_awk() {
  local -r output_file=$1

  cat << "EOF" > "$output_file"
# This script converts Terraform 0.12 variables/outputs to something suitable for `terraform-docs`
# As of terraform-docs v0.6.0, HCL2 is not supported. This script is a *dirty hack* to get around it.
# https://github.com/terraform-docs/terraform-docs/
# https://github.com/terraform-docs/terraform-docs/issues/62
# Script was originally found here: https://github.com/cloudposse/build-harness/blob/master/bin/terraform-docs.awk
{
  if ( $0 ~ /\{/ ) {
    braceCnt++
  }
  if ( $0 ~ /\}/ ) {
    braceCnt--
  }
  # ----------------------------------------------------------------------------------------------
  # variable|output "..." {
  # ----------------------------------------------------------------------------------------------
  # [END] variable/output block
  if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt == 0) {
    if (braceCnt == 0 && blockCnt > 0) {
      blockCnt--
      print $0
    }
  }
  # [START] variable or output block started
  if ($0 ~ /^[[:space:]]*(variable|output)[[:space:]][[:space:]]*"(.*?)"/) {
    # Normalize the braceCnt and block (should be 1 now)
    braceCnt = 1
    blockCnt = 1
    # [CLOSE] "default" and "type" block
    blockDefaultCnt = 0
    blockTypeCnt = 0
    # Print variable|output line
    print $0
  }
  # ----------------------------------------------------------------------------------------------
  # default = ...
  # ----------------------------------------------------------------------------------------------
  # [END] multiline "default" continues/ends
  if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt > 0) {
      print $0
      # Count opening blocks
      blockDefaultCnt += gsub(/\(/, "")
      blockDefaultCnt += gsub(/\[/, "")
      blockDefaultCnt += gsub(/\{/, "")
      # Count closing blocks
      blockDefaultCnt -= gsub(/\)/, "")
      blockDefaultCnt -= gsub(/\]/, "")
      blockDefaultCnt -= gsub(/\}/, "")
  }
  # [START] multiline "default" statement started
  if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt == 0) {
    if ($0 ~ /^[[:space:]][[:space:]]*(default)[[:space:]][[:space:]]*=/) {
      if ($3 ~ "null") {
        print "  default = \"null\""
      } else {
        print $0
        # Count opening blocks
        blockDefaultCnt += gsub(/\(/, "")
        blockDefaultCnt += gsub(/\[/, "")
        blockDefaultCnt += gsub(/\{/, "")
        # Count closing blocks
        blockDefaultCnt -= gsub(/\)/, "")
        blockDefaultCnt -= gsub(/\]/, "")
        blockDefaultCnt -= gsub(/\}/, "")
      }
    }
  }
  # ----------------------------------------------------------------------------------------------
  # type  = ...
  # ----------------------------------------------------------------------------------------------
  # [END] multiline "type" continues/ends
  if (blockCnt > 0 && blockTypeCnt > 0 && blockDefaultCnt == 0) {
    # The following 'print $0' would print multiline type definitions
    #print $0
    # Count opening blocks
    blockTypeCnt += gsub(/\(/, "")
    blockTypeCnt += gsub(/\[/, "")
    blockTypeCnt += gsub(/\{/, "")
    # Count closing blocks
    blockTypeCnt -= gsub(/\)/, "")
    blockTypeCnt -= gsub(/\]/, "")
    blockTypeCnt -= gsub(/\}/, "")
  }
  # [START] multiline "type" statement started
  if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt == 0) {
    if ($0 ~ /^[[:space:]][[:space:]]*(type)[[:space:]][[:space:]]*=/ ) {
      if ($3 ~ "object") {
        print "  type = \"object\""
      } else {
        # Convert multiline stuff into single line
        if ($3 ~ /^[[:space:]]*list[[:space:]]*\([[:space:]]*$/) {
          type = "list"
        } else if ($3 ~ /^[[:space:]]*string[[:space:]]*\([[:space:]]*$/) {
          type = "string"
        } else if ($3 ~ /^[[:space:]]*map[[:space:]]*\([[:space:]]*$/) {
          type = "map"
        } else {
          type = $3
        }
        # legacy quoted types: "string", "list", and "map"
        if (type ~ /^[[:space:]]*"(.*?)"[[:space:]]*$/) {
          print "  type = " type
        } else {
          print "  type = \"" type "\""
        }
      }
      # Count opening blocks
      blockTypeCnt += gsub(/\(/, "")
      blockTypeCnt += gsub(/\[/, "")
      blockTypeCnt += gsub(/\{/, "")
      # Count closing blocks
      blockTypeCnt -= gsub(/\)/, "")
      blockTypeCnt -= gsub(/\]/, "")
      blockTypeCnt -= gsub(/\}/, "")
    }
  }
  # ----------------------------------------------------------------------------------------------
  # description = ...
  # ----------------------------------------------------------------------------------------------
  # [PRINT] single line "description"
  if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt == 0) {
    if ($0 ~ /^[[:space:]][[:space:]]*description[[:space:]][[:space:]]*=/) {
      print $0
    }
  }
  # ----------------------------------------------------------------------------------------------
  # value = ...
  # ----------------------------------------------------------------------------------------------
  ## [PRINT] single line "value"
  #if (blockCnt > 0 && blockTypeCnt == 0 && blockDefaultCnt == 0) {
  #  if ($0 ~ /^[[:space:]][[:space:]]*value[[:space:]][[:space:]]*=/) {
  #    print $0
  #  }
  #}
  # ----------------------------------------------------------------------------------------------
  # Newlines, comments, everything else
  # ----------------------------------------------------------------------------------------------
  #if (blockTypeCnt == 0 && blockDefaultCnt == 0) {
  # Comments with '#'
  if ($0 ~ /^[[:space:]]*#/) {
    print $0
  }
  # Comments with '//'
  if ($0 ~ /^[[:space:]]*\/\//) {
    print $0
  }
  # Newlines
  if ($0 ~ /^[[:space:]]*$/) {
    print $0
  }
  #}
}
EOF

}

# global arrays
declare -a ARGS=()
declare -a FILES=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
