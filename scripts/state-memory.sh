#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 load <repo_root>
  $0 save <repo_root> <scenario> <workstream> <standards_csv> <spec_path_or_dash>
  $0 log <repo_root> <message>
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

assert_not_symlink() {
  local path="$1"
  local label="${2:-path}"
  if [[ -L "$path" ]]; then
    echo "Refusing to write $label because it is a symlink: $path" >&2
    exit 1
  fi
}

yaml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

yaml_quote() {
  local value="$1"
  printf '"%s"' "$(yaml_escape "$value")"
}

write_file_atomically() {
  local target="$1"
  local tmp_file

  assert_not_symlink "$target" "$target"
  tmp_file="$(mktemp "$state_dir/.tmp.XXXXXX")"

  if ! cat > "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  if ! mv "$tmp_file" "$target"; then
    rm -f "$tmp_file"
    return 1
  fi
}

state_paths() {
  local repo_root="$1"
  local gov_root
  gov_root="$($script_dir/governance-root.sh "$repo_root")"
  state_dir="$gov_root/state"
  context_file="$state_dir/context.yml"
  standards_file="$state_dir/last-standards.yml"
  decisions_file="$state_dir/decisions.log"
}

ensure_state_dir() {
  mkdir -p "$state_dir"
}

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

is_stale() {
  local updated_at="$1"
  local ttl_days="$2"

  if ! command -v date >/dev/null 2>&1; then
    echo "false"
    return
  fi

  local now_epoch updated_epoch ttl_seconds
  now_epoch="$(date -u +%s)"
  updated_epoch="$(date -u -d "$updated_at" +%s 2>/dev/null || echo "")"

  if [[ -z "$updated_epoch" ]]; then
    echo "false"
    return
  fi

  ttl_seconds=$((ttl_days * 86400))
  if (( now_epoch - updated_epoch > ttl_seconds )); then
    echo "true"
  else
    echo "false"
  fi
}

load_state() {
  local repo_root="$1"
  state_paths "$repo_root"

  if [[ ! -f "$context_file" ]]; then
    exit 0
  fi

  local updated_at ttl_days stale
  updated_at="$(sed -n 's/^updated_at:[[:space:]]*//p' "$context_file" | head -n1)"
  ttl_days="$(sed -n 's/^ttl_days:[[:space:]]*//p' "$context_file" | head -n1)"
  ttl_days="${ttl_days:-14}"
  stale="$(is_stale "$updated_at" "$ttl_days")"

  if [[ "$stale" == "true" ]]; then
    local last_spec
    last_spec="$(sed -n 's/^last_spec_path:[[:space:]]*//p' "$context_file" | head -n1)"
    cat <<OUT
version: 1
state: stale
last_spec_path: ${last_spec:-null}
OUT
    exit 0
  fi

  cat "$context_file"
  if [[ -f "$standards_file" ]]; then
    echo ""
    cat "$standards_file"
  fi
}

save_state() {
  local repo_root="$1"
  local scenario="$2"
  local workstream="$3"
  local standards_csv="$4"
  local spec_path="$5"

  state_paths "$repo_root"
  ensure_state_dir

  local updated_at
  updated_at="$(timestamp_utc)"

  if [[ "$spec_path" == "-" ]]; then
    spec_path="null"
  fi

  local scenario_yaml workstream_yaml spec_path_yaml
  scenario_yaml="$(yaml_quote "$scenario")"
  workstream_yaml="$(yaml_quote "$workstream")"
  if [[ "$spec_path" == "null" ]]; then
    spec_path_yaml="null"
  else
    spec_path_yaml="$(yaml_quote "$spec_path")"
  fi

  write_file_atomically "$context_file" <<CTX
version: 1
updated_at: $updated_at
scenario: $scenario_yaml
active_workstream: $workstream_yaml
last_spec_path: $spec_path_yaml
product_context_loaded: false
ttl_days: 14
CTX

  {
    echo "updated_at: $updated_at"
    echo "standards:"
    IFS=',' read -r -a standards <<< "$standards_csv"
    for std in "${standards[@]}"; do
      local trimmed
      trimmed="$(printf '%s' "$std" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [[ -z "$trimmed" ]] && continue
      echo "  - $(yaml_quote "$trimmed")"
    done
  } | write_file_atomically "$standards_file"
}

append_log() {
  local repo_root="$1"
  local message="$2"

  state_paths "$repo_root"
  ensure_state_dir

  assert_not_symlink "$decisions_file" "$decisions_file"
  printf '%s | %s\n' "$(timestamp_utc)" "$message" >> "$decisions_file"
}

main() {
  if [[ "$#" -lt 2 ]]; then
    usage
    exit 1
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    load)
      [[ "$#" -eq 1 ]] || { usage; exit 1; }
      load_state "$1"
      ;;
    save)
      [[ "$#" -eq 5 ]] || { usage; exit 1; }
      save_state "$1" "$2" "$3" "$4" "$5"
      ;;
    log)
      [[ "$#" -ge 2 ]] || { usage; exit 1; }
      local repo_root="$1"
      shift
      append_log "$repo_root" "$*"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
