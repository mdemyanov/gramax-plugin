# Применение подхода к разработке из project_template к gramax

**Дата:** 2026-05-08
**Автор:** brainstorming-сессия (PM-роль через Claude Code)
**Статус:** approved by user → в работу

## Цель

Перенести в репо `gramax` (Claude Code marketplace) рабочий конвейер `brainstorm → spec → plan → TDD → review` из шаблона `/Users/mdemyanov/knowlage/project_template`, адаптировав его под контекст marketplace-плагин-разработки и оставив за бортом тяжёлые части шаблона, не применимые к код-репозиторию.

## Контекст

- `/Users/mdemyanov/Devel/gramax` — публичный Claude Code marketplace с двумя плагинами: `gramax` (наш) и `claude-mermaid` (vendored MIT submodule).
- В репо нет `CLAUDE.md` / `AGENTS.md`, нет каталога `docs/`, нет конвейера ролей.
- Шаблон `project_template` ориентирован на внутренние Naumen-проекты с `content/`-документацией и 7 профилями. Прямой `/init` не подходит: уничтожает `.git`, привязан к мульти-профильной инфре.

## Решение

Применяем **Product-профиль шаблона** (pm + ba + sa + dev + qa + researcher + tech-writer = 7 ролей), без `content/`, без профильной/overlay-инфры, без devops/devsecops/compliance.

### Целевая структура

```
gramax/
├── CLAUDE.md                              ← НОВОЕ: ядро правил
├── AGENTS.md                              ← НОВОЕ: карта 7 ролей + контракт вызова
├── README.md                              ← без изменений (marketplace docs)
├── CHANGELOG.md                           ← без изменений
├── .claude-plugin/marketplace.json        ← без изменений
├── .claude/
│   ├── settings.json                      ← НОВОЕ: подключить локальный плагин
│   └── plugins/project/                   ← НОВОЕ: локальный плагин ролей
│       ├── .claude-plugin/plugin.json
│       ├── agents/   (pm, ba, sa, dev, qa-author, qa-runner, researcher, tech-writer)
│       └── commands/ (/pm, /ba, /sa, /dev, /qa, /research, /tech-writer, /pm-review)
├── docs/
│   ├── superpowers/specs/                 ← brainstorming → дизайн-доки
│   ├── superpowers/plans/                 ← writing-plans → планы реализации
│   ├── adr/                               ← Architecture Decision Records
│   └── lessons-learned.md                 ← append-only журнал
├── plugins/                               ← без изменений (gramax + claude-mermaid)
├── .githooks/pre-commit                   ← НОВОЕ: light pre-commit gate
└── scripts/check.sh                       ← НОВОЕ: light gate без content-валидаторов
```

### Что НЕ переносим (явно)

| Не переносим | Почему |
|---|---|
| `content/` + `validate-content.py` | Это для документ. проектов; gramax — код-репо, плагины уже лежат в `plugins/`. |
| Профили (`docs/overlays/profiles/`, `apply-overlay.sh`, `validate-profile.py`) | Выбран один режим (product); мульти-профильная инфра — оверкилл. |
| `init.sh` + slash-команда `/init` | Репо уже инициализировано; вайпать историю нельзя. |
| Агенты devops / devsecops / compliance | Marketplace-плагин не деплоится, compliance вне скоупа. |
| Pipelines (`project-planning`, `ba-acceptance`, `critical-path`) | Stub'ы из шаблона; для одного maintainer'а сейчас оверкилл. Можно вернуться позже. |
| Skills `correspondence-2`, `infoinstyle` | CTO-скиллы для русских текстов; могут быть полезны, но opt-in позже. |

### Адаптация ролей под marketplace-плагин-контекст

Промпт-файлы в `.claude/plugins/project/agents/` берём из шаблона **с правкой контекста**: пути `content/30-requirements/` → `docs/superpowers/specs/`, `content/40-architecture/` → `docs/adr/`, упоминания «Naumen-документация в Gramax» → «Claude Code marketplace plugin development».

| Роль | Адаптация |
|---|---|
| **pm** | Оркестратор brainstorm→spec→plan→dev→qa→review. Артефакты в `docs/superpowers/specs|plans/`. |
| **ba** | Spec на новые skills/agents/commands в плагинах. AC формата «команда `/foo` делает X в Y». |
| **sa** | Архитектура: where skill vs command vs agent, boundaries между плагинами. ADR в `docs/adr/`. |
| **dev** | TDD для shell-скриптов и JS-обвязки плагинов. Markdown-skills — без TDD, но с self-test (вызов команды). |
| **qa-author/runner** | Smoke-тест активации плагина, вызов команд, проверка outputs. Минимум. |
| **researcher** | Claude Code docs, plugin patterns, MCP, marketplace conventions (через `mcp__plugin_context7_context7__*` + WebFetch). |
| **tech-writer** | README, CHANGELOG, `marketplace.json` descriptions, `plugins/*/README.md`. |

### Branch strategy

Шаблон предлагает `private`/`public`. У gramax уже `main`. **Не трогаем** — оставляем `main` как trunk, в AGENTS.md документируем «merge через PR в main после `/pm-review`».

### CLAUDE.md (ядро правил) — содержание

- Краткое описание проекта (marketplace, 2 плагина, vendored claude-mermaid).
- Правило: для нетривиальной задачи начинать с `superpowers:brainstorming` → `writing-plans` → TDD.
- Red lines:
  - НЕ публиковать секреты (`.env`, токены, API-ключи).
  - НЕ менять `.claude-plugin/marketplace.json` без ADR.
  - НЕ редактировать `plugins/claude-mermaid/` (vendored submodule на upstream).
  - НЕ принимать `/dev`-задачи без артефакта SA (для нетривиальных фич).
  - Tests/линтеры зелёные перед commit.
- Тон коммитов: текущий стиль (`feat:`, `docs:`, `feat(gramax):`).

### Lightweight check.sh

Без `validate-content.py` / `validate-profile.py`. Минимум:
- `git diff --check` (whitespace).
- Если в staged есть `.json` — `python3 -m json.tool` или `jq` валидация.
- Если в staged есть `.sh` — `shellcheck` (если установлен; иначе skip с warning).

`pre-commit` hook вызывает `bash scripts/check.sh --fast`.

## Phasing

| Phase | Что |
|---|---|
| 1 | Skeleton: `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, директории `docs/superpowers/{specs,plans}`, `docs/adr/`, `docs/lessons-learned.md`. |
| 2 | Agents: 8 промпт-файлов в `.claude/plugins/project/agents/` (копируем + адаптируем). |
| 3 | Commands: 8 slash-команд в `.claude/plugins/project/commands/` (копируем + адаптируем). |
| 4 | `scripts/check.sh` + `.githooks/pre-commit` + `scripts/install-hooks.sh`. |
| 5 | Smoke-проверка: убедиться что `/pm decompose <фейковая фича>` отрабатывает в Claude Code. |

## Open Questions / Risks

- **`.claude/settings.json` merge:** если у пользователя есть глобальные `~/.claude/settings.json` с конфликтующим `enabledPlugins` — адресуем при апдейте, сделаем minimal local config.
- **Submodule `claude-mermaid`:** не трогаем; в CLAUDE.md прописана red line.
- **TDD для markdown-skills:** TDD не очень применим; ограничимся «self-test через вызов команды» (Phase 5).

## Acceptance Criteria

1. В репо есть `CLAUDE.md`, `AGENTS.md`, структура `docs/superpowers/{specs,plans}/`, `docs/adr/`, `docs/lessons-learned.md`.
2. В `.claude/plugins/project/` лежат 8 агентов и 8 slash-команд, адаптированные под marketplace-контекст (нет упоминаний `content/`, есть упоминания `plugins/`, `marketplace.json`).
3. `bash scripts/check.sh --fast` отрабатывает без ошибок на чистом репе.
4. После `git commit` срабатывает pre-commit hook (если установлен через `install-hooks.sh`).
5. В Claude Code доступны команды `/pm`, `/ba`, `/sa`, `/dev`, `/qa`, `/research`, `/tech-writer`, `/pm-review`.
