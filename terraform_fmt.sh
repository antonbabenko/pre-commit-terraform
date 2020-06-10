#!C:/Program\ Files/Git/bin/bash.exe
set -e

# The format command can be run recursively from any directory,
# so there is no need to parse the input files.
terraform fmt -recursive

