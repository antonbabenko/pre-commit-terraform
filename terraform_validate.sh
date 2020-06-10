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

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  # Set a temporary provider in case the current directory is a module without a provider block.
  if [[ ${path_uniq} == *"modules"* && ! ${path_uniq} == *"examples"* ]]; then
    echo -e "provider \"azurerm\" {\n  features{}\n}" >| temp-provider.tf
  fi

  # Initialize the directory
  if ! terraform init $validate_path -backend=false; then
    error=1
    echo "==============================================================================="
    echo "Failed terraform init on path: $path_uniq"
    echo "==============================================================================="
  fi

  # Perform the validation
  if ! terraform validate $validate_path; then
    error=1
    echo "==============================================================================="
    echo "Failed terraform validate on path: $path_uniq"
    echo "==============================================================================="
  fi

  # Remove the temporary provider block if required.
  if [[ ${path_uniq} == *"modules"* && ! ${path_uniq} == *"examples"* ]]; then
    rm temp-provider.tf
  fi

  # Remove the terraform configuration directory that was created after init
  if [[ -d .terraform ]]; then
    rm -r .terraform
  fi
  
  popd > /dev/null
done

if [[ "${error}" -ne 0 ]]; then
  exit 1
fi
