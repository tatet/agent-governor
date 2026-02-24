#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root>

Behavior:
  - Renames non-.md standards files under project-governance/standards/ (excluding index.yml) to .md
  - Rebuilds standards/index.yml from discovered .md files
  - Preserves existing index descriptions when possible
  - Validates that every index entry maps to an existing .md file
USAGE
}

repo_root="${1:-}"
if [[ -z "$repo_root" ]]; then
  usage
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
standards_dir="$($script_dir/governance-root.sh "$repo_root" "standards")"
index_file="$standards_dir/index.yml"

if [[ ! -d "$standards_dir" ]]; then
  echo "NO_STANDARDS_DIR"
  exit 0
fi

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

old_index="$tmpdir/old-index.yml"
if [[ -f "$index_file" ]]; then
  cp "$index_file" "$old_index"
else
  : > "$old_index"
fi

renamed_count=0
conflict_count=0

while IFS= read -r -d '' file; do
  base="$(basename "$file")"

  if [[ "$base" == "index.yml" ]]; then
    continue
  fi

  if [[ "$file" == *.md ]]; then
    continue
  fi

  target="$file.md"
  if [[ -e "$target" ]]; then
    echo "CONFLICT: cannot rename '$file' because '$target' already exists" >&2
    conflict_count=$((conflict_count + 1))
    continue
  fi

  mv "$file" "$target"
  renamed_count=$((renamed_count + 1))
done < <(find "$standards_dir" -type f ! -path "*/.backups/*" -print0)

declare -A desc_map
while IFS='|' read -r key desc; do
  [[ -z "$key" ]] && continue
  desc_map["$key"]="$desc"
done < <(
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
      gsub(/^"|"$/, "", desc)
      if (folder != "" && file != "") {
        printf "%s/%s|%s\n", folder, file, desc
      }
    }
  ' "$old_index"
)

entries_file="$tmpdir/entries.txt"
: > "$entries_file"

while IFS= read -r file; do
  rel="${file#$standards_dir/}"

  if [[ "$rel" == "index.yml" ]]; then
    continue
  fi

  if [[ "$rel" != *.md ]]; then
    continue
  fi

  if [[ "$rel" == */* ]]; then
    folder="${rel%%/*}"
    name="$(basename "$rel" .md)"
  else
    folder="root"
    name="$(basename "$rel" .md)"
  fi

  printf "%s|%s\n" "$folder" "$name" >> "$entries_file"
done < <(find "$standards_dir" -type f -name "*.md" ! -path "*/.backups/*" | sort)

sort -u "$entries_file" -o "$entries_file"

if [[ ! -s "$entries_file" ]]; then
  cat > "$index_file" <<IDX
# Project Governance Standards Index
IDX
  echo "renamed=$renamed_count rebuilt=1 entries=0 conflicts=$conflict_count"
  exit 0
fi

folders_file="$tmpdir/folders.txt"
cut -d'|' -f1 "$entries_file" | sort -u > "$folders_file"

{
  echo "# Project Governance Standards Index"
  echo ""

  while IFS= read -r folder; do
    [[ -z "$folder" ]] && continue

    echo "$folder:"

    while IFS='|' read -r e_folder e_name; do
      [[ "$e_folder" != "$folder" ]] && continue

      key="$e_folder/$e_name"
      desc="${desc_map[$key]:-Needs description - update index descriptions}"
      desc_escaped="${desc//\\/\\\\}"
      desc_escaped="${desc_escaped//\"/\\\"}"

      echo "  $e_name:"
      echo "    description: \"$desc_escaped\""
    done < "$entries_file"

    echo ""
  done < "$folders_file"
} > "$index_file"

missing_count=0
while IFS='|' read -r folder name; do
  if [[ "$folder" == "root" ]]; then
    target="$standards_dir/$name.md"
  else
    target="$standards_dir/$folder/$name.md"
  fi

  if [[ ! -f "$target" ]]; then
    echo "MISSING: index entry '$folder/$name' has no matching file '$target'" >&2
    missing_count=$((missing_count + 1))
  fi
done < "$entries_file"

if [[ "$missing_count" -gt 0 ]]; then
  echo "validation=failed missing=$missing_count" >&2
  exit 1
fi

entry_count="$(wc -l < "$entries_file" | tr -d ' ')"
echo "renamed=$renamed_count rebuilt=1 entries=$entry_count conflicts=$conflict_count validation=ok"
