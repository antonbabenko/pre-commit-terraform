#!C:/Program\ Files/Git/bin/bash.exe
set -e

declare -a paths
index=0
error=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")
  (("index+=1"))
done

echo $paths

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  if [[ -n "$(find $path_uniq -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

    starting_path=$(realpath "$path_uniq")
    terraform_path="$path_uniq"

    # Find the relevant .terraform directory (indicating a 'terraform init'),
    # but fall through to the current directory.
    while [[ "$terraform_path" != "." ]]; do
      if [[ -d "$terraform_path/.terraform" ]]; then
        echo "Break: $terraform_path"
        break
      else
        echo "Else: $terraform_path"
        terraform_path=$(dirname "$terraform_path")
      fi
    done

    validate_path="${path_uniq#"$terraform_path"}"
    echo "Validated path: ${validate_path}"

    # Change to the directory that has been initialized, run validation, then
    # change back to the starting directory.
    cd "$(realpath "$terraform_path")"
    echo "Init and validate dir: ${pwd}"

    # Set an empty provider block to satisfy the AzureRM provider when running validation
    # checks, in case the current directory is a module with no provider block.
    echo "provider \"azurerm\" {features{}}" > temp-provider.tf

    # Initializing the directory before validation is required.
    # TODO: Init

    if ! terraform validate $validate_path; then
      error=1
      echo
      echo "Failed path: $path_uniq"
      echo "================================"
    fi

    # rm temp-provider.tf

    cd "$starting_path"
  fi
done

if [[ "${error}" -ne 0 ]]; then
  exit 1
fi
