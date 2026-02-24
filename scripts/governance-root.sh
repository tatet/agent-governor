#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root> [relative_subpath]

Examples:
  $0 /path/to/repo
  $0 /path/to/repo standards/index.yml
USAGE
}

repo_root="${1:-}"
subpath="${2:-}"

if [[ -z "$repo_root" ]]; then
  usage
  exit 1
fi

root="$repo_root/project-governance"

if [[ -n "$subpath" ]]; then
  echo "$root/$subpath"
else
  echo "$root"
fi
