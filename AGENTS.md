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
