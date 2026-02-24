#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-}"
intent_text="${2:-}"
top_n="${3:-3}"

if [[ -z "$repo_root" ]]; then
  echo "Usage: $0 <repo_root> <intent_text> [top_n]" >&2
  exit 1
fi

if ! [[ "$top_n" =~ ^[0-9]+$ ]] || [[ "$top_n" -lt 1 ]]; then
  echo "Invalid top_n: $top_n" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
index_file="$($script_dir/governance-root.sh "$repo_root" "standards/index.yml")"
state_file="$($script_dir/governance-root.sh "$repo_root" "state/context.yml")"

if [[ ! -f "$index_file" ]]; then
  echo "NO_INDEX"
  exit 2
fi

normalize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

tokenize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/ /g' \
    | tr -s ' ' '\n' \
    | awk 'length($0) >= 3'
}

intent_lc="$(normalize "$intent_text")"
workstream=""
if [[ -f "$state_file" ]]; then
  workstream="$(sed -n 's/^active_workstream:[[:space:]]*//p' "$state_file" | head -n1 | sed 's/^"//; s/"$//')"
fi
workstream_lc="$(normalize "$workstream")"

mapfile -t entries < <(
  awk '
    /^[a-zA-Z0-9_-]+:$/ {
      folder=$0
      sub(/:$/, "", folder)
      next
    }
    /^  [a-zA-Z0-9_-]+:$/ {
      file=$0
      sub(/^  /, "", file)
      sub(/:$/, "", file)
      next
    }
    /^    description:[[:space:]]*/ {
      desc=$0
      sub(/^    description:[[:space:]]*/, "", desc)
      if (folder != "" && file != "") {
        printf "%s/%s|%s\n", folder, file, desc
      }
    }
  ' "$index_file"
)

if [[ "${#entries[@]}" -eq 0 ]]; then
  echo "NO_INDEX"
  exit 2
fi

tmp_scores="$(mktemp)"
cleanup() {
  rm -f "$tmp_scores"
}
trap cleanup EXIT

# shellcheck disable=SC2207
intent_tokens=($(tokenize "$intent_lc"))
# shellcheck disable=SC2207
workstream_tokens=($(tokenize "$workstream_lc"))

for entry in "${entries[@]}"; do
  path="${entry%%|*}"
  desc="${entry#*|}"
  folder="${path%%/*}"
  file="${path##*/}"

  entry_lc="$(normalize "$path $desc")"
  score=0

  if [[ "$intent_lc" == *"$folder"* ]]; then
    score=$((score + 4))
  fi

  file_spaces="${file//-/ }"
  if [[ "$intent_lc" == *"$file"* ]] || [[ "$intent_lc" == *"$file_spaces"* ]]; then
    score=$((score + 3))
  fi

  for token in "${intent_tokens[@]:-}"; do
    if [[ "$entry_lc" == *"$token"* ]]; then
      score=$((score + 2))
    fi
  done

  for token in "${workstream_tokens[@]:-}"; do
    if [[ "$entry_lc" == *"$token"* ]]; then
      score=$((score + 1))
    fi
  done

  printf "%s\t%s\n" "$score" "$path" >> "$tmp_scores"
done

if awk -F '\t' '$1 > 0 { found=1 } END { exit(found ? 0 : 1) }' "$tmp_scores"; then
  awk -F '\t' '$1 > 0 { print }' "$tmp_scores" \
    | sort -t $'\t' -k1,1nr -k2,2 \
    | awk -F '\t' '!seen[$2]++ { print $2 }' \
    | head -n "$top_n"
else
  awk -F '\t' '{ print $2 }' "$tmp_scores" \
    | sort \
    | head -n "$top_n"
fi
