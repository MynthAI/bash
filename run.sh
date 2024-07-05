#!/usr/bin/env bash

set -e

# This script executes other scripts stored within
# private GitHub repositories. Given a GitHub
# organization/user name, a repository name, and the path
# to a specific script  within that repository, this
# script will clone the repository, retrieve the
# specified script, and execute it. This is useful for
# automating tasks or running scripts directly without
# manually downloading and setting them up.

# Usage: ./run.sh <org> <name> <script>
# Example: ./run.sh my-org my-repo path/to/script.sh

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <org> <name> <script>"
  exit 1
fi

original_dir=$(pwd)
repo_url="git@github.com:$1/$2.git"
script="$3"

echo "Retrieving $script from $repo_url"
temp_dir=$(mktemp -d)
cd "$temp_dir" || exit 1
git clone "$repo_url" &> /dev/null
cd "$(basename "$repo_url" .git)" || exit 1

script_contents=$(cat "$script")

cd "$original_dir" || exit 1
rm -rf "$temp_dir"

echo "Running $script"
eval "$script_contents"
