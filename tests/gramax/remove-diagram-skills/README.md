# tests/gramax/remove-diagram-skills

Smoke-тесты для фичи «удаление diagram-on-demand + diagrams skills, переход на внешний drawio» (spec: `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`, ADR-0008).

## Запуск

```bash
bash tests/gramax/remove-diagram-skills/run.sh
```

Каждый `ac-*.sh` соответствует одному AC из spec'а. `run.sh` запускает их по алфавиту и агрегирует pass/fail.

## TDD-статус

- **До Dev** (skills и скрипты ещё на месте): все 16 тестов **должны падать (RED)**. Это ожидаемое поведение TDD.
- **После Dev** (skills удалены, writer rewired, bump 2.0.0, README обновлён): все 16 тестов **должны проходить (GREEN)**.

## Покрытие AC

| Test | AC | Что проверяет |
|------|----|----|
| ac-001 | AC-001 | `skills/diagram-on-demand/` удалён |
| ac-002 | AC-002 | `skills/diagrams/` удалён |
| ac-003 | AC-003 | 4 скрипта-сироты удалены (find_doc_root.sh, save_diagram.sh, insert_diagram_ref.sh, validate_diagram_type.sh) |
| ac-004 | AC-004 | `scripts/drawio_convert.py` удалён |
| ac-005 | AC-005 | `writer/SKILL.md` без `drawio_convert` |
| ac-006 | AC-006 | `writer/references/drawio.md` без `drawio_convert` |
| ac-007 | AC-007 | `writer/references/staging.md` без `drawio_convert` |
| ac-008 | AC-008 | `writer/references/drawio.md` описывает новый workflow |
| ac-009 | AC-009 | README плагина имеет prerequisites блок |
| ac-010 | AC-010 | README без упоминаний удалённых skills |
| ac-011 | AC-011 | `plugin.json` v2.0.0 + обновлённое description |
| ac-012 | AC-012 | `marketplace.json` обновлён |
| ac-013 | AC-013 | `CHANGELOG.md` имеет секцию `## 2.0.0` |
| ac-014 | AC-014 | `mermaid/SKILL.md` description уточнён |
| ac-015 | AC-015 | `scripts/check.sh --fast` зелёный |
| ac-016 | AC-016 | Нет orphan references на удалённые скрипты в `plugins/gramax/` |
