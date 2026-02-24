# Command Contract (Native Codex)

This skill provides native governance behavior for Codex projects with `project-governance/` as source of truth.

## Source Paths

- Standards: `project-governance/standards/**/*.md`
- Index: `project-governance/standards/index.yml`
- Product: `project-governance/product/*`
- Specs: `project-governance/specs/*`
- State: `project-governance/state/*`

## Intent Mapping

### Standards discovery/init intent

- Initialize governance through question-driven setup.
- Seed baseline standards and index.
- Enforce markdown/index invariants after creation.

### Standards injection intent

- Detect scenario.
- Select top relevant standards from index.
- Apply concise constraints first, full standard content on demand.

### Shape-spec intent

- Plan scenario proposes shape-spec flow.
- Collect scope, visuals, references, product alignment, standards.
- Write artifacts after explicit confirmation.

## Precedence Rules

1. Explicit user instruction.
2. Current conversation intent.
3. Existing project state.
4. Default heuristics.

## Non-Goals

- Do not require external framework installation.
- Do not force initialization automatically.
- Do not perform data migrations across governance systems.
