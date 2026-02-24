#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root> <feature_text> [top_n_standards]
USAGE
}

repo_root="${1:-}"
feature_text="${2:-}"
top_n="${3:-3}"

if [[ -z "$repo_root" || -z "$feature_text" ]]; then
  usage
  exit 1
fi

if ! [[ "$top_n" =~ ^[0-9]+$ ]] || [[ "$top_n" -lt 1 ]]; then
  echo "Invalid top_n: $top_n" >&2
  exit 1
fi

if [[ ! -d "$repo_root" ]]; then
  echo "Repository root not found: $repo_root" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gov_root="$($script_dir/governance-root.sh "$repo_root")"

folder_name="$($script_dir/spec-folder-name.sh "$feature_text")"
spec_rel_path="project-governance/specs/$folder_name"

product_dir="$gov_root/product"
index_file="$gov_root/standards/index.yml"

product_exists="false"
product_files=()
if [[ -d "$product_dir" ]]; then
  product_exists="true"
  for name in mission.md roadmap.md tech-stack.md; do
    if [[ -f "$product_dir/$name" ]]; then
      product_files+=("$name")
    fi
  done
fi

standards_status="NO_INDEX"
standards=()
if [[ -f "$index_file" ]]; then
  set +e
  mapfile -t standards < <("$script_dir/select-standards.sh" "$repo_root" "$feature_text" "$top_n" 2>/dev/null)
  sel_status=$?
  set -e

  if [[ "$sel_status" -eq 0 ]]; then
    standards_status="OK"
  else
    standards_status="NO_INDEX"
    standards=()
  fi
fi

cat <<EOF2
# Shape Spec Runbook Draft

## Scope Seed

Feature request:
- $feature_text

## Proposed Spec Folder

- folder_name: $folder_name
- relative_path: $spec_rel_path

## Questions To Ask

1. What are we building exactly, and what does success look like?
2. Is this net-new functionality or a change to existing behavior?
3. Are there constraints (timeline, compatibility, security, performance)?
4. Do we have visuals (mockups/screenshots/examples) or should we proceed without them?
5. What existing code paths should we reference?

## Product Context

- product_docs_present: $product_exists
EOF2

if [[ "$product_exists" == "true" ]]; then
  if [[ "${#product_files[@]}" -gt 0 ]]; then
    echo "- product_files:"
    for f in "${product_files[@]}"; do
      echo "  - project-governance/product/$f"
    done
  else
    echo "- product_files: none"
  fi
else
  echo "- product_files: none"
fi

cat <<EOF3

## Standards Suggestions

- status: $standards_status
EOF3

if [[ "$standards_status" == "OK" && "${#standards[@]}" -gt 0 ]]; then
  echo "- selected_standards:"
  for s in "${standards[@]}"; do
    echo "  - $s"
  done
else
  echo "- selected_standards: []"
fi

cat <<'EOF4'

## Task Skeleton

1. Task 1: Save spec documentation
2. Task 2: Implement first core slice
3. Task 3: Complete remaining implementation slices
4. Task 4: Validate behavior and quality gates

## Artifact Checklist

Create in `project-governance/specs/{folder_name}/`:
- `plan.md`
- `shape.md`
- `standards.md`
- `references.md`
- `visuals/` (optional contents)

## Execution Notes

- Confirm with the user before writing artifacts.
- After writing artifacts, update state with scenario `plan` and `last_spec_path`.
- If standards index is missing, continue shaping but note reduced standards coverage.
EOF4
