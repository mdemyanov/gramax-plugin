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

Публичный Claude Code marketplace (`mdemyanov/gramax-plugin`), один плагин:

- **`plugins/gramax/`** — writer, comments-read, comments-write, mermaid, drawio, review-agent. Версионируется отдельно (см. `plugins/gramax/CHANGELOG.md`). Drawio — заглушка-делегатор к внешнему плагину `Agents365-ai/drawio-skill`.

Marketplace объявлен в корневом `.claude-plugin/marketplace.json` под именем `gramax-marketplace` (для публичного distribution).

## Стек

- Markdown skills и agent prompts (большая часть плагина).
- Bash скрипты (плагинная инфраструктура, smoke-тесты).
- JSON (manifests, settings).

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
- НЕ принимать `/dev`-задачи без артефакта SA (для нетривиальных фич — обязателен ADR).
- НЕ ломать обратную совместимость skill-имён в `plugins/gramax/skills/` без bump major-версии в `plugins/gramax/CHANGELOG.md` + анонс в основном CHANGELOG.
- Tests/линтеры (если в проекте есть) — зелёные перед commit.
- НЕ коммитить с `--no-verify` без явного разрешения.

## Self-improvement

- `docs/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промптов агентов.
