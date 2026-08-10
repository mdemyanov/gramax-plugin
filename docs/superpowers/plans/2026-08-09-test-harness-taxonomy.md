# Test Harness Taxonomy & doc-paths Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Разделить `tests/gramax/` на замороженный архив свидетельств приёмки и два живых гейта, закрыть два дефекта v4.1.0, которые вскрыл разбор, и вычистить нерабочие `docs/`-указатели внутри `content/`.

**Architecture:** Каждый из четырёх красных suite смешивал свидетельство приёмки релиза (версионные пины, синтаксис, канонический на момент поставки) с инвариантом, который обязан держаться всегда. Живые ассерты извлекаются в новый `tests/gramax/plugin-contract/`, остаток замораживается в `tests/gramax/archive/` без единой правки, `diagram-on-demand` удаляется целиком. Проверки «удалённый артефакт больше не упоминается» не дублируются в suite, а поглощаются существующим реестром `orphan-references`. Указатели в `content/` чинятся, исторические записи остаются дословно и защищаются allowlist'ом нового гейта `doc-paths`.

**Tech Stack:** bash (suite и гейты, без внешних зависимостей), Python 3 stdlib (разбор JSON-манифестов внутри ассертов), `uv run` для валидаторов nauta, git (`git mv`/`git rm` для сохранения истории).

## Источники

- Требование: `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` (FR-001…FR-034, AC-001…AC-035 — FR-034/AC-035 добавлены 2026-08-10 по итогам финального ревью, см. задачу 9)
- ADR: `content/00-project/adr/0011-test-harness-taxonomy.md` (Решения 1-6)
- Диспозиция путей: `docs/doc-paths-disposition.md`

## Global Constraints

- Ни один коммит — включая промежуточные — не оставляет `bash scripts/check.sh --fast` или `--full` красным (NFR-001). Новый suite подключается к `check.sh` **только после** того, как стал зелёным.
- Перемещения — только `git mv`, удаления — только `git rm`. Delete + create недопустим (NFR-002).
- Python-валидаторы запускаются только через `uv run` (NFR-003).
- `scripts/*.py` и `scripts/apply-overlay.sh` — чужие файлы под `.nauta-scripts-basis.yaml`, править запрещено. `scripts/check.sh` — файл проекта, править можно.
- `tests/gramax/archive/**` после коммита переезда не редактируется никогда. Ни `>=`, ни обновления пинов до текущей версии (BR-001).
- Корневой `.claude-plugin/marketplace.json` — меняется ровно одно поле `metadata.version`. Поля `name`, `owner`, `plugins[]` неприкосновенны (NFR-005, ADR-0011 Решение 6).
- Коммит без `--no-verify`. Pre-commit хук не установлен — `bash scripts/check.sh --fast` запускается явно перед каждым коммитом.
- Платформа darwin: `sed -i ''` (с пустым аргументом), не `sed -i`.
- Паттерны `sunset-registry.txt` опознают артефакт по пути или способу вызова, никогда по голому слову (ADR-0011 Решение 3).

## File Structure

**Создаются:**

| Файл | Ответственность |
|---|---|
| `tests/gramax/archive/README.md` | Что заморожено, за приёмку какой версии отвечало, почему не запускается; ретировка AC про поле `skills` |
| `tests/gramax/archive/mermaid-file-based/verify.sh` | Ручной верификатор выхода `gramax:mermaid`, принимает `<output-dir>` |
| `tests/gramax/plugin-contract/lib/assert.sh` | Копия общей assert-библиотеки (suite самодостаточен) |
| `tests/gramax/plugin-contract/run.sh` | Агрегатор `ac-*.sh` |
| `tests/gramax/plugin-contract/README.md` | Таблица «категория FR → файл ac-*.sh» |
| `tests/gramax/plugin-contract/ac-001…ac-007*.sh` | Роутинг, формат тега, writer-справочник, README, mermaid-контракт, манифесты |
| `tests/gramax/doc-paths/lib/scan.sh` | Ядро гейта: скан + разбор allowlist + проверка свежести. Переиспользуется ассертом и фикстурой |
| `tests/gramax/doc-paths/run.sh` | Агрегатор `ac-*.sh` |
| `tests/gramax/doc-paths/allowlist.txt` | 14 точечных записей + 2 whole-file |
| `tests/gramax/doc-paths/ac-001-no-stale-pointers.sh` | Гейт против живого `content/` |
| `tests/gramax/doc-paths/ac-002-stale-allowlist-detected.sh` | Гейт против фикстуры: рассинхрон обязан быть замечен |
| `tests/gramax/doc-paths/fixtures/stale-allowlist/` | Заведомо рассинхронизированная пара «content + allowlist» |
| `docs/onboarding-nauta.md` | Онбординг контрибьютора на чистой машине |
| `.claude/settings.local.json.example` | Шаблон локального включения nauta |

**Изменяются:**

| Файл | Что |
|---|---|
| `tests/gramax/orphan-references/run.sh` | `EXCLUDE_RE` → один паттерн `^tests/gramax/archive/` |
| `tests/gramax/orphan-references/sunset-registry.txt` | +3 паттерна по форме из ADR-0011 Решение 3 |
| `scripts/check.sh` | Убрать 3 мёртвых guard'а `claude-mermaid`; подключить два новых suite |
| `plugins/gramax/skills/writer/SKILL.md` | Строки 229-243: старый тег → `<drawio path=…/>` |
| `plugins/gramax/README.md` | Строка 39: тег; новый WARNING-блок |
| `plugins/gramax/CHANGELOG.md` | Секция `## 4.1.1` |
| `plugins/gramax/.claude-plugin/plugin.json` | `version` → `4.1.1` |
| `.claude-plugin/marketplace.json` | `metadata.version` → `4.1.1`, больше ничего |
| 18 файлов в `content/` | 41 указатель на новые пути |
| `CLAUDE.md`, `README.md` | Указатели на онбординг |

**Перемещаются (`git mv`):** `tests/gramax/{remove-diagram-skills,routing-mermaid-drawio,mermaid-file-based}/` → `tests/gramax/archive/`

**Удаляется (`git rm -r`):** `tests/gramax/diagram-on-demand/`

## Порядок задач и почему он такой

1. **Задача 1** — переезд и удаление. Должна быть первой: `EXCLUDE_RE` в задаче 2 ссылается на `^tests/gramax/archive/`.
2. **Задача 2** — очистка `check.sh` + расширение реестра. Порядок внутри задачи жёсткий: паттерн `plugins/claude-mermaid` совпадает с `scripts/check.sh:39` и `:75`, поэтому guard'ы удаляются **до** добавления паттерна, иначе гейт красный (замер PM, FR-013).
3. **Задача 3** — `plugin-contract` красный, **без подключения** к `check.sh`. Подключение красного suite нарушило бы Global Constraint.
4. **Задача 4** — продуктовые фиксы, suite зеленеет, **тогда** подключается.
5. **Задача 5** — `verify.sh` (независима, может идти параллельно 3-4).
6. **Задача 6** — гейт `doc-paths` красный, без подключения.
7. **Задача 7** — починка 41 указателя, гейт зеленеет, подключается.
8. **Задача 8** — онбординг.

---

### Task 1: Реорганизация харнесса — архив и удаление

**Files:**
- Delete: `tests/gramax/diagram-on-demand/` (13 файлов)
- Move: `tests/gramax/remove-diagram-skills/` → `tests/gramax/archive/remove-diagram-skills/`
- Move: `tests/gramax/routing-mermaid-drawio/` → `tests/gramax/archive/routing-mermaid-drawio/`
- Move: `tests/gramax/mermaid-file-based/` → `tests/gramax/archive/mermaid-file-based/`
- Create: `tests/gramax/archive/README.md`
- Modify: `tests/gramax/orphan-references/run.sh` (строки 26-30, `EXCLUDE_RE`)

**Interfaces:**
- Produces: путь `tests/gramax/archive/` — на него ссылается `EXCLUDE_RE` (эта же задача) и `verify.sh` (задача 5).

- [ ] **Step 1: Зафиксировать базовую ревизию для последующей сверки**

```bash
cd <repo-root>
git rev-parse HEAD > <scratchpad>/BASE_REV
cat <scratchpad>/BASE_REV
```

Эта ревизия — аргумент `BASE_REV` для проверки побайтового совпадения архива (AC-003).

- [ ] **Step 2: Удалить diagram-on-demand**

```bash
git rm -r -q tests/gramax/diagram-on-demand
test ! -d tests/gramax/diagram-on-demand && echo "OK: удалён"
```

- [ ] **Step 3: Переместить три suite в архив**

```bash
mkdir -p tests/gramax/archive
git mv tests/gramax/remove-diagram-skills   tests/gramax/archive/remove-diagram-skills
git mv tests/gramax/routing-mermaid-drawio  tests/gramax/archive/routing-mermaid-drawio
git mv tests/gramax/mermaid-file-based      tests/gramax/archive/mermaid-file-based
ls tests/gramax/
```

Ожидается: `archive  nauta-integration  orphan-references`.

- [ ] **Step 4: Проверить, что переезд не изменил содержимое**

```bash
BASE=$(cat <scratchpad>/BASE_REV)
rc=0
for s in remove-diagram-skills routing-mermaid-drawio mermaid-file-based; do
  while IFS= read -r f; do
    rel="${f#tests/gramax/archive/$s/}"
    # Скобки вокруг BASE обязательны: Bash-инструмент исполняет команды через zsh,
    # где "$VAR:tests/…" съедает ':t' как history-модификатор (tail) даже в кавычках.
    if ! git show "${BASE}:tests/gramax/$s/$rel" 2>/dev/null | diff -q - "$f" > /dev/null; then
      echo "DIFF: $f"; rc=1
    fi
  done < <(find "tests/gramax/archive/$s" -type f)
done
[ $rc -eq 0 ] && echo "OK: архив побайтово совпадает с $BASE"
```

Ожидается: `OK: архив побайтово совпадает…`. Любой `DIFF:` — ошибка переезда, откатить и повторить `git mv`.

- [ ] **Step 5: Написать `tests/gramax/archive/README.md`**

Содержание — по FR-002. Обязательные элементы: для каждого из трёх suite исходный путь, версия релиза, приёмку которой suite удостоверяет (`remove-diagram-skills` → 2.0.0, `routing-mermaid-drawio` → 3.0.0, `mermaid-file-based` → 4.0.0); явное «не редактировать, не запускать, не включать в счёт»; отдельный раздел про ретировку AC о поле `skills` в `plugin.json` с обоснованием (замер SA: 53 файла `plugin.json`, 22 плагина, 0 с полем `skills` — skills обнаруживаются автоматически из каталога `skills/`); указание, что `verify.sh` в `mermaid-file-based/` появится задачей 5 и является единственным исполняемым файлом архива, запускаемым вручную; ссылка на `content/00-project/adr/0011-test-harness-taxonomy.md`.

- [ ] **Step 6: Схлопнуть `EXCLUDE_RE`**

В `tests/gramax/orphan-references/run.sh` заменить строки комментария 26-28 и `EXCLUDE_RE` (строка 30). Было:

```bash
# Исторические suite исключены осознанно: remove-diagram-skills проверяет ровно эти имена
# как предмет своих AC, diagram-on-demand покрывает удалённую по ADR-0008 фичу и содержит
# все пять паттернов в 11 файлах. Без этих двух исключений гейт красный с первого прогона.
EXCLUDE_RE='(^|/)CHANGELOG\.md$|^content/00-project/adr/|^content/60-implementation/|^docs/|^tests/gramax/orphan-references/|^tests/gramax/remove-diagram-skills/|^tests/gramax/diagram-on-demand/'
```

Стало:

```bash
# Архив исключён по принципу, а не по списку имён: tests/gramax/archive/ — замороженные
# свидетельства приёмки прошлых релизов, они обязаны называть удалённые артефакты как
# предмет своих ассертов (ADR-0011, Решение 1). CHANGELOG, ADR и отчёты — то же основание.
EXCLUDE_RE='(^|/)CHANGELOG\.md$|^content/00-project/adr/|^content/60-implementation/|^docs/|^tests/gramax/orphan-references/|^tests/gramax/archive/'
```

- [ ] **Step 7: Прогнать гейты**

```bash
bash tests/gramax/orphan-references/run.sh && bash scripts/check.sh --full
```

Ожидается: `PASS: остаточных ссылок…`, затем `==> RESULT: PASS`.

- [ ] **Step 8: Commit**

```bash
bash scripts/check.sh --fast
git add -A tests/ && git commit -m "$(cat <<'EOF'
test(gramax): заморозить свидетельства приёмки в archive/, удалить diagram-on-demand

Три suite переезжают в tests/gramax/archive/ как свидетельства приёмки
2.0.0/3.0.0/4.0.0 — не редактируются и не запускаются (ADR-0011 Решение 1).
diagram-on-demand удалён: покрываемая функциональность снята ADR-0008
без остатка, факт приёмки живёт в content/60-implementation/acceptance/.

EXCLUDE_RE выражает принцип «архив не считается остаточной ссылкой»
вместо перечня исторических имён suite.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Мёртвые guard'ы `check.sh` и расширение реестра

**Files:**
- Modify: `scripts/check.sh:38-39, 75`
- Modify: `tests/gramax/orphan-references/sunset-registry.txt`

**Interfaces:**
- Consumes: `^tests/gramax/archive/` в `EXCLUDE_RE` (задача 1) — без него новые паттерны ловят архив.
- Produces: расширенный реестр; на него опирается AC-016.

**Порядок шагов внутри задачи обязателен:** паттерн `plugins/claude-mermaid` совпадает с `scripts/check.sh:39` и `:75`. Добавить паттерн раньше очистки — красный гейт.

- [ ] **Step 1: Убрать мёртвые guard'ы из `scripts/check.sh`**

Строки 38-39, удалить обе:

```bash
    # Skip submodule contents (claude-mermaid)
    if [[ "$f" == plugins/claude-mermaid/* ]]; then continue; fi
```

Строка 75, было:

```bash
    SH_FILES=$(git ls-files '*.sh' 2>/dev/null | grep -v '^plugins/claude-mermaid/' || true)
```

стало:

```bash
    SH_FILES=$(git ls-files '*.sh' 2>/dev/null || true)
```

- [ ] **Step 2: Убедиться, что упоминаний не осталось**

```bash
grep -c 'claude-mermaid' scripts/check.sh
```

Ожидается: `0`.

- [ ] **Step 3: Прогнать `--full` до расширения реестра**

```bash
bash scripts/check.sh --full
```

Ожидается: `==> RESULT: PASS`. Это контрольная точка: удаление guard'ов ничего не сломало (submodule'а нет с v3.0.0, фильтровать нечего).

- [ ] **Step 4: Расширить `sunset-registry.txt`**

Дописать в конец файла:

```
#
# 2026-05-11, ADR-0009 — удаление vendored submodule claude-mermaid:
plugins/claude-mermaid([^a-zA-Z0-9-]|$)
#
# 2026-05-11, ADR-0008 — удаление skill'ов diagrams и diagram-on-demand.
# Паттерн опознаёт артефакт по пути или способу вызова, не по слову (ADR-0011 Решение 3):
# голое `diagrams` ловит прозу о действующем workflow (writer/references/staging.md,
# drawio.md) и вымышленный пример gramax:diagrams-export в AGENTS.md; голое
# `diagram-on-demand` ловит имена переехавших документов в ассертах nauta-integration.
skills/diagrams([^a-zA-Z0-9-]|$)|gramax:diagrams([^a-zA-Z0-9-]|$)
skills/diagram-on-demand([^a-zA-Z0-9-]|$)|gramax:diagram-on-demand([^a-zA-Z0-9-]|$)
```

- [ ] **Step 5: Проверить гейт в обе стороны**

```bash
bash tests/gramax/orphan-references/run.sh
```

Ожидается: `PASS: остаточных ссылок на удалённые артефакты нет.`

Контроль негативной стороны — эти три обязаны остаться незамеченными:

```bash
grep -nE 'skills/diagrams([^a-zA-Z0-9-]|$)|gramax:diagrams([^a-zA-Z0-9-]|$)' \
  plugins/gramax/skills/writer/references/staging.md \
  plugins/gramax/skills/writer/references/drawio.md \
  AGENTS.md || echo "OK: легитимные упоминания не задеты"
```

Ожидается: `OK: легитимные упоминания не задеты`.

Контроль позитивной стороны:

```bash
printf 'skills/diagrams/SKILL.md\nskills/diagram-on-demand/\nplugins/claude-mermaid/x\n' \
| grep -cE 'skills/diagrams([^a-zA-Z0-9-]|$)|skills/diagram-on-demand([^a-zA-Z0-9-]|$)|plugins/claude-mermaid([^a-zA-Z0-9-]|$)'
```

Ожидается: `3`.

- [ ] **Step 6: Commit**

```bash
bash scripts/check.sh --fast
git add scripts/check.sh tests/gramax/orphan-references/sunset-registry.txt
git commit -m "$(cat <<'EOF'
test(gramax): внести claude-mermaid и удалённые skill'ы в sunset-registry

Реестр опознаёт артефакт по пути или способу вызова, не по голому слову:
голое diagram-on-demand ловит имена переехавших документов в ассертах
nauta-integration и красит сегодня зелёный гейт (ADR-0011 Решение 3).

Мёртвые guard'ы claude-mermaid в check.sh удалены до расширения реестра —
паттерн plugins/claude-mermaid совпал бы с ними.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Suite `plugin-contract` (красный, без подключения)

**Files:**
- Create: `tests/gramax/plugin-contract/lib/assert.sh`, `run.sh`, `README.md`, `ac-001…ac-007`

**Interfaces:**
- Consumes: `tests/gramax/nauta-integration/lib/assert.sh` — копируется как есть, чтобы suite был самодостаточен (тот же приём, что у существующих suite).
- Produces: `tests/gramax/plugin-contract/run.sh` — подключается к `check.sh` в задаче 4.

**Ожидаемый результат задачи: 5 PASS / 2 FAIL.** Красные — `ac-002` (формат тега, негативная часть) и `ac-004` (WARNING в README). Это два реальных дефекта v4.1.0, их чинит задача 4. Suite **не подключается** к `check.sh` в этой задаче.

- [ ] **Step 1: Скопировать assert-библиотеку**

```bash
mkdir -p tests/gramax/plugin-contract/lib
cp tests/gramax/nauta-integration/lib/assert.sh tests/gramax/plugin-contract/lib/assert.sh
sed -i '' 's|tests/gramax/nauta-integration/lib/assert.sh|tests/gramax/plugin-contract/lib/assert.sh|' \
  tests/gramax/plugin-contract/lib/assert.sh
head -3 tests/gramax/plugin-contract/lib/assert.sh
```

- [ ] **Step 2: Скопировать агрегатор**

```bash
cp tests/gramax/nauta-integration/run.sh tests/gramax/plugin-contract/run.sh
sed -i '' 's|tests/gramax/nauta-integration/run.sh|tests/gramax/plugin-contract/run.sh|' \
  tests/gramax/plugin-contract/run.sh
```

Агрегатор параметризован через `SCRIPT_DIR`, тела менять не требуется (ADR-0011 Решение 5).

- [ ] **Step 3: `ac-001-routing-contract.sh` — роутинг drawio/mermaid (FR-006)**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-001-routing-contract.sh
# Требование: content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md FR-006
# Происхождение: обобщает archive/routing-mermaid-drawio ac-001…008 и
#                archive/remove-diagram-skills ac-014 — живая часть, без версионных пинов.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DRAWIO="$ROOT/plugins/gramax/skills/drawio/SKILL.md"
MERMAID="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$DRAWIO"  "FR-006: skills/drawio/SKILL.md должен существовать"
assert_file_exists "$MERMAID" "FR-006: skills/mermaid/SKILL.md должен существовать"

# Границы скиллов друг относительно друга — обе стороны, иначе роутинг однонаправленный
assert_grep_regex "$DRAWIO" 'НЕ для mermaid|не для mermaid' \
  "FR-006: description drawio обязан явно исключать mermaid"
assert_grep "$DRAWIO" "gramax:mermaid" \
  "FR-006: drawio обязан перекрёстно ссылаться на gramax:mermaid"
assert_grep_regex "$MERMAID" 'НЕ для drawio|не для drawio' \
  "FR-006: description mermaid обязан явно исключать drawio"
assert_grep "$MERMAID" "gramax:drawio" \
  "FR-006: mermaid обязан перекрёстно ссылаться на gramax:drawio"

# Подсказка установки внешнего плагина — без неё делегирование необнаружимо
assert_grep "$DRAWIO" "Agents365-ai" \
  "FR-006: drawio обязан называть внешний плагин Agents365-ai"

# Секции тела
assert_grep_regex "$DRAWIO" '^## Workflow' \
  "FR-006: drawio обязан иметь секцию Workflow"
assert_grep_regex "$DRAWIO" '^## Fallback' \
  "FR-006: drawio обязан иметь секцию Fallback при ambiguous-request"
assert_grep_regex "$MERMAID" 'Fallback|ambiguous' \
  "FR-006: mermaid обязан иметь fallback-секцию с альтернативой drawio"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: контракт роутинга drawio ↔ mermaid соблюдён"
```

- [ ] **Step 4: `ac-002-drawio-tag-format.sh` — формат тега (FR-007). ОЖИДАЕТСЯ КРАСНЫМ**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-002-drawio-tag-format.sh
# Требование: FR-007. Происхождение: archive/remove-diagram-skills ac-008 (часть про тег),
#             archive/routing-mermaid-drawio ac-005 — переформулированы под канон v4.1.0.
# Природа: живой контракт. КРАСНЫЙ до FR-017/FR-018 — недомигрированный тег есть дефект v4.1.0.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
CANON='<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>'

# Позитив: канонический тег задокументирован там, где writer его ищет
assert_grep_regex "$ROOT/plugins/gramax/skills/writer/references/drawio.md" "$CANON" \
  "FR-007: writer/references/drawio.md обязан показывать канонический тег"

# Негатив: ни один живой документ плагина не учит устаревшему синтаксису.
# Исключены: CHANGELOG (история релизов) и blocks.md (явная пометка «устаревший формат»).
STALE=$(grep -rnE '\[drawio:|<Image src' "$ROOT/plugins/gramax" --include='*.md' 2>/dev/null \
        | grep -v '/CHANGELOG\.md:' \
        | grep -v '/references/blocks\.md:' || true)

if [ -n "$STALE" ]; then
  echo "  FAIL: FR-007: живые документы плагина всё ещё учат устаревшему синтаксису тега:" >&2
  echo "$STALE" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: формат drawio-тега канонический во всех живых документах"
```

- [ ] **Step 5: `ac-003-writer-drawio-reference.sh` — структура справочника (FR-008)**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-003-writer-drawio-reference.sh
# Требование: FR-008. Происхождение: archive/remove-diagram-skills ac-008 (структурная часть).
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
REF="$ROOT/plugins/gramax/skills/writer/references/drawio.md"

assert_file_exists "$REF" "FR-008: writer/references/drawio.md должен существовать"
assert_grep "$REF" "Prerequisites"      "FR-008: секция Prerequisites"
assert_grep "$REF" "draw.io desktop"    "FR-008: упоминание draw.io desktop"
assert_grep_regex "$REF" 'Python 3|python3' "FR-008: упоминание Python 3"
assert_grep "$REF" "/plugin marketplace add Agents365-ai/365-skills" \
  "FR-008: команда установки marketplace"
assert_grep "$REF" "/plugin install drawio" "FR-008: команда установки плагина"
assert_grep_regex "$REF" 'двухшаговый|Двухшаговый|Шаг 1' "FR-008: описание двухшагового workflow"
assert_grep_regex "$REF" 'не вставляет|не знает|doc-root' \
  "FR-008: примечание, что drawio-skill не вставляет тег сам"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: структура writer/references/drawio.md соблюдена"
```

- [ ] **Step 6: `ac-004-readme-prerequisites-warning.sh` — README (FR-009). ОЖИДАЕТСЯ КРАСНЫМ**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-004-readme-prerequisites-warning.sh
# Требование: FR-009. Происхождение: archive/remove-diagram-skills ac-009.
# Природа: живой контракт. КРАСНЫЙ до FR-019 — WARNING по ADR-0008 Решение 6 не был добавлен.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
README="$ROOT/plugins/gramax/README.md"

assert_file_exists "$README" "FR-009: plugins/gramax/README.md должен существовать"
assert_grep "$README" "draw.io desktop" "FR-009: prerequisites — draw.io desktop"
assert_grep "$README" "/plugin marketplace add Agents365-ai/365-skills" \
  "FR-009: prerequisites — команда marketplace"
assert_grep "$README" "/plugin install drawio" "FR-009: prerequisites — команда install"
assert_grep_regex "$README" 'Python 3|python3|repair_png' "FR-009: prerequisites — Python 3"

# ADR-0008 Решение 6: предупреждение о конфликте триггеров с чужим mermaid-skill
assert_grep_regex "$README" 'Warning|WARNING|Предупреждение' \
  "FR-009: README обязан нести WARNING о конфликте с Agents365-ai/mermaid-skill"
assert_grep "$README" "mermaid-skill" \
  "FR-009: WARNING обязан называть конфликтующий skill поимённо"
assert_grep_regex "$README" 'недетерминирован' \
  "FR-009: WARNING обязан объяснять последствие — недетерминированный выбор skill'а"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: README несёт prerequisites и WARNING по ADR-0008 Решение 6"
```

- [ ] **Step 7: `ac-005-mermaid-file-based-contract.sh` — контракт mermaid (FR-010)**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-005-mermaid-file-based-contract.sh
# Требование: FR-010. Происхождение: статически проверяемая половина
#             archive/mermaid-file-based (ac-005b, ac-006, ac-008, ac-011).
#             Динамическая половина — archive/mermaid-file-based/verify.sh.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$SKILL" "FR-010: skills/mermaid/SKILL.md должен существовать"
assert_grep "$SKILL" '<page-slug>-<diagram-slug>.mermaid' \
  "FR-010: SKILL.md обязан задавать naming convention файла"
assert_grep "$SKILL" '_index.md' \
  "FR-010: SKILL.md обязан описывать правило _index.md → имя родительского каталога"
assert_grep "$SKILL" '800px' "FR-010: SKILL.md обязан задавать дефолтную ширину"
assert_grep "$SKILL" '450px' "FR-010: SKILL.md обязан задавать дефолтную высоту"
assert_grep_regex "$SKILL" '<mermaid path="[^"]*"[^>]*/>' \
  "FR-010: SKILL.md обязан показывать самозакрывающийся тег"
assert_grep_regex "$SKILL" 'перезаписать|не трогай файл' \
  "FR-010: SKILL.md обязан запрещать молчаливую перезапись"
assert_no_grep "$SKILL" 'inline DSL, без файла' \
  "FR-010: устаревшая формулировка inline-workflow не должна вернуться"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: контракт file-based workflow в mermaid/SKILL.md соблюдён"
```

- [ ] **Step 8: `ac-006-manifest-coherence.sh` — согласованность манифестов (FR-011)**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-006-manifest-coherence.sh
# Требование: FR-011. Происхождение: поглощает шесть версионных пинов трёх архивных suite
#             (remove ac-011/012, routing ac-012/013, mermaid ac-012). Проверяет не число,
#             а инвариант ADR-0006 — синхронность двух манифестов, которая истинна всегда.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"
MARKET_JSON="$ROOT/.claude-plugin/marketplace.json"
CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"

assert_file_exists "$PLUGIN_JSON" "FR-011: plugin.json должен существовать"
assert_file_exists "$MARKET_JSON" "FR-011: marketplace.json должен существовать"

PV=$(python3 -c "import json;print(json.load(open('$PLUGIN_JSON')).get('version','MISSING'))" 2>/dev/null || echo PARSE_ERROR)
MV=$(python3 -c "import json;print(json.load(open('$MARKET_JSON')).get('metadata',{}).get('version','MISSING'))" 2>/dev/null || echo PARSE_ERROR)

assert_eq "$PV" "$MV" \
  "FR-011: версии plugin.json и marketplace.json обязаны совпадать (ADR-0006, синхронное версионирование)"

if [ "$PV" != "MISSING" ] && [ "$PV" != "PARSE_ERROR" ]; then
  assert_grep "$CHANGELOG" "## $PV" \
    "FR-011: CHANGELOG обязан иметь секцию для текущей версии ($PV)"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: манифесты согласованы, CHANGELOG несёт секцию текущей версии"
```

- [ ] **Step 9: `ac-007-retired-skills-field.sh` — ретировка (FR-012)**

```bash
#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-007-retired-skills-field.sh
# Требование: FR-012. Происхождение: archive/routing-mermaid-drawio ac-014 — РЕТИРОВАН.
# Замер SA: 53 файла plugin.json, 22 плагина, 0 с полем skills — skills обнаруживаются
# автоматически из каталога skills/. AC опиралось на ложную посылку (ADR-0011 Решение 2).
# Этот тест сторожит саму ретировку: ассерт на поле skills не должен вернуться в suite.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

REVIVED=$(grep -rlE "get\('skills'\)|\[.skills.\]|\"skills\"" "$SCRIPT_DIR" \
          --include='ac-*.sh' 2>/dev/null | grep -v 'ac-007-retired' || true)

if [ -n "$REVIVED" ]; then
  echo "  FAIL: FR-012: ассерт на поле 'skills' в plugin.json вернулся в suite:" >&2
  echo "$REVIVED" >&2
  echo "  Ретировка обоснована в ADR-0011 Решение 2 и tests/gramax/archive/README.md." >&2
  echo "  Возврат требует новой санкции, а не молчаливого добавления." >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: ретировка AC про поле skills соблюдена"
```

- [ ] **Step 10: `README.md` suite — таблица соответствия**

Создать `tests/gramax/plugin-contract/README.md` с таблицей «FR → файл → происхождение → природа (живой контракт / regression guard)» по семи файлам выше, и явной пометкой, что `ac-002` и `ac-004` создаются красными и зеленеют задачей 4.

- [ ] **Step 11: Сделать исполняемыми и прогнать**

```bash
chmod +x tests/gramax/plugin-contract/*.sh
bash tests/gramax/plugin-contract/run.sh; echo "exit=$?"
```

Ожидается: `Passed: 5`, `Failed: 2`, упавшие — `ac-002-drawio-tag-format.sh` и `ac-004-readme-prerequisites-warning.sh`, `exit=1`.

**Если упало что-то ещё — остановиться и разобраться.** Красным обязаны быть ровно два известных дефекта; третий красный означает либо ошибку в ассерте, либо ещё один невыявленный дефект — в обоих случаях это находка для PM, а не повод ослабить тест.

- [ ] **Step 12: Commit (suite не подключён к check.sh — это задача 4)**

```bash
bash scripts/check.sh --fast
git add tests/gramax/plugin-contract
git commit -m "$(cat <<'EOF'
test(gramax): suite plugin-contract — живые инварианты плагина

Семь ассертов вместо 34 из трёх suite: роутинг, формат тега, структура
writer-справочника, README, контракт mermaid, согласованность манифестов,
сторож ретировки. Версионные пины заменены инвариантом ADR-0006 —
plugin.json и marketplace.json обязаны совпадать, число не фиксируется.

ac-002 и ac-004 красные: недомигрированный тег в writer/SKILL.md и
README, отсутствующий WARNING по ADR-0008 Решение 6. Это дефекты
поставленной v4.1.0, их закрывает следующая задача. Suite подключается
к check.sh --full только после позеленения.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Продуктовые фиксы v4.1.1 и подключение `plugin-contract`

**Files:**
- Modify: `plugins/gramax/skills/writer/SKILL.md:229-243`
- Modify: `plugins/gramax/README.md:39` + новый WARNING-блок
- Modify: `plugins/gramax/CHANGELOG.md` (новая секция сверху)
- Modify: `plugins/gramax/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (только `metadata.version`)
- Modify: `scripts/check.sh` (подключение suite)

**Interfaces:**
- Consumes: `tests/gramax/plugin-contract/run.sh` (задача 3).

- [ ] **Step 1: Прочитать текущее состояние правимых мест**

```bash
sed -n '220,250p' plugins/gramax/skills/writer/SKILL.md
sed -n '35,45p' plugins/gramax/README.md
```

- [ ] **Step 2: `writer/SKILL.md` — заменить примеры тега**

Заменить четыре места (текущие строки 229, 234, 235, 243) на канонический синтаксис:

| Было | Стало |
|---|---|
| `[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]` | `<drawio path="./filename.svg" width="WIDTHpx" height="HEIGHTpx"/>` |
| `[drawio:./architecture.svg:Общая схема процесса:971px:311px]` | `<drawio path="./architecture.svg" width="971px" height="311px"/>` |
| `[drawio:./overview.svg::211px:101px]` | `<drawio path="./overview.svg" width="211px" height="101px"/>` |

Строка 243 (шаг 4 workflow) — было:

```
4. Вставь тег в md вручную: `[drawio:./file.svg:alt:WxHpx]` для Markdown-syntax или `<Image src="./file.svg" />` для XML-syntax (`.doc-root.yaml syntax`).
```

стало:

```
4. Вставь тег в md вручную: `<drawio path="./file.svg" width="800px" height="600px"/>` — единый синтаксис для Markdown и XML (с v4.1.0; `.doc-root.yaml syntax` на формат тега больше не влияет).
```

Формулировка «единый синтаксис для Markdown и XML» обязательна: она объясняет, почему исчезло ветвление по `.doc-root.yaml`, — иначе правка выглядит потерей функциональности.

- [ ] **Step 3: `plugins/gramax/README.md` — тег в шаге 2**

Строка 39, было:

```
- Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат): `[drawio:./diagram.svg:Описание:800px:600px]`.
```

стало:

```
- Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат): `<drawio path="./diagram.svg" width="800px" height="600px"/>`.
```

- [ ] **Step 4: `plugins/gramax/README.md` — WARNING по ADR-0008 Решение 6**

Вставить сразу после блока «Установка внешнего плагина» (перед «Дополнительные зависимости»), дословно из ADR-0008:

```markdown
> **Warning:** Не устанавливайте `Agents365-ai/mermaid-skill` из 365-skills одновременно
> с `gramax:mermaid`. Оба skill'а описывают одинаковые триггеры (flowchart, sequence,
> gantt и др.) — Claude может выбрать не тот, поведение становится недетерминированным.
> Для drawio устанавливайте только `drawio` из 365-skills (не `mermaid`).
```

- [ ] **Step 5: Прогнать suite — обязан позеленеть**

```bash
bash tests/gramax/plugin-contract/run.sh; echo "exit=$?"
```

Ожидается: `Passed: 7`, `Failed: 0`, `exit=0`.

**Если `ac-002` всё ещё красный — прочитать его вывод и починить оставшиеся файлы, а не ослабить ассерт.** Ассерт сканирует весь `plugins/gramax` рекурсивно; он мог найти место, которого нет в списке из FR-017/FR-018.

- [ ] **Step 6: CHANGELOG 4.1.1**

Добавить секцию сразу под заголовком файла, над `## 4.1.0`:

```markdown
## 4.1.1

### Fixed

- `skills/writer/SKILL.md` — примеры и шаг 4 двухшагового workflow учили устаревшему тегу `[drawio:...]` / `<Image src=.../>`; заменено на канонический `<drawio path="..." width="..." height="..."/>`, введённый в 4.1.0. Расхождение с `references/drawio.md` и `references/blocks.md`, где формат уже был обновлён, устранено.
- `README.md` — та же правка тега в описании шага 2 drawio-workflow.
- `README.md` — добавлен `Warning` о конфликте триггеров с `Agents365-ai/mermaid-skill`, предписанный ADR-0008 «Решение 6» и не попавший в 2.0.0.
```

- [ ] **Step 7: Синхронный bump обоих манифестов**

```bash
sed -i '' 's/"version": "4.1.0"/"version": "4.1.1"/' plugins/gramax/.claude-plugin/plugin.json
sed -i '' 's/"version": "4.1.0"/"version": "4.1.1"/' .claude-plugin/marketplace.json
git diff --stat .claude-plugin/marketplace.json
git diff .claude-plugin/marketplace.json
```

Проверить глазами: в диффе `marketplace.json` **ровно одна** изменённая строка — `metadata.version`. Любая другая правка нарушает NFR-005 и ADR-0011 Решение 6.

- [ ] **Step 8: Проверить неприкосновенность договорных полей**

```bash
python3 -c "
import json
d = json.load(open('.claude-plugin/marketplace.json'))
assert d['name'] == 'gramax-marketplace', d['name']
assert d['owner'] == {'name': 'mdemyanov', 'email': 'qutask@gmail.com'}, d['owner']
assert d['metadata']['version'] == '4.1.1', d['metadata']['version']
assert len(d['plugins']) == 1 and d['plugins'][0]['name'] == 'gramax'
assert d['plugins'][0]['source'] == './plugins/gramax'
print('OK: изменена только metadata.version')"
```

- [ ] **Step 9: Подключить `plugin-contract` к `check.sh --full`**

В `scripts/check.sh`, после блока `# --- 6. (--full only) nauta-integration AC suite ---`, добавить:

```bash
  # --- 7. (--full only) plugin-contract: живые инварианты плагина ---
  echo "==> plugin-contract"
  if bash tests/gramax/plugin-contract/run.sh; then
    echo "OK: plugin-contract green"
  else
    echo "FAIL: plugin-contract"
    FAILED=1
  fi
```

- [ ] **Step 10: Полный гейт**

```bash
bash scripts/check.sh --full
```

Ожидается: `==> RESULT: PASS`, в выводе виден `==> plugin-contract` и `Passed: 7`.

- [ ] **Step 11: Commit**

```bash
bash scripts/check.sh --fast
git add plugins/ .claude-plugin/marketplace.json scripts/check.sh
git commit -m "$(cat <<'EOF'
fix(gramax): довести миграцию drawio-тега и добавить WARNING по ADR-0008

v4.1.0 ввёл единый тег <drawio path=.../>, но writer/SKILL.md и README
продолжали учить старому синтаксису — при том что references/blocks.md
уже называл его устаревшим. Плагин противоречил сам себе.

WARNING о конфликте триггеров с Agents365-ai/mermaid-skill предписан
ADR-0008 Решение 6 и не попал в 2.0.0.

marketplace.json: изменено только metadata.version, синхронно с
plugin.json по ADR-0006 (разрешение — ADR-0011 Решение 6).
plugin-contract подключён к check.sh --full после позеленения.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: `archive/mermaid-file-based/verify.sh`

**Files:**
- Create: `tests/gramax/archive/mermaid-file-based/verify.sh`
- Modify: `tests/gramax/archive/README.md` (раздел про `verify.sh`)

**Interfaces:**
- Consumes: фикстуры `tests/gramax/archive/mermaid-file-based/fixtures/expected-diagram.mermaid`, `expected-tag.md`.

Единственное разрешённое дополнение к архиву (FR-003). Скрипт заменяет 10 неавтоматизируемых `ac-*.sh`, которые печатали `TODO:` и падали: их ассерты перенесены сюда и принимают каталог, куда скилл реально отработал.

- [ ] **Step 1: Написать `verify.sh`**

```bash
#!/usr/bin/env bash
# tests/gramax/archive/mermaid-file-based/verify.sh
# Ручной верификатор выхода gramax:mermaid (FR-015).
#
# Почему не ac-*.sh: проверяемое поведение — результат работы скилла, а не состояние
# репозитория. Автоматизировать в pre-commit нельзя: нужен живой вызов Claude. Прежние
# ac-001…ac-010 это игнорировали — печатали TODO и падали, создавая видимость покрытия.
#
# Использование:
#   1. Создай тестовую статью в пустом каталоге, например /tmp/mtest/docs/auth/overview.md
#   2. Вызови gramax:mermaid на ней (тема — «процесс авторизации», diagram-slug «auth-flow»)
#   3. bash tests/gramax/archive/mermaid-file-based/verify.sh /tmp/mtest
#
# Не входит ни в один режим scripts/check.sh.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUT="${1:-}"
if [ -z "$OUT" ]; then
  cat >&2 <<'USAGE'
usage: verify.sh <output-dir>

  <output-dir>  каталог, в котором gramax:mermaid отработал по тестовой статье.
                Ожидаемая структура: <output-dir>/docs/auth/overview.md
                                     <output-dir>/docs/auth/overview-auth-flow.mermaid

Скрипт ручной: сначала вызови скилл, потом передай сюда каталог с результатом.
USAGE
  exit 2
fi

if [ ! -d "$OUT" ]; then
  echo "FAIL: каталог не найден: $OUT" >&2
  exit 2
fi

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAIL=0
note() { printf "${RED}FAIL${NC}: %s\n" "$1" >&2; FAIL=$((FAIL + 1)); }

ART="$OUT/docs/auth/overview.md"
DSL="$OUT/docs/auth/overview-auth-flow.mermaid"

# AC-001: файл создан рядом со статьёй
[ -f "$DSL" ] || note "AC-001: .mermaid-файл не создан рядом со статьёй: $DSL"

if [ -f "$DSL" ]; then
  # AC-002: DSL начинается с объявления типа диаграммы
  head -1 "$DSL" | grep -qE '^(flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram-v2|erDiagram|pie|mindmap)' \
    || note "AC-002: первая строка DSL не объявляет поддерживаемый тип диаграммы"

  # AC-007: в .mermaid-файле нет markdown-разметки и ограждений
  grep -qE '^\s*```|^\s*#{1,6} |\*\*' "$DSL" \
    && note "AC-007: .mermaid-файл содержит markdown-разметку — должен нести только DSL"

  # AC-010: нумерованный list-syntax ломает парсер Gramax
  grep -qE '^[[:space:]]*[0-9]+\. ' "$DSL" \
    && note "AC-010: DSL содержит list-syntax '1. ' — конфликтует с парсером"
fi

if [ -f "$ART" ]; then
  # AC-003/004/006: тег-ссылка вставлена, самозакрывающаяся, с width и height
  grep -qE '<mermaid path="\./overview-auth-flow\.mermaid"[^>]*/>' "$ART" \
    || note "AC-003/006: в статье нет самозакрывающегося тега на созданный файл"
  grep -qE '<mermaid[^>]*width="[0-9]+px"[^>]*/>' "$ART" \
    || note "AC-004: у тега нет атрибута width"
  grep -qE '<mermaid[^>]*height="[0-9]+px"[^>]*/>' "$ART" \
    || note "AC-004: у тега нет атрибута height"

  # AC-009: инлайновый блок не должен быть вырезан молча
  grep -qE '^\s*```mermaid' "$ART" && printf "NOTE: в статье остался inline-блок ```mermaid — проверь, что миграция была подтверждена пользователем, а не сделана молча\n"
else
  note "AC-003: статья не найдена: $ART"
fi

# AC-005b: конвенция имени — <page-slug>-<diagram-slug>.mermaid
find "$OUT" -name '*.mermaid' -print0 2>/dev/null | while IFS= read -r -d '' f; do
  base="$(basename "$f" .mermaid)"
  echo "$base" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)+$' \
    || printf "${RED}FAIL${NC}: AC-005b: имя '%s' не соответствует конвенции <page-slug>-<diagram-slug>\n" "$base" >&2
done

if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}FAILED${NC}: %d проверок не прошли.\n" "$FAIL" >&2
  exit 1
fi
printf "\n${GREEN}PASS${NC}: выход gramax:mermaid соответствует file-based контракту.\n"
exit 0
```

- [ ] **Step 2: Проверить поведение без аргумента**

```bash
chmod +x tests/gramax/archive/mermaid-file-based/verify.sh
bash tests/gramax/archive/mermaid-file-based/verify.sh; echo "exit=$?"
```

Ожидается: usage на stderr, `exit=2`.

- [ ] **Step 3: Проверить на заведомо пустом каталоге**

```bash
TMP=$(mktemp -d)
bash tests/gramax/archive/mermaid-file-based/verify.sh "$TMP"; echo "exit=$?"
rm -rf "$TMP"
```

Ожидается: несколько `FAIL:` и `exit=1` — скрипт действительно проверяет, а не молчит на пустоте.

- [ ] **Step 4: Дописать раздел в `archive/README.md`**

Короткий раздел: назначение `verify.sh`, порядок ручного прогона, явное «в `check.sh` не входит и входить не должен», перечень AC исходного suite, которые он покрывает (001-007, 009, 010), и какие ушли в `plugin-contract` (005b частично, 008, 011, 012).

- [ ] **Step 5: Commit**

```bash
bash scripts/check.sh --fast
git add tests/gramax/archive
git commit -m "$(cat <<'EOF'
test(gramax): параметризованный verify.sh вместо TODO-заглушек mermaid

Десять ac-*.sh архивного suite печатали TODO и падали: проверяемое
поведение — результат вызова скилла, а не состояние репозитория.
Ассерты собраны в verify.sh <output-dir>, который принимает каталог
с реальным выходом gramax:mermaid. В check.sh не входит осознанно.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Гейт `doc-paths` (красный, без подключения)

**Files:**
- Create: `tests/gramax/doc-paths/lib/scan.sh`, `lib/assert.sh`, `run.sh`, `allowlist.txt`, `README.md`
- Create: `tests/gramax/doc-paths/ac-001-no-stale-pointers.sh`, `ac-002-stale-allowlist-detected.sh`
- Create: `tests/gramax/doc-paths/fixtures/stale-allowlist/{content/sample.md,allowlist.txt}`

**Interfaces:**
- Produces: `scan_doc_paths <content-root> <allowlist-path>` — функция в `lib/scan.sh`, возвращает 0 при чистоте, 1 при находках; печатает диагностику на stderr. Используется обоими `ac-*.sh`.

**Ожидаемый результат задачи: `ac-001` красный (41 указатель ещё не починен), `ac-002` зелёный.** Гейт **не подключается** к `check.sh`.

- [ ] **Step 1: Библиотеки**

```bash
mkdir -p tests/gramax/doc-paths/lib tests/gramax/doc-paths/fixtures/stale-allowlist/content
cp tests/gramax/nauta-integration/lib/assert.sh tests/gramax/doc-paths/lib/assert.sh
sed -i '' 's|tests/gramax/nauta-integration/lib/assert.sh|tests/gramax/doc-paths/lib/assert.sh|' \
  tests/gramax/doc-paths/lib/assert.sh
cp tests/gramax/nauta-integration/run.sh tests/gramax/doc-paths/run.sh
sed -i '' 's|tests/gramax/nauta-integration/run.sh|tests/gramax/doc-paths/run.sh|' \
  tests/gramax/doc-paths/run.sh
```

- [ ] **Step 2: `lib/scan.sh` — ядро гейта**

```bash
#!/usr/bin/env bash
# tests/gramax/doc-paths/lib/scan.sh
# Ядро гейта doc-paths (FR-024, FR-026, FR-027). Вынесено в функцию, чтобы одна и та же
# логика проверялась и на живом content/, и на фикстуре рассинхрона — иначе тест на
# поведение при рассинхроне пришлось бы делать мутацией рабочего дерева.
#
# Форматы записи allowlist:
#   path/to/file.md:123 — причина    точечная: конкретная строка есть историческая запись
#   path/to/file.md — причина        whole-file: весь документ посвящён самой миграции
#
# Whole-file форма не дыра: такой документ не содержит указателей, по которым читателя
# приглашают перейти, — он содержит таблицу соответствия старого и нового (ADR-0011 Решение 4).

DOC_PATHS_PATTERN='docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)'

# scan_doc_paths <content-root> <allowlist-path>
scan_doc_paths() {
  local root="$1" allowlist="$2"
  local violations=0 stale_entries=0

  if [ ! -f "$allowlist" ]; then
    echo "  FAIL: allowlist не найден: $allowlist" >&2
    return 1
  fi

  # Разбор allowlist в две таблицы
  local -a wholefile_paths=() line_keys=()
  local line entry
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    entry="${line%% — *}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    if printf '%s' "$entry" | grep -qE ':[0-9]+$'; then
      line_keys+=("$entry")
    else
      wholefile_paths+=("$entry")
    fi
  done < "$allowlist"

  # 1. Находки в корпусе, не покрытые allowlist — нерабочие указатели
  local hit file lineno key covered
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    file="${hit%%:*}"
    lineno="$(printf '%s' "$hit" | cut -d: -f2)"
    key="$file:$lineno"

    covered=0
    for p in ${wholefile_paths[@]+"${wholefile_paths[@]}"}; do
      [ "$p" = "$file" ] && covered=1 && break
    done
    if [ "$covered" -eq 0 ]; then
      for k in ${line_keys[@]+"${line_keys[@]}"}; do
        [ "$k" = "$key" ] && covered=1 && break
      done
    fi

    if [ "$covered" -eq 0 ]; then
      echo "  FAIL: нерабочий указатель на docs/: $hit" >&2
      violations=$((violations + 1))
    fi
  done <<< "$(grep -rnE "$DOC_PATHS_PATTERN" "$root" 2>/dev/null || true)"

  # 2. Свежесть allowlist: каждая точечная запись обязана указывать на строку,
  #    которая всё ещё содержит docs/-путь. Иначе запись устарела и молча
  #    прикрывает строку, которой там больше нет (FR-027).
  local f n content
  for k in ${line_keys[@]+"${line_keys[@]}"}; do
    f="${k%:*}"; n="${k##*:}"
    if [ ! -f "$f" ]; then
      echo "  FAIL: allowlist устарел: файл $f не существует (запись $k)" >&2
      stale_entries=$((stale_entries + 1))
      continue
    fi
    content="$(sed -n "${n}p" "$f")"
    if ! printf '%s' "$content" | grep -qE "$DOC_PATHS_PATTERN"; then
      echo "  FAIL: allowlist устарел: строка $n в файле $f больше не содержит ожидаемого паттерна" >&2
      echo "        фактическое содержимое: ${content:-<пустая строка>}" >&2
      stale_entries=$((stale_entries + 1))
    fi
  done

  if [ "$violations" -gt 0 ] || [ "$stale_entries" -gt 0 ]; then
    echo "  Итого: $violations нерабочих указателей, $stale_entries устаревших записей allowlist" >&2
    return 1
  fi
  return 0
}
```

- [ ] **Step 3: `ac-001-no-stale-pointers.sh`**

```bash
#!/usr/bin/env bash
# tests/gramax/doc-paths/ac-001-no-stale-pointers.sh
# Требование: FR-024, FR-025, FR-026. Область — только content/.
# plugins/, tests/ и корневые документы покрывает nauta-integration/ac-007 (BR-003).

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/scan.sh"
cd "$ROOT"

if scan_doc_paths "content" "$SCRIPT_DIR/allowlist.txt"; then
  pass_msg "ac-001: в content/ нет нерабочих docs/-указателей, allowlist актуален"
  exit 0
fi
fail_msg "ac-001: гейт doc-paths не пройден"
exit 1
```

- [ ] **Step 4: Фикстура рассинхрона**

Фикстура изолирует **ровно один** отказ — протухшую запись. Непокрытых указателей в ней быть не должно: иначе `ac-002` зеленел бы и от обычного нарушения, не доказывая, что рассинхрон вообще замечается.

`tests/gramax/doc-paths/fixtures/stale-allowlist/content/sample.md` — ровно пять строк:

```markdown
# Фикстура: протухшая запись allowlist

Эта строка когда-то несла docs-путь, его убрали, а запись allowlist осталась.

Историческая запись: проверка выполнялась командой `grep -r x --exclude-dir="docs/qa-reports"`.
```

`tests/gramax/doc-paths/fixtures/stale-allowlist/allowlist.txt`:

```
# Фикстура для FR-027. Запись на строку 3 протухла — там больше нет docs/-пути.
# Запись на строку 5 корректна. Гейт обязан назвать первую и не тронуть вторую.
content/sample.md:3 — заведомо протухшая запись (проверка FR-027)
content/sample.md:5 — легитимная историческая запись, процитированная команда
```

Проверить фикстуру после создания:

```bash
cd tests/gramax/doc-paths/fixtures/stale-allowlist
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' content/sample.md
sed -n '3p' content/sample.md
cd - > /dev/null
```

Ожидается: единственное попадание — строка 5; строка 3 существует и `docs/`-пути не содержит. Если номера иные — привести `allowlist.txt` фикстуры в соответствие, сохранив свойство «одна запись протухшая, одна корректная, непокрытых указателей нет».

- [ ] **Step 5: `ac-002-stale-allowlist-detected.sh`**

```bash
#!/usr/bin/env bash
# tests/gramax/doc-paths/ac-002-stale-allowlist-detected.sh
# Требование: FR-027. Гейт обязан замечать протухшую запись allowlist, а не пропускать молча.
# Проверяется на фикстуре: мутировать живой content/ в pre-commit/CI нельзя.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/scan.sh"

FAIL=0
FIX="$SCRIPT_DIR/fixtures/stale-allowlist"

assert_dir_exists "$FIX" "FR-027: фикстура рассинхрона должна существовать"

cd "$FIX"
OUTPUT="$(scan_doc_paths "content" "$FIX/allowlist.txt" 2>&1)" && RC=0 || RC=$?

if [ "${RC:-0}" -eq 0 ]; then
  echo "  FAIL: FR-027: гейт пропустил протухшую запись allowlist — обязан был упасть" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s' "$OUTPUT" | grep -q 'allowlist устарел'; then
  echo "  FAIL: FR-027: в диагностике нет подстроки «allowlist устарел»" >&2
  echo "  Фактический вывод: $OUTPUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: протухшая запись allowlist обнаружена и названа явно"
```

- [ ] **Step 6: `allowlist.txt` — 14 точечных + 2 whole-file**

Заполнить по разделу «RECORD — сохраняем дословно» диспозиции. Точные строки на момент HEAD задачи 6 — **проверить актуальность номеров перед записью**:

```bash
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' \
  content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md \
  content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md \
  content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md \
  content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md
```

Файл (номера строк — из вывода выше):

```
# tests/gramax/doc-paths/allowlist.txt
# Упоминания docs/-путей в content/, которые остаются дословно.
#
# Две формы:
#   file.md:N — причина    точечная: конкретная строка есть историческая запись
#   file.md — причина      whole-file: весь документ посвящён самой миграции путей
#
# Критерий (ADR-0011 Решение 4): роль предложения, не каталог. Указатель, по которому
# читателя приглашают перейти, — чиним. Запись о том, что было выполнено или решено на
# тот момент, — сохраняем: замена пути переписала бы историческую запись.

# --- Решение ADR, зафиксировавшее исключения на дату принятия ---
content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:270 — список каталогов, исключённых из правки на момент решения; замена превратила бы решение в утверждение о сегодняшней раскладке

# --- Запись приёмки: где orphan-hits были допущены в тот прогон ---
content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md:52 — вердикт AC-016, перечень допущенных локаций на момент приёмки
content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md:92 — рекомендация PM в той формулировке, в какой была вынесена

# --- Отчёт QA: перечень найденного при скане с классификацией ---
content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:60 — свидетельство прогона: найденная локация и её классификация
content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:61 — то же
content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:62 — то же; плюс glob-паттерн, а не путь к файлу
content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:63 — то же
content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:64 — то же

# --- Отчёт QA: процитированная выполненная команда и таблица hits ---
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:72 — команда была выполнена именно так; правка сделала бы отчёт ложным описанием собственного метода
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:83 — строка таблицы найденных hits с вердиктом
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:84 — то же
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:85 — то же
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:86 — то же
content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:87 — то же

# --- Whole-file: документы, предмет которых — сама миграция путей ---
content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md — требование этой работы: карта переездов и диспозиция обязаны называть старые пути
content/00-project/adr/0011-test-harness-taxonomy.md — ADR этой работы: обоснование политики требует цитировать старые пути
```

- [ ] **Step 7: `README.md` гейта**

Короткий: назначение, область (`content/` и только), граница с `nauta-integration/ac-007` и правило «куда класть новое правило», две формы allowlist, как чинить падение (починить указатель либо, если это запись, добавить в allowlist с причиной).

- [ ] **Step 8: Прогнать — ожидается 1 красный, 1 зелёный**

```bash
chmod +x tests/gramax/doc-paths/*.sh
bash tests/gramax/doc-paths/run.sh; echo "exit=$?"
```

Ожидается: `ac-001` FAIL со списком 41 нерабочего указателя, `ac-002` PASS, `exit=1`.

Проверить, что счёт сходится:

```bash
bash tests/gramax/doc-paths/ac-001-no-stale-pointers.sh 2>&1 | grep -c 'нерабочий указатель'
```

Ожидается: `41`. Другое число означает ошибку в allowlist или в разборе — разобраться до перехода к задаче 7.

- [ ] **Step 9: Commit (гейт не подключён — это задача 7)**

```bash
bash scripts/check.sh --fast
git add tests/gramax/doc-paths
git commit -m "$(cat <<'EOF'
test(gramax): гейт doc-paths против нерабочих docs/-указателей в content/

Ядро вынесено в lib/scan.sh, чтобы поведение при протухшем allowlist
проверялось на фикстуре, а не мутацией рабочего дерева.

Allowlist о двух формах: точечная на историческую запись и whole-file
на документ, предмет которого — сама миграция. Второе не дыра: такой
документ несёт таблицу соответствия, а не указатели (ADR-0011 Решение 4).

ac-001 красный на 41 указателе — их чинит следующая задача.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Починка 41 указателя и подключение гейта

**Files:**
- Modify: 16 файлов `content/` целиком (только указатели)
- Modify: 2 файла `content/` построчно (смешанные — указатели и записи в одном файле)
- Modify: `scripts/check.sh` (подключение гейта)

**Interfaces:**
- Consumes: `tests/gramax/doc-paths/run.sh` (задача 6).

**Два файла не трогаются вовсе** — в них только записи: `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md` и `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md`.

- [ ] **Step 1: Массовая замена в 16 файлах, где только указатели**

```bash
cd <repo-root>
FILES=(
  content/00-project/adr/0001-diagram-on-demand-plugin-split.md
  content/00-project/adr/0002-drawio-mcp-backend-selection.md
  content/00-project/adr/0003-drawio-backend-vendoring-strategy.md
  content/00-project/adr/0004-router-and-engine-selection.md
  content/00-project/adr/0005-save-flow-script-api-contract.md
  content/00-project/adr/0006-marketplace-json-semver-strategy.md
  content/00-project/adr/0007-out-of-scope-phase2.md
  content/00-project/adr/0008-drop-internal-drawio-skills.md
  content/00-project/adr/0010-mermaid-file-based-workflow.md
  content/30-requirements/2026-05-08-diagram-on-demand-design.md
  content/30-requirements/2026-05-11-remove-diagram-skills.md
  content/30-requirements/2026-05-11-routing-mermaid-drawio.md
  content/30-requirements/2026-05-12-mermaid-file-based-design.md
  content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md
  content/60-implementation/acceptance/2026-05-11-routing-mermaid-drawio.md
  content/lessons-learned.md
)
for f in "${FILES[@]}"; do
  sed -i '' \
    -e 's|docs/superpowers/specs/2026-05-08-diagram-on-demand-design\.md|content/30-requirements/2026-05-08-diagram-on-demand-design.md|g' \
    -e 's|docs/superpowers/specs/2026-05-11-remove-diagram-skills\.md|content/30-requirements/2026-05-11-remove-diagram-skills.md|g' \
    -e 's|docs/superpowers/specs/2026-05-11-routing-mermaid-drawio\.md|content/30-requirements/2026-05-11-routing-mermaid-drawio.md|g' \
    -e 's|docs/superpowers/specs/2026-05-12-mermaid-file-based-design\.md|content/30-requirements/2026-05-12-mermaid-file-based-design.md|g' \
    -e 's|docs/qa-reports/|content/60-implementation/test-reports/|g' \
    -e 's|docs/acceptance/|content/60-implementation/acceptance/|g' \
    -e 's|docs/research/|content/10-domain/research/|g' \
    -e 's|docs/lessons-learned\.md|content/lessons-learned.md|g' \
    -e 's|docs/adr/|content/00-project/adr/|g' \
    "$f"
done
```

Порядок правил в `sed` значим: четыре точных имени спек идут **до** общих префиксов, иначе `docs/superpowers/specs/` осталось бы нетронутым (BR-004 — замена только по точному имени файла для этого каталога).

- [ ] **Step 2: Проверить, что в 16 файлах не осталось указателей**

```bash
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' "${FILES[@]}" || echo "OK: указатели починены"
```

Ожидается: `OK: указатели починены`.

- [ ] **Step 3: Смешанный файл 1 — `adr/0009`, построчно**

В этом файле 7 указателей (строки 19, 360, 361, 380, 381, 382, 383) и **одна запись на строке 270**, которую трогать нельзя: `…(кроме docs/adr/ и docs/superpowers/ — исторический контекст)`.

```bash
F=content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' "$F"
```

Убедиться, что номера строк совпадают с ожидаемыми (19, 270, 360, 361, 380-383). Затем — замена с адресацией по строкам, минуя 270:

```bash
sed -i '' \
  -e '19s|docs/superpowers/specs/2026-05-11-routing-mermaid-drawio\.md|content/30-requirements/2026-05-11-routing-mermaid-drawio.md|' \
  -e '360s|docs/superpowers/specs/2026-05-11-routing-mermaid-drawio\.md|content/30-requirements/2026-05-11-routing-mermaid-drawio.md|' \
  -e '361s|docs/adr/|content/00-project/adr/|' \
  -e '380s|docs/superpowers/specs/2026-05-11-routing-mermaid-drawio\.md|content/30-requirements/2026-05-11-routing-mermaid-drawio.md|' \
  -e '381s|docs/adr/|content/00-project/adr/|' \
  -e '382s|docs/adr/|content/00-project/adr/|' \
  -e '383s|docs/adr/|content/00-project/adr/|' \
  "$F"
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' "$F"
```

Ожидается: осталась ровно одна строка — 270.

- [ ] **Step 4: Смешанный файл 2 — acceptance remove-diagram-skills, построчно**

Указатели на строках 15, 16, 17; записи на 52 и 92. Запись 92 содержит `docs/lessons-learned.md` — общая замена задела бы её.

```bash
F=content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' "$F"
sed -i '' \
  -e '15s|docs/superpowers/specs/2026-05-11-remove-diagram-skills\.md|content/30-requirements/2026-05-11-remove-diagram-skills.md|' \
  -e '16s|docs/adr/|content/00-project/adr/|' \
  -e '17s|docs/qa-reports/|content/60-implementation/test-reports/|' \
  "$F"
grep -nE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' "$F"
```

Ожидается: остались ровно строки 52 и 92.

- [ ] **Step 5: Гейт обязан позеленеть**

```bash
bash tests/gramax/doc-paths/run.sh; echo "exit=$?"
```

Ожидается: `Passed: 2`, `Failed: 0`, `exit=0`.

Если `ac-001` красный — прочитать список: либо указатель пропущен, либо номера строк в `allowlist.txt` съехали относительно задачи 6 (правки в шагах 3-4 не меняют число строк, но проверить стоит).

- [ ] **Step 6: Контрольные реперы (AC-025)**

```bash
grep -q 'content/00-project/adr/0006' content/00-project/adr/0010-mermaid-file-based-workflow.md \
  && ! grep -q 'docs/adr/0006' content/00-project/adr/0010-mermaid-file-based-workflow.md \
  && grep -q 'content/30-requirements/2026-05-11-remove-diagram-skills.md' content/00-project/adr/0008-drop-internal-drawio-skills.md \
  && echo "OK: реперные указатели ведут в content/"
```

- [ ] **Step 7: Проверить, что два спека вне периметра не задеты (AC-029)**

```bash
test -f docs/superpowers/specs/2026-05-08-apply-project-template-design.md \
  && test -f docs/superpowers/specs/2026-08-07-nauta-integration-design.md \
  && echo "OK: мета-спеки на месте"
git status --short docs/
```

Ожидается: `OK: мета-спеки на месте`, и в `git status` по `docs/` — только новый файл плана.

- [ ] **Step 8: Подключить гейт к `check.sh --full`**

После блока `# --- 7. (--full only) plugin-contract ---` добавить:

```bash
  # --- 8. (--full only) doc-paths: нет нерабочих docs/-указателей в content/ ---
  echo "==> doc-paths"
  if bash tests/gramax/doc-paths/run.sh; then
    echo "OK: doc-paths clean"
  else
    echo "FAIL: doc-paths gate"
    FAILED=1
  fi
```

- [ ] **Step 9: Полный гейт**

```bash
bash scripts/check.sh --full
```

Ожидается: `==> RESULT: PASS`, в выводе видны все четыре suite.

- [ ] **Step 10: Commit**

```bash
bash scripts/check.sh --fast
git add content/ scripts/check.sh
git commit -m "$(cat <<'EOF'
docs(content): починить 41 нерабочий docs/-указатель, сохранив 14 записей

Граница по роли предложения, не по каталогу (ADR-0011 Решение 4).
Указатель, по которому читателя приглашают перейти, ведёт в content/.
Запись о выполненном — процитированная команда, таблица найденных hits,
список исключений на дату решения — остаётся дословно.

Два файла со смешанным содержимым правились построчно: общая замена
задела бы запись на adr/0009:270 и на acceptance:92.

doc-paths подключён к check.sh --full после позеленения.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Онбординг nauta

**Files:**
- Create: `docs/onboarding-nauta.md`, `.claude/settings.local.json.example`
- Modify: `README.md` (новый раздел после «Установка»), `CLAUDE.md` (указатель)

- [ ] **Step 1: Снять фактическую конфигурацию как образец**

```bash
python3 -c "
import json,os
p = os.path.expanduser('~/.claude/settings.json')
d = json.load(open(p))
print(json.dumps({k: v for k, v in d.items() if 'arketplace' in k or 'lugin' in k}, ensure_ascii=False, indent=2))"
```

Из вывода взять **форму** записи marketplace `nauta` с `ref: v0.3.1`. В документ переносится только структура — никаких путей и значений, специфичных для машины пользователя.

- [ ] **Step 2: `.claude/settings.local.json.example`**

```json
{
  "enabledPlugins": {
    "nauta@nauta": true,
    "superpowers@claude-plugins-official": true
  }
}
```

- [ ] **Step 3: `docs/onboarding-nauta.md`**

Содержание (FR-030): зачем нужен nauta в этом репозитории (роли `/nauta:*` — единственный способ вести цикл, собственных агентов репозиторий не держит); регистрация marketplace в `~/.claude/settings.json` с `ref: v0.3.1` и почему ref закреплён, а не плавает; включение локально копированием `.claude/settings.local.json.example` → `.claude/settings.local.json` и почему этот файл в `.gitignore` (per-machine, не распространяется); `uv` как жёсткий пререквизит — `scripts/check.sh --fast` падает без него, это не предупреждение; `bash scripts/install-hooks.sh` и что хук по умолчанию не установлен; проверка «всё встало»: `bash scripts/check.sh --full` зелёный и `/nauta:pm` отвечает.

Обязательный раздел «Проверка установки» с конкретной командой и ожидаемым выводом — иначе документ описывает намерение, а не воспроизводимость.

- [ ] **Step 4: Раздел в корневом `README.md`**

Вставить после «Установка», перед «Skills (плагин gramax)»:

```markdown
## Разработка этого репозитория

Работа над плагином ведётся ролями из marketplace `nauta` (`/nauta:ba`, `/nauta:sa`, `/nauta:dev`, …) — собственных агентов репозиторий не держит. Установка на чистой машине, пререквизиты (`uv`, git-хуки) и проверка — в [docs/onboarding-nauta.md](docs/onboarding-nauta.md).
```

- [ ] **Step 5: Указатель в `CLAUDE.md`**

В абзаце после таблицы ролей (сейчас: «Роли приходят из плагина `nauta` — marketplace закреплён…») дописать предложение:

```
Как поднять это на чистой машине — `docs/onboarding-nauta.md`.
```

- [ ] **Step 6: Проверить AC онбординга**

```bash
test -f docs/onboarding-nauta.md \
  && grep -q 'v0.3.1' docs/onboarding-nauta.md \
  && grep -q 'settings.local.json' docs/onboarding-nauta.md \
  && grep -qi 'uv' docs/onboarding-nauta.md \
  && grep -q 'install-hooks.sh' docs/onboarding-nauta.md \
  && test -f .claude/settings.local.json.example \
  && grep -q 'onboarding-nauta.md' CLAUDE.md \
  && grep -q 'onboarding-nauta.md' README.md \
  && echo "OK: AC-030…AC-033"
```

- [ ] **Step 7: Убедиться, что пример не игнорируется git**

```bash
git check-ignore -v .claude/settings.local.json.example || echo "OK: пример отслеживается"
```

Ожидается: `OK: пример отслеживается`. `.gitignore` игнорирует `.claude/settings.local.json` — точное имя, без `.example`.

- [ ] **Step 8: Финальный гейт и commit**

```bash
bash scripts/check.sh --full
git add docs/onboarding-nauta.md .claude/settings.local.json.example README.md CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: онбординг nauta для чистой машины

Репозиторий описывал состояние, но не воспроизводимость: ни README,
ни CLAUDE.md не объясняли, что роли /nauta:* требуют marketplace в
~/.claude/settings.json с ref v0.3.1 и локального включения через
.claude/settings.local.json, который не коммитится.

Добавлен settings.local.json.example для копирования и раздел
«Проверка установки» с ожидаемым выводом.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Проверка перед сдачей

```bash
bash scripts/check.sh --full
bash tests/gramax/plugin-contract/run.sh
bash tests/gramax/doc-paths/run.sh
bash tests/gramax/orphan-references/run.sh
bash tests/gramax/nauta-integration/run.sh
bash tests/gramax/archive/mermaid-file-based/verify.sh   # ожидается usage + exit 2
```

Ожидается: `--full` зелёный и включает четыре suite; архив не запускается ни одним из них.

## Self-review плана

**Покрытие спеки.** FR-001…FR-005 → задача 1. FR-006…FR-012 → задача 3. FR-013, FR-020 → задача 2. FR-014 → задача 1. FR-015 → задача 5. FR-016 → задача 4 шаг 9. FR-017…FR-019, FR-021…FR-023 → задача 4. FR-024…FR-027 → задача 6. FR-025 (правка) → задача 7. FR-028 → задача 7 шаг 8. FR-029 → задача 7 шаг 7. FR-030…FR-033 → задача 8. Непокрытых FR нет.

**Расхождение с нумерацией AC спеки.** AC-003 требует сверки архива с `BASE_REV` — план фиксирует его в задаче 1 шаг 1 и использует в шаге 4 той же задачи, а не отложенной проверкой: после последующих коммитов определить «коммит непосредственно перед переездом» сложнее, чем записать его заранее.

**Известное отклонение.** Спека (FR-021) относит удаление мёртвых guard'ов `check.sh` к продуктовым фиксам 4.1.1, план выполняет его в задаче 2 — ограничение порядка из FR-013 требует, чтобы очистка предшествовала расширению реестра. Запись в CHANGELOG остаётся в задаче 4, как и предписано. Изменение сделано осознанно и здесь зафиксировано.

По итогам ревью задачи 4 (коммит `fefb9c5`) FR-021 сужен: удаление мёртвых guard'ов — фикс
`scripts/check.sh`, а не поставки плагина, поэтому в CHANGELOG плагина о нём записи нет
(коммит `bdcc5ec` вычистил четвёртый буллет из `plugins/gramax/CHANGELOG.md`). Step 6 выше
приведён в соответствие: CHANGELOG 4.1.1 несёт только три буллета про drawio-тег и WARNING.

**Типы и имена.** Функция `scan_doc_paths <root> <allowlist>` объявлена в задаче 6 шаг 2 и вызывается под тем же именем и с той же сигнатурой в шагах 3 и 5. Переменная `DOC_PATHS_PATTERN` объявлена там же и используется внутри функции. `BASE_REV` пишется в файл в задаче 1 шаг 1 и читается в шаге 4.
