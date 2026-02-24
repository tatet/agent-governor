---
name: agent-governor
description: Native governance skill for Codex projects. Use when you need to initialize project standards and planning guardrails, apply relevant standards automatically during implementation/refactors/planning, persist project memory across sessions, and run shape-spec style planning with artifact generation under project-governance/.
---

# Agent Governor

## Overview

Manage repository governance natively in Codex using `project-governance/` as the single source of truth.

## Core Paths

- Governance root: `project-governance/`
- Standards: `project-governance/standards/**/*.md`
- Standards index: `project-governance/standards/index.yml`
- Product docs: `project-governance/product/`
- Specs: `project-governance/specs/`
- State: `project-governance/state/`

## Commands To Use

Use scripts in this folder for deterministic behavior:

1. Initialize governance (explicit trigger only):
- `scripts/init-governance.sh <repo_root>`
- Optional non-interactive mode: `scripts/init-governance.sh <repo_root> --non-interactive`

2. Detect scenario:
- `scripts/detect-scenario.sh "<intent>" "<plan_hint_optional>"`

3. Select standards:
- `scripts/select-standards.sh <repo_root> "<intent>" 3`

4. Enforce standards/index invariants:
- `scripts/enforce-standards-layout.sh <repo_root>`

5. Plan shaping draft:
- `scripts/shape-spec-runbook.sh <repo_root> "<feature_text>" 3`

6. Persist shape artifacts after explicit approval:
- `scripts/spec-artifacts.sh <repo_root> <feature_text> <plan_src> <shape_src> <standards_src> <references_src> [visuals_src_or_dash] [standards_csv_or_dash]`

7. Manage state:
- `scripts/state-memory.sh load <repo_root>`
- `scripts/state-memory.sh save <repo_root> <scenario> <workstream> <standards_csv> <spec_path_or_dash>`
- `scripts/state-memory.sh log <repo_root> "<message>"`

8. Seed AGENTS defaults:
- `scripts/ensure-project-governance.sh <repo_root>`

## Runtime Workflow

1. Resolve governance root with `scripts/governance-root.sh`.
2. Ensure AGENTS managed block exists.
3. Load state and detect scenario.
4. For conversation/skill scenarios: select standards and apply concise constraints.
5. For plan scenario: propose shape-spec flow, ask confirmation before writing artifacts.
6. Save state and decision logs.

## Initialization Policy

Initialization must be explicit. Do not auto-run wizard on first use.

If governance folder is missing and user has not asked to initialize:
- Continue in passive mode.
- Offer one concise suggestion to run initialization.

## Non-Negotiable Invariants

1. Standards must be `.md` files under `project-governance/standards/`.
2. `index.yml` entries must map to existing `.md` files only.
3. Run `scripts/enforce-standards-layout.sh` after standards edits.
4. Shape-spec writes require explicit user approval before file creation.

## Shape-Spec Completion Gate

Before reporting shape-spec completion:

1. Confirm approval happened before artifact writes.
2. Confirm spec folder exists under `project-governance/specs/YYYY-MM-DD-HHMM-slug/`.
3. Confirm files exist: `plan.md`, `shape.md`, `standards.md`, `references.md`.
4. Confirm `visuals/` exists (can be empty).
5. Confirm state includes `scenario: plan` and `last_spec_path`.

## References

- `references/command-contract.md`
- `references/scenario-mapping.md`
