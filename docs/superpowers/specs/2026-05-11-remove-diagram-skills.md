---
title: Удаление diagram-on-demand и diagrams, переход на внешний drawio-skill
status: draft
date: 2026-05-11
plugin: gramax
---

# Удаление diagram-on-demand и diagrams, переход на внешний drawio-skill

## JTBD

**Story 1 — сокращение поверхности плагина:**
Когда я поддерживаю собственный drawio-pipeline (drawio_convert.py, save_diagram.sh, insert_diagram_ref.sh) внутри плагина и вижу, что сторонний drawio-skill делает то же самое и поддерживается отдельной командой, я (плагин-автор) хочу удалить все drawio-специфичные skills и скрипты из gramax, чтобы сократить поверхность поддержки и устранить дублирование функциональности.

**Story 2 — делегирование drawio внешнему плагину:**
Когда мне нужно создать drawio-диаграмму в рамках Gramax-каталога, я (разработчик документации) хочу использовать поддерживаемый внешний плагин `Agents365-ai/drawio-skill` для генерации файла, а затем вручную вставить тег-ссылку в md-страницу с подсказкой от writer-skill, чтобы не зависеть от самодельного скрипта, который может отстать от апстрима.

**Story 3 — корректное описание нового workflow в writer-skill:**
Когда я прошу writer-skill помочь со вставкой drawio в Gramax-страницу, я (автор документации) хочу получить инструкцию о двухшаговом workflow (сначала вызвать внешний drawio-skill, затем вставить тег вручную), а не ссылку на несуществующий drawio_convert.py, чтобы инструкция была достоверной и не вводила меня в заблуждение.

## Описание

Плагин gramax@1.4.0 содержит два skill'а для работы с диаграммами (`diagram-on-demand`, `diagrams`) и четыре вспомогательных скрипта (`find_doc_root.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`, `validate_diagram_type.sh`), а также `drawio_convert.py`. Эти компоненты реализуют полный pipeline: генерация DSL/XML → конвертация в SVG → вставка ссылки в md. Pipeline рабочий, но требует собственной поддержки.

Исследование (RES-001, 2026-05-11) показало, что сторонний плагин `Agents365-ai/drawio-skill` (MIT, v1.5.2) покрывает генерацию drawio-файлов и их экспорт, и поддерживается отдельной командой. Функциональность не идентична: внешний skill не знает о `.doc-root.yaml`, не вставляет ссылку в md автоматически и не использует Gramax-теги. Это осознанный trade-off: пользователь принимает ручной шаг вставки взамен на снятие бремени поддержки с плагина.

Изменение является breaking change: skills `diagram-on-demand` и `diagrams` удаляются без замены внутри плагина. Drawio-workflow становится двухшаговым и требует установки внешнего плагина. Mermaid-skill остаётся без изменений — он inline, без внешних зависимостей. Версия плагина поднимается до 2.0.0.

Writer-skill (`SKILL.md`, `references/drawio.md`, `references/staging.md`) содержит прямые ссылки на `drawio_convert.py`. После удаления скрипта эти ссылки станут нерабочими: writer будет советовать несуществующий путь. Поэтому writer-skill подлежит обновлению — заменить инструкции по конвертации на описание двухшагового workflow с внешним плагином.

## Scope

### In scope

- Удаление `plugins/gramax/skills/diagram-on-demand/` (каталог целиком).
- Удаление `plugins/gramax/skills/diagrams/` (каталог целиком).
- Удаление скриптов-сирот: `find_doc_root.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`, `validate_diagram_type.sh`.
- Удаление `plugins/gramax/scripts/drawio_convert.py`.
- Обновление `plugins/gramax/skills/writer/SKILL.md` — убрать команду `uv run ... drawio_convert.py`, описать двухшаговый drawio-workflow.
- Обновление `plugins/gramax/skills/writer/references/drawio.md` — убрать секцию «Конвертация .drawio → SVG (обязательно)» с `drawio_convert.py`, описать новый workflow (внешний drawio-skill → ручная вставка тега).
- Обновление `plugins/gramax/skills/writer/references/staging.md` — убрать пункт «Конвертировать .drawio → .svg» с командой `drawio_convert.py`.
- Обновление `plugins/gramax/skills/mermaid/SKILL.md` — уточнить description и секцию «Не для», чтобы явно ограничить mermaid-кейсами и снизить конфликт триггеров с внешним drawio-skill.
- Обновление `plugins/gramax/README.md` — убрать упоминания удалённых skills, добавить блок prerequisites внешнего drawio-плагина.
- Обновление `plugins/gramax/.claude-plugin/plugin.json` — bump до 2.0.0, новое description, keywords.
- Обновление корневого `.claude-plugin/marketplace.json` — description.
- Добавление секции 2.0.0 в `plugins/gramax/CHANGELOG.md` с подразделами Added / Removed / Changed / Migration.

### Out of scope

- `plugins/claude-mermaid/` — submodule, не редактируем.
- Wrapper-скрипты или адаптеры для делегирования drawio-skill — пользователь сам вызывает внешний плагин.
- Автоматическая установка Python 3 или draw.io desktop.
- Дублирование функциональности drawio-skill внутри плагина gramax.
- ADR — создаёт SA.
- Тесты — создаёт QA-author.

## Функциональные требования

- **FR-001:** skills `diagram-on-demand` и `diagrams` отсутствуют в `plugins/gramax/skills/` после изменений.
- **FR-002:** скрипты `find_doc_root.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`, `validate_diagram_type.sh`, `drawio_convert.py` отсутствуют в `plugins/gramax/scripts/` после изменений.
- **FR-003:** `plugins/gramax/skills/writer/SKILL.md` не содержит команды вида `drawio_convert.py` и содержит описание двухшагового drawio-workflow (внешний drawio-skill → ручная вставка тега).
- **FR-004:** `plugins/gramax/skills/writer/references/drawio.md` не содержит секцию `### Готовый инструмент` с `drawio_convert.py` и содержит раздел «Workflow создания drawio-диаграммы» с описанием внешнего плагина.
- **FR-005:** `plugins/gramax/skills/writer/references/staging.md` не содержит блок с командой `drawio_convert.py` в секции конвертации.
- **FR-006:** `plugins/gramax/skills/mermaid/SKILL.md` description в frontmatter явно ограничивает scope mermaid-случаями и не упоминает drawio как кейс применения данного skill'а.
- **FR-007:** `plugins/gramax/README.md` не упоминает `diagram-on-demand` и `diagrams` как доступные skills.
- **FR-008:** `plugins/gramax/README.md` содержит блок prerequisites для внешнего drawio-плагина: draw.io desktop (с платформенными деталями), Python 3, команды `marketplace add` и `plugin install`.
- **FR-009:** `plugins/gramax/.claude-plugin/plugin.json` содержит `"version": "2.0.0"`, description без упоминания `diagrams`/`diagram-on-demand`, keywords без `drawio` или с пометкой `external`.
- **FR-010:** корневой `.claude-plugin/marketplace.json` description не упоминает `diagram-on-demand` и `diagrams` как компоненты плагина gramax.
- **FR-011:** `plugins/gramax/CHANGELOG.md` содержит секцию `## 2.0.0` с подразделами Removed, Changed, Migration notes.

## Нефункциональные требования

- **NFR-001:** обратная совместимость — намеренно нарушена. Это breaking change (major bump). Migration notes обязательны в CHANGELOG.
- **NFR-002:** локализация README — русский язык (как в текущей версии).
- **NFR-003:** `bash scripts/check.sh --fast` проходит без ошибок после всех изменений.
- **NFR-004:** ни один оставшийся файл плагина не ссылается на удалённые скрипты по имени.
- **NFR-005:** изменения в writer-skill не нарушают существующую функциональность описания синтаксиса Gramax-блоков (drawio.md остаётся актуальным в части синтаксиса тегов `[drawio:...]`).

## UX / Интерфейс

После изменений доступные skills плагина gramax:
- `/gramax:writer` — без изменений в поведении (только обновлены ссылки на workflow).
- `/gramax:comments-read <path>` — без изменений.
- `/gramax:comments-write <path>` — без изменений.
- `/gramax:mermaid` — без изменений в функциональности, уточнено описание.

Удалённые skills: `/gramax:diagrams`, `/gramax:diagram-on-demand`.

Drawio-workflow для пользователя после изменений:
1. `/plugin marketplace add Agents365-ai/365-skills` (однократно)
2. `/plugin install drawio` (однократно)
3. Вызвать drawio-skill: описание → `.drawio` + экспорт в CWD
4. Вставить тег вручную в md-страницу: `[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]` (writer-skill подскажет формат)

## Acceptance Criteria

- [ ] **AC-001:** каталог `plugins/gramax/skills/diagram-on-demand/` не существует: `test ! -d plugins/gramax/skills/diagram-on-demand && echo PASS`
- [ ] **AC-002:** каталог `plugins/gramax/skills/diagrams/` не существует: `test ! -d plugins/gramax/skills/diagrams && echo PASS`
- [ ] **AC-003:** скрипты-сироты отсутствуют: `for f in find_doc_root.sh save_diagram.sh insert_diagram_ref.sh validate_diagram_type.sh; do test ! -f "plugins/gramax/scripts/$f" && echo "OK: $f absent" || echo "FAIL: $f still exists"; done`
- [ ] **AC-004:** `drawio_convert.py` отсутствует: `test ! -f plugins/gramax/scripts/drawio_convert.py && echo PASS`
- [ ] **AC-005:** `writer/SKILL.md` не содержит строки с `drawio_convert.py`: `grep -n 'drawio_convert.py' plugins/gramax/skills/writer/SKILL.md | wc -l | grep -q '^0$' && echo PASS`
- [ ] **AC-006:** `writer/references/drawio.md` не содержит строки с `drawio_convert.py`: `grep -n 'drawio_convert.py' plugins/gramax/skills/writer/references/drawio.md | wc -l | grep -q '^0$' && echo PASS`
- [ ] **AC-007:** `writer/references/staging.md` не содержит строки с `drawio_convert.py`: `grep -n 'drawio_convert.py' plugins/gramax/skills/writer/references/staging.md | wc -l | grep -q '^0$' && echo PASS`
- [ ] **AC-008:** `writer/references/drawio.md` содержит описание двухшагового workflow с внешним плагином (ключевая фраза `Agents365-ai` или `drawio-skill`): `grep -c 'Agents365-ai\|drawio-skill' plugins/gramax/skills/writer/references/drawio.md | grep -qv '^0$' && echo PASS`
- [ ] **AC-009:** `plugins/gramax/README.md` содержит prerequisites-блок с командой `marketplace add Agents365-ai/365-skills`: `grep -c 'Agents365-ai/365-skills' plugins/gramax/README.md | grep -qv '^0$' && echo PASS`
- [ ] **AC-010:** `plugins/gramax/README.md` не упоминает skills `diagram-on-demand` и `diagrams` как доступные: `grep -E 'diagram-on-demand|/gramax:diagrams' plugins/gramax/README.md | wc -l | grep -q '^0$' && echo PASS`
- [ ] **AC-011:** `plugins/gramax/.claude-plugin/plugin.json` содержит версию 2.0.0: `python3 -c "import json; d=json.load(open('plugins/gramax/.claude-plugin/plugin.json')); assert d['version']=='2.0.0', d['version']; print('PASS')"`
- [ ] **AC-012:** корневой `.claude-plugin/marketplace.json` description не содержит `diagram-on-demand` или `diagrams` в описании плагина gramax: `python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); desc=[p['description'] for p in d['plugins'] if p['name']=='gramax'][0]; assert 'diagram-on-demand' not in desc and 'diagrams' not in desc, desc; print('PASS')"`
- [ ] **AC-013:** `plugins/gramax/CHANGELOG.md` содержит секцию `## 2.0.0` и подраздел `### Migration`: `grep -c '## 2.0.0' plugins/gramax/CHANGELOG.md | grep -qv '^0$' && grep -c '### Migration' plugins/gramax/CHANGELOG.md | grep -qv '^0$' && echo PASS`
- [ ] **AC-014:** `plugins/gramax/skills/mermaid/SKILL.md` description в frontmatter не содержит `drawio` как кейс применения: `python3 -c "import re; content=open('plugins/gramax/skills/mermaid/SKILL.md').read(); fm=re.search(r'^---(.+?)---', content, re.DOTALL); desc=re.search(r'description:\s*(.+)', fm.group(1)); assert 'drawio' not in desc.group(1).lower() or 'не для' in desc.group(1).lower(), 'drawio found in description'; print('PASS')"`
- [ ] **AC-015:** `bash scripts/check.sh --fast` завершается с exit code 0: `bash scripts/check.sh --fast && echo PASS`
- [ ] **AC-016:** ни один файл плагина не ссылается на удалённые скрипты по имени: `grep -rn 'drawio_convert\|find_doc_root\|save_diagram\|insert_diagram_ref\|validate_diagram_type' plugins/gramax/skills/ plugins/gramax/agents/ plugins/gramax/.claude-plugin/ plugins/gramax/README.md plugins/gramax/CHANGELOG.md 2>/dev/null | wc -l | grep -q '^0$' && echo PASS`

## Migration plan (для пользователей)

Пользователи версии 1.x, обновляющиеся до 2.0.0:

1. **Обновить плагин:**
   ```
   /plugin update gramax
   ```

2. **Если использовался `diagram-on-demand` или `diagrams` — установить внешний drawio-плагин:**
   ```
   /plugin marketplace add Agents365-ai/365-skills
   /plugin install drawio
   ```
   Дополнительно установить:
   - draw.io desktop: macOS — `brew install --cask drawio`; Windows/Linux — см. github.com/jgraph/drawio-desktop/releases (Linux: избегать snap-версии, использовать .deb/.rpm; headless-серверы требуют дополнительно `xvfb`).
   - Python 3 (необходим для `repair_png.py` из drawio-skill): macOS/Linux — обычно уже установлен; Windows — python.org.

3. **Существующие файлы продолжают работать:** уже созданные `.drawio` и `.svg` файлы в Gramax-каталогах отображаются корректно — Gramax-фронтенд их рендерит независимо от плагина.

4. **Новый workflow создания drawio-диаграмм — двухшаговый:**
   - Шаг 1: вызвать drawio-skill для генерации `.drawio` + экспорта (файл окажется в CWD или явно указанном пути).
   - Шаг 2: вставить тег вручную в нужную md-страницу — writer-skill подскажет формат: `[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]`.
   - Важно: drawio-skill не знает о `.doc-root.yaml` и не вставляет ссылку автоматически.

5. **Если `drawio_convert.py` использовался в собственных скриптах:** скрипт удалён из плагина. Его функциональность (конвертация `.drawio` → SVG с embedded XML и корректной обработкой кириллицы) не воспроизведена во внешнем плагине в том же виде. Пользователю, который полагался на этот скрипт в своих пайплайнах, необходимо либо сохранить копию из предыдущей версии плагина, либо перейти на CLI draw.io desktop для конвертации.

## Открытые вопросы для SA (ADR-0008)

1. **Semver: 2.0.0 vs 1.5.0.** Удаление двух публичных skills (`diagram-on-demand`, `diagrams`) и публичного скрипта (`drawio_convert.py`) — это breaking change по semver. SA должен подтвердить major bump или обосновать альтернативу.

2. **Судьба ADR-0001—0007.** Часть существующих ADR описывают архитектуру удаляемых компонентов (0002, 0003, 0004, 0005 — drawio MCP и pipeline). Помечать ли их как Superseded или оставить как историческую запись? SA решает политику.

3. **Сохранение `drawio_convert.py` как deprecated-утилиты.** Вариант: не удалять скрипт полностью, а переместить в `scripts/deprecated/` с предупреждением. Компромисс между чистотой и backward-compat для пользователей, встроивших скрипт в свои пайплайны. SA взвешивает.

4. **Уточнение mermaid SKILL.md description.** Текущий description упоминает «flowchart/sequence/gantt/...» — те же слова, что и в drawio-skill trigger. SA решает: достаточно ли убрать `drawio` из description mermaid, или нужна более явная формулировка «только для mermaid DSL, не для drawio».

5. **Политика по 365-skills/mermaid.** Marketplace `Agents365-ai/365-skills` содержит также mermaid-skill, который конфликтует триггерами с нашим `gramax:mermaid`. SA формулирует в ADR рекомендацию: устанавливать ли 365-skills/mermaid одновременно с gramax, или рекомендовать пользователям установить только drawio из 365-skills, а mermaid брать из gramax.

6. **Windows без Python 3.** drawio-skill требует Python 3 для `repair_png.py`. SA решает: описывать в README установку Python 3 для Windows-пользователей (ссылка на python.org) или ограничиться предупреждением.

## Definition of Done

- Spec сформулирован с JTBD, Scope, FR/NFR, AC (все проверяемы shell-командой).
- Migration plan ясен пользователю.
- Открытые вопросы для SA сформулированы и переданы в ADR-0008.
- Все AC (AC-001—AC-016) написаны как однострочные shell-проверки.

## Бриф для SA

**Spec:** `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`

**Спроектировать:**
- Подтвердить semver (2.0.0 vs 1.5.0) и задокументировать в ADR-0008.
- Определить судьбу ADR-0001—0007 (superseded / historical record).
- Решить вопрос о `drawio_convert.py`: удалить полностью или перенести в `scripts/deprecated/`.
- Сформулировать политику по конфликту триггеров `mermaid` skill vs `365-skills/mermaid`.
- Дать рекомендацию по Windows / Python 3 для README.

**Бизнес-правила:**
- `plugins/claude-mermaid/` не трогаем (submodule).
- Gramax-тег `[drawio:./file.svg:...:WIDTHpx:HEIGHTpx]` остаётся каноническим форматом вставки drawio в md — writer-skill документирует его в `references/drawio.md`.
- Mermaid-skill (`/gramax:mermaid`) сохраняет текущую функциональность без изменений в логике.
- `bash scripts/check.sh --fast` должен быть зелёным после изменений (AC-015).

**Acceptance Criteria для проверки архитектуры:** AC-001, AC-002, AC-003, AC-004, AC-011, AC-015, AC-016.

## Бриф для QA-author

**Spec:** `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`

**Покрыть тестами:** каждое из AC-001—AC-016 должно быть реализовано как отдельный failing stub в `tests/gramax/remove-diagram-skills/` до начала Dev.

**Особое внимание:**
- AC-016 — интеграционная проверка: ни один файл плагина не должен ссылаться на удалённые скрипты. Важно охватить README, CHANGELOG, все skill SKILL.md, agents.
- AC-008 — позитивная проверка: `drawio.md` должен содержать описание нового workflow, а не просто отсутствие старого.
- AC-014 — проверить frontmatter `mermaid/SKILL.md` на отсутствие drawio в description как триггерного случая.
