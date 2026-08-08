# AGENTS.md — gramax-marketplace

Матрица ролей, контракт вызова субагентов и поток работы для AI-команды проекта.

## Каталог ролей

| Имя | Описание | Где исполняется | Модель | Промпт-файл | Slash-команда |
|-----|----------|-----------------|--------|-------------|---------------|
| pm | Координатор/orchestrator | main | Opus | (main, не subagent) | `/nauta:pm` |
| researcher | Контекст-сборщик | subagent | Sonnet | `nauta:researcher-agent` | `/nauta:research` |
| ba | Бизнес-аналитик | subagent | Sonnet | `nauta:ba-agent` | `/nauta:ba` |
| sa | Архитектор плагина | subagent | Sonnet | `nauta:sa-agent` | `/nauta:sa` |
| dev | TDD-разработчик | subagent | Sonnet | `nauta:dev-agent` | `/nauta:dev` |
| qa | QA author + runner | subagent | Sonnet | `nauta:qa-author-agent`, `nauta:qa-runner-agent` | `/nauta:qa` |
| tech-writer | README, CHANGELOG, descriptions | subagent | Sonnet | `nauta:tech-writer-agent` | `/nauta:tech-writer` |
| devsecops | Secrets/SAST/supply-chain (opt-in) | subagent | Sonnet | `nauta:devsecops-agent` | `/nauta:devsecops` |

**Выключены:** `devops` — плагин не деплоится; `compliance` — compliance-скоупа у публичного
marketplace нет. Включаются явным запросом, если появится основание.

**Почему nauta, а не свои промпты:** локальный плагин `project` дублировал те же роли в более
старых редакциях и при этом не загружался. Источник ролей теперь один.

## Контракт вызова субагента

При запуске любой роли (через `/<command>` или Task tool) передавай:

1. **Цель** одной фразой.
2. **Входные файлы** — пути к контексту (spec, ADR, код плагина, плагин-документация). Субагент сам прочитает.
3. **Ожидаемый артефакт** — какой файл должен появиться/измениться.
4. **Критерии приёмки** — как проверить, что задача выполнена.

**Конвенции передавай в промпте, а не надейся, что агент их прочитает.** Из десяти агентов
nauta только три вообще упоминают `CLAUDE.md`, и то точечно (секции «Стек», «Команды сборки»);
`AGENTS.md` не читает ни один. Целевой путь артефакта, таксономию `content/` и красные линии
включай в текст задачи явно.

Пример корректного prompt'а для `/nauta:dev`:

```
Цель: добавить skill `gramax:diagrams-export` в плагин gramax.
Входы: content/30-requirements/2026-05-09-diagrams-export-design.md,
       plugins/gramax/skills/mermaid/SKILL.md (для стиля),
       tests/gramax/diagrams-export/ac-001-skill-exists.sh (failing stub от qa-author)
Артефакт: plugins/gramax/skills/diagrams-export/SKILL.md
Критерии: suite из tests/gramax/diagrams-export/ зелёный, обновлён plugins/gramax/CHANGELOG.md,
          AC из требования покрыты, bash scripts/check.sh --fast зелёный.
```

Субагент **не ищет контекст «вокруг»** — работает по явно переданному скопу.

(Полные prompt'ы — агенты плагина `nauta`, см. столбец «Промпт-файл» в каталоге ролей выше.)

## Поток работы (канонический порядок)

Researcher (опц.) → BA → SA (для нетривиальных фич) → QA-author (failing stubs) → Dev (TDD) → QA-runner → BA-acceptance gate → Tech-writer (docs).

PM координирует на каждом этапе: приоритизирует, разрешает блокеры, запускает `/nauta:pm-review` перед merge.

## Branch strategy

`main` — единственная trunk-ветка. Feature-ветки опциональны (через worktree из `superpowers:using-git-worktrees`); merge через PR с прошедшим `/nauta:pm-review`.

## Self-improvement

- `content/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/nauta:pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промтов агентов.

## Красные линии (универсальные)

- НЕ публиковать секреты (`.env`, токены, API-ключи, credentials).
- НЕ включать PII (реальные имена, контакты, персональные данные).
- НЕ менять корневой `.claude-plugin/marketplace.json` (публичный) без ADR.
- НЕ добавлять vendored submodule без ADR (vendored-плагины удаляются через ADR, см. content/00-project/adr/).
- НЕ принимать задачи `/nauta:dev` без артефакта SA для нетривиальных фич.
- НЕ передавать тесты из Dev в qa-runner до прохождения qa-author stub'ов (TDD-цепочка).
- Tests/линтеры (если есть) — зелёные перед commit.
