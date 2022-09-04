#!/usr/bin/env bash
set -eo pipefail

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# expected base to strip from repository name to get the module resource name
readonly REPO_BASE_PATTERN="terraform-aws-(.*)"

# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars
  # JFYI: suppress color for `hcledit` is N/A`

  check_dependencies

  # shellcheck disable=SC2153 # False positive
  terraform_module_wrapper_ "${ARGS[*]}"
}

readonly CONTENT_MAIN_TF='module "wrapper" {}'
readonly CONTENT_VARIABLES_TF='variable "defaults" {
  description = "Map of default values which will be used for each item."
  type        = any
  default     = {}
}

variable "items" {
  description = "Maps of items to create a wrapper from. Values are passed through to the module."
  type        = any
  default     = {}
}'
readonly CONTENT_OUTPUTS_TF='output "wrapper" {
  description = "Map of outputs of a wrapper."
  value       = module.wrapper
  WRAPPER_OUTPUT_SENSITIVE
}'
readonly CONTENT_VERSIONS_TF='terraform {
  required_version = ">= 0.13.1"
}'
# shellcheck disable=SC2016 # False positive
readonly CONTENT_README='# WRAPPER_TITLE

The configuration in this directory contains an implementation of a single module wrapper pattern, which allows managing several copies of a module in places where using the native Terraform 0.13+ `for_each` feature is not feasible (e.g., with Terragrunt).

You may want to use a single Terragrunt configuration file to manage multiple resources without duplicating `terragrunt.hcl` files for each copy of the same module.

This wrapper does not implement any extra functionality.

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///MODULE_REPO_ORG/MODULE_REPO_SHORTNAME/MODULE_REPO_PROVIDER//WRAPPER_PATH"
  # Alternative source:
  # source = "git::git@github.com:MODULE_REPO_ORG/terraform-MODULE_REPO_PROVIDER-MODULE_REPO_SHORTNAME.git//WRAPPER_PATH?ref=master"
}

inputs = {
  defaults = { # Default values
    create = true
    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```

## Usage with Terraform

```hcl
module "wrapper" {
  source = "MODULE_REPO_ORG/MODULE_REPO_SHORTNAME/MODULE_REPO_PROVIDER//WRAPPER_PATH"

  defaults = { # Default values
    create = true
    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```

## Example: Manage multiple S3 buckets in one Terragrunt layer

`eu-west-1/s3-buckets/terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//wrappers"
  # Alternative source:
  # source = "git::git@github.com:terraform-aws-modules/terraform-aws-s3-bucket.git//wrappers?ref=master"
}

inputs = {
  defaults = {
    force_destroy = true

    attach_elb_log_delivery_policy        = true
    attach_lb_log_delivery_policy         = true
    attach_deny_insecure_transport_policy = true
    attach_require_latest_tls_policy      = true
  }

  items = {
    bucket1 = {
      bucket = "my-random-bucket-1"
    }
    bucket2 = {
      bucket = "my-random-bucket-2"
      tags = {
        Secure = "probably"
      }
    }
  }
}
```'

function terraform_module_wrapper_ {
  local args
  read -r -a args <<< "$1"

  local root_dir
  local module_dir="" # values: empty (default), "." (just root module), or a single module (e.g. "modules/iam-user")
  local wrapper_dir="wrappers"
  local wrapper_relative_source_path="../" # From "wrappers" to root_dir.
  local module_repo_org
  local module_repo_shortname
  local module_repo_provider
  local dry_run="false"
  local verbose="false"

  root_dir=$(git rev-parse --show-toplevel 2> /dev/null || pwd)
  module_repo_org="terraform-aws-modules"
  module_repo_shortname="$(determine_repo_shortname "${root_dir}")"
  module_repo_provider="aws"

  for argv in "${args[@]}"; do

    local key="${argv%%=*}"
    local value="${argv#*=}"

    case "$key" in
      --root-dir)
        root_dir="$value"
        ;;
      --module-dir)
        module_dir="$value"
        ;;
      --wrapper-dir)
        wrapper_dir="$value"
        ;;
      --module-repo-org)
        module_repo_org="$value"
        ;;
      --module-repo-shortname)
        module_repo_shortname="$value"
        ;;
      --module-repo-provider)
        module_repo_provider="$value"
        ;;
      --dry-run)
        dry_run="true"
        ;;
      --verbose)
        verbose="true"
        ;;
      *)
        cat << EOF
ERROR: Unrecognized argument: $key
Hook ID: $HOOK_ID.
Generate Terraform module wrapper. Available arguments:
--root-dir=...                - Root dir of the repository (Optional)
--module-dir=...              - Single module directory. Options: "." (means just root module),
                                "modules/iam-user" (a single module), or empty (means include all
                                submodules found in "modules/*"). Default: "${module_dir}". (Optional)
--wrapper-dir=...             - Directory where 'wrappers' should be saved. Default: "${wrapper_dir}". (Optional)
--module-repo-org=...         - Module repository organization (e.g., 'terraform-aws-modules'). (Optional)
--module-repo-shortname=...   - Short name of the repository (e.g., for 'terraform-aws-s3-bucket' it should be 's3-bucket'). (Optional)
--module-repo-provider=...    - Name of the repository provider (e.g., for 'terraform-aws-s3-bucket' it should be 'aws'). (Optional)
--dry-run                     - Whether to run in dry mode. If not specified, wrapper files will be overwritten.
--verbose                     - Show verbose output.

Example:
--module-dir=modules/object   - Generate wrapper for one specific submodule.
--module-dir=.                - Generate wrapper for the root module.
--module-repo-org=terraform-google-modules --module-repo-shortname=network --module-repo-provider=google  - Generate wrappers for repository available by name "terraform-google-modules/network/google" in the Terraform registry and it includes all modules (root and in "modules/*").
EOF
        exit 1
        ;;
    esac

  done

  if [[ ! $root_dir ]]; then
    echo "--root-dir can't be empty. Remove it to use default value."
    exit 1
  fi

  if [[ ! $wrapper_dir ]]; then
    echo "--wrapper-dir can't be empty. Remove it to use default value."
    exit 1
  fi

  if [[ ! $module_repo_org ]]; then
    echo "--module-repo-org can't be empty. Remove it to use default value."
    exit 1
  fi

  if [[ ! $module_repo_shortname ]]; then
    echo "--module-repo-shortname can't be empty. It should be part of full repo name (eg, s3-bucket)."
    exit 1
  fi

  if [[ ! $module_repo_provider ]]; then
    echo "--module-repo-provider can't be empty. It should be name of the provider used by the module (eg, aws)."
    exit 1
  fi

  if [[ ! -d "$root_dir" ]]; then
    echo "Root directory $root_dir does not exist!"
    exit 1
  fi

  OLD_IFS="$IFS"
  IFS=$'\n'

  all_module_dirs=("./")
  # Find all modules directories if nothing was provided via "--module-dir" argument
  if [[ ! $module_dir ]]; then
    # shellcheck disable=SC2207
    all_module_dirs+=($(cd "${root_dir}" && find . -maxdepth 2 -path '**/modules/*' -type d -print))
  else
    all_module_dirs=("$module_dir")
  fi

  IFS="$OLD_IFS"

  for module_dir in "${all_module_dirs[@]}"; do

    # Remove "./" from the "./modules/iam-user" or "./"
    module_dir="${module_dir/.\//}"

    full_module_dir="${root_dir}/${module_dir}"
    # echo "FULL=${full_module_dir}"

    if [[ ! -d "$full_module_dir" ]]; then
      echo "Module directory \"$full_module_dir\" does not exist!"
      exit 1
    fi

    # Remove "modules/" from "modules/iam-user"
    #    module_name="${module_dir//modules\//}"
    module_name="${module_dir#modules/}"
    if [[ ! $module_name ]]; then
      wrapper_title="Wrapper for the root module"
      wrapper_path="${wrapper_dir}"
    else
      wrapper_title="Wrapper for module: \`${module_dir}\`"
      wrapper_path="${wrapper_dir}/${module_name}"
    fi

    # Wrappers will be stored in "wrappers/{module_name}"
    output_dir="${root_dir}/${wrapper_dir}/${module_name}"

    [[ ! -d "$output_dir" ]] && mkdir -p "$output_dir"

    # Calculate relative depth for module source by number of slashes
    module_depth="${module_dir//[^\/]/}"

    local relative_source_path=$wrapper_relative_source_path

    for ((c = 0; c < ${#module_depth}; c++)); do
      relative_source_path+="../"
    done

    create_tmp_file_tf

    if [[ "$verbose" == "true" ]]; then
      echo "Root directory: $root_dir"
      echo "Module directory: $module_dir"
      echo "Output directory: $output_dir"
      echo "Temp file: $tmp_file_tf"
      echo
    fi

    # Read content of all terraform files
    # shellcheck disable=SC2207
    all_tf_content=$(find "${full_module_dir}" -name '*.tf' -maxdepth 1 -type f -exec cat {} +)

    if [[ ! $all_tf_content ]]; then
      common::colorify "yellow" "Skipping ${full_module_dir} because there are no *.tf files."
      continue
    fi

    # Get names of module variables in all terraform files
    # shellcheck disable=SC2207
    module_vars=($(echo "$all_tf_content" | hcledit block list | grep variable. | cut -d'.' -f 2))

    # Get names of module outputs in all terraform files
    # shellcheck disable=SC2207
    module_outputs=($(echo "$all_tf_content" | hcledit block list | grep output. | cut -d'.' -f 2))

    # Looking for sensitive output
    local wrapper_output_sensitive="# sensitive = false  # No sensitive module output found"
    for module_output in "${module_outputs[@]}"; do
      module_output_sensitive=$(echo "$all_tf_content" | hcledit attribute get "output.${module_output}.sensitive")

      # At least one output is sensitive - the wrapper's output should be sensitive, too
      if [[ "$module_output_sensitive" == "true" ]]; then
        wrapper_output_sensitive="sensitive   = true  # At least one sensitive module output (${module_output}) found (requires Terraform 0.14+)"
        break
      fi
    done

    # Create content of temporary main.tf file
    hcledit attribute append module.wrapper.source "\"${relative_source_path}${module_dir}\"" --newline -f "$tmp_file_tf" -u
    hcledit attribute append module.wrapper.for_each var.items --newline -f "$tmp_file_tf" -u

    # Add newline before the first variable in a loop
    local newline="--newline"

    for module_var in "${module_vars[@]}"; do
      # Get default value for the variable
      var_default=$(echo "$all_tf_content" | hcledit attribute get "variable.${module_var}.default")

      # Empty default means that the variable is required
      if [[ ! $var_default ]]; then
        var_value="try(each.value.${module_var}, var.defaults.${module_var})"
      elif [[ "$var_default" == "{" ]]; then
        # BUG in hcledit ( https://github.com/minamijoyo/hcledit/issues/31 ) which breaks on inline comments
        # https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/0bd31aa88339194efff470d3b3f58705bd008db0/rules.tf#L8
        # As a result, wrappers in terraform-aws-security-group module are missing values of the rules variable and is not useful. :(
        var_value="try(each.value.${module_var}, var.defaults.${module_var}, {})"
      else
        var_value="try(each.value.${module_var}, var.defaults.${module_var}, $var_default)"
      fi

      hcledit attribute append "module.wrapper.${module_var}" "${var_value}" $newline -f "$tmp_file_tf" -u

      newline=""
    done

    [[ "$verbose" == "true" ]] && cat "$tmp_file_tf"

    if [[ "$dry_run" == "false" ]]; then
      common::colorify "green" "Saving files into \"${output_dir}\""

      mv "$tmp_file_tf" "${output_dir}/main.tf"

      echo "$CONTENT_VARIABLES_TF" > "${output_dir}/variables.tf"
      echo "$CONTENT_VERSIONS_TF" > "${output_dir}/versions.tf"

      echo "$CONTENT_OUTPUTS_TF" > "${output_dir}/outputs.tf"
      sed -i.bak "s|WRAPPER_OUTPUT_SENSITIVE|${wrapper_output_sensitive}|g" "${output_dir}/outputs.tf"
      rm -rf "${output_dir}/outputs.tf.bak"

      echo "$CONTENT_README" > "${output_dir}/README.md"
      sed -i.bak -e "
      s#WRAPPER_TITLE#${wrapper_title}#g
      s#WRAPPER_PATH#${wrapper_path}#g
      s#MODULE_REPO_ORG#${module_repo_org}#g
      s#MODULE_REPO_SHORTNAME#${module_repo_shortname}#g
      s#MODULE_REPO_PROVIDER#${module_repo_provider}#g
      " "${output_dir}/README.md"
      rm -rf "${output_dir}/README.md.bak"
    else
      common::colorify "yellow" "There is nothing to save. Remove --dry-run flag to write files."
    fi

  done

}

function check_dependencies {
  if ! command -v hcledit > /dev/null; then
    echo "ERROR: The binary 'hcledit' is required by this hook but is not installed or is not in the system's PATH."
    echo "Check documentation: https://github.com/minamijoyo/hcledit"
    exit 1
  fi
}

function create_tmp_file_tf {
  # Can't append extension for mktemp, so renaming instead
  tmp_file=$(mktemp "${TMPDIR:-/tmp}/tfwrapper-XXXXXXXXXX")
  mv "$tmp_file" "$tmp_file.tf"
  tmp_file_tf="$tmp_file.tf"

  echo "$CONTENT_MAIN_TF" > "$tmp_file_tf"
}

#######################################
# Take provided path/url and strip any path or URL markings, .git ending,
# and the REPO_BASE_PATTERN
# Globals:
#   REPO_BASE_PATTERN
# Arguments:
#   Path or URL to strip
# Outputs:
#   Remaining string after stripping, if failed return
#     string with path/URL markings and .git ending removed
# Returns:
#   0 if stripped and matched REPO_BASE_PATTERN, 1 on error
#######################################
function strip_path_url_to_shortname {
  if [[ -n "$1" ]]; then

    local reponame
    # if last character is /, remove it
    reponame="${1%/}"
    # only keep anything to the right of the last /
    reponame="${reponame##*/}"
    # remove trailing .git if there
    reponame="${reponame%.git}"
    # remove the repo base pattern if matches
    if [[ "$reponame" =~ $REPO_BASE_PATTERN ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi

  fi

  # doesn't match pattern, return param stripped of .git and path
  echo "$reponame"
  return 1
}

#######################################
# Take provided directory/url, and provide the "short name" of the module
# after it's stripped using strip_path_url_to_shortname
#
# ie for "terraform-aws-ec2-instance" return "ec2-instance"
#    for "/a/b/c/terraform-aws-ec2-instance" return "ec2-instance"
#    for "https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git"
#      return "ec2-instance"
#    for "lint" this will attempt to find a respository name through existing
#      git remotes configuration, otherwise will return "lint"
#    for "/x/lint" will attempt to find repo as above, otherwise will return
#      "lint"
#
# This was created to work around issue where directory name does not
# match repository name (for example, Docker container mounting repo at /lint).
#
# Function tries provided path/url first (or $(pwd) if none provided),
# then tries using the repo's remote URLs for "origin" and "upstream".
# If all fails, return original parameter (or $(pwd)) with directory/path
# info and trailing .git stripped
#
# Globals:
#   REPO_BASE_PATTERN
# Arguments:
#   path to use to gather short module name
# Outputs:
#   short name of the module, ie provided "terraform-aws-ec2-instance",
#     return "ec2-instance"
#   if one could not be determined, return the provided path (or $(pwd)
#     if none provided) stripped of path/url markings
# Returns:
#   0
#######################################
function determine_repo_shortname {
  local topdir="${1:-$(pwd)}"

  # if provided name can be stripped and matches repo pattern, return
  local paramshortname
  if paramshortname="$(strip_path_url_to_shortname "${topdir}")"; then
    echo "$paramshortname"
    return 0
  fi

  # try the URLs for remote repos, and strip those, return the first match
  local remotenames=("origin" "upstream")
  local remote remoteurl shortname
  for remote in "${remotenames[@]}"; do
    if remoteurl="$(git remote get-url "${remote}" 2> /dev/null)"; then
      if shortname="$(strip_path_url_to_shortname "${remoteurl}")"; then
        echo "${shortname}"
        return 0
      fi
    fi
  done

  # fall back to returning provided param (or $(pwd)) with path and trailing
  # .git stripped
  echo "${paramshortname}"
  return 0
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || main "$@"
