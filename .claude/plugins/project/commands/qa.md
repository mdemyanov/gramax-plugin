---
description: "QA с режимами author (failing stubs до Dev) и runner (smoke + регрессия). Тесты — bash-harness в tests/<plugin>/. Пример: /qa --mode=author plugin-status, /qa --mode=runner gramax"
allowed-tools: Task
---

# /qa — QA-агент с двумя режимами

Аргументы: `--mode=author <feature-or-spec>` или `--mode=runner <plugin-or-feature>`.

## Логика

Распарсь `$ARGUMENTS`:

1. **`--mode=author`** — диспетч `project:qa-author-agent` через Task tool (`subagent_type: "project:qa-author-agent"`).
   - Цель: создать AC-driven test design + failing test stubs ДО Dev'а
   - Входы: spec `docs/superpowers/specs/<feature>.md` (с AC); опц. ADR в `docs/adr/`
   - Артефакты:
     - `docs/superpowers/specs/<feature>/at-design.md` — матрица AC × test
     - failing stubs `tests/<plugin>/<feature>_test.sh` (bash-harness)
   - Критерии: stubs запускаются и падают (red); AC покрытие 100%; `bash tests/<plugin>/run.sh` показывает падения только для нового файла

2. **`--mode=runner`** — диспетч `project:qa-runner-agent` через Task tool (`subagent_type: "project:qa-runner-agent"`).
   - Цель: прогнать full test suite + регрессии после Dev'а; сформировать отчёт
   - Входы: реализация в `plugins/<name>/`, тесты `tests/<plugin>/`, spec с AC
   - Запуск: `bash tests/<plugin>/run.sh` (или индивидуальные `bash tests/<plugin>/<feature>_test.sh`)
   - Артефакт: `docs/superpowers/specs/<feature>/test-report-YYYY-MM-DD.md` или inline-секция в spec
   - Критерии: отчёт включает passed/failed/skipped + regression analysis + рекомендация (merge/block/re-run); вывод `git diff --check` чистый

3. **`--mode` пропущен** — попроси пользователя уточнить режим.

## Передача subagent'у

Сформируй prompt по контракту из AGENTS.md («Контракт вызова субагента»):

1. **Цель** одной фразой
2. **Входные файлы** — конкретные пути в зависимости от режима
3. **Ожидаемый артефакт** — путь и формат (см. логику выше)
4. **Критерии приёмки** — из контракта роли

## Тестовая инфраструктура

- Bash-harness живёт в `tests/<plugin>/`
- Раннер: `bash tests/<plugin>/run.sh` (или общий `bash scripts/check.sh --fast`, если задан)
- Формат теста: shell-скрипт, который exitcode != 0 при падении и пишет понятную диагностику
- Для markdown-skills — self-test через frontmatter-парсинг и проверку триггеров

## Примеры

- `/qa --mode=author plugin-status` → запускает `project:qa-author-agent` с задачей «написать AC-driven test design + failing stubs для plugin-status»
- `/qa --mode=runner gramax` → запускает `project:qa-runner-agent` с задачей «прогнать full suite для plugin gramax, написать отчёт»

## Handoff

QA-author вызывается ПОСЛЕ ba/sa, ДО dev (TDD red-stage); qa-runner — ПОСЛЕ dev, ПЕРЕД ba-acceptance gate'ом и `/pm-review`.
