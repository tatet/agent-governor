#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root> <feature_text> <plan_src> <shape_src> <standards_src> <references_src> [visuals_src_or_dash] [standards_csv_or_dash]
USAGE
}

repo_root="${1:-}"
feature_text="${2:-}"
plan_src="${3:-}"
shape_src="${4:-}"
standards_src="${5:-}"
references_src="${6:-}"
visuals_src="${7:--}"
standards_csv="${8:--}"

if [[ -z "$repo_root" || -z "$feature_text" || -z "$plan_src" || -z "$shape_src" || -z "$standards_src" || -z "$references_src" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$repo_root" ]]; then
  echo "Repository root not found: $repo_root" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gov_root="$($script_dir/governance-root.sh "$repo_root")"

for src in "$plan_src" "$shape_src" "$standards_src" "$references_src"; do
  if [[ ! -f "$src" ]]; then
    echo "Missing source file: $src" >&2
    exit 1
  fi
done

if [[ "$visuals_src" != "-" && ! -d "$visuals_src" ]]; then
  echo "Visuals source is not a directory: $visuals_src" >&2
  exit 1
fi

base_folder="$($script_dir/spec-folder-name.sh "$feature_text")"
folder_name="$base_folder"
suffix=2
while [[ -d "$gov_root/specs/$folder_name" ]]; do
  folder_name="${base_folder}-v${suffix}"
  suffix=$((suffix + 1))
done

spec_dir="$gov_root/specs/$folder_name"
visuals_dir="$spec_dir/visuals"

mkdir -p "$gov_root/specs"
mkdir -p "$spec_dir"
mkdir -p "$visuals_dir"

cp "$plan_src" "$spec_dir/plan.md"
cp "$shape_src" "$spec_dir/shape.md"
cp "$standards_src" "$spec_dir/standards.md"
cp "$references_src" "$spec_dir/references.md"

if [[ "$visuals_src" != "-" ]]; then
  if find "$visuals_src" -mindepth 1 -maxdepth 1 -print -quit >/dev/null; then
    cp -R "$visuals_src"/. "$visuals_dir/"
  fi
fi

spec_rel_path="project-governance/specs/$folder_name"

if [[ "$standards_csv" == "-" ]]; then
  standards_csv=""
fi

"$script_dir/state-memory.sh" save "$repo_root" "plan" "$feature_text" "$standards_csv" "$spec_rel_path"
"$script_dir/state-memory.sh" log "$repo_root" "shape-spec artifacts saved at $spec_rel_path"

printf 'spec_path=%s\n' "$spec_rel_path"
printf 'spec_abs_path=%s\n' "$spec_dir"
printf 'created_files=%s\n' "plan.md,shape.md,standards.md,references.md"
printf 'visuals_dir=%s\n' "$visuals_dir"
printf 'state_updated=true\n'
