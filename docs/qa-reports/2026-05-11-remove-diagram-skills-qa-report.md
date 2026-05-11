# QA Report: remove-diagram-skills

Дата: 2026-05-11
QA-runner: qa-runner-agent
Worktree: `feat-remove-diagram-skills`
Spec: [docs/superpowers/specs/2026-05-11-remove-diagram-skills.md](../superpowers/specs/2026-05-11-remove-diagram-skills.md)
ADR: [docs/adr/0008-drop-internal-drawio-skills.md](../adr/0008-drop-internal-drawio-skills.md)

## Summary

| Проверка | Результат |
|----------|-----------|
| AC tests (`run.sh`) | 16/16 GREEN |
| `check.sh --fast` | PASS (exit 0) |
| `check.sh` full | PASS (exit 0) |
| comments tests (Python) | 7/7 PASS |
| Структурная регрессия (4 skills frontmatter) | PASS |
| Manifest validity (`plugin.json` + `marketplace.json`) | PASS — оба `version = 2.0.0` |
| Orphan-refs (расширенный охват) | PASS — только в разрешённых исторических локациях |
| Submodule `claude-mermaid` | clean |
| **Overall** | ✅ **READY FOR ACCEPTANCE** |

## AC coverage

| AC | Test | Status |
|----|------|--------|
| AC-001 — `skills/diagram-on-demand/` удалён | ac-001 | PASS |
| AC-002 — `skills/diagrams/` удалён | ac-002 | PASS |
| AC-003 — 4 скрипта-сироты удалены | ac-003 | PASS |
| AC-004 — `drawio_convert.py` удалён | ac-004 | PASS |
| AC-005 — `writer/SKILL.md` без `drawio_convert.py` | ac-005 | PASS |
| AC-006 — `writer/references/drawio.md` без `drawio_convert.py` | ac-006 | PASS |
| AC-007 — `writer/references/staging.md` без `drawio_convert.py` | ac-007 | PASS |
| AC-008 — `writer/references/drawio.md` содержит новый workflow | ac-008 | PASS |
| AC-009 — README содержит prerequisites блок | ac-009 | PASS |
| AC-010 — README без удалённых skills | ac-010 | PASS |
| AC-011 — `plugin.json` v2.0.0 + clean description | ac-011 | PASS |
| AC-012 — `marketplace.json` v2.0.0 + updated descriptions | ac-012 | PASS |
| AC-013 — CHANGELOG `## 2.0.0` секция полная | ac-013 | PASS |
| AC-014 — `mermaid/SKILL.md` description ограничен Mermaid DSL | ac-014 | PASS |
| AC-015 — `scripts/check.sh --fast` exit 0 | ac-015 | PASS |
| AC-016 — нет orphan-ссылок в плагине | ac-016 | PASS |

## Orphan-references (расширенный охват)

Grep по `README.md`, `CHANGELOG.md`, `docs/`, `plugins/gramax/`, `.claude/plugins/` для:
`drawio_convert`, `find_doc_root`, `save_diagram.sh`, `insert_diagram_ref`, `validate_diagram_type`.

**Hits только в разрешённых исторических локациях:**
- `docs/acceptance/2026-05-08-diagram-on-demand-acceptance.md` — архив прошлого acceptance.
- `docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md` — архив прошлого QA.
- `docs/adr/0001-0007*.md` — история ADR (разрешено, ADR-0008 superseded маркер).
- `docs/research/` — research outputs.
- `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/lessons-learned.md` — историческая документация.

**0 hits** в живых файлах `plugins/gramax/skills/`, `plugins/gramax/scripts/`, `.claude/plugins/`.

## Регрессионная диагностика

- **comments-read / comments-write**: 7 Python-тестов из `plugins/gramax/scripts/tests/test_validate_structure.py` — PASS. Скрипты не затронуты данным изменением.
- **writer skill**: SKILL.md и references переписаны; frontmatter валиден; ссылки на `drawio_convert.py` отсутствуют (3 файла подтверждены AC-005/006/007). Структура skill валидна.
- **mermaid skill**: frontmatter валиден; description ограничен Mermaid DSL и делегирует drawio внешнему плагину (AC-014). LICENSE.upstream.md сохранён.
- **review-agent**: не затронут изменением.
- **submodule `claude-mermaid`**: git submodule status чист (`-817759b9b79eec7e365b9c18b5b14d870ef3ea9c`).

## Open issues / Risks

Нет блокирующих находок. Допустимые открытые вопросы переадресуются BA-acceptance:

1. **Tone CHANGELOG**: миграционные ноты технически полны, но tech-writer должен пройти стилистическую финализацию (DOC-001).
2. **Lessons-learned**: фиксация урока «sunset skill требует tracking ссылок в writer-references» — задача tech-writer.

## Verdict

**✅ READY FOR ACCEPTANCE** — передача в BA acceptance-gate.

Команда: `/ba --mode=acceptance remove-diagram-skills`
