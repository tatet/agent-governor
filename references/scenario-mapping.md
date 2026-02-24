# Scenario Mapping

Use deterministic detection to route behavior.

## conversation

Trigger:
- implementation, bugfix, refactor, Q&A

Behavior:
- select top standards
- apply concise governance summary
- persist workstream and selected standards

## plan

Trigger:
- plan/spec/shaping/requirements/architecture requests

Behavior:
- propose shape-spec flow
- ask confirmation before writing artifacts
- write artifacts in `project-governance/specs/` only after approval
- update `last_spec_path`

## skill

Trigger:
- creating/updating skills or `.codex/skills` requests

Behavior:
- keep outputs concise and reusable
- prefer references over large inline blocks

## Tie-breakers

1. If both plan and skill are present, use `plan` for product planning and `skill` for packaging.
2. If uncertain, default to `conversation`.

## Manual Override

Honor explicit overrides for standards selection or dry-run behavior.
