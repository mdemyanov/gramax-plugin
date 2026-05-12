# Test Report — 2026-05-12 — gramax / mermaid-file-based (QA-R-007)

## Summary

- passed: 3
- failed: 10
- skipped: 0
- total: 13
- duration: < 5s
- run command: `bash tests/gramax/mermaid-file-based/run.sh`
- repo-level check: `bash scripts/check.sh --fast` — PASS

## Manifest validation

- `.claude-plugin/marketplace.json`: OK (`jq` valid JSON, `metadata.version = "4.0.0"`)
- `plugins/gramax/.claude-plugin/plugin.json`: OK (`jq` valid JSON, `version = "4.0.0"`)
- Объявленные артефакты (skills): `writer`, `comments-read`, `comments-write`, `mermaid`, `drawio` — все директории присутствуют в `plugins/gramax/skills/`

## Regression analysis

Директория `tests/gramax/mermaid-file-based/` — **untracked** (git status: `??`), в истории репозитория не встречается. Это первый прогон нового пакета тестов. Ни один из упавших тестов не был зелёным в предыдущих PR (#3, #4, #5, #6) — регрессий нет. Все 10 падений классифицируются как **new** или **integration pending**.

## Failed tests (детали)

| Тест | Категория | Причина | Действие |
|------|-----------|---------|----------|
| `ac-001-mermaid-file-created.sh` | integration pending | Тест проверяет runtime-действие Claude: Write tool должен создать `.mermaid`-файл. Файл не существует в temp-директории, т.к. LLM не вызывался. Fixture-части (clean-article.md) созданы корректно. | Manual smoke после ручного вызова skill |
| `ac-002-mermaid-file-valid-dsl.sh` | integration pending | Зависит от AC-001 (файл отсутствует). Fixture-субассерт (`expected-diagram.mermaid` начинается с `flowchart`) — PASS. Основная проверка заблокирована отсутствием файла. | Manual smoke |
| `ac-003-md-contains-tag.sh` | integration pending | Тег `<mermaid path="./"/>` не вставлен в temp md-файл — Edit tool не вызывался. `clean-article.md` не содержит тег по дизайну. | Manual smoke |
| `ac-004-tag-has-width-height.sh` | integration pending | Зависит от AC-003 (тег не вставлен). Fixture-субассерты (`expected-tag.md` содержит `width="` и `height="`) — PASS. | Manual smoke |
| `ac-005-default-width-height-values.sh` | integration pending | Зависит от AC-003. Fixture-субассерт (`expected-tag.md` содержит `width="800px" height="450px"`) — PASS. | Manual smoke |
| `ac-005b-naming-convention-slug.sh` | integration pending | Три케 file-existence кейса (overview-auth-flow.mermaid, endpoints-diagram.mermaid, payments-diagram.mermaid) — все отсутствуют, т.к. skill не вызывался. Boundary slug-length (k8s-setup-deployment-pipeline) — прошёл внутри теста (slug ≤ 30 символов). | Manual smoke |
| `ac-006-tag-self-closing.sh` | integration pending | Зависит от AC-003. Fixture-субассерт (`expected-tag.md` содержит самозакрывающийся тег с path/width/height) — PASS. | Manual smoke |
| `ac-007-no-markup-in-mermaid-file.sh` | integration pending | Зависит от AC-001 (файл отсутствует). Fixture-субассерты: `dirty-diagram-with-markup.mermaid` содержит `<mermaid>` (negative санити PASS), `expected-diagram.mermaid` не содержит обёрток (positive PASS). | Manual smoke |
| `ac-009-inline-block-warning.sh` | integration pending | Тест проверяет runtime-вывод Claude в stdout. Жёстко прошит `INLINE_BLOCK_DETECTED=0` — тест намеренно red до реализации. Fixture-санити (inline-mermaid.md содержит `<mermaid>`, fenced.md содержит `` ```mermaid ``) — оба PASS. No-mutation assert (файл не изменён без подтверждения) — PASS. | Manual smoke после ручного вызова |
| `ac-010-no-list-syntax-in-dsl.sh` | integration pending | Зависит от AC-001 (файл отсутствует). Fixture-субассерты: `diagram-with-list-syntax.mermaid` содержит `1. ` (negative санити PASS), `expected-diagram.mermaid` не содержит (positive PASS). | Manual smoke |

## Прошедшие тесты

| Тест | Что проверяет |
|------|---------------|
| `ac-008-no-silent-overwrite.sh` | Static: файл, записанный в setup, не изменяется без вызова skill. Логика идемпотентности верифицирована на уровне инварианта. |
| `ac-011-no-inline-phrase-in-skill.sh` | Static: `SKILL.md` не содержит устаревшую фразу `inline DSL, без файла`. Реализован корректно. |
| `ac-012-manifest-version-4.sh` | Static: `plugin.json` и `marketplace.json` содержат `version = "4.0.0"`. JSON-валидность подтверждена `jq`. |

## Структурные проверки (дополнительно)

| Проверка | Результат |
|----------|-----------|
| `plugin.json` содержит `"version": "4.0.0"` | PASS |
| `marketplace.json` содержит `"version": "4.0.0"` | PASS |
| `plugins/gramax/CHANGELOG.md` содержит секцию `## 4.0.0` | PASS (строка 3) |
| `SKILL.md` НЕ содержит `"inline DSL, без файла"` | PASS |
| `SKILL.md` содержит `<mermaid path=` | PASS (строки 8, 46, 90, 105) |
| `SKILL.md` содержит раздел «Naming convention» | PASS (строка 51) |
| `SKILL.md` содержит раздел «Backward compatibility» | PASS (строка 273) |
| Quick start описывает Write tool (создание файла) | PASS (шаг 7, строка 43) |
| Checklist содержит пункт про отсутствие Gramax-разметки в `.mermaid`-файле | PASS (строка 271) |
| `scripts/check.sh --fast` (whitespace + JSON) | PASS |

## AC coverage check

| AC | Тест | Статус |
|----|------|--------|
| AC-001 (.mermaid-файл создаётся рядом с target_page) | `ac-001-mermaid-file-created.sh` | Integration pending |
| AC-001 (boundary: _index.md → page-slug из родительской директории) | `ac-001-mermaid-file-created.sh` | Integration pending |
| AC-002 (первая строка DSL — поддерживаемый тип) | `ac-002-mermaid-file-valid-dsl.sh` | Integration pending |
| AC-003 (md содержит тег `<mermaid path="./"/>`) | `ac-003-md-contains-tag.sh` | Integration pending |
| AC-004 (тег содержит width и height) | `ac-004-tag-has-width-height.sh` | Integration pending |
| AC-005 (дефолты `width="800px" height="450px"`) | `ac-005-default-width-height-values.sh` | Integration pending |
| AC-005 naming (kebab-case slug ≤ 30 символов) | `ac-005b-naming-convention-slug.sh` | Integration pending |
| AC-006 (тег самозакрывающийся) | `ac-006-tag-self-closing.sh` | Integration pending |
| AC-007 (.mermaid-файл — только чистый DSL, без обёрток) | `ac-007-no-markup-in-mermaid-file.sh` | Integration pending |
| AC-008 (нет тихой перезаписи без подтверждения) | `ac-008-no-silent-overwrite.sh` | Static PASS |
| AC-009 (предупреждение при inline-блоке — XML и fenced) | `ac-009-inline-block-warning.sh` | Integration pending |
| AC-010 (DSL без list-syntax паттерна) | `ac-010-no-list-syntax-in-dsl.sh` | Integration pending |
| AC-011 (SKILL.md без устаревшей фразы) | `ac-011-no-inline-phrase-in-skill.sh` | Static PASS |
| AC-012 / манифесты version 4.0.0 | `ac-012-manifest-version-4.sh` | Static PASS |

## Рекомендация

- [ ] merge
- [ ] block + назад в Dev
- [x] re-run после ручной smoke-проверки (integration pending)

**Обоснование:**

Все 10 падений классифицированы как **integration pending** — это ожидаемое состояние, предупреждённое Dev'ом. Тесты проверяют runtime-поведение Claude (Write tool / Edit tool / stdout skill'а), которое не может быть верифицировано bash-harness'ом без вызова LLM.

Регрессий нет: `tests/gramax/mermaid-file-based/` — новый untracked пакет, в истории репозитория отсутствует.

Статические проверки (3/3) зелёные: SKILL.md реализован корректно (файловый workflow, naming convention, backward compatibility), манифесты обновлены до 4.0.0, CHANGELOG содержит секцию 4.0.0.

Fixture-субассерты внутри упавших тестов все зелёные: `expected-diagram.mermaid`, `expected-tag.md`, `dirty-diagram-with-markup.mermaid`, `diagram-with-list-syntax.mermaid`, `article-with-inline-mermaid.md`, `article-with-fenced-mermaid.md` — валидированы корректно.

**Действия для BA acceptance gate:**

1. QA-runner передаёт в BA статус: **integration pending** (10 тестов требуют ручной smoke-проверки при реальном вызове skill в Gramax-документе).
2. Для acceptance достаточно ручного smoke по AC-001 / AC-003 / AC-009 с реальным вызовом `gramax:mermaid` — проверить создание `.mermaid`-файла, вставку тега, предупреждение при inline-блоке.
3. После ручного smoke BA выносит вердикт: merge или block.
