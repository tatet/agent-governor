#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root>
USAGE
}

repo_root="${1:-}"
if [[ -z "$repo_root" ]]; then
  usage
  exit 1
fi

agents_file="$repo_root/AGENTS.md"
start_marker="<!-- agent-governor:start -->"
end_marker="<!-- agent-governor:end -->"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

trim_trailing_blanks() {
  local input_file="$1"
  local output_file="$2"

  awk '
    {
      lines[NR] = $0
      if ($0 !~ /^[[:space:]]*$/) {
        last = NR
      }
    }
    END {
      if (last > 0) {
        for (i = 1; i <= last; i++) {
          print lines[i]
        }
      }
    }
  ' "$input_file" > "$output_file"
}

managed_block="$tmpdir/managed-block.md"
cat > "$managed_block" <<'BLOCK'
<!-- agent-governor:start -->
## Agent Governor Default Governance

When `project-governance/standards/index.yml` exists, apply agent-governor workflow by default for implementation, planning, and refactoring tasks.

- Auto-detect scenario (`conversation`, `plan`, or `skill`).
- Auto-select relevant standards from `project-governance/standards/index.yml`.
- Read selected standards before proposing changes.
- Persist continuity in `project-governance/state/*`.
- Do not require repetitive prompts like "use the skill" each turn.

If `project-governance/` is missing, stay in passive mode and continue normally.
<!-- agent-governor:end -->
BLOCK

if [[ ! -f "$agents_file" ]]; then
  cat > "$agents_file" <<EOF2
# AGENTS

$(cat "$managed_block")
EOF2
  echo "created=$agents_file updated_block=1"
  exit 0
fi

if grep -qF "$start_marker" "$agents_file"; then
  awk -v start="$start_marker" -v end="$end_marker" '
    BEGIN { in_block=0 }
    {
      if (index($0, start) > 0) {
        in_block=1
        next
      }
      if (index($0, end) > 0) {
        in_block=0
        next
      }
      if (!in_block) print $0
    }
  ' "$agents_file" > "$tmpdir/cleaned.md"

  trim_trailing_blanks "$tmpdir/cleaned.md" "$tmpdir/cleaned-trimmed.md"

  {
    if [[ -s "$tmpdir/cleaned-trimmed.md" ]]; then
      cat "$tmpdir/cleaned-trimmed.md"
      echo ""
    fi
    cat "$managed_block"
  } > "$agents_file"

  echo "updated=$agents_file replaced_block=1"
  exit 0
fi

trim_trailing_blanks "$agents_file" "$tmpdir/original-trimmed.md"

{
  if [[ -s "$tmpdir/original-trimmed.md" ]]; then
    cat "$tmpdir/original-trimmed.md"
    echo ""
  fi
  cat "$managed_block"
} > "$tmpdir/with-block.md"
mv "$tmpdir/with-block.md" "$agents_file"

echo "updated=$agents_file appended_block=1"
