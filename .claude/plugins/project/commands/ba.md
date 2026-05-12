---
description: "Бизнес-аналитик (subagent, Sonnet). Spec на skill/command/agent плагина и проверка AC. Пример: /ba new-feature plugin-status, /ba --mode=acceptance plugin-status"
allowed-tools: Task
---

Запусти subagent `project:ba-agent` через Task tool (`subagent_type: "project:ba-agent"`).

**Входы пользователя:** `$ARGUMENTS`

## Что передать subagent'у

Сформируй prompt по контракту из AGENTS.md («Вызов субагентов — контракт»):

1. **Цель** одной фразой (что специфицировать или валидировать).
2. **Входные файлы** — конкретные пути:
   - Существующие spec'и: `docs/superpowers/specs/`
   - ADR: `docs/adr/`
   - Реализация плагина: `plugins/<name>/skills/`, `plugins/<name>/agents/`, `plugins/<name>/commands/`
   - Тесты: `tests/<plugin>/`
3. **Ожидаемый артефакт** — путь `docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md`.
4. **Критерии приёмки**:
   - JTBD сформулирован (кто пользователь плагина, какую задачу решает в Claude Code)
   - Перечислены затронутые единицы плагина (skill / command / agent / script)
   - FR с триггерами (когда вызывается skill, что попадает в `$ARGUMENTS`)
   - NFR (производительность, идемпотентность, совместимость с Claude Code-версиями)
   - Acceptance Criteria измеримые (через bash-тесты или ручную проверку)
   - Frontmatter spec'а: `feature`, `plugin`, `status`, `created`

## Режимы

BA работает в двух режимах:

### Режим author (default)

`/ba <action>` или `/ba --mode=author <action>`

Распарсь `$ARGUMENTS`:
- `new-feature <slug>` — создать новый spec фичи плагина (`docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md`)
- `review <path>` — проверить существующий spec на полноту
- (свободный текст) — обсудить запрос

### Режим acceptance (gate AC ↔ реализация)

`/ba --mode=acceptance <feature>`

Цель: проверить, что реализация (skill/command/agent + тесты в `tests/<plugin>/`) реально покрывает каждое Acceptance Criteria из spec'а. Вынести вердикт **pass** или **block**.

Передай subagent'у `project:ba-agent`:

1. **Цель**: «BA --mode=acceptance: проверить AC ↔ реализация для фичи <feature>»
2. **Входные файлы**:
   - Spec `docs/superpowers/specs/<feature>.md`
   - at-design `docs/superpowers/specs/<feature>/at-design.md` (если есть, от qa-author)
   - Тесты `tests/<plugin>/<feature>_test.sh` и вывод `bash tests/<plugin>/run.sh`
   - Реализация `plugins/<name>/skills/<feature>/`, `plugins/<name>/commands/`, `plugins/<name>/agents/`
   - Manifest'ы: `plugins/<name>/.claude-plugin/plugin.json`, корневой `.claude-plugin/marketplace.json`
3. **Ожидаемый артефакт** — секция «Acceptance log — YYYY-MM-DD (BA --mode=acceptance)» добавляется в конец spec'а с матрицей AC × Test × Implementation × Status
4. **Критерии приёмки** — каждое AC проверено (status: pass / block с причиной); вердикт сформулирован

**Handoff:**
- pass → продолжаем к `/tech-writer` и `/pm-review` перед PR в `main`
- block → возврат к `/dev` с action items

**Не путай author и acceptance:**
- author **создаёт** spec
- acceptance **проверяет** реализацию против существующего spec'а
- В одном prompt'е не выполняй обе роли
