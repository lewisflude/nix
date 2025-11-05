#!/usr/bin/env bash
# Helper script to run nix commands with GitHub token from sops
# Usage: ./nix-with-github-token.sh <nix-command>
# Example: ./nix-with-github-token.sh "nix flake update"
# Example: ./nix-with-github-token.sh "nix flake lock"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Decrypt the GitHub token from sops
GITHUB_TOKEN=$(cd "$REPO_ROOT" && sops -d secrets/secrets.yaml | yq -r '.GITHUB_TOKEN')

if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" == "null" ]; then
  echo "Error: Failed to decrypt GITHUB_TOKEN from sops" >&2
  exit 1
fi

# Export the token and run the nix command
export GITHUB_TOKEN

# Set nix access token for the current session
export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"

# Run the provided command
exec "$@"
