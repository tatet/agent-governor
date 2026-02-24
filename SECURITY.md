# Security Policy

## Supported Versions

- Supported: latest `main` branch.
- Older commits are not guaranteed to receive fixes.

## Reporting a Vulnerability

Please report security issues through **GitHub Security Advisories** for this repository.

- Use a private advisory submission.
- Include reproduction steps, affected files/scripts, and impact.
- Do not open public issues for undisclosed vulnerabilities.

## Response Expectations

- Initial acknowledgment target: within 3 business days.
- Triage/update target: within 7 business days.
- Fix timing depends on severity and complexity.

## Security Scope and Guarantees

This project is a local governance skill. Its scripts are designed to:

- Operate on repository-local files.
- Avoid privilege escalation.
- Avoid outbound network calls in normal operation.

## Out of Scope

- Host/OS hardening outside repository scripts.
- Vulnerabilities caused by running scripts as `root` in untrusted repositories.
- Security issues in third-party tools outside this repository.

## Hardening Notes

Current protections include:

- Input quoting and strict shell mode (`set -euo pipefail`).
- Explicit approval gate for shape-spec artifact writes.
- Safer temporary file handling for initialization.
- Symlink write protections on managed outputs.
- YAML escaping for state persistence.

## Maintainer Security Checklist

- Validate shell syntax on all scripts before release.
- Review file writes for path/symlink safety.
- Keep governance root and output paths deterministic.
- Prefer unique temporary files over fixed `/tmp` names.
- Document behavior changes that affect security assumptions.
