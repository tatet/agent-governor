#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 <repo_root> [--non-interactive]

Initializes native governance in project-governance/.
USAGE
}

repo_root="${1:-}"
mode="${2:-}"

if [[ -z "$repo_root" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$repo_root" ]]; then
  echo "Repository root not found: $repo_root" >&2
  exit 1
fi

non_interactive="false"
if [[ "$mode" == "--non-interactive" ]]; then
  non_interactive="true"
elif [[ -n "$mode" ]]; then
  usage
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gov_root="$($script_dir/governance-root.sh "$repo_root")"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mission=""
target_users=""
solution=""
frontend_stack=""
backend_stack=""
database_stack=""
rule_level="recommended"
ci_gate="true"

if [[ "$non_interactive" == "true" ]]; then
  mission="Deliver reliable software faster with codified governance."
  target_users="Engineering teams using Codex."
  solution="Standards-driven workflow with persistent planning artifacts and state."
  frontend_stack="N/A"
  backend_stack="N/A"
  database_stack="N/A"
else
  read -r -p "Mission (one sentence): " mission
  read -r -p "Target users: " target_users
  read -r -p "What makes this approach unique: " solution
  read -r -p "Frontend stack [N/A]: " frontend_stack
  read -r -p "Backend stack [N/A]: " backend_stack
  read -r -p "Database stack [N/A]: " database_stack

  tmp_rule=""
  read -r -p "Rule strictness (recommended/blocking) [recommended]: " tmp_rule
  if [[ -n "$tmp_rule" ]]; then
    rule_level="$tmp_rule"
  fi

  tmp_ci=""
  read -r -p "Require CI lint+test+build before deploy? (Y/n): " tmp_ci
  if [[ "$tmp_ci" =~ ^[Nn]$ ]]; then
    ci_gate="false"
  fi
fi

mission="${mission:-Deliver reliable software faster with codified governance.}"
target_users="${target_users:-Engineering teams using Codex.}"
solution="${solution:-Standards-driven workflow with persistent planning artifacts and state.}"
frontend_stack="${frontend_stack:-N/A}"
backend_stack="${backend_stack:-N/A}"
database_stack="${database_stack:-N/A}"

if [[ "$rule_level" != "recommended" && "$rule_level" != "blocking" ]]; then
  rule_level="recommended"
fi

mkdir -p "$gov_root/standards/global"
mkdir -p "$gov_root/standards/operations"
mkdir -p "$gov_root/product"
mkdir -p "$gov_root/specs"
mkdir -p "$gov_root/state"

created=()
reused=()

write_if_missing() {
  local path="$1"
  local content="$2"

  if [[ -f "$path" ]]; then
    reused+=("$path")
  else
    printf '%s\n' "$content" > "$path"
    created+=("$path")
  fi
}

must_word="should"
if [[ "$rule_level" == "blocking" ]]; then
  must_word="must"
fi

ci_line="CI ${must_word} run lint, test, and build before deploy."
if [[ "$ci_gate" == "false" ]]; then
  ci_line="CI should run lint, test, and build before deploy when possible."
fi

write_if_missing "$gov_root/standards/global/coding-style.md" "# Coding Style

Use clear names and small functions.

- New code ${must_word} favor readability over cleverness.
- Keep modules focused and avoid broad side effects.
- Preserve project naming conventions.
"

write_if_missing "$gov_root/standards/global/testing-quality.md" "# Testing Quality

Ship changes with confidence.

- New behavior ${must_word} include tests at the appropriate layer.
- Bug fixes ${must_word} include a regression test when feasible.
- Tests should be deterministic and avoid hidden coupling.
"

write_if_missing "$gov_root/standards/global/dependency-security.md" "# Dependency Security

Keep dependencies controlled.

- New dependencies ${must_word} be justified and actively maintained.
- Pin versions where lockfiles are available.
- Remove unused dependencies promptly.
"

write_if_missing "$gov_root/standards/global/env-and-secrets.md" "# Environment and Secrets

Protect secrets by default.

- Secrets ${must_word} never be committed.
- Document required environment variables.
- Use least-privilege credentials for local and CI runs.
"

write_if_missing "$gov_root/standards/operations/ci-cd-release.md" "# CI/CD Release

Release safely and predictably.

- $ci_line
- Failed quality gates block release candidates.
- Release notes should summarize user-visible and operational changes.
"

write_if_missing "$gov_root/product/mission.md" "# Product Mission

## Problem
$mission

## Target Users
$target_users

## Solution
$solution
"

write_if_missing "$gov_root/product/roadmap.md" "# Product Roadmap

## Phase 1: MVP
- Establish baseline capabilities and quality gates.

## Phase 2: Post-Launch
- Improve reliability, developer speed, and user-facing quality.
"

write_if_missing "$gov_root/product/tech-stack.md" "# Tech Stack

## Frontend
$frontend_stack

## Backend
$backend_stack

## Database
$database_stack
"

enforce_out="$tmpdir/enforce.out"
agents_out="$tmpdir/agents.out"

"$script_dir/enforce-standards-layout.sh" "$repo_root" >"$enforce_out"

"$script_dir/state-memory.sh" save "$repo_root" "conversation" "governance-initialization" "global/coding-style,global/testing-quality,operations/ci-cd-release" "-"
"$script_dir/state-memory.sh" log "$repo_root" "governance initialized at project-governance"

"$script_dir/ensure-project-governance.sh" "$repo_root" >"$agents_out"

echo "governance_root=$gov_root"
echo "created_count=${#created[@]}"
for p in "${created[@]}"; do
  echo "created=$p"
done

echo "reused_count=${#reused[@]}"
for p in "${reused[@]}"; do
  echo "reused=$p"
done

echo "index_status=$(cat "$enforce_out")"
echo "agents_status=$(cat "$agents_out")"
