# Tests: routing-mermaid-drawio (gramax 3.0.0)

## What this tests

Failing stubs for **routing-mermaid-drawio v3.0.0** — the feature that adds `gramax:drawio`
skill (delegate stub), removes the `claude-mermaid` vendored submodule, and bumps the plugin
to version 3.0.0 (breaking change).

## Spec and ADR

- Spec: `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` (AC-001..AC-015)
- ADR: `docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md`

## AC to test mapping

| Test file | AC | Description |
|-----------|-----|-------------|
| ac-001-drawio-skill-exists.sh | AC-001/FR-001 | drawio/SKILL.md exists with YAML frontmatter |
| ac-002-drawio-description-explicit-triggers.sh | AC-003/FR-002 | description triggers on drawio, not mermaid |
| ac-003-drawio-description-install-hint.sh | AC-004/FR-004 | Agents365-ai install hint present |
| ac-004-drawio-skill-workflow-section.sh | AC-005/FR-005 | two-step workflow documented |
| ac-005-drawio-skill-gramax-tags.sh | AC-005/FR-005 | both [drawio:] and <Image src tags |
| ac-006-drawio-skill-fallback-section.sh | AC-006/FR-006 | cross-ref to gramax:mermaid |
| ac-007-mermaid-description-drawio-xref.sh | AC-008/FR-007 | mermaid description has gramax:drawio xref |
| ac-008-mermaid-skill-fallback-section.sh | AC-008/FR-006 | mermaid has ambiguous-request fallback |
| ac-009-claude-mermaid-dir-removed.sh | AC-010/FR-008 | plugins/claude-mermaid/ absent |
| ac-010-gitmodules-clean.sh | AC-009/FR-008 | .gitmodules has no claude-mermaid entry |
| ac-011-marketplace-no-claude-mermaid.sh | AC-011/FR-010 | marketplace.json plugins no claude-mermaid |
| ac-012-plugin-json-version-3.sh | AC-012/FR-009 | plugin.json version == 3.0.0 |
| ac-013-marketplace-json-version-3.sh | AC-012/FR-010 | marketplace.json metadata.version == 3.0.0 |
| ac-014-plugin-json-drawio-skill-listed.sh | AC-002/FR-001 | plugin.json declares drawio skill |
| ac-015-changelog-breaking-section.sh | AC-013/FR-011 | CHANGELOG.md has ## 3.0.0 section |
| ac-016-no-orphan-claude-mermaid-refs.sh | Sunset pattern | no orphan claude-mermaid refs in plugin files |
| ac-017-marketplace-description-updated.sh | Sunset pattern | marketplace.json descriptions updated |
| ac-018-check-sh-passes.sh | AC-014/NFR-004 | scripts/check.sh --fast exits 0 |

## How to run

```bash
# From worktree root:
bash tests/gramax/routing-mermaid-drawio/run-all.sh

# Single test:
bash tests/gramax/routing-mermaid-drawio/ac-001-drawio-skill-exists.sh
```

Requires: `bash`, `python3` (stdlib only — no pip packages). No `jq` needed.

## Current status

**Failing stubs before Dev implementation — this is intentional.**

Dev makes tests green by following ADR-0009 actionable list (8 steps).
After all 18 tests pass, run `bash scripts/check.sh --fast` as final gate.
