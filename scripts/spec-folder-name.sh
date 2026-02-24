#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <feature_text> [timestamp]
USAGE
}

feature_text="${1:-}"
timestamp="${2:-}"

if [[ -z "$feature_text" ]]; then
  usage
  exit 1
fi

if [[ -z "$timestamp" ]]; then
  timestamp="$(date +"%Y-%m-%d-%H%M")"
fi

if ! [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
  echo "Invalid timestamp format: $timestamp" >&2
  exit 1
fi

slug="$(printf '%s' "$feature_text" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/-\{2,\}/-/g' \
  | sed 's/^-//; s/-$//')"

if [[ -z "$slug" ]]; then
  slug="feature"
fi

slug="$(printf '%s' "$slug" | cut -c1-40)"
slug="$(printf '%s' "$slug" | sed 's/^-//; s/-$//')"

if [[ -z "$slug" ]]; then
  slug="feature"
fi

echo "${timestamp}-${slug}"
