# Agent Governor

Agent Governor organizes project rules, planning, and working context inside your repository.
Standards live in `project-governance/standards/`, are versioned with your code, and are shared across the team.

**Same code across your team.**

## What It Does

- Centralizes project governance in `project-governance/`.
- Detects the work type (`conversation`, `plan`, `skill`).
- Selects relevant standards for each task.
- Maintains continuity across sessions in `project-governance/state/`.
- Supports shape-spec flow with explicit approval before writing artifacts.

## How To Use It

Work with the agent in natural language.
Ask it to activate the skill, initialize governance when needed, and manage standards as work evolves.

## Example Requests For The Agent

- "Use agent-governor in this repository and initialize governance."
- "Add a backend standard for API error handling and update the index."
- "Update testing-quality so bug fixes include regression tests."
- "Remove global/old-style-guide and reconcile the standards index."
- "Review current standards and suggest what to keep, merge, or remove."
- "Prepare a shape-spec for multi-tenant audit trail."

## Governance Structure

Everything lives under `project-governance/`:

- `project-governance/standards/`
- `project-governance/standards/index.yml`
- `project-governance/product/`
- `project-governance/specs/`
- `project-governance/state/`

## Shared Standards Model

Standards are project files, not local notes.
This lets every team member and every agent session work from the same rules.
The result is more consistency in technical decisions, implementation, and generated code quality.

## Shape-Spec Flow

1. The agent prepares a planning draft with scope, key questions, and suggested standards.
2. Explicit confirmation happens before artifacts are created.
3. `plan.md`, `shape.md`, `standards.md`, `references.md`, and `visuals/` are saved in `project-governance/specs/...`.
4. State is updated to preserve continuity.

## Guardrails

- Standards must be `.md` files under `project-governance/standards/`.
- `index.yml` must reference existing standards only.
- Writing shape-spec artifacts requires explicit approval.
- If `project-governance/` is missing, the skill stays in passive mode until initialization is requested.

## Troubleshooting

- If `index.yml` is missing, ask the agent to initialize governance or rebuild the index.
- If the managed block in `AGENTS.md` is inconsistent, ask the agent to refresh it.
- If state looks stale, ask the agent to save state for the current workstream.

## License

MIT. See `LICENSE`.
