# Переход gramax-marketplace на nauta — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перевести репозиторий на роли из плагина `nauta`, мигрировать 24 документа из `docs/` в `content/` по nauta-таксономии и включить `validate-content.py` как pre-commit гейт.

**Architecture:** Локальный плагин `project` удаляется (он не загружается: marketplace `gramax-plugin-internal-local` отсутствует в `~/.claude/plugins/known_marketplaces.json`). Документы переезжают через `git mv` с сохранением истории и получают frontmatter в object-нотации Gramax. Гейт `validate-content.py` доставляется рано (чтобы миграция была TDD-проверяемой), но подключается в `check.sh` последним — иначе pre-commit заблокирует собственные коммиты миграции. Sunset-урок из удаляемого плагина превращается из проверки текста промпта в постоянный orphan-гейт по репозиторию.

**Tech Stack:** bash 3.2 (потолок macOS), Python 3.11+ через `uv run` (PEP 723), pyyaml 6.x, git, Claude Code plugins.

**Спека:** `docs/superpowers/specs/2026-08-07-nauta-integration-design.md`

## Global Constraints

- Валидаторы запускаются **только** через `uv run`, не через `python3` — зависимости объявлены по PEP 723 (`pyyaml>=6.0,<7.0`).
- Все shell-скрипты совместимы с bash 3.2: без `declare -A`, пустые массивы разворачиваются как `"${arr[@]:-}"`.
- Переезды файлов — **только** `git mv`, не delete + create (AC-4 требует работающий `git log --follow`).
- Значения enum в frontmatter сравниваются точно, с учётом регистра: `type: "Enum"` в `.doc-root.yaml` — с заглавной E.
- В `.doc-root.yaml` список допустимых значений — ключ `values`; в frontmatter статьи элемент `properties` несёт **ровно** ключи `name` и `value`.
- `_index.md` не несёт `properties` — проверка C2 это запрещает.
- Корневой `.claude-plugin/marketplace.json` не изменяется ни в одной задаче — это публичный договор с пользователями, правка требует ADR.
- `plugins/gramax/` не изменяется, кроме `CHANGELOG.md` в Task 8.
- Коммиты без `--no-verify`. Перед каждым коммитом `bash scripts/check.sh --fast` зелёный.
- Каждый коммит заканчивается строкой `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.

## File Structure

**Создаются:**
- `tests/gramax/orphan-references/sunset-registry.txt` — реестр удалённых артефактов, по regex на строку
- `tests/gramax/orphan-references/run.sh` — постоянный гейт: грепает репо по реестру
- `tests/gramax/nauta-integration/lib/assert.sh` — копия мини-библиотеки ассертов (конвенция репозитория: каждый suite несёт свою)
- `tests/gramax/nauta-integration/run.sh` — агрегатор `ac-*.sh`
- `tests/gramax/nauta-integration/ac-001…ac-008-*.sh` — AC-тесты перехода
- `content/.doc-root.yaml` — контракт каталога Gramax
- `content/_index.md`, `content/00-project/_index.md`, `content/00-project/adr/_index.md`, `content/10-domain/_index.md`, `content/10-domain/research/_index.md`, `content/30-requirements/_index.md`, `content/60-implementation/_index.md`, `content/60-implementation/test-reports/_index.md`, `content/60-implementation/acceptance/_index.md` — 9 индексов
- `scripts/{validate-content,validate-profile,check-status-drift,_validate_common,_apply_profile,_apply_yaml_patch,_drift_check,_init_helpers,_resolve_agents}.py`, `scripts/apply-overlay.sh` — от `/nauta:sync-scripts`
- `.nauta-scripts-basis.yaml`, `docs/overlays/profiles/.gitkeep` — от `/nauta:sync-scripts`

**Удаляются:** `.claude/plugins/project/` (17 файлов), `.claude/.claude-plugin/marketplace.json`, `tests/project/`, `docs/adr/.gitkeep`

**Перемещаются:** 24 файла `docs/` → `content/`

**Изменяются:** `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `scripts/check.sh`, `plugins/gramax/CHANGELOG.md`, комментарии в `tests/gramax/remove-diagram-skills/*.sh`

---

## Phase 1 — Гейт и удаление мёртвого плагина

### Task 1: Постоянный orphan-references гейт

Заменяет `tests/project/sunset-pattern-in-agents/run.sh`, который ассертит слова в тексте промпта. Новый гейт проверяет само поведение: нет ли в репозитории ссылок на удалённые артефакты. Покрывает AC-11, AC-12.

**Files:**
- Create: `tests/gramax/orphan-references/sunset-registry.txt`
- Create: `tests/gramax/orphan-references/run.sh`

**Interfaces:**
- Produces: исполняемый `bash tests/gramax/orphan-references/run.sh` → exit 0 если сирот нет, exit 1 со списком совпадений иначе. Реестр пополняется при каждом следующем sunset.
- Consumes: ничего.

- [ ] **Step 1: Создать реестр удалённых артефактов**

Паттерны перенесены из `tests/gramax/remove-diagram-skills/ac-016-no-orphan-references.sh` (там они захардкожены в одну строку `PATTERN=`).

Create `tests/gramax/orphan-references/sunset-registry.txt`:

```
# tests/gramax/orphan-references/sunset-registry.txt
# Реестр артефактов, удалённых из плагина. Один extended-regex на строку.
# Строки, начинающиеся с #, и пустые — игнорируются.
#
# Правило (CLAUDE.md → Красные линии): удаляя skill или script, добавь сюда его имя.
# Гейт tests/gramax/orphan-references/run.sh не даст остаточной ссылке дожить до коммита.
#
# 2026-05-11, ADR-0008 — удаление внутренних drawio-скиллов:
drawio_convert
find_doc_root
save_diagram
insert_diagram_ref
validate_diagram_type
```

- [ ] **Step 2: Написать гейт**

Исключения не косметика: `CHANGELOG.md` обязан называть удалённое (это его работа), ADR и отчёты фиксируют историю, `docs/` — архив мета-артефактов, а `remove-diagram-skills/` — feature-suite, который сам проверяет эти же имена.

Create `tests/gramax/orphan-references/run.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/orphan-references/run.sh
# Постоянный гейт: ни один живой файл репозитория не ссылается на удалённые артефакты.
# Реестр — sunset-registry.txt рядом. Обобщение ac-016 из remove-diagram-skills.
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-8

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REGISTRY="$SCRIPT_DIR/sunset-registry.txt"

if [ ! -f "$REGISTRY" ]; then
  printf "${RED}FAIL${NC}: реестр не найден: %s\n" "$REGISTRY" >&2
  exit 2
fi

# Где ищем. Историю удалённого легитимно хранят CHANGELOG, ADR, отчёты и docs/ —
# они исключены ниже, а не здесь, чтобы список областей оставался читаемым.
SEARCH_PATHS=(plugins scripts tests CLAUDE.md AGENTS.md README.md)

# Исторические suite исключены осознанно: remove-diagram-skills проверяет ровно эти имена
# как предмет своих AC, diagram-on-demand покрывает удалённую по ADR-0008 фичу и содержит
# все пять паттернов в 11 файлах. Без этих двух исключений гейт красный с первого прогона.
EXCLUDE_RE='(^|/)CHANGELOG\.md$|^content/00-project/adr/|^content/60-implementation/|^docs/|^tests/gramax/orphan-references/|^tests/gramax/remove-diagram-skills/|^tests/gramax/diagram-on-demand/'

TOTAL=0
while IFS= read -r pattern; do
  case "$pattern" in
    ''|'#'*) continue ;;
  esac

  for path in "${SEARCH_PATHS[@]:-}"; do
    [ -e "$path" ] || continue
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      file="${hit%%:*}"
      if printf '%s\n' "$file" | grep -qE "$EXCLUDE_RE"; then
        continue
      fi
      printf "${RED}FAIL${NC}: остаточная ссылка на '%s': %s\n" "$pattern" "$hit" >&2
      TOTAL=$((TOTAL + 1))
    done <<< "$(grep -rnE "$pattern" "$path" 2>/dev/null || true)"
  done
done < "$REGISTRY"

if [ "$TOTAL" -gt 0 ]; then
  printf "\n${RED}FAILED${NC}: %d остаточных ссылок на удалённые артефакты.\n" "$TOTAL" >&2
  printf "Почини ссылки либо, если упоминание историческое, расширь EXCLUDE_RE.\n" >&2
  exit 1
fi

printf "${GREEN}PASS${NC}: остаточных ссылок на удалённые артефакты нет.\n"
exit 0
```

- [ ] **Step 3: Сделать исполняемым и прогнать — должен пройти**

Гейт обязан быть зелёным на текущем дереве: удалённые скрипты уже вычищены в PR по ADR-0008.

Run:
```bash
chmod +x tests/gramax/orphan-references/run.sh
bash tests/gramax/orphan-references/run.sh
```
Expected: `PASS: остаточных ссылок на удалённые артефакты нет.`, exit 0

- [ ] **Step 4: Проверить, что гейт живой (AC-12)**

Тест на тест: подсадить ссылку и убедиться, что гейт её ловит.

Run:
```bash
echo '# sentinel drawio_convert' >> plugins/gramax/README.md
bash tests/gramax/orphan-references/run.sh; echo "exit=$?"
git checkout plugins/gramax/README.md
bash tests/gramax/orphan-references/run.sh; echo "exit=$?"
```
Expected: первый прогон — `FAIL: остаточная ссылка на 'drawio_convert': plugins/gramax/README.md:…`, `exit=1`; после отката — `PASS`, `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add tests/gramax/orphan-references/
git commit -m "test(gramax): постоянный orphan-references гейт

Обобщает ac-016 из remove-diagram-skills: реестр удалённых артефактов
вместо захардкоженного паттерна, проверка по всему репозиторию.
Заменяет tests/project/sunset-pattern-in-agents, который проверял
формулировку промпта, а не поведение.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-8

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Удаление локального плагина `project`

Покрывает AC-1, AC-11.

**Files:**
- Create: `tests/gramax/nauta-integration/lib/assert.sh`
- Create: `tests/gramax/nauta-integration/run.sh`
- Create: `tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh`
- Delete: `.claude/plugins/project/` (17 файлов), `.claude/.claude-plugin/marketplace.json`, `tests/project/`
- Modify: `.claude/settings.json`

**Interfaces:**
- Consumes: ничего.
- Produces: suite `tests/gramax/nauta-integration/` с агрегатором `run.sh` и библиотекой `lib/assert.sh` — Tasks 4–9 добавляют в него свои `ac-*.sh`.

- [ ] **Step 1: Скопировать библиотеку ассертов и агрегатор**

Конвенция репозитория — каждый suite несёт собственную копию `lib/assert.sh` и `run.sh` (см. `remove-diagram-skills`, `routing-mermaid-drawio`, `mermaid-file-based`). Следуем ей, а не заводим общую.

Run:
```bash
mkdir -p tests/gramax/nauta-integration/lib
cp tests/gramax/remove-diagram-skills/lib/assert.sh tests/gramax/nauta-integration/lib/assert.sh
cp tests/gramax/remove-diagram-skills/run.sh tests/gramax/nauta-integration/run.sh
sed -i '' 's|tests/gramax/remove-diagram-skills/run.sh|tests/gramax/nauta-integration/run.sh|' tests/gramax/nauta-integration/run.sh
sed -i '' 's|tests/gramax/remove-diagram-skills/lib/assert.sh|tests/gramax/nauta-integration/lib/assert.sh|' tests/gramax/nauta-integration/lib/assert.sh
```

- [ ] **Step 2: Написать падающий тест AC-001**

Create `tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-1
# AC coverage:
#   AC-1  → локальный плагин project удалён, settings.json без упоминаний
#   AC-11 → tests/project/ удалён

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_dir_not_exists ".claude/plugins/project" \
  "AC-1: каталог локального плагина должен быть удалён"
assert_file_not_exists ".claude/.claude-plugin/marketplace.json" \
  "AC-1: внутренний marketplace-манифест должен быть удалён"
assert_dir_not_exists "tests/project" \
  "AC-11: tests/project должен быть удалён вместе с плагином"

if [ -f ".claude/settings.json" ]; then
  assert_no_grep ".claude/settings.json" "gramax-plugin-internal-local" \
    "AC-1: settings.json не должен упоминать внутренний marketplace"
  assert_no_grep ".claude/settings.json" "project@" \
    "AC-1: settings.json не должен включать плагин project"
  if ! python3 -m json.tool ".claude/settings.json" > /dev/null 2>&1; then
    echo "  FAIL: AC-1: .claude/settings.json — невалидный JSON" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-001: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-001: локальный плагин project удалён, settings.json чист"
```

- [ ] **Step 3: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh`
Expected: FAIL — каталог `.claude/plugins/project` ещё существует, в `settings.json` есть обе записи.

- [ ] **Step 4: Удалить плагин и его тест**

Run:
```bash
git rm -r --quiet .claude/plugins/project .claude/.claude-plugin tests/project
```

- [ ] **Step 5: Вычистить записи из `.claude/settings.json`**

После удаления обоих ключей объект пустеет — файл остаётся с `{}`, а не удаляется (FR-1).

Write `.claude/settings.json`:

```json
{}
```

- [ ] **Step 6: Прогнать — должен пройти**

Run: `bash tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh`
Expected: `[PASS] ac-001: локальный плагин project удалён, settings.json чист`

- [ ] **Step 7: Убедиться, что orphan-гейт и check.sh не сломались**

Run:
```bash
bash tests/gramax/orphan-references/run.sh
bash scripts/check.sh --fast
```
Expected: оба exit 0.

- [ ] **Step 8: Commit**

```bash
git add -A .claude tests/gramax/nauta-integration
git commit -m "chore(claude)!: удалить мёртвый локальный плагин project

Плагин не загружался: marketplace gramax-plugin-internal-local
отсутствовал в known_marketplaces.json, команды project:* и агенты
project:*-agent в сессии недоступны. Роли берутся из nauta.

BREAKING CHANGE: команды /pm, /ba, /sa, /dev, /qa, /research,
/tech-writer, /pm-review больше не объявляются репозиторием —
используйте /nauta:* из плагина nauta.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-1

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2 — Каркас `content/`

### Task 3: Доставка валидаторов nauta

Доставка отделена от подключения: файл валидатора нужен уже сейчас, чтобы Tasks 4–8 были TDD-проверяемыми, но в `check.sh` он попадёт только в Task 9 — иначе pre-commit заблокирует коммиты самой миграции. Покрывает AC-10.

**Files:**
- Create: `scripts/*.py` (9 файлов), `scripts/apply-overlay.sh`, `.nauta-scripts-basis.yaml`, `docs/overlays/profiles/.gitkeep`
- Create: `tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh`

**Interfaces:**
- Consumes: suite из Task 2.
- Produces: `uv run scripts/validate-content.py [dir]` → exit 0 clean / 1 errors / 2 нет pyyaml или плохой путь. Tasks 4–9 вызывают именно его.

- [ ] **Step 1: Зафиксировать sha256 своих гейт-файлов до синка**

AC-10 требует, чтобы `deliver.sh` не перезаписал собственные скрипты репозитория. Снимаем эталон заранее.

Run:
```bash
shasum -a 256 scripts/check.sh scripts/install-hooks.sh .githooks/pre-commit | tee /tmp/gramax-gates-before.txt
```
Expected: три строки с хэшами.

- [ ] **Step 2: Написать падающий тест AC-002**

Create `tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7
# AC coverage:
#   AC-10 → свои check.sh / install-hooks.sh / pre-commit не перезаписаны синком
#   (валидатор доставлен и запускается)

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "scripts/validate-content.py" \
  "валидатор content/ должен быть доставлен"
assert_file_exists "scripts/_validate_common.py" \
  "общий модуль валидаторов должен быть доставлен"
assert_file_exists ".nauta-scripts-basis.yaml" \
  "базис синка должен быть создан"

# AC-10: собственные гейты остались нашими — deliver.sh относит их к «чужим».
assert_grep "scripts/check.sh" "gramax-marketplace" \
  "AC-10: scripts/check.sh должен остаться версией gramax, не nauta"
assert_grep ".githooks/pre-commit" "scripts/check.sh --fast" \
  "AC-10: .githooks/pre-commit должен остаться версией gramax"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002: валидаторы nauta доставлены, собственные гейты не тронуты"
```

- [ ] **Step 3: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh`
Expected: FAIL — `scripts/validate-content.py` не найден.

- [ ] **Step 4: Выполнить синк**

Вызови slash-команду `/nauta:sync-scripts`. Она запускает `bash ${CLAUDE_PLUGIN_ROOT}/bin/deliver.sh` — корень плагина подставляет сама команда.

Expected в отчёте: `Создано: 10 файл(ов)`, `Чужие (не тронуты): 3 файл(ов)`, `Конфликт: 0 файлов`.

Три «чужих» — это `scripts/check.sh`, `scripts/install-hooks.sh`, `.githooks/pre-commit`: они существовали до синка и базисом не отслеживаются, поэтому не перезаписываются.

- [ ] **Step 5: Проверить, что свои гейты не изменились**

Run:
```bash
shasum -a 256 scripts/check.sh scripts/install-hooks.sh .githooks/pre-commit | diff /tmp/gramax-gates-before.txt - && echo "AC-10 OK: гейты не тронуты"
```
Expected: `AC-10 OK: гейты не тронуты`, diff пуст.

- [ ] **Step 6: Проверить, что валидатор запускается**

Run: `uv run scripts/validate-content.py; echo "exit=$?"`
Expected: `ERROR: not a directory: content`, `exit=2` — каталога ещё нет, это ожидаемо и подтверждает, что скрипт исполняется и pyyaml подтягивается.

- [ ] **Step 7: Прогнать тест — должен пройти**

Run: `bash tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh`
Expected: `[PASS] ac-002: валидаторы nauta доставлены, собственные гейты не тронуты`

- [ ] **Step 8: Commit**

```bash
git add scripts/ .nauta-scripts-basis.yaml docs/overlays tests/gramax/nauta-integration
git commit -m "build: доставить валидаторы nauta через sync-scripts

10 файлов + базис с sha256-трекингом. Собственные check.sh,
install-hooks.sh и pre-commit не перезаписаны (deliver.sh относит их
к «чужим»). В check.sh валидатор подключается позже — Task 9.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Контракт каталога и корневой индекс

Покрывает AC-6 частично (валидатор зелёный на пустом каркасе).

**Files:**
- Create: `content/.doc-root.yaml`, `content/_index.md`
- Create: `tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`

**Interfaces:**
- Consumes: `uv run scripts/validate-content.py` из Task 3.
- Produces: enum-словарь, на который опираются frontmatter'ы в Tasks 5–8. Имена свойств: `Тип контента`, `Статус`, `Плагин`.

- [ ] **Step 1: Написать падающий тест AC-003**

Create `tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-003-doc-root-contract.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-4
# AC coverage:
#   AC-6 → validate-content.py зелёный (ноль errors)

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "content/.doc-root.yaml" ".doc-root.yaml должен существовать"
assert_file_exists "content/_index.md" "корневой _index.md должен существовать"

# Контракт схемы: type: Enum с заглавной, значения в ключе values.
assert_grep_regex "content/.doc-root.yaml" '^\s+type: Enum' \
  "properties должны объявлять type: Enum (регистр важен)"
assert_grep "content/.doc-root.yaml" "filterProperties" \
  "filterProperties должен быть объявлен"
assert_grep "content/.doc-root.yaml" "Тип контента" \
  "свойство «Тип контента» должно быть объявлено"

# C2: _index.md не несёт properties.
assert_no_grep "content/_index.md" "properties:" \
  "C2: _index.md не должен содержать properties"

set +e
VALIDATOR_OUT="$(uv run scripts/validate-content.py 2>&1)"
VALIDATOR_RC=$?
set -e
if [ "$VALIDATOR_RC" -ne 0 ]; then
  echo "  FAIL: AC-6: validate-content.py exit=$VALIDATOR_RC" >&2
  echo "$VALIDATOR_OUT" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-003: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-003: контракт .doc-root.yaml валиден, validate-content.py зелёный"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`
Expected: FAIL — `content/.doc-root.yaml` не найден.

- [ ] **Step 3: Создать `.doc-root.yaml`**

Create `content/.doc-root.yaml`:

```yaml
code: GRAMAX-PLUGIN
title: Gramax Marketplace
description: Документация плагина gramax для Claude Code
editors:
  - qutask@gmail.com
properties:
  - name: Тип контента
    type: Enum
    values: [ADR, Требование, Research, Тест-отчёт, Приёмка, Урок, Архитектура]
  - name: Статус
    type: Enum
    values: [Draft, Active, Accepted, Superseded, Historical, Done]
  - name: Плагин
    type: Enum
    values: [gramax, marketplace]
filterProperties: [Тип контента, Статус, Плагин]
```

- [ ] **Step 4: Создать корневой индекс**

Ссылки на разделы добавляются по мере их появления в Tasks 5–8; сейчас разделов нет.

Create `content/_index.md`:

```markdown
---
title: Gramax Marketplace
order: 0
---

# Gramax Marketplace

Документация публичного Claude Code marketplace `mdemyanov/gramax-plugin` — плагин `gramax`
для работы с документацией Gramax.

Мета-артефакты о самом репозитории и его процессе (спеки по тулингу, планы исполнения)
живут в `docs/`, не здесь. Правило разделения — `AGENTS.md`.
```

- [ ] **Step 5: Прогнать — должен пройти**

Run: `bash tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`
Expected: `[PASS] ac-003: контракт .doc-root.yaml валиден, validate-content.py зелёный`

- [ ] **Step 6: Commit**

```bash
git add content tests/gramax/nauta-integration
git commit -m "feat(content): каркас Gramax-каталога — .doc-root.yaml и корневой индекс

Схема свойств вычитана из validate-content.py: type: Enum с заглавной,
допустимые значения в ключе values, filterProperties синхронно.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-4

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3 — Миграция документов

### Task 5: ADR → `content/00-project/adr/`

11 файлов. Покрывает AC-3 частично, AC-4, AC-7, AC-8.

**Files:**
- Move: `docs/adr/0001…0010-*.md` → `content/00-project/adr/`
- Move: `docs/adr/README.md` → `content/00-project/adr/_index.md`
- Delete: `docs/adr/.gitkeep`
- Create: `content/00-project/_index.md`
- Create: `tests/gramax/nauta-integration/ac-004-adr-migrated.sh`

**Interfaces:**
- Consumes: enum-словарь из Task 4.
- Produces: `content/00-project/adr/` — путь, на который Tasks 8 и 9 чинят ссылки.

- [ ] **Step 1: Написать падающий тест AC-004**

Статусы не назначаются заново — они берутся из реестра `docs/adr/README.md` и тест их фиксирует.

Create `tests/gramax/nauta-integration/ac-004-adr-migrated.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-004-adr-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → ADR переехали, docs/adr/ отсутствует
#   AC-7 → каждая статья объявляет «Тип контента»
#   AC-8 → статусы совпадают с реестром до переезда

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
ADR_DIR="content/00-project/adr"

assert_dir_not_exists "docs/adr" "AC-3: docs/adr должен быть пуст и удалён"
assert_dir_exists "$ADR_DIR" "AC-3: ADR должны переехать в content/00-project/adr"
assert_file_exists "$ADR_DIR/_index.md" "C1: раздел ADR должен иметь _index.md"
assert_file_exists "content/00-project/_index.md" "C1: 00-project должен иметь _index.md"

for n in 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010; do
  f=$(ls "$ADR_DIR"/${n}-*.md 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    echo "  FAIL: AC-3: ADR-$n не найден в $ADR_DIR" >&2
    FAIL=$((FAIL + 1))
    continue
  fi
  assert_grep "$f" "Тип контента" "AC-7: $n объявляет «Тип контента»"
  assert_grep "$f" "value: [ADR]" "AC-7: $n имеет тип ADR"
done

# AC-8: статусы из реестра docs/adr/README.md на момент переезда.
check_status() {
  local n="$1" expected="$2"
  local f
  f=$(ls "$ADR_DIR"/${n}-*.md 2>/dev/null | head -1)
  [ -z "$f" ] && return
  if ! grep -qF "value: [$expected]" "$f"; then
    echo "  FAIL: AC-8: ADR-$n должен иметь статус $expected" >&2
    FAIL=$((FAIL + 1))
  fi
}

check_status 0001 Superseded
check_status 0002 Historical
check_status 0003 Historical
check_status 0004 Superseded
check_status 0005 Superseded
check_status 0006 Accepted
check_status 0007 Superseded
check_status 0008 Accepted
check_status 0009 Accepted
check_status 0010 Accepted

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-004: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-004: 10 ADR мигрированы с корректными статусами"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-004-adr-migrated.sh`
Expected: FAIL — `docs/adr` существует, `content/00-project/adr` нет.

- [ ] **Step 3: Переместить файлы через `git mv`**

Run:
```bash
mkdir -p content/00-project/adr
git mv docs/adr/0001-diagram-on-demand-plugin-split.md content/00-project/adr/
git mv docs/adr/0002-drawio-mcp-backend-selection.md content/00-project/adr/
git mv docs/adr/0003-drawio-backend-vendoring-strategy.md content/00-project/adr/
git mv docs/adr/0004-router-and-engine-selection.md content/00-project/adr/
git mv docs/adr/0005-save-flow-script-api-contract.md content/00-project/adr/
git mv docs/adr/0006-marketplace-json-semver-strategy.md content/00-project/adr/
git mv docs/adr/0007-out-of-scope-phase2.md content/00-project/adr/
git mv docs/adr/0008-drop-internal-drawio-skills.md content/00-project/adr/
git mv docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md content/00-project/adr/
git mv docs/adr/0010-mermaid-file-based-workflow.md content/00-project/adr/
git mv docs/adr/README.md content/00-project/adr/_index.md
git rm --quiet docs/adr/.gitkeep
```

- [ ] **Step 4: Проставить frontmatter каждому ADR**

Вставляется в самое начало файла, перед строкой `# ADR-NNNN: …`. Значения «Плагин» и «Статус» — из колонок реестра.

Для `0001-diagram-on-demand-plugin-split.md`:

```yaml
---
properties:
  - name: Тип контента
    value: [ADR]
  - name: Статус
    value: [Superseded]
  - name: Плагин
    value: [gramax, marketplace]
---
```

Остальные девять — та же структура, меняются только значения:

| Файл | Статус | Плагин |
|---|---|---|
| `0002-drawio-mcp-backend-selection.md` | `[Historical]` | `[gramax]` |
| `0003-drawio-backend-vendoring-strategy.md` | `[Historical]` | `[gramax]` |
| `0004-router-and-engine-selection.md` | `[Superseded]` | `[gramax]` |
| `0005-save-flow-script-api-contract.md` | `[Superseded]` | `[gramax]` |
| `0006-marketplace-json-semver-strategy.md` | `[Accepted]` | `[marketplace]` |
| `0007-out-of-scope-phase2.md` | `[Superseded]` | `[gramax]` |
| `0008-drop-internal-drawio-skills.md` | `[Accepted]` | `[gramax, marketplace]` |
| `0009-drawio-stub-and-claude-mermaid-removal.md` | `[Accepted]` | `[gramax, marketplace]` |
| `0010-mermaid-file-based-workflow.md` | `[Accepted]` | `[gramax]` |

- [ ] **Step 5: Привести `_index.md` раздела ADR**

Бывший `README.md`. Frontmatter без `properties` (C2), заголовок `title`, ссылки уже относительные — менять их не нужно, файлы лежат рядом.

Заменить первые строки файла `content/00-project/adr/_index.md` (было `# Architecture Decision Records`) на:

```markdown
---
title: Архитектурные решения
order: 1
---

# Architecture Decision Records
```

Остальное тело реестра оставить как есть.

- [ ] **Step 6: Создать `content/00-project/_index.md`**

Create `content/00-project/_index.md`:

```markdown
---
title: Проект
order: 1
---

# Проект

Проектные артефакты: архитектурные решения и их реестр.

- [Архитектурные решения](adr/_index.md)
```

- [ ] **Step 7: Прогнать тест и валидатор**

Run:
```bash
bash tests/gramax/nauta-integration/ac-004-adr-migrated.sh
uv run scripts/validate-content.py
```
Expected: `[PASS] ac-004: 10 ADR мигрированы с корректными статусами`; валидатор exit 0 (warnings про сирот допустимы — их закроет Task 8).

- [ ] **Step 8: Проверить сохранность истории (AC-4)**

Run: `git log --follow --oneline content/00-project/adr/0010-mermaid-file-based-workflow.md | head -3`
Expected: минимум 2 коммита, включая `ddeda69` (создание файла до переезда).

- [ ] **Step 9: Commit**

```bash
git add -A content docs tests/gramax/nauta-integration
git commit -m "refactor(content): перенести ADR в content/00-project/adr

10 ADR + реестр как _index.md. Статусы взяты из реестра, не назначены
заново: Superseded — 0001/0004/0005/0007, Historical — 0002/0003,
Accepted — 0006/0008/0009/0010.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Уроки, research и требования

6 файлов. Покрывает AC-3 частично, AC-5, AC-7.

**Files:**
- Move: `docs/lessons-learned.md` → `content/lessons-learned.md`
- Move: `docs/research/2026-05-11-drawio-skill-external.md` → `content/10-domain/research/`
- Move: 4 файла `docs/superpowers/specs/` → `content/30-requirements/`
- Create: `content/10-domain/_index.md`, `content/10-domain/research/_index.md`, `content/30-requirements/_index.md`
- Create: `tests/gramax/nauta-integration/ac-005-requirements-migrated.sh`

**Interfaces:**
- Consumes: enum-словарь из Task 4.
- Produces: `content/lessons-learned.md` — путь, на который Task 9 переключает `CLAUDE.md`.

- [ ] **Step 1: Написать падающий тест AC-005**

Путь `content/lessons-learned.md` — корень `content/`, а не `00-project/`: именно так на него ссылаются агенты nauta (10 вхождений).

Create `tests/gramax/nauta-integration/ac-005-requirements-migrated.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-005-requirements-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → уроки, research и требования переехали
#   AC-5 → мета-спека и мета-план остались в docs/
#   AC-7 → «Тип контента» проставлен

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "content/lessons-learned.md" "AC-3: журнал уроков в корне content/"
assert_file_not_exists "docs/lessons-learned.md" "AC-3: старый путь журнала удалён"
assert_dir_not_exists "docs/research" "AC-3: docs/research удалён"

assert_file_exists "content/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "AC-3: research переехал"
assert_file_exists "content/10-domain/_index.md" "C1: 10-domain должен иметь _index.md"
assert_file_exists "content/10-domain/research/_index.md" "C1: research должен иметь _index.md"
assert_file_exists "content/30-requirements/_index.md" "C1: 30-requirements должен иметь _index.md"

for f in 2026-05-08-diagram-on-demand-design.md \
         2026-05-11-remove-diagram-skills.md \
         2026-05-11-routing-mermaid-drawio.md \
         2026-05-12-mermaid-file-based-design.md; do
  assert_file_exists "content/30-requirements/$f" "AC-3: требование $f переехало"
  assert_file_not_exists "docs/superpowers/specs/$f" "AC-3: старый путь $f удалён"
  [ -f "content/30-requirements/$f" ] && \
    assert_grep "content/30-requirements/$f" "value: [Требование]" \
      "AC-7: $f имеет тип Требование"
done

# AC-5: мета-артефакты остаются в docs/.
assert_file_exists "docs/superpowers/specs/2026-05-08-apply-project-template-design.md" \
  "AC-5: мета-спека остаётся в docs/"
assert_file_exists "docs/superpowers/plans/2026-05-08-apply-project-template.md" \
  "AC-5: мета-план остаётся в docs/"

assert_grep "content/lessons-learned.md" "value: [Урок]" "AC-7: журнал имеет тип Урок"
assert_grep "content/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "value: [Research]" "AC-7: research имеет тип Research"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: уроки, research и требования мигрированы; мета осталась в docs/"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-005-requirements-migrated.sh`
Expected: FAIL — `content/lessons-learned.md` не найден.

- [ ] **Step 3: Переместить файлы**

Run:
```bash
mkdir -p content/10-domain/research content/30-requirements
git mv docs/lessons-learned.md content/lessons-learned.md
git mv docs/research/2026-05-11-drawio-skill-external.md content/10-domain/research/
git mv docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md content/30-requirements/
git mv docs/superpowers/specs/2026-05-11-remove-diagram-skills.md content/30-requirements/
git mv docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md content/30-requirements/
git mv docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md content/30-requirements/
```

- [ ] **Step 4: Проставить frontmatter журналу уроков**

Файл начинается без frontmatter — блок вставляется первым. Статус `Active`: у живого журнала нет конечного состояния.

Вставить в начало `content/lessons-learned.md`:

```yaml
---
properties:
  - name: Тип контента
    value: [Урок]
  - name: Статус
    value: [Active]
  - name: Плагин
    value: [gramax, marketplace]
---
```

- [ ] **Step 5: Проставить frontmatter research-файлу**

Вставить в начало `content/10-domain/research/2026-05-11-drawio-skill-external.md`:

```yaml
---
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---
```

- [ ] **Step 6: Проставить frontmatter требованиям**

У трёх из четырёх файлов frontmatter уже есть (`title:`, `status:`, `date:`, `plugin:`, `feature:`). Существующие ключи **не удаляются** — C4 и C5 читают только `fm["properties"]`. Блок `properties:` добавляется внутрь существующего frontmatter; у файла без frontmatter создаётся новый.

Статусы: `2026-05-08-diagram-on-demand-design.md` → `Superseded` (описанная фича удалена по ADR-0008), остальные три → `Done` (реализованы и приняты).

Для `content/30-requirements/2026-05-12-mermaid-file-based-design.md` итоговый frontmatter:

```yaml
---
feature: mermaid-file-based
plugin: gramax
status: draft
created: 2026-05-12
properties:
  - name: Тип контента
    value: [Требование]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---
```

Аналогично для остальных трёх: сохранить их текущие ключи, дописать блок `properties` с `Тип контента: [Требование]`, `Плагин: [gramax]` и статусом из абзаца выше.

- [ ] **Step 7: Создать три индекса**

Create `content/10-domain/_index.md`:

```markdown
---
title: Домен
order: 2
---

# Домен

Доменный контекст: исследования внешних решений и терминология.

- [Исследования](research/_index.md)
```

Create `content/10-domain/research/_index.md`:

```markdown
---
title: Исследования
order: 1
---

# Исследования

Аналитические выжимки по внешним решениям. Входы для BA и SA, не требования.

- [Внешний drawio-skill как замена внутренним скиллам](2026-05-11-drawio-skill-external.md)
```

Create `content/30-requirements/_index.md`:

```markdown
---
title: Требования
order: 3
---

# Требования

Спеки фич плагина `gramax`: JTBD, функциональные требования, критерии приёмки.

- [Diagram-on-demand](2026-05-08-diagram-on-demand-design.md) — Superseded по ADR-0008
- [Удаление внутренних diagram-скиллов](2026-05-11-remove-diagram-skills.md)
- [Роутинг mermaid и drawio](2026-05-11-routing-mermaid-drawio.md)
- [Mermaid — file-based workflow](2026-05-12-mermaid-file-based-design.md)
```

- [ ] **Step 8: Дописать разделы в корневой индекс**

Добавить в конец `content/_index.md`:

```markdown

## Разделы

- [Проект](00-project/_index.md) — архитектурные решения
- [Домен](10-domain/_index.md) — исследования
- [Требования](30-requirements/_index.md) — спеки фич плагина
- [Уроки](lessons-learned.md) — журнал находок команды
```

- [ ] **Step 9: Прогнать тест и валидатор**

Run:
```bash
bash tests/gramax/nauta-integration/ac-005-requirements-migrated.sh
uv run scripts/validate-content.py
```
Expected: `[PASS] ac-005: …`; валидатор exit 0.

- [ ] **Step 10: Commit**

```bash
git add -A content docs tests/gramax/nauta-integration
git commit -m "refactor(content): перенести уроки, research и требования

Журнал уроков — в корень content/ (так на него ссылаются агенты nauta).
4 предметные спеки — в 30-requirements. Спека и план про применение
шаблона остаются в docs/ как мета-артефакты о самом репозитории.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Отчёты прогона и приёмки

7 файлов. Покрывает AC-3 полностью, AC-7.

**Files:**
- Move: 4 файла `docs/qa-reports/` → `content/60-implementation/test-reports/`
- Move: 3 файла `docs/acceptance/` → `content/60-implementation/acceptance/`
- Create: `content/60-implementation/_index.md`, `content/60-implementation/test-reports/_index.md`, `content/60-implementation/acceptance/_index.md`
- Create: `tests/gramax/nauta-integration/ac-006-reports-migrated.sh`

**Interfaces:**
- Consumes: enum-словарь из Task 4.
- Produces: завершённую структуру `content/` — Task 8 чинит на неё внешние ссылки.

Приёмка отделена от отчётов прогона намеренно: это артефакты разных ролей — вердикт BA по AC против результата прогона QA.

- [ ] **Step 1: Написать падающий тест AC-006**

Create `tests/gramax/nauta-integration/ac-006-reports-migrated.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-006-reports-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → отчёты прогона и приёмки переехали, docs/ очищен от них
#   AC-7 → «Тип контента» проставлен

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_dir_not_exists "docs/qa-reports" "AC-3: docs/qa-reports удалён"
assert_dir_not_exists "docs/acceptance" "AC-3: docs/acceptance удалён"

assert_file_exists "content/60-implementation/_index.md" "C1: 60-implementation индекс"
assert_file_exists "content/60-implementation/test-reports/_index.md" "C1: test-reports индекс"
assert_file_exists "content/60-implementation/acceptance/_index.md" "C1: acceptance индекс"

for f in 2026-05-08-diagram-on-demand-qa-report.md \
         2026-05-11-remove-diagram-skills-qa-report.md \
         2026-05-11-routing-mermaid-drawio.md \
         2026-05-12-mermaid-file-based-qa-report.md; do
  p="content/60-implementation/test-reports/$f"
  assert_file_exists "$p" "AC-3: тест-отчёт $f переехал"
  [ -f "$p" ] && assert_grep "$p" "value: [Тест-отчёт]" "AC-7: $f имеет тип Тест-отчёт"
done

for f in 2026-05-08-diagram-on-demand-acceptance.md \
         2026-05-11-remove-diagram-skills-acceptance.md \
         2026-05-11-routing-mermaid-drawio.md; do
  p="content/60-implementation/acceptance/$f"
  assert_file_exists "$p" "AC-3: приёмка $f переехала"
  [ -f "$p" ] && assert_grep "$p" "value: [Приёмка]" "AC-7: $f имеет тип Приёмка"
done

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006: 7 отчётов мигрированы"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-006-reports-migrated.sh`
Expected: FAIL — `docs/qa-reports` ещё существует.

- [ ] **Step 3: Переместить файлы**

Оба каталога содержат файл `2026-05-11-routing-mermaid-drawio.md` — это разные документы, коллизии нет, они едут в разные подкаталоги.

Run:
```bash
mkdir -p content/60-implementation/test-reports content/60-implementation/acceptance
git mv docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md content/60-implementation/test-reports/
git mv docs/qa-reports/2026-05-11-remove-diagram-skills-qa-report.md content/60-implementation/test-reports/
git mv docs/qa-reports/2026-05-11-routing-mermaid-drawio.md content/60-implementation/test-reports/
git mv docs/qa-reports/2026-05-12-mermaid-file-based-qa-report.md content/60-implementation/test-reports/
git mv docs/acceptance/2026-05-08-diagram-on-demand-acceptance.md content/60-implementation/acceptance/
git mv docs/acceptance/2026-05-11-remove-diagram-skills-acceptance.md content/60-implementation/acceptance/
git mv docs/acceptance/2026-05-11-routing-mermaid-drawio.md content/60-implementation/acceptance/
```

- [ ] **Step 4: Проставить frontmatter четырём тест-отчётам**

Вставить в начало каждого файла в `content/60-implementation/test-reports/`:

```yaml
---
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---
```

- [ ] **Step 5: Проставить frontmatter трём документам приёмки**

Вставить в начало каждого файла в `content/60-implementation/acceptance/`:

```yaml
---
properties:
  - name: Тип контента
    value: [Приёмка]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---
```

- [ ] **Step 6: Создать три индекса**

Create `content/60-implementation/_index.md`:

```markdown
---
title: Реализация
order: 4
---

# Реализация

Артефакты фазы реализации: отчёты прогона тестов и вердикты приёмки.

- [Отчёты прогона](test-reports/_index.md)
- [Приёмка](acceptance/_index.md)
```

Create `content/60-implementation/test-reports/_index.md`:

```markdown
---
title: Отчёты прогона
order: 1
---

# Отчёты прогона

Результаты прогона тестовых suite по фичам плагина.

- [Diagram-on-demand](2026-05-08-diagram-on-demand-qa-report.md)
- [Удаление diagram-скиллов](2026-05-11-remove-diagram-skills-qa-report.md)
- [Роутинг mermaid и drawio](2026-05-11-routing-mermaid-drawio.md)
- [Mermaid file-based](2026-05-12-mermaid-file-based-qa-report.md)
```

Create `content/60-implementation/acceptance/_index.md`:

```markdown
---
title: Приёмка
order: 2
---

# Приёмка

Вердикты по критериям приёмки: покрыты ли AC требования реализацией.

- [Diagram-on-demand](2026-05-08-diagram-on-demand-acceptance.md)
- [Удаление diagram-скиллов](2026-05-11-remove-diagram-skills-acceptance.md)
- [Роутинг mermaid и drawio](2026-05-11-routing-mermaid-drawio.md)
```

- [ ] **Step 7: Дописать раздел в корневой индекс**

Добавить строку в список «Разделы» в `content/_index.md`, после строки про Требования:

```markdown
- [Реализация](60-implementation/_index.md) — отчёты прогона и приёмки
```

- [ ] **Step 8: Прогнать тест и валидатор**

Run:
```bash
bash tests/gramax/nauta-integration/ac-006-reports-migrated.sh
uv run scripts/validate-content.py
```
Expected: `[PASS] ac-006: 7 отчётов мигрированы`; валидатор exit 0, ноль errors.

- [ ] **Step 9: Проверить, что в `docs/` осталось ровно два файла**

Run: `find docs -type f | sort`
Expected: ровно `docs/overlays/profiles/.gitkeep`, `docs/superpowers/plans/2026-05-08-apply-project-template.md`, `docs/superpowers/plans/2026-08-07-nauta-integration.md`, `docs/superpowers/specs/2026-05-08-apply-project-template-design.md`, `docs/superpowers/specs/2026-08-07-nauta-integration-design.md`.

- [ ] **Step 10: Commit**

```bash
git add -A content docs tests/gramax/nauta-integration
git commit -m "refactor(content): перенести отчёты прогона и приёмки

qa-reports → 60-implementation/test-reports, acceptance →
60-implementation/acceptance. Разделены намеренно: вердикт BA по AC и
результат прогона QA — артефакты разных ролей.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Починка ссылок на переехавшие файлы

Покрывает AC-14.

**Files:**
- Modify: `plugins/gramax/CHANGELOG.md:52`, `plugins/gramax/CHANGELOG.md:96`
- Modify: комментарии-заголовки в `tests/gramax/remove-diagram-skills/*.sh`
- Create: `tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh`

**Interfaces:**
- Consumes: пути из Tasks 5–7.
- Produces: ничего для следующих задач.

- [ ] **Step 1: Написать падающий тест AC-007**

Примеры вида `docs/auth/overview.md` в `SKILL.md` и `README.md` под паттерн не подпадают — это чужой Gramax-каталог в документации скилла, а не пути этого репозитория.

Create `tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-10
# AC coverage:
#   AC-14 → нет ссылок на docs/adr, docs/qa-reports, docs/acceptance, docs/research

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
PATTERN='docs/(adr|qa-reports|acceptance|research)'

# scripts/ вне области: доставленные sync-scripts валидаторы — чужие файлы под управлением
# .nauta-scripts-basis.yaml (validate-content.py несёт "docs/adr/" в собственном комментарии),
# править их нельзя. tests/gramax/nauta-integration/ исключён: этот suite обязан называть
# старые пути в ассертах их отсутствия.
HITS="$(grep -rnE "$PATTERN" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -v '^tests/gramax/nauta-integration/' || true)"

if [ -n "$HITS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие каталоги:" >&2
  echo "$HITS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: ссылок на старые пути docs/ не осталось"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh`
Expected: FAIL — 2 строки в `plugins/gramax/CHANGELOG.md` и комментарии в `tests/gramax/remove-diagram-skills/*.sh`.

- [ ] **Step 3: Починить CHANGELOG плагина**

В `plugins/gramax/CHANGELOG.md` заменить:
- `` `docs/adr/0010-mermaid-file-based-workflow.md` `` → `` `content/00-project/adr/0010-mermaid-file-based-workflow.md` ``
- `` `docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md` `` → `` `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` ``

- [ ] **Step 4: Починить комментарии в тестах**

Run:
```bash
cd "$(git rev-parse --show-toplevel)"
sed -i '' \
  -e 's|docs/superpowers/specs/2026-05-11-remove-diagram-skills\.md|content/30-requirements/2026-05-11-remove-diagram-skills.md|g' \
  -e 's|docs/adr/|content/00-project/adr/|g' \
  tests/gramax/remove-diagram-skills/*.sh
```

- [ ] **Step 5: Проверить, что правки не задели ассерты**

`sed` прошёл по всем `.sh` каталога, включая тела тестов. Убеждаемся, что затронуты только строки комментариев.

Run: `git diff --stat tests/gramax/remove-diagram-skills/ && git diff tests/gramax/remove-diagram-skills/ | grep '^[+-]' | grep -v '^[+-][+-]' | grep -v '^[+-]#'`
Expected: второй grep не даёт вывода — изменены только строки, начинающиеся с `#`.

- [ ] **Step 6: Прогнать тест и весь suite remove-diagram-skills**

Run:
```bash
bash tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
bash tests/gramax/remove-diagram-skills/run.sh 2>&1 | grep -E 'Passed:|Failed:'
```
Expected: `[PASS] ac-007: …`; счёт suite — ровно `Passed: 11`, `Failed: 5`, как в baseline до правки. Suite не зелёный и до перехода: пять его ассертов привязаны к версии `2.0.0`, а в манифесте `4.1.0`. Задача `sed` — не сломать оставшиеся 11, а не починить эти 5.

- [ ] **Step 7: Commit**

```bash
git add -A plugins tests
git commit -m "docs: обновить ссылки на переехавшие в content/ документы

CHANGELOG плагина и комментарии-заголовки AC-тестов. Примеры чужого
Gramax-каталога в SKILL.md и README.md не тронуты — это не пути
этого репозитория.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-10

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 4 — Подключение гейта

### Task 9: `validate-content.py` в `check.sh`

Подключается только сейчас: раньше pre-commit блокировал бы собственные коммиты миграции. Покрывает AC-9, AC-15.

**Files:**
- Modify: `scripts/check.sh:1-11` (шапка), после строки 45 (новый блок)
- Create: `tests/gramax/nauta-integration/ac-008-check-includes-validator.sh`

**Interfaces:**
- Consumes: `uv run scripts/validate-content.py` из Task 3, валидный `content/` из Tasks 4–7.
- Produces: `bash scripts/check.sh --fast` с тремя проверками.

- [ ] **Step 1: Написать падающий тест AC-008**

Create `tests/gramax/nauta-integration/ac-008-check-includes-validator.sh`:

```bash
#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-008-check-includes-validator.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7
# AC coverage:
#   AC-9 → check.sh --fast включает validate-content.py и зелёный

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_grep "scripts/check.sh" "validate-content.py" \
  "AC-9: check.sh должен вызывать валидатор content/"
assert_grep "scripts/check.sh" "uv run" \
  "AC-9: валидатор должен запускаться через uv run (PEP 723)"
assert_no_grep "scripts/check.sh" "validate-profile.py" \
  "профильный валидатор не подключается — профилей в gramax нет"

set +e
OUT="$(bash scripts/check.sh --fast 2>&1)"
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-9: check.sh --fast exit=$RC" >&2
  echo "$OUT" | tail -20 >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$OUT" | grep -q "content"; then
  echo "  FAIL: AC-9: в выводе check.sh нет шага проверки content/" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: check.sh --fast включает validate-content.py и зелёный"
```

- [ ] **Step 2: Прогнать — должен упасть**

Run: `bash tests/gramax/nauta-integration/ac-008-check-includes-validator.sh`
Expected: FAIL — в `scripts/check.sh` нет `validate-content.py`.

- [ ] **Step 3: Обновить шапку `scripts/check.sh`**

Заменить строки 2–7 (`# scripts/check.sh — light pre-commit…` до `#   --full : …`) на:

```bash
# scripts/check.sh — light pre-commit/pre-merge gate для gramax-marketplace.
# Без profile-валидаторов (профилей нет). Валидатор content/ — из nauta,
# доставлен через /nauta:sync-scripts, обновляется тем же каналом.
#
# Modes:
#   --fast   : whitespace + JSON validity + validate-content.py (для pre-commit hook)
#   --full   : --fast + shellcheck (если установлен) + проверка submodule status
```

- [ ] **Step 4: Добавить блок валидатора**

Вставить после блока JSON (после строки `fi`, закрывающей секцию 2, перед комментарием `# --- 3. (--full only) Shellcheck…`):

```bash
# --- 2.5. Gramax content/ validation (валидатор nauta, PEP 723) ---
echo "==> content"
if [ -d content ]; then
  if command -v uv > /dev/null 2>&1; then
    if ! uv run scripts/validate-content.py; then
      echo "FAIL: content/ validation"
      FAILED=1
    else
      echo "OK: content validated"
    fi
  else
    echo "WARN: uv not installed — skipping content validation"
  fi
else
  echo "OK: no content/ directory"
fi
```

- [ ] **Step 5: Прогнать тест**

Run: `bash tests/gramax/nauta-integration/ac-008-check-includes-validator.sh`
Expected: `[PASS] ac-008: check.sh --fast включает validate-content.py и зелёный`

- [ ] **Step 6: Сверить регресс с baseline (AC-15)**

Новые suite обязаны быть зелёными. Четыре старых — не зелёные и до перехода; проверяется, что их счёт не ухудшился.

Run:
```bash
bash scripts/check.sh --fast; echo "check.sh exit=$?"
bash tests/gramax/nauta-integration/run.sh; echo "nauta-integration exit=$?"
bash tests/gramax/orphan-references/run.sh; echo "orphan exit=$?"
for s in remove-diagram-skills/run.sh routing-mermaid-drawio/run-all.sh mermaid-file-based/run.sh diagram-on-demand/run.sh; do
  echo "--- $s"
  bash "tests/gramax/$s" 2>&1 | grep -E 'Passed:|Failed:|passed=|failed='
done
```

Expected: три первых — exit 0. Далее ровно baseline, замеренный до перехода:

| Suite | passed | failed |
|---|---|---|
| `remove-diagram-skills` | 11 | 5 |
| `routing-mermaid-drawio` | 15 | 3 |
| `mermaid-file-based` | 2 | 11 |
| `diagram-on-demand` | 1 | 11 |

Если `passed` где-то уменьшилось или `failed` выросло — переход что-то сломал, останови задачу и разбирайся. Если числа совпали — красные ассерты предшествуют переходу и чинятся отдельной работой (см. «Вне скоупа» спеки), не здесь.

- [ ] **Step 7: Commit**

```bash
git add scripts/check.sh tests/gramax/nauta-integration
git commit -m "build: подключить validate-content.py к check.sh --fast

Гейт включается последним: раньше pre-commit блокировал бы коммиты
самой миграции. Запуск через uv run — зависимости по PEP 723.
validate-profile.py намеренно не подключается: профилей в gramax нет.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 5 — Документация

### Task 10: `CLAUDE.md` и `AGENTS.md`

Покрывает AC-13.

**Files:**
- Modify: `CLAUDE.md` (карта команды, архитектурные правила, красные линии, self-improvement, команды сборки)
- Modify: `AGENTS.md` (каталог ролей, контракт вызова, пример промпта)

**Interfaces:**
- Consumes: пути `content/` из Tasks 5–7, реестр sunset из Task 1.
- Produces: ничего для следующих задач.

- [ ] **Step 1: Переписать «Карту команды» в `CLAUDE.md`**

Заменить таблицу под `## Карта команды`:

```markdown
| Команда | Роль | Где исполняется | Артефакты |
|---------|------|----------------|-----------|
| `/nauta:pm` | PM (orchestrator) | main (Opus) | Декомпозиция, координация |
| `/nauta:pm-review` | PM | main (Opus) | Финальная валидация перед merge в main |
| `/nauta:research` | Researcher | subagent (Sonnet) | `content/10-domain/research/` |
| `/nauta:ba` | BA | subagent (Sonnet) | `content/30-requirements/` |
| `/nauta:sa` | SA | subagent (Sonnet) | `content/00-project/adr/`, `content/40-architecture/` |
| `/nauta:dev` | Dev | subagent (Sonnet) | Код в `plugins/gramax/` (TDD) |
| `/nauta:qa` | QA (author/runner) | subagent (Sonnet) | `content/60-implementation/test-reports/` |
| `/nauta:tech-writer` | Tech-writer | subagent (Sonnet) | README, CHANGELOG, marketplace descriptions |
| `/nauta:devsecops` | DevSecOps (opt-in) | subagent (Sonnet) | Secrets sweep перед публичным релизом |

Роли приходят из плагина `nauta` (user-scope, `nauta@nauta`). Собственных агентов
репозиторий не держит. Полная матрица и контракт вызова — в **AGENTS.md**.
```

- [ ] **Step 2: Поправить «Архитектурные правила» в `CLAUDE.md`**

Удалить строку `- Локальный CTO-инструментарий (агенты PM/BA/SA/...) — в `.claude/plugins/project/`, не в `plugins/` (не публикуется).` и заменить строку про ADR:

```markdown
- Skills и команды плагина — в `plugins/<name>/skills/` и `plugins/<name>/commands/`.
- Артефакты продукта (ADR, требования, research, отчёты) — в `content/` по таксономии Gramax.
  Мета-артефакты о самом репозитории и процессе (спеки по тулингу, планы исполнения) — в `docs/`.
- Решения по структуре marketplace, разделению плагинов, изменению manifests — через ADR
  (`content/00-project/adr/`).
```

- [ ] **Step 3: Обновить «Команды сборки и проверки» в `CLAUDE.md`**

```markdown
- `bash scripts/check.sh --fast` — pre-commit gate (whitespace, JSON, валидация `content/`).
- `uv run scripts/validate-content.py` — только валидация Gramax-каталога.
- `bash scripts/install-hooks.sh` — активировать `.githooks/pre-commit` (опционально).
- `bash tests/gramax/orphan-references/run.sh` — гейт остаточных ссылок на удалённое.
- Для распространения: `git push` → пользователи получают через
  `/plugin marketplace add mdemyanov/gramax-plugin`.
```

- [ ] **Step 4: Добавить sunset-правило в «Красные линии» `CLAUDE.md`**

Добавить пункт:

```markdown
- Удаляя skill или script — добавь его имя в `tests/gramax/orphan-references/sunset-registry.txt`
  и прогони `grep -rn '<имя>' .` по репозиторию. Остаточные ссылки на удалённое ловятся гейтом,
  а не глазами на ревью.
```

- [ ] **Step 5: Обновить «Self-improvement» в `CLAUDE.md`**

Заменить путь журнала:

```markdown
- `content/lessons-learned.md` — append-only журнал.
- Субагенты сохраняют находки в auto-memory (типы: `reference`, `project`, `feedback`).
- `/nauta:pm-review` читает lessons + memory и предлагает обновления `CLAUDE.md` / промптов.
```

- [ ] **Step 6: Переписать «Каталог ролей» в `AGENTS.md`**

```markdown
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
```

- [ ] **Step 7: Усилить «Контракт вызова субагента» в `AGENTS.md`**

Добавить абзац после списка из четырёх пунктов:

```markdown
**Конвенции передавай в промпте, а не надейся, что агент их прочитает.** Из десяти агентов
nauta только три вообще упоминают `CLAUDE.md`, и то точечно (секции «Стек», «Команды сборки»);
`AGENTS.md` не читает ни один. Целевой путь артефакта, таксономию `content/` и красные линии
включай в текст задачи явно.
```

- [ ] **Step 8: Обновить пример промпта в `AGENTS.md`**

```
Цель: добавить skill `gramax:diagrams-export` в плагин gramax.
Входы: content/30-requirements/2026-05-09-diagrams-export-design.md,
       plugins/gramax/skills/mermaid/SKILL.md (для стиля),
       tests/gramax/diagrams-export/ac-001-skill-exists.sh (failing stub от qa-author)
Артефакт: plugins/gramax/skills/diagrams-export/SKILL.md
Критерии: suite из tests/gramax/diagrams-export/ зелёный, обновлён plugins/gramax/CHANGELOG.md,
          AC из требования покрыты, bash scripts/check.sh --fast зелёный.
```

- [ ] **Step 9: Проверить AC-13**

Run:
```bash
grep -rn 'plugins/project' CLAUDE.md AGENTS.md; echo "exit=$?"
grep -c 'nauta' CLAUDE.md AGENTS.md
bash tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
```
Expected: первый grep — пусто, `exit=1`; счётчики `nauta` больше нуля в обоих файлах; ac-007 зелёный.

- [ ] **Step 10: Прогнать полный гейт**

Run:
```bash
bash scripts/check.sh --fast
bash tests/gramax/nauta-integration/run.sh
bash tests/gramax/orphan-references/run.sh
```
Expected: все exit 0.

- [ ] **Step 11: Commit**

```bash
git add CLAUDE.md AGENTS.md
git commit -m "docs: перевести CLAUDE.md и AGENTS.md на роли nauta

Карта команды — на /nauta:*, пути артефактов — на content/. Контракт
вызова субагента усилен: конвенции передаются в промпте, потому что
AGENTS.md не читает ни один агент nauta, а CLAUDE.md — только три и
точечно. devops и compliance выключены с обоснованием.

Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-9

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 6 — Пиннинг

### Task 11: Закрепить версию nauta

Правка пользовательского конфига вне репозитория — в коммит не попадает. Покрывает AC-2.

**Files:**
- Modify: `~/.claude/settings.json` → `extraKnownMarketplaces.nauta.source`

**Interfaces:**
- Consumes: ничего.
- Produces: воспроизводимую версию плагина для всех проектов пользователя.

- [ ] **Step 1: Показать текущее состояние**

Run: `python3 -c "import json;print(json.dumps(json.load(open('$HOME/.claude/settings.json'))['extraKnownMarketplaces']['nauta'],ensure_ascii=False,indent=1))"`
Expected: объект `source` с `source: git` и `url`, **без** ключа `ref`.

- [ ] **Step 2: Сделать резервную копию**

Run: `cp ~/.claude/settings.json ~/.claude/settings.json.bak-nauta-pin`

- [ ] **Step 3: Добавить `ref`**

`ref` — единственный узел пиннинга у nauta: источник плагина внутри её `marketplace.json` задан относительным путём `"./"`, который полей не несёт.

Отредактировать `~/.claude/settings.json`, привести запись к виду:

> Хост в `url` ниже замаскирован 2026-08-10: репозиторий публичный, и публиковать в нём
> адрес внутренней инфраструктуры компании не нужно. Это редактура ради нераскрытия хоста,
> а не правка исторического решения — сам шаг и его результат (закрепление `ref`) не
> менялись.

```json
    "nauta": {
      "source": {
        "source": "git",
        "url": "https://<внутренний-хост>/tools-ai/nauta.git",
        "ref": "v0.2.1"
      }
    }
```

- [ ] **Step 4: Проверить валидность и содержимое (AC-2)**

Run:
```bash
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "JSON OK"
python3 -c "import json;print(json.load(open('$HOME/.claude/settings.json'))['extraKnownMarketplaces']['nauta']['source'].get('ref'))"
```
Expected: `JSON OK`, затем `v0.2.1`.

- [ ] **Step 5: Убедиться, что тег существует в репозитории плагина**

Run: `git -C ~/.claude/plugins/marketplaces/nauta tag -l 'v0.2.*'`
Expected: в списке есть `v0.2.1`. Если тега нет — останови задачу и сообщи: пиннинг на несуществующий тег сломает загрузку плагина. Запасной вариант — `"ref": "stable"` с пометкой, что ветка движется.

- [ ] **Step 6: Финальная верификация всего перехода**

Run:
```bash
cd "$(git rev-parse --show-toplevel)"
bash scripts/check.sh --fast
bash tests/gramax/nauta-integration/run.sh
bash tests/gramax/orphan-references/run.sh
uv run scripts/validate-content.py
git status --short
```
Expected: все exit 0; `git status` чист (правка `~/.claude/settings.json` вне репозитория).

---

## Проверка покрытия спеки

| Требование | Задача |
|---|---|
| FR-1 удаление плагина | Task 2 |
| FR-2 пиннинг nauta | Task 11 |
| FR-3 миграция документов | Tasks 5, 6, 7 |
| FR-4 контракт `.doc-root.yaml` | Task 4 |
| FR-5 frontmatter статей | Tasks 5, 6, 7 |
| FR-6 файлы `_index.md` | Tasks 4, 5, 6, 7 |
| FR-7 гейт `validate-content.py` | Tasks 3, 9 |
| FR-8 orphan-гейт | Task 1 |
| FR-9 `CLAUDE.md` и `AGENTS.md` | Task 10 |
| FR-10 починка ссылок | Task 8 |

| AC | Задача |
|---|---|
| AC-1 плагин удалён | Task 2 |
| AC-2 `ref: v0.2.1` | Task 11 |
| AC-3 24 файла в `content/` | Tasks 5, 6, 7 |
| AC-4 `git log --follow` | Task 5 Step 8 |
| AC-5 мета осталась в `docs/` | Task 6 |
| AC-6 валидатор зелёный | Tasks 4, 5, 6, 7 |
| AC-7 «Тип контента» везде | Tasks 5, 6, 7 |
| AC-8 статусы ADR из реестра | Task 5 |
| AC-9 `check.sh` с валидатором | Task 9 |
| AC-10 свои гейты не тронуты | Task 3 |
| AC-11 `tests/project/` удалён | Tasks 1, 2 |
| AC-12 orphan-гейт живой | Task 1 Step 4 |
| AC-13 `CLAUDE.md`/`AGENTS.md` на nauta | Task 10 |
| AC-14 нет старых путей | Task 8 |
| AC-15 регресс зелёный | Task 9 Step 6 |
