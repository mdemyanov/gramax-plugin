---
description: "Финальная валидация перед PR в main. Smoke-проверки, JSON-манифесты, submodule-статус, lessons-learned. Пример: /pm-review"
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git submodule status:*), Bash(jq:*), Bash(bash scripts/check.sh:*)
---

Ты — руководитель проекта в роли ревьюера. Проверь готовность ветки к PR в `main`.

## Что проверить

### 1. Состояние рабочего дерева

- `git status` — должен быть чистый (нет неотслеживаемых артефактов вне `.gitignore`).
- `git diff --check` — нет смешанных пробелов/табов и trailing whitespace в diff'е.
- `git log --oneline main..HEAD` — какие коммиты пойдут в PR.
- `git diff --name-only main..HEAD` — какие файлы изменены.

### 2. Smoke и линтеры

Запусти быстрый прогон проверок:

```bash
bash scripts/check.sh --fast
```

Любой error — блокер PR. Warnings обозначь в отчёте.

Если `scripts/check.sh` ещё не существует — пометь как warning (предложи завести в следующей итерации) и проверь руками: bash-тесты в `tests/`, JSON-манифесты, frontmatter skills.

### 3. Целостность манифестов

Проверь JSON-валидность ключевых манифестов:

```bash
jq . .claude-plugin/marketplace.json > /dev/null
for f in plugins/*/.claude-plugin/plugin.json; do jq . "$f" > /dev/null || echo "BROKEN: $f"; done
```

Дополнительно:
- В каждом изменённом `plugin.json` поле `version` обновлено по semver, если меняли `plugins/<name>/`.
- В корневом `marketplace.json` запись о плагине синхронна с `plugin.json` (имя, версия, описание).
- Frontmatter skills/commands/agents валиден (есть `description`, `name` для агентов).

### 4. Submodule status

```bash
git submodule status
```

- Не должно быть неучтённых изменений в submodule'ах (символ `+` перед хэшем).
- Если в репо есть vendored submodule'ы — изменения внутри не принимаются (только bump SHA через PR в upstream).

### 5. CHANGELOG обновлён

Если `git diff --name-only main..HEAD` затрагивает `plugins/<name>/` — должна быть запись:
- В `plugins/<name>/CHANGELOG.md` (если ведётся отдельно) или
- В корневом `CHANGELOG.md` под секцией соответствующего плагина

Формат — Keep a Changelog (`## [version] - YYYY-MM-DD` + `Added/Changed/Fixed/Removed`).

### 6. Spec и ADR

- Для нетривиальных фич есть spec в `docs/superpowers/specs/` с заполненным acceptance log от `/ba --mode=acceptance`.
- Если затронут публичный manifest или добавлен submodule — должен быть ADR в `docs/adr/NNNN-<slug>.md` со статусом `accepted`.

### 7. Lessons-learned

Прочитай `docs/lessons-learned.md` (свежие записи) и memory (через auto-memory). Предложи: какие фрагменты добавить в CLAUDE.md, в промты агентов (`.claude/plugins/project/agents/*-agent.md`) или в эту команду?

### 8. Активные worktree'и

```bash
git worktree list
```

- Есть ли заброшенные feat-worktree'и (>7 дней без коммитов) → предложи `commit-commands:clean_gone`.
- Текущий worktree — это feat-ветка, готовая к merge через PR в `main`.

## Формат ответа

```markdown
## PM-Review

### Готовность к PR в main: OK / WARN / BLOCK

### Diff
- N файлов изменены, M добавлены, K удалены
- Затронутые плагины: [список]

### Проверки
- scripts/check.sh --fast: [результат]
- JSON-манифесты: [результат]
- git submodule status: [результат]
- CHANGELOG обновлён: [да/нет/не требуется]
- spec acceptance log: [есть/нет/не требуется]
- ADR: [есть/нет/не требуется]

### Проблемы (если есть)
- [файл] — [что не так] — [как починить]

### Lessons synthesis (предложения)
- В CLAUDE.md: [что добавить]
- В <agent>.md: [что добавить]
- В команды: [что обновить]

### Решение
[Готов к PR / Доработать / Отложить]
```
