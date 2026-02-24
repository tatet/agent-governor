#!/usr/bin/env bash
set -euo pipefail

intent_text="${1:-}"
plan_hint="${2:-}"

normalize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

intent_lc="$(normalize "$intent_text")"
plan_hint_lc="$(normalize "$plan_hint")"

if [[ "$plan_hint_lc" == "true" || "$plan_hint_lc" == "1" || "$plan_hint_lc" == "yes" ]]; then
  echo "plan"
  exit 0
fi

if [[ "$intent_lc" =~ (^|[[:space:]])(plan|planning|spec|shape-spec|shape[[:space:]]spec|roadmap|requirements|architecture|arquitectura|planificar|especificacion)([[:space:]]|$) ]]; then
  echo "plan"
  exit 0
fi

if [[ "$intent_lc" =~ (^|[[:space:]])(skill|skills|\.codex/skills|create[[:space:]]skill|crear[[:space:]]skill|reusable[[:space:]]workflow)([[:space:]]|$) ]]; then
  echo "skill"
  exit 0
fi

echo "conversation"
