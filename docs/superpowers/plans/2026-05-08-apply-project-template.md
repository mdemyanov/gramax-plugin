# Apply project_template to gramax — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перенести в gramax-marketplace-репо рабочий конвейер `brainstorm → spec → plan → TDD → review` из шаблона `project_template`, с 7-ролевой PM-оркестрацией, без `content/`/profiles/devops/init.

**Architecture:** Создаём в репо локальный приватный marketplace (`.claude/.claude-plugin/marketplace.json`, отдельно от публичного `gramax-marketplace`) с одним плагином `project`, содержащим 8 ролевых агентов и 8 slash-команд. Workflow и red lines описаны в `CLAUDE.md`/`AGENTS.md`. `docs/superpowers/{specs,plans}/`, `docs/adr/`, `docs/lessons-learned.md` — артефакты ролей. Lightweight `scripts/check.sh` (без content-валидаторов).

**Tech Stack:** Markdown, Bash, JSON. Никакого нового рантайма не добавляем.

**Source spec:** `docs/superpowers/specs/2026-05-08-apply-project-template-design.md`.

**Reference template:** `/Users/mdemyanov/knowlage/project_template/`.

---

## File Structure

| Файл | Назначение |
|---|---|
| `CLAUDE.md` | Ядро правил (marketplace-context, red lines, когда какой скилл звать) |
| `AGENTS.md` | Карта 7 ролей + контракт вызова субагента |
| `.claude/settings.json` | Регистрирует приватный marketplace `gramax-internal` и включает `project@gramax-internal` |
| `.claude/.claude-plugin/marketplace.json` | Приватный marketplace, объявляет `project` plugin |
| `.claude/plugins/project/.claude-plugin/plugin.json` | Plugin manifest |
| `.claude/plugins/project/agents/{pm,ba,sa,dev,qa-author,qa-runner,researcher,tech-writer}-agent.md` | 8 ролевых промптов |
| `.claude/plugins/project/commands/{pm,ba,sa,dev,qa,research,tech-writer,pm-review}.md` | 8 slash-команд |
| `docs/superpowers/specs/.gitkeep` | Директория для брейнштормов |
| `docs/superpowers/plans/.gitkeep` | Директория для планов реализации |
| `docs/adr/.gitkeep` | Architecture Decision Records |
| `docs/lessons-learned.md` | Append-only журнал уроков |
| `scripts/check.sh` | Light pre-commit gate (whitespace + JSON validate) |
| `scripts/install-hooks.sh` | Активация `.githooks/` |
| `.githooks/pre-commit` | Hook вызывающий `check.sh --fast` |

---

## Phase 1 — Skeleton (CLAUDE.md, AGENTS.md, docs structure)

### Task 1.1: Create docs directories and lessons-learned.md

**Files:**
- Create: `docs/superpowers/specs/.gitkeep`
- Create: `docs/superpowers/plans/.gitkeep`
- Create: `docs/adr/.gitkeep`
- Create: `docs/lessons-learned.md`

**Note:** `docs/superpowers/specs/` and `docs/superpowers/plans/` уже частично существуют (созданы при brainstorming-сессии для размещения этого плана и его спеки). Создание `.gitkeep` нужно только для `docs/adr/` и для пустых каталогов; в `docs/superpowers/specs/` уже лежит spec-файл — `.gitkeep` не нужен. То же для `plans/` после того как этот план будет закоммичен.

- [ ] **Step 1: Create directories**

```bash
mkdir -p docs/adr
```

- [ ] **Step 2: Add `.gitkeep` to keep `docs/adr/` in git**

Create `docs/adr/.gitkeep` with empty content.

- [ ] **Step 3: Create `docs/lessons-learned.md`**

Content:

```markdown
# Lessons Learned — gramax marketplace

> Append-only журнал. Каждая запись — короткий урок из реальной работы (фича, bug, surprise). Формат: `## YYYY-MM-DD — <тема>`, далее 3-5 строк: контекст / что узнали / как теперь делаем.

<!-- Первая запись появится после первой завершённой задачи через `/pm`. -->
```

- [ ] **Step 4: Verify**

```bash
ls -la docs/adr/.gitkeep docs/lessons-learned.md
```

Expected: оба файла существуют.

- [ ] **Step 5: Stage (commit будет в конце Phase 1)**

```bash
git add docs/adr/.gitkeep docs/lessons-learned.md
```

---

### Task 1.2: Create CLAUDE.md (marketplace-adapted)

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write `CLAUDE.md` with marketplace-specific content**

Полный контент:

````markdown
# gramax-marketplace — AI-ассистент команды

Работаешь в Claude Code как **PM/координатор** (main-context, Opus). Содержательная ролевая работа делегируется субагентам через slash-команды. Репозиторий — публичный Claude Code marketplace для Gramax-документации.

## Карта команды

| Команда | Роль | Где исполняется | Артефакты |
|---------|------|----------------|-----------|
| `/pm`   | PM (orchestrator) | main (Opus) | Декомпозиция, координация, roadmap |
| `/pm-review` | PM | main (Opus) | Финальная валидация перед merge в main |
| `/research` | Researcher | subagent (Sonnet) | Аналитические выжимки (Claude Code docs, plugin patterns, MCP) |
| `/ba`   | BA  | subagent (Sonnet) | Spec в `docs/superpowers/specs/` |
| `/sa`   | SA  | subagent (Sonnet) | Архитектурные решения в `docs/adr/` |
| `/dev`  | Dev | subagent (Sonnet) | Код в `plugins/gramax/` (TDD для shell/JS) |
| `/qa`   | QA (author/runner) | subagent (Sonnet) | Smoke-тесты плагина, проверка outputs |
| `/tech-writer` | Tech-writer | subagent (Sonnet) | README, CHANGELOG, marketplace.json descriptions |

Полная матрица ролей и контракт вызова субагентов — в **AGENTS.md**.

## Контекст проекта

Публичный Claude Code marketplace (`mdemyanov/gramax-plugin`), включает два плагина:

- **`plugins/gramax/`** — наш плагин: writer, comments-read, comments-write, diagrams, review-agent. Версионируется отдельно (см. `plugins/gramax/CHANGELOG.md`).
- **`plugins/claude-mermaid/`** — vendored MIT-плагин (git submodule на upstream `veelenga/claude-mermaid`). НЕ редактировать.

Marketplace объявлен в корневом `.claude-plugin/marketplace.json` под именем `gramax-marketplace` (для публичного distribution).

## Стек

- Markdown skills и agent prompts (большая часть плагина).
- Bash скрипты (плагинная инфраструктура, smoke-тесты).
- JSON (manifests, settings).
- В составе `claude-mermaid` есть JS/MCP — но это submodule, мы его не трогаем.

## Команды сборки и проверки

- `bash scripts/check.sh --fast` — pre-commit gate (whitespace, JSON-валидность).
- `bash scripts/install-hooks.sh` — активировать `.githooks/pre-commit` (опционально).
- Для распространения: `git push` → пользователи получают через `/plugin marketplace add mdemyanov/gramax-plugin`.

## Архитектурные правила

- Каждый плагин в `plugins/<name>/` имеет свой `.claude-plugin/plugin.json`, `README.md`, `CHANGELOG.md`.
- Skills и команды плагина — в `plugins/<name>/skills/` и `plugins/<name>/commands/`.
- Локальный CTO-инструментарий (агенты PM/BA/SA/...) — в `.claude/plugins/project/`, не в `plugins/` (не публикуется).
- Решения по структуре marketplace, разделению плагинов, изменению manifests — через ADR (`docs/adr/`).

## Подключённые плагины

- **gramax@ai-assistants** или `gramax@gramax-marketplace` — `gramax:writer`, `gramax:comments-read`, `gramax:comments-write`, `gramax:diagrams` (наш собственный плагин, тестируем здесь же).
- **superpowers@claude-plugins-official** — `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`.
- **project@gramax-internal** — локальный CTO-плагин с агентами PM/BA/SA/Dev/QA/Researcher/Tech-writer (приватный, не для distribution).

Marketplace'ы и enabled плагины — в `.claude/settings.json`.

## Поток работы

Канонический порядок новой фичи: **Researcher (опц.) → BA (spec) → SA (ADR при нетривиальной фиче) → Dev (TDD) → QA → Tech-writer (docs)**. PM координирует, `/pm-review` валидирует перед merge.

Ветвление: `main` — единственная ветка, в которую вливаются PR. Feature-ветки опциональны, через worktree (`superpowers:using-git-worktrees`).

## Когда какой скилл звать

| Ситуация | Скилл |
|----------|-------|
| Новая фича/skill/команда плагина | `superpowers:brainstorming` → `writing-plans` → `executing-plans` |
| Реализация фичи или фикса | `superpowers:test-driven-development` |
| Любой баг/непонятное поведение | `superpowers:systematic-debugging` |
| Перед claim'ом «готово» | `superpowers:verification-before-completion` |
| Получение code review | `superpowers:receiving-code-review` |
| Запрос code review | `superpowers:requesting-code-review` |
| Создание/редактирование Gramax-статьи (если нужно) | `gramax:writer` |

## Красные линии

- НЕ публиковать секреты (`.env`, токены, API-ключи, credentials).
- НЕ менять `.claude-plugin/marketplace.json` (корневой, публичный) без ADR. Это договор с пользователями.
- НЕ редактировать `plugins/claude-mermaid/` — это git submodule на upstream `veelenga/claude-mermaid` (MIT). Все изменения — через PR upstream.
- НЕ принимать `/dev`-задачи без артефакта SA (для нетривиальных фич — обязателен ADR).
- НЕ ломать обратную совместимость skill-имён в `plugins/gramax/skills/` без bump major-версии в `plugins/gramax/CHANGELOG.md` + анонс в основном CHANGELOG.
- Tests/линтеры (если в проекте есть) — зелёные перед commit.
- НЕ коммитить с `--no-verify` без явного разрешения.

## Self-improvement

- `docs/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промптов агентов.
````

- [ ] **Step 2: Verify**

```bash
test -f CLAUDE.md && head -5 CLAUDE.md
```

Expected: первые 5 строк начинаются с `# gramax-marketplace`.

- [ ] **Step 3: Stage**

```bash
git add CLAUDE.md
```

---

### Task 1.3: Create AGENTS.md (slim, 7 ролей)

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write `AGENTS.md`**

Полный контент:

````markdown
# AGENTS.md — gramax-marketplace

Матрица ролей, контракт вызова субагентов и поток работы для AI-команды проекта.

## Каталог ролей

| Имя | Описание | Где исполняется | Модель | Промпт-файл | Slash-команды |
|-----|----------|-----------------|--------|-------------|---------------|
| pm | Координатор/orchestrator | main | Opus | (main, не subagent) | `/pm` |
| researcher | Контекст-сборщик (Claude Code docs, plugin patterns, MCP) | subagent | Sonnet | `.claude/plugins/project/agents/researcher-agent.md` | `/research` |
| ba | Бизнес-аналитик: spec на новые skills/agents/commands | subagent | Sonnet | `.claude/plugins/project/agents/ba-agent.md` | `/ba`, `/ba --mode=acceptance` |
| sa | Архитектор плагина: where skill vs command vs agent, ADR | subagent | Sonnet | `.claude/plugins/project/agents/sa-agent.md` | `/sa` |
| dev | TDD-разработчик (shell/JS/markdown skills) | subagent | Sonnet | `.claude/plugins/project/agents/dev-agent.md` | `/dev` |
| qa | QA author + runner: smoke-тесты плагина | subagent | Sonnet | `.claude/plugins/project/agents/qa-author-agent.md` + `qa-runner-agent.md` | `/qa --mode=author`, `/qa --mode=runner` |
| tech-writer | README, CHANGELOG, marketplace.json descriptions | subagent | Sonnet | `.claude/plugins/project/agents/tech-writer-agent.md` | `/tech-writer` |

**Почему так:** PM-координация живёт в main-context, чтобы не раздувать контекст субагентов. Ролевая работа вытесняется в субагенты на более дешёвой модели (Sonnet) — экономия LLM-бюджета. Devops/devsecops/compliance из шаблона исключены: marketplace-плагин не деплоится и не имеет compliance-скоупа.

## Контракт вызова субагента

При запуске любой роли (через `/<command>` или Task tool) передавай:

1. **Цель** одной фразой.
2. **Входные файлы** — пути к контексту (spec, ADR, код плагина, плагин-документация). Субагент сам прочитает.
3. **Ожидаемый артефакт** — какой файл должен появиться/измениться.
4. **Критерии приёмки** — как проверить, что задача выполнена.

Пример корректного prompt'а для `/dev`:

```
Цель: добавить skill `gramax:diagrams-export` в плагин gramax.
Входы: docs/superpowers/specs/2026-05-09-diagrams-export-design.md, plugins/gramax/skills/diagrams/SKILL.md (для стиля), tests/gramax/diagrams_export_test.sh (failing stub от qa-author)
Артефакт: plugins/gramax/skills/diagrams-export/SKILL.md
Критерии: smoke-тест из tests/ зелёный, обновлён plugins/gramax/CHANGELOG.md, AC из spec покрыты.
```

Субагент **не ищет контекст «вокруг»** — работает по явно переданному скопу.

(Полные prompt'ы — в `.claude/plugins/project/agents/<role>-agent.md`.)

## Поток работы (канонический порядок)

Researcher (опц.) → BA → SA (для нетривиальных фич) → QA-author (failing stubs) → Dev (TDD) → QA-runner → BA-acceptance gate → Tech-writer (docs).

PM координирует на каждом этапе: приоритизирует, разрешает блокеры, запускает `/pm-review` перед merge.

## Branch strategy

`main` — единственная trunk-ветка. Feature-ветки опциональны (через worktree из `superpowers:using-git-worktrees`); merge через PR с прошедшим `/pm-review`.

## Self-improvement

- `docs/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промтов агентов.

## Красные линии (универсальные)

- НЕ публиковать секреты (`.env`, токены, API-ключи, credentials).
- НЕ включать PII (реальные имена, контакты, персональные данные).
- НЕ менять корневой `.claude-plugin/marketplace.json` (публичный) без ADR.
- НЕ редактировать `plugins/claude-mermaid/` (vendored submodule на upstream).
- НЕ принимать задачи `/dev` без артефакта SA для нетривиальных фич.
- НЕ передавать тесты из Dev в qa-runner до прохождения qa-author stub'ов (TDD-цепочка).
- Tests/линтеры (если есть) — зелёные перед commit.
````

- [ ] **Step 2: Verify**

```bash
grep -c "^| " AGENTS.md
```

Expected: ≥ 8 (7 ролей + header строки таблиц).

- [ ] **Step 3: Stage**

```bash
git add AGENTS.md
```

---

### Task 1.4: Commit Phase 1

- [ ] **Step 1: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: add CLAUDE.md, AGENTS.md, docs/ skeleton

Бутстрап CTO-workflow из project_template (адаптация под marketplace-репо):
- CLAUDE.md: ядро правил, red lines, when-which-skill
- AGENTS.md: карта 7 ролей + контракт вызова субагента
- docs/superpowers/{specs,plans}, docs/adr/, docs/lessons-learned.md

Спека: docs/superpowers/specs/2026-05-08-apply-project-template-design.md
Plan: docs/superpowers/plans/2026-05-08-apply-project-template.md
EOF
)"
```

- [ ] **Step 2: Verify**

```bash
git log -1 --stat
```

Expected: коммит с CLAUDE.md, AGENTS.md, docs/lessons-learned.md, docs/adr/.gitkeep.

---

## Phase 2 — Local marketplace + plugin manifest + settings

### Task 2.1: Create local marketplace manifest

**Files:**
- Create: `.claude/.claude-plugin/marketplace.json`

- [ ] **Step 1: Create directory**

```bash
mkdir -p .claude/.claude-plugin
```

- [ ] **Step 2: Write `.claude/.claude-plugin/marketplace.json`**

Полный контент:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "gramax-internal",
  "description": "Внутренний CTO-инструментарий gramax-marketplace: PM/BA/SA/Dev/QA/Researcher/Tech-writer. Не для публичного distribution.",
  "owner": {
    "name": "mdemyanov",
    "email": "qutask@gmail.com"
  },
  "plugins": [
    {
      "name": "project",
      "description": "Универсальные агенты (PM/BA/SA/Dev/QA/Researcher/Tech-writer) и slash-команды для разработки плагинов в gramax-marketplace.",
      "source": "./plugins/project",
      "category": "development"
    }
  ]
}
```

**Внимание к `source`:** путь `./plugins/project` относителен директории, в которой лежит `marketplace.json` — то есть `.claude/`. Полный путь к плагину: `.claude/plugins/project/`.

- [ ] **Step 3: Verify JSON**

```bash
python3 -m json.tool .claude/.claude-plugin/marketplace.json > /dev/null && echo "OK"
```

Expected: `OK`.

- [ ] **Step 4: Stage**

```bash
git add .claude/.claude-plugin/marketplace.json
```

---

### Task 2.2: Create plugin manifest

**Files:**
- Create: `.claude/plugins/project/.claude-plugin/plugin.json`

- [ ] **Step 1: Create directories**

```bash
mkdir -p .claude/plugins/project/.claude-plugin .claude/plugins/project/agents .claude/plugins/project/commands
```

- [ ] **Step 2: Write `plugin.json`**

```json
{
  "name": "project",
  "version": "0.1.0",
  "description": "Локальные агенты PM/BA/SA/Dev/QA/Researcher/Tech-writer для разработки плагинов в gramax-marketplace.",
  "author": {
    "name": "mdemyanov",
    "email": "qutask@gmail.com"
  }
}
```

- [ ] **Step 3: Verify**

```bash
python3 -m json.tool .claude/plugins/project/.claude-plugin/plugin.json > /dev/null && echo "OK"
```

Expected: `OK`.

- [ ] **Step 4: Stage**

```bash
git add .claude/plugins/project/.claude-plugin/plugin.json
```

---

### Task 2.3: Create `.claude/settings.json`

**Files:**
- Create: `.claude/settings.json`

- [ ] **Step 1: Write settings**

```json
{
  "extraKnownMarketplaces": {
    "gramax-internal": {
      "source": {
        "source": "directory",
        "path": ".claude"
      }
    }
  },
  "enabledPlugins": {
    "project@gramax-internal": true
  }
}
```

**Заметка:** глобально у пользователя уже подключены `superpowers@claude-plugins-official` и `gramax@ai-assistants` — здесь их не дублируем, чтобы избежать конфликтов merge. Этот settings.json только добавляет приватный CTO-плагин `project`.

- [ ] **Step 2: Verify JSON**

```bash
python3 -m json.tool .claude/settings.json > /dev/null && echo "OK"
```

Expected: `OK`.

- [ ] **Step 3: Stage**

```bash
git add .claude/settings.json
```

---

### Task 2.4: Commit Phase 2

- [ ] **Step 1: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: add private gramax-internal marketplace with project plugin scaffold

- .claude/.claude-plugin/marketplace.json: declares gramax-internal marketplace
- .claude/plugins/project/.claude-plugin/plugin.json: plugin manifest
- .claude/settings.json: enables project@gramax-internal locally

Раздельный приватный marketplace позволяет не загрязнять публичный
gramax-marketplace CTO-инструментами.
EOF
)"
```

---

## Phase 3 — Agent prompts (8 файлов)

**Общая стратегия адаптации** (применяется ко всем 8 файлам):

1. Скопировать исходник из `/Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/<file>`.
2. Применить **search→replace** правила (через Edit tool):
   - `content/30-requirements/` → `docs/superpowers/specs/`
   - `content/40-architecture/` → `docs/adr/`
   - `content/00-project/adr/` → `docs/adr/`
   - `content/00-project/plans/` → `docs/superpowers/plans/`
   - `content/60-implementation/` → `plugins/`
   - `content/70-operations/` → `(удалить упоминание; devops роль исключена)` — если упоминается оперативный артефакт, заменить на «(N/A для marketplace-репо)» или удалить блок
   - Любые упоминания `.doc-root.yaml` / `.gramax/` / Naumen / SMP — переформулировать под marketplace-context (плагин, marketplace.json, plugins/<name>/)
   - `validate-content.py` → `scripts/check.sh --fast`
3. Дополнительно — секция «Контекст» в начале файла (если есть): дописать «Этот агент работает в marketplace-репо `mdemyanov/gramax-plugin`; артефакты — в `docs/`, не в `content/`».

**Если файла-роли нет в нашем списке** (devops/devsecops/compliance) — НЕ копируем.

---

### Task 3.1: Adapt pm-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/pm-agent.md`

- [ ] **Step 1: Copy template file as starting point**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/pm-agent.md \
   .claude/plugins/project/agents/pm-agent.md
```

- [ ] **Step 2: Apply path replacements (через Edit tool, replace_all)**

Применить последовательно:

| old_string | new_string |
|---|---|
| `content/30-requirements/` | `docs/superpowers/specs/` |
| `content/40-architecture/` | `docs/adr/` |
| `content/00-project/adr/` | `docs/adr/` |
| `content/00-project/plans/` | `docs/superpowers/plans/` |
| `content/60-implementation/` | `plugins/` |
| `validate-content.py` | `scripts/check.sh --fast` |

- [ ] **Step 3: Manual context-pass — найти и адаптировать упоминания «Naumen», «SMP», «Gramax-каталог», «.doc-root.yaml», «private/public»**

Прочесть файл, найти такие фрагменты, переформулировать. Конкретно:
- «private/public ветки» → «main + feature-worktrees»
- «merge в public» → «PR в main после `/pm-review`»
- «Gramax-документация» → «marketplace-плагин и его документация (README, CHANGELOG)»
- «.doc-root.yaml» → удалить упоминание, либо заменить на «`.claude-plugin/plugin.json`»
- Упоминания devops/devsecops/compliance в потоке работы — удалить или заменить «(не применимо для marketplace-репо)»

- [ ] **Step 4: Verify нет остаточных `content/`**

```bash
grep -n "content/" .claude/plugins/project/agents/pm-agent.md || echo "clean"
```

Expected: `clean` (или ноль строк).

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/pm-agent.md
```

---

### Task 3.2: Adapt ba-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/ba-agent.md`

- [ ] **Step 1: Copy template**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/ba-agent.md \
   .claude/plugins/project/agents/ba-agent.md
```

- [ ] **Step 2: Apply path replacements (см. таблицу из Task 3.1)**

Применить ту же таблицу замен.

- [ ] **Step 3: Manual context-pass**

BA в шаблоне работает с `content/30-requirements/`. Адаптация для marketplace-плагин:
- Артефакт BA — `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md` (тот же путь, что использует `superpowers:brainstorming`).
- Acceptance criteria формата «при `/<plugin>:<skill> <args>` происходит X».
- Если есть упоминания «properties: name/value», «.doc-root.yaml», «Тип контента: ADR» — переформулировать под frontmatter spec-документа (свой простой YAML: title, status, date).

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/ba-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/ba-agent.md
```

---

### Task 3.3: Adapt sa-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/sa-agent.md`

- [ ] **Step 1: Copy template**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/sa-agent.md \
   .claude/plugins/project/agents/sa-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass для SA-роли**

SA в шаблоне проектирует «архитектуру системы / интеграции». В marketplace-репо его задачи:
- Где skill vs command vs agent (boundaries в плагине).
- Когда нужен submodule vs vendor vs `npm install`.
- Дизайн `.claude-plugin/marketplace.json`-разделов (новый плагин → отдельная запись или как skill в существующем?).
- ADR в `docs/adr/NNNN-<slug>.md`.

Заменить упоминания «hexagonal/layered» если есть — на «plugin boundaries». Упоминания «БД / миграции» — удалить или «(N/A для marketplace-репо)».

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/sa-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/sa-agent.md
```

---

### Task 3.4: Adapt dev-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/dev-agent.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/dev-agent.md \
   .claude/plugins/project/agents/dev-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass для Dev-роли**

Dev пишет код плагина. Контекст:
- Файлы кода — в `plugins/<name>/skills/`, `plugins/<name>/scripts/`, `plugins/<name>/agents/`.
- Тесты (если есть) — в `tests/` или `plugins/<name>/tests/`.
- TDD обязателен для shell/JS; для markdown-skills — self-test через вызов команды + проверка output.
- Если есть упоминание «Python/Java/любого специфичного стека» — заменить на «shell + JS + markdown».
- Если есть «migrations/БД» — удалить.

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/dev-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/dev-agent.md
```

---

### Task 3.5: Adapt qa-author-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/qa-author-agent.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/qa-author-agent.md \
   .claude/plugins/project/agents/qa-author-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass**

QA-author пишет failing-stub'ы тестов до Dev. В marketplace-репо:
- Тесты для плагин-команд — bash (`bats` если хочется, иначе обычный shell с `set -e` + assertions).
- Тесты для skill — smoke (вызов через Claude Code и проверка text output).
- Файлы — `tests/<plugin>/<feature>_test.sh` или `plugins/<name>/tests/`.

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/qa-author-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/qa-author-agent.md
```

---

### Task 3.6: Adapt qa-runner-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/qa-runner-agent.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/qa-runner-agent.md \
   .claude/plugins/project/agents/qa-runner-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass**

QA-runner запускает тесты, написанные QA-author + Dev. Адаптация:
- Команды запуска — `bash tests/<plugin>/run.sh` или индивидуальные `bash tests/<plugin>/<feature>_test.sh`.
- Если есть упоминания pytest/jest — заменить на `bash` или «(в зависимости от плагина — текущие плагины используют shell)».

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/qa-runner-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/qa-runner-agent.md
```

---

### Task 3.7: Adapt researcher-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/researcher-agent.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/researcher-agent.md \
   .claude/plugins/project/agents/researcher-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass**

Researcher для marketplace-плагина — собирает контекст по:
- Claude Code docs (через `WebFetch`, `WebSearch`).
- Plugin API conventions (через `mcp__plugin_context7_context7__*` если задействован).
- Best practices маркетплейс-плагинов от Anthropic (anthropics/claude-plugins).
- Reference plugins (`gramax@ai-assistants`, `superpowers@claude-plugins-official`).

Артефакт исследования — `docs/research/<topic>.md` (создать каталог при необходимости) или короткая выжимка прямо в spec.

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/researcher-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/researcher-agent.md
```

---

### Task 3.8: Adapt tech-writer-agent.md

**Files:**
- Create: `.claude/plugins/project/agents/tech-writer-agent.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/agents/tech-writer-agent.md \
   .claude/plugins/project/agents/tech-writer-agent.md
```

- [ ] **Step 2: Apply path replacements (см. Task 3.1)**

- [ ] **Step 3: Manual context-pass**

Tech-writer для marketplace-репо — пишет/правит:
- Корневой `README.md` (общее описание marketplace).
- Корневой `CHANGELOG.md` (марbergining версии).
- `plugins/<name>/README.md` и `plugins/<name>/CHANGELOG.md`.
- `description` поля в `marketplace.json` и `plugin.json` (короткие, точные).
- Тон — нейтральный, технический; русский — по уже сложившемуся в репо стилю.

Заменить упоминания «Gramax-статьи / properties / `.doc-root.yaml`» — на «marketplace README / CHANGELOG / plugin.json descriptions».

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/agents/tech-writer-agent.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/agents/tech-writer-agent.md
```

---

### Task 3.9: Verify Phase 3 + commit

- [ ] **Step 1: Verify all 8 agent files exist and are clean**

```bash
ls .claude/plugins/project/agents/
grep -l "content/" .claude/plugins/project/agents/*.md || echo "all clean"
```

Expected: 8 файлов (`ba-agent.md`, `dev-agent.md`, `pm-agent.md`, `qa-author-agent.md`, `qa-runner-agent.md`, `researcher-agent.md`, `sa-agent.md`, `tech-writer-agent.md`), и `all clean`.

- [ ] **Step 2: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(.claude/plugins/project): add 8 role agents adapted for marketplace context

Перенесли pm/ba/sa/dev/qa-author/qa-runner/researcher/tech-writer из
project_template, заменили content/-пути на docs/superpowers/specs|plans/
и docs/adr/, переформулировали Naumen/Gramax-каталог-контекст под
marketplace-плагин-разработку.

Devops/devsecops/compliance исключены (вне скоупа marketplace-репо).
EOF
)"
```

---

## Phase 4 — Slash commands (8 файлов)

**Общая стратегия:** идентична Phase 3 — copy + path replacements + context-pass.

Команды короче агентов (30-80 строк), их адаптация быстрее.

---

### Task 4.1: Adapt commands/pm.md

**Files:**
- Create: `.claude/plugins/project/commands/pm.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/pm.md \
   .claude/plugins/project/commands/pm.md
```

- [ ] **Step 2: Apply path replacements (та же таблица, что в Task 3.1)**

- [ ] **Step 3: Manual context-pass**

`/pm` orchestrate decompose. Для marketplace-репо:
- Декомпозиция эпика = разбиение крупной фичи плагина на под-задачи (новые skills, обновления command, тесты, docs).
- `/pm decompose <feature>` создаёт spec + план.
- Удалить упоминания pipelines/`/pipelines/...` (мы их не переносим).
- `private/public` → `feature-worktree → main через PR`.

- [ ] **Step 4: Verify**

```bash
grep -n "content/\|/pipelines/" .claude/plugins/project/commands/pm.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/commands/pm.md
```

---

### Task 4.2: Adapt commands/ba.md

**Files:**
- Create: `.claude/plugins/project/commands/ba.md`

- [ ] **Step 1: Copy**

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/ba.md \
   .claude/plugins/project/commands/ba.md
```

- [ ] **Step 2: Apply path replacements**

- [ ] **Step 3: Manual context-pass**

`/ba new-feature <slug>` создаёт spec в `docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md`. `/ba --mode=acceptance` валидирует AC по реализованной фиче плагина.

- [ ] **Step 4: Verify**

```bash
grep -n "content/" .claude/plugins/project/commands/ba.md || echo "clean"
```

- [ ] **Step 5: Stage**

```bash
git add .claude/plugins/project/commands/ba.md
```

---

### Task 4.3: Adapt commands/sa.md

**Files:**
- Create: `.claude/plugins/project/commands/sa.md`

- [ ] **Step 1-5:** идентичны Task 4.1/4.2 (cp → replace → context-pass → verify → stage). Контекст SA: ADR в `docs/adr/NNNN-<slug>.md`.

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/sa.md \
   .claude/plugins/project/commands/sa.md
# применить замены, context-pass
grep -n "content/" .claude/plugins/project/commands/sa.md || echo "clean"
git add .claude/plugins/project/commands/sa.md
```

---

### Task 4.4: Adapt commands/dev.md

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/dev.md \
   .claude/plugins/project/commands/dev.md
# применить замены: content/60-implementation/ → plugins/
# context-pass: TDD для shell/JS; markdown-skills — self-test
grep -n "content/" .claude/plugins/project/commands/dev.md || echo "clean"
git add .claude/plugins/project/commands/dev.md
```

- [ ] **Шаги 1-5** аналогичны Task 4.1.

---

### Task 4.5: Adapt commands/qa.md

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/qa.md \
   .claude/plugins/project/commands/qa.md
# применить замены, context-pass: тесты — shell, в tests/ или plugins/<name>/tests/
grep -n "content/" .claude/plugins/project/commands/qa.md || echo "clean"
git add .claude/plugins/project/commands/qa.md
```

- [ ] **Шаги 1-5** аналогичны Task 4.1.

---

### Task 4.6: Adapt commands/research.md

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/research.md \
   .claude/plugins/project/commands/research.md
# context-pass: research targets — Claude Code docs, plugin patterns, MCP, marketplace conventions
grep -n "content/" .claude/plugins/project/commands/research.md || echo "clean"
git add .claude/plugins/project/commands/research.md
```

- [ ] **Шаги 1-5** аналогичны Task 4.1.

---

### Task 4.7: Adapt commands/tech-writer.md

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/tech-writer.md \
   .claude/plugins/project/commands/tech-writer.md
# context-pass: README, CHANGELOG, marketplace.json descriptions, plugins/<name>/README.md
grep -n "content/" .claude/plugins/project/commands/tech-writer.md || echo "clean"
git add .claude/plugins/project/commands/tech-writer.md
```

- [ ] **Шаги 1-5** аналогичны Task 4.1.

---

### Task 4.8: Adapt commands/pm-review.md

```bash
cp /Users/mdemyanov/knowlage/project_template/.claude/plugins/project/commands/pm-review.md \
   .claude/plugins/project/commands/pm-review.md
# context-pass:
# - удалить вызов validate-content.py;
# - заменить на bash scripts/check.sh --fast;
# - убрать «merge private→public» — заменить на «PR в main»;
# - убрать упоминания content/-валидации.
grep -n "content/\|validate-content" .claude/plugins/project/commands/pm-review.md || echo "clean"
git add .claude/plugins/project/commands/pm-review.md
```

- [ ] **Шаги 1-5** аналогичны Task 4.1.

---

### Task 4.9: Verify Phase 4 + commit

- [ ] **Step 1: Verify все 8 commands**

```bash
ls .claude/plugins/project/commands/
grep -l "content/\|validate-content\|/pipelines/" .claude/plugins/project/commands/*.md || echo "all clean"
```

Expected: 8 файлов, и `all clean`.

- [ ] **Step 2: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(.claude/plugins/project): add 8 slash commands adapted for marketplace

/pm, /ba, /sa, /dev, /qa, /research, /tech-writer, /pm-review.
Удалены /init, /devops, /devsecops, /compliance, /pipelines/*
(вне скоупа marketplace-репо).

Контекст переформулирован: артефакты — в docs/superpowers/{specs,plans}/
и docs/adr/, не в content/. validate-content заменён на check.sh --fast.
EOF
)"
```

---

## Phase 5 — Lightweight check.sh + pre-commit hook

### Task 5.1: Create scripts/check.sh

**Files:**
- Create: `scripts/check.sh`

- [ ] **Step 1: Create directory**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Write `scripts/check.sh`**

Полный контент:

```bash
#!/usr/bin/env bash
# scripts/check.sh — light pre-commit/pre-merge gate для gramax-marketplace.
# Без content/-валидаторов (нет content/), без profile-валидаторов (нет профилей).
#
# Modes:
#   --fast   : whitespace + JSON validity (для pre-commit hook)
#   --full   : --fast + shellcheck (если установлен) + проверка submodule status
#
# Exit codes:
#   0 — all checks passed
#   1 — at least one check failed

set -euo pipefail

MODE="${1:---fast}"
FAILED=0

echo "==> mode: $MODE"

# --- 1. Whitespace check on staged/all files ---
echo "==> whitespace"
if git diff --check HEAD -- 2>&1 | grep -q .; then
  git diff --check HEAD --
  echo "FAIL: trailing whitespace or mixed indent detected"
  FAILED=1
else
  echo "OK: no whitespace issues"
fi

# --- 2. JSON validity for tracked .json files ---
echo "==> json"
JSON_FILES=$(git ls-files '*.json' 2>/dev/null || true)
if [ -n "$JSON_FILES" ]; then
  for f in $JSON_FILES; do
    # Skip submodule contents (claude-mermaid)
    if [[ "$f" == plugins/claude-mermaid/* ]]; then continue; fi
    if ! python3 -m json.tool "$f" > /dev/null 2>&1; then
      echo "FAIL: invalid JSON: $f"
      FAILED=1
    fi
  done
  echo "OK: JSON validated"
else
  echo "OK: no JSON files tracked"
fi

# --- 3. (--full only) Shellcheck on tracked .sh files, if installed ---
if [ "$MODE" = "--full" ]; then
  echo "==> shellcheck"
  if command -v shellcheck > /dev/null 2>&1; then
    SH_FILES=$(git ls-files '*.sh' 2>/dev/null | grep -v '^plugins/claude-mermaid/' || true)
    if [ -n "$SH_FILES" ]; then
      # shellcheck disable=SC2086
      if ! shellcheck $SH_FILES; then
        echo "FAIL: shellcheck issues"
        FAILED=1
      else
        echo "OK: shellcheck clean"
      fi
    else
      echo "OK: no shell files tracked"
    fi
  else
    echo "WARN: shellcheck not installed — skipping"
  fi

  # --- 4. (--full only) Submodule status ---
  echo "==> submodule status"
  if git submodule status 2>&1 | grep -q '^[+-]'; then
    echo "WARN: submodule out of sync (not a hard fail)"
    git submodule status
  else
    echo "OK: submodules in sync"
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "==> RESULT: FAIL"
  exit 1
fi

echo "==> RESULT: PASS"
```

- [ ] **Step 3: Make executable**

```bash
chmod +x scripts/check.sh
```

- [ ] **Step 4: Run on current state**

```bash
bash scripts/check.sh --fast
```

Expected: `==> RESULT: PASS`.

- [ ] **Step 5: Stage**

```bash
git add scripts/check.sh
```

---

### Task 5.2: Create scripts/install-hooks.sh

**Files:**
- Create: `scripts/install-hooks.sh`

- [ ] **Step 1: Write script**

```bash
#!/usr/bin/env bash
# scripts/install-hooks.sh — активирует .githooks/ как hook directory для git.
# Идемпотентен: повторный запуск не ломает.
# Disable: git config --unset core.hooksPath
# Bypass на коммит: git commit --no-verify

set -euo pipefail

if [ ! -d .githooks ]; then
  echo "FAIL: .githooks/ directory not found"
  exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

echo "OK: git hooks activated from .githooks/"
echo "  to disable: git config --unset core.hooksPath"
echo "  to bypass once: git commit --no-verify"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/install-hooks.sh
```

- [ ] **Step 3: Stage**

```bash
git add scripts/install-hooks.sh
```

---

### Task 5.3: Create .githooks/pre-commit

**Files:**
- Create: `.githooks/pre-commit`

- [ ] **Step 1: Create directory**

```bash
mkdir -p .githooks
```

- [ ] **Step 2: Write hook**

```bash
#!/usr/bin/env bash
# .githooks/pre-commit — вызывает scripts/check.sh --fast.
# Активируется через bash scripts/install-hooks.sh.
# Bypass: git commit --no-verify.

set -euo pipefail

if [ -x scripts/check.sh ]; then
  bash scripts/check.sh --fast
else
  echo "WARN: scripts/check.sh не найден или не исполняем — пропускаю pre-commit gate"
fi
```

- [ ] **Step 3: Make executable**

```bash
chmod +x .githooks/pre-commit
```

- [ ] **Step 4: Stage**

```bash
git add .githooks/pre-commit
```

---

### Task 5.4: Commit Phase 5

- [ ] **Step 1: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: add lightweight check.sh + optional pre-commit hook

- scripts/check.sh: whitespace + JSON validity (fast); +shellcheck +submodule status (full)
- scripts/install-hooks.sh: idempotent activation of .githooks/
- .githooks/pre-commit: calls check.sh --fast

Без content/-валидаторов (нет content/) и profile-валидаторов
(нет профилей) — light версия, специфичная для marketplace-репо.

Активация: bash scripts/install-hooks.sh
Bypass: git commit --no-verify
EOF
)"
```

---

## Phase 6 — Smoke verification

### Task 6.1: Manual smoke verification

Эта задача — список проверок без автоматизации. Прогнать вручную после Phase 5.

- [ ] **Step 1: Все файлы на месте**

```bash
test -f CLAUDE.md && \
test -f AGENTS.md && \
test -f .claude/settings.json && \
test -f .claude/.claude-plugin/marketplace.json && \
test -f .claude/plugins/project/.claude-plugin/plugin.json && \
test -d docs/superpowers/specs && \
test -d docs/superpowers/plans && \
test -d docs/adr && \
test -f docs/lessons-learned.md && \
test -x scripts/check.sh && \
test -x scripts/install-hooks.sh && \
test -x .githooks/pre-commit && \
ls .claude/plugins/project/agents/*.md | wc -l | grep -q '8' && \
ls .claude/plugins/project/commands/*.md | wc -l | grep -q '8' && \
echo "ALL FILES PRESENT"
```

Expected: `ALL FILES PRESENT`.

- [ ] **Step 2: JSON-валидность всех manifest'ов**

```bash
for f in .claude/settings.json .claude/.claude-plugin/marketplace.json .claude/plugins/project/.claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```

Expected: 4 строки `OK:`.

- [ ] **Step 3: Все агент- и команд-файлы свободны от content/-зависимостей**

```bash
grep -rn "content/" .claude/plugins/project/ || echo "clean"
```

Expected: `clean`.

- [ ] **Step 4: check.sh --fast зелёный**

```bash
bash scripts/check.sh --fast
```

Expected: `==> RESULT: PASS`.

- [ ] **Step 5: Установить и проверить pre-commit hook (опционально)**

```bash
bash scripts/install-hooks.sh
git config core.hooksPath  # должно вывести .githooks
```

- [ ] **Step 6: В Claude Code проверить, что плагин подгружен**

Открыть проект в Claude Code, набрать `/` — в списке должны появиться `/pm`, `/ba`, `/sa`, `/dev`, `/qa`, `/research`, `/tech-writer`, `/pm-review`. Если нет — запустить `/plugin marketplace add .` или `/plugin install project@gramax-internal`.

- [ ] **Step 7: Smoke test через `/pm`**

В Claude Code: `/pm decompose добавить smoke-test для plugin gramax`

PM должен вернуть план с чёткими ролями (BA → SA-skip → Dev → QA), пути к артефактам в `docs/superpowers/`, без упоминаний `content/`.

---

## Self-Review (выполнено автором плана)

**1. Spec coverage:**

| Spec section | Tasks |
|---|---|
| Целевая структура: CLAUDE.md, AGENTS.md | 1.2, 1.3 |
| Целевая структура: docs/{superpowers,adr}, lessons-learned | 1.1 |
| Целевая структура: .claude/settings.json, .claude/.claude-plugin/marketplace.json, .claude/plugins/project/ | 2.1, 2.2, 2.3 |
| 8 агентов | 3.1-3.8 |
| 8 команд | 4.1-4.8 |
| scripts/check.sh + .githooks/ | 5.1, 5.2, 5.3 |
| Branch strategy main + worktrees | в CLAUDE.md и AGENTS.md (Task 1.2, 1.3) |
| Red lines | в CLAUDE.md и AGENTS.md (Task 1.2, 1.3) |
| Smoke verification | 6.1 |

Покрытие полное.

**2. Placeholder scan:** нет TBD/TODO в шагах — везде указано конкретное действие или конкретное содержимое файла. Sed-таблица замен полная.

**3. Type/path consistency:**
- `docs/superpowers/specs/` — везде одинаково.
- `docs/adr/` — везде одинаково.
- `gramax-internal` (имя приватного marketplace) — везде одинаково.
- `project@gramax-internal` — везде одинаково.

OK, план готов.

---

## Execution Handoff

Plan complete. Two options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, two-stage review между задачами.
2. **Inline Execution** — выполняю в этой же сессии через `executing-plans`, с чекпоинтами.

Какой подход?
