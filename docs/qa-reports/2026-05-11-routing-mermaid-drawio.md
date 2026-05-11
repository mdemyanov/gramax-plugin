# QA Report — routing-mermaid-drawio-v2 (gramax 3.0.0)

**Date:** 2026-05-11
**Branch:** feat-routing-mermaid-drawio
**Tester:** QA-runner

---

## Резюме

**PASS with notes**

Целевой тест-набор фичи (`routing-mermaid-drawio`) — 18/18 PASS. Все ключевые артефакты (manifests, submodule, SKILL.md, check.sh) зелёные. Падения в двух исторических наборах (`remove-diagram-skills`, `diagram-on-demand`) классифицированы ниже и не являются регрессиями, введёнными текущей веткой.

---

## Прогон тестов

| Набор | Результат | Заметки |
|-------|-----------|---------|
| `tests/gramax/routing-mermaid-drawio` | 18/18 PASS | Все AC фичи v3.0.0 зелёные |
| `tests/gramax/remove-diagram-skills` | 13/16 PASS | 3 падения: ac-011, ac-012, ac-014 — см. классификацию |
| `tests/gramax/diagram-on-demand` | 1/12 PASS | 11 падений — artifacts удалены в PR #4 (v2.0.0); тесты — исторический artifact |

---

## JSON validity

- `.claude-plugin/marketplace.json`: **OK** — `python3 -c "import json; json.load(open(...))"` без ошибок.
- `plugins/gramax/.claude-plugin/plugin.json`: **OK** — то же самое.

---

## Submodule check

- `git submodule status`: пусто (нет submodule'ов).
- `.gitmodules`: файл отсутствует.
- `ls plugins/`: только `gramax/` — `claude-mermaid/` отсутствует.

**PASS**

---

## SKILL.md sanity

Все файлы проверены командой `grep -c "^---$"` и `grep -c "^description:"`:

| Skill | Frontmatter (---) | description: |
|-------|-------------------|--------------|
| `drawio` | 2 | 1 |
| `mermaid` | 2 | 1 |
| `writer` | 8 (внутренние секции) | 2 |
| `comments-read` | 3 | 1 |
| `comments-write` | 2 | 1 |

**PASS** — все файлы существуют, frontmatter присутствует, поле `description` есть у каждого.

---

## Orphan scan

Команда: `grep -r "claude-mermaid" . --include="*.md" --include="*.json" --exclude-dir=".git" --exclude-dir=".worktrees" --exclude-dir="docs/adr" --exclude-dir="docs/superpowers" -l`

Найдены упоминания в:

| Файл | Характер | Допустимость |
|------|----------|--------------|
| `CLAUDE.md` | Историческое описание vendored submodule (3 строки) | **Техдолг** — CLAUDE.md не обновлён после удаления submodule |
| `plugins/gramax/CHANGELOG.md` | Секция 3.0.0 ### Removed — контекст удаления | **Допустимо** (CHANGELOG — летопись) |
| `tests/gramax/routing-mermaid-drawio/README.md` | Тест грепает эту строку намеренно | **Допустимо** (тестовый файл) |
| `.claude/plugins/project/agents/*.md` | Описание роли агентов (historical context) | **Допустимо** (не в `plugins/`, не публикуется) |
| `.claude/plugins/project/commands/*.md` | Команды PM (historical context) | **Допустимо** (не публикуется) |
| `docs/lessons-learned.md` | Запись урока из Research-фазы | **Допустимо** (lessons-journal) |
| `docs/qa-reports/2026-05-11-remove-diagram-skills-qa-report.md` | Отчёт предыдущего QA-цикла | **Допустимо** (архив) |
| `docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md` | Отчёт предыдущего QA-цикла | **Допустимо** (архив) |
| `docs/acceptance/2026-05-11-remove-diagram-skills-acceptance.md` | Acceptance-gate запись | **Допустимо** (архив) |
| `docs/acceptance/2026-05-08-diagram-on-demand-acceptance.md` | Acceptance-gate запись | **Допустимо** (архив) |

**Нарушение:** `CLAUDE.md` содержит 3 строки, описывающие `plugins/claude-mermaid/` как активный vendored submodule. После удаления submodule в PR #4 этот текст не актуален. Это **техдолг**, но не регрессия, введённая текущей веткой (CLAUDE.md не менялся в `feat-routing-mermaid-drawio`).

**Вердикт orphan scan: PASS with note** — orphan в `CLAUDE.md` существовал до начала этой фичи; не является регрессией текущей ветки. Рекомендую Dev'у или Tech-writer'у устранить в отдельном PR.

---

## check.sh --fast

```
==> mode: --fast
==> whitespace: OK
==> json: OK
==> RESULT: PASS
```

**PASS**

---

## Регрессии

**Нет регрессий, введённых веткой `feat-routing-mermaid-drawio`.**

---

## Классификация падений

### `tests/gramax/remove-diagram-skills/` — 3 падения

| Тест | Категория | Причина | Действие |
|------|-----------|---------|---------|
| `ac-011-plugin-json-2-0-0.sh` | **acceptable / version progression** | Тест хардкодит `"version": "2.0.0"`. Текущая ветка легитимно бампает до `3.0.0`. Тест был написан как stub для v2.0.0 и не обновлён под v3.0.0. | QA-author должен обновить тест под новую версию (не блокирует merge) |
| `ac-012-marketplace-json-updated.sh` | **acceptable / version progression** | То же — хардкод `"2.0.0"` в marketplace. | Аналогично |
| `ac-014-mermaid-description-updated.sh` | **acceptable / pattern mismatch** | Тест требует regex `Agents365-ai\|drawio-skill\|внешний.*drawio\|drawio.*внешний`. Фактическое описание: «...Не для: drawio... — используй gramax:drawio.» — семантически эквивалентно ADR-0008 Решение 5, но не попадает под regex. Код корректен, тест не учитывает вариации формулировки. | QA-author должен расширить regex (не блокирует merge) |

### `tests/gramax/diagram-on-demand/` — 11 падений

| Категория | Причина |
|-----------|---------|
| **env / deliberately deleted** | Skill `diagram-on-demand` и все его скрипты (`find_doc_root.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`, `drawio_convert.py`, `validate_diagram_type.sh`) были **намеренно удалены** в коммите `31ff5b8` (PR #4, merged в main). Тесты в `tests/gramax/diagram-on-demand/` остались как исторические артефакты. Они не могут быть зелёными на архитектуре v2.0.0+. Единственный проходящий тест — `ac-007-slugify.sh`, который тестирует `slugify` — независимую утилиту. |

Эти падения существовали **до** начала `feat-routing-mermaid-drawio` и не являются регрессией данной фичи. Рекомендация: тест-набор `diagram-on-demand` должен быть помечен как `[DEPRECATED]` или удалён QA-author'ом.

---

## Известные acceptable-изменения

1. **Version bump 2.0.0 → 3.0.0**: `plugin.json` и `marketplace.json` — ожидаемое изменение для `gramax 3.0.0`. Тесты `remove-diagram-skills`, хардкодящие `2.0.0`, устарели.
2. **Тесты `diagram-on-demand` — deprecated**: Skill удалён в v2.0.0, тесты не мигрированы. 11/12 падений — следствие намеренного architectural decision (ADR-0008), а не ошибки текущей фичи.
3. **`drawio` skill присутствует**: Старые тесты из `remove-diagram-skills` не тестировали наличие `drawio` skill (он добавлен в текущей фиче v3.0.0). Тест ac-016 и ac-009 из `routing-mermaid-drawio` подтверждают его корректное добавление.
4. **`CLAUDE.md` — orphan**: 3 строки про `plugins/claude-mermaid/` не актуальны после PR #4. Техдолг вне scope текущей фичи.

---

## AC coverage (routing-mermaid-drawio v3.0.0)

| AC | Тест | Статус |
|----|------|--------|
| AC-001: drawio/SKILL.md с YAML frontmatter | ac-001 | PASS |
| AC-002: drawio description не триггерит mermaid | ac-002 | PASS |
| AC-003: drawio содержит Agents365-ai install hint | ac-003 | PASS |
| AC-004: drawio two-step workflow | ac-004 | PASS |
| AC-005: оба формата тегов Gramax | ac-005 | PASS |
| AC-006: drawio cross-ref → gramax:mermaid | ac-006 | PASS |
| AC-007: mermaid cross-ref → gramax:drawio, без Agents365-ai | ac-007 | PASS |
| AC-008: mermaid ambiguous-request fallback | ac-008 | PASS |
| AC-009: plugins/claude-mermaid/ отсутствует | ac-009 | PASS |
| AC-010: .gitmodules без claude-mermaid | ac-010 | PASS |
| AC-011: marketplace.json без claude-mermaid | ac-011 | PASS |
| AC-012: plugin.json version == 3.0.0 | ac-012 | PASS |
| AC-013: marketplace.json version == 3.0.0 | ac-013 | PASS |
| AC-014: plugin.json skills объявляет drawio | ac-014 | PASS |
| AC-015: CHANGELOG.md 3.0.0 секция полная | ac-015 | PASS |
| AC-016: нет orphan claude-mermaid в plugin files | ac-016 | PASS |
| AC-017: marketplace.json descriptions без claude-mermaid | ac-017 | PASS |
| AC-018: check.sh --fast exit 0 | ac-018 | PASS |

**Все 18 AC фичи routing-mermaid-drawio закрыты.**

---

## Рекомендации

- [x] **go for BA-acceptance** — все AC фичи v3.0.0 зелёные, артефакты валидны.

**Обоснование:** Все 18 AC routing-mermaid-drawio прошли. JSON-манифесты валидны. Submodule удалён. SKILL.md sanity OK. check.sh PASS. Падения в исторических наборах — следствие архитектурных решений PR #4 (ADR-0008), не регрессий текущей фичи.

**Пост-PR рекомендации (не блокируют merge):**
1. `CLAUDE.md`: убрать 3 строки про `plugins/claude-mermaid/` как активный submodule (Tech-writer или Dev в следующем PR).
2. `tests/gramax/remove-diagram-skills/ac-011`, `ac-012`, `ac-014`: обновить хардкод версий и regex под v3.0.0 (QA-author).
3. `tests/gramax/diagram-on-demand/`: пометить набор как `[DEPRECATED]` или удалить (QA-author + PM-decision).
