#!/usr/bin/env bash

# This script installs the latest release from GitHub repository.
# 
# Usage:
#   ./script.sh <github_repo> <variant>
# 
# Arguments:
#   github_repo  The GitHub repository in the format 'owner/repo'.
#   variant      The specific variant of the release to download (e.g.,
#   'linux-x86_64').
# 
# Example:
#   ./script.sh danielgtaylor/restish linux-x86_64
# 
# This script performs the following actions:
#   1. Fetches the latest release URL for the specified repository and variant
#   from the GitHub API.
#   2. Downloads the release binary.
#   3. If the downloaded file is a gzip-compressed archive, it extracts the
#   contents.
#   4. Identifies the executable binary within the extracted contents, if
#   applicable.
#   5. Installs the binary to '/usr/local/bin'.
#   6. Cleans up any temporary files created during the process.
# 
# Note: Ensure that you have the necessary permissions to install files to
# '/usr/local/bin'.

set -e

get_latest_release_url() {
  local repo=$1
  local variant=$2
  curl -s "https://api.github.com/repos/$repo/releases/latest" \
  | grep "browser_download_url.*$variant" \
  | cut -d '"' -f 4 \
  | head -n 1
}

install_latest_release() {
  local repo=$1
  local variant=$2
  local install_dir=$3
  local url

  url=$(get_latest_release_url "$repo" "$variant")
  if [ -z "$url" ]; then
    echo "No release found for variant $variant."
    exit 1
  fi

  echo "Downloading $url"
  curl -sL "$url" -o latest_release

  if file latest_release | grep -q 'gzip compressed'; then
    echo "Extracting release..."
    mkdir -p latest_release_dir
    tar -xzf latest_release -C latest_release_dir

    echo "Identifying the binary..."
    binary=$(find latest_release_dir -type f -executable | head -n 1)

    if [ -z "$binary" ]; then
      first=$(find latest_release_dir -type f | head -n 1)
      chmod +x "$first"
      binary=$(find latest_release_dir -type f -executable | head -n 1)
    fi

    if [ -z "$binary" ]; then
      echo "No binary file found in the release archive."
      exit 1
    fi

    echo "Installing $binary to $install_dir..."
    mkdir -p "$install_dir"
    sudo cp "$binary" "$install_dir"
    rm -rf latest_release latest_release_dir
  else
    echo "Installing binary directly to $install_dir..."
    name="$(basename "$repo")"
    sudo cp latest_release "$install_dir/$name"
    sudo chmod +x "$install_dir/$name"
    rm latest_release
  fi

  echo "The latest release from $repo has been installed successfully to $install_dir"
}

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <github_repo> <variant>"
  echo "Example: $0 danielgtaylor/restish linux-x86_64"
  exit 1
fi

REPO=$1
VARIANT=$2
INSTALL_DIR=/usr/local/bin
install_latest_release "$REPO" "$VARIANT" "$INSTALL_DIR"
