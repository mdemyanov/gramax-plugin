---
title: Наведение порядка в test harness gramax и вычистка устаревших docs-путей
status: done
date: 2026-08-09
plugin: gramax
properties:
  - name: Тип контента
    value: [Требование]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# Наведение порядка в test harness gramax и вычистка устаревших docs-путей

## JTBD

**Story 1 — таксономия test harness:**
Когда я смотрю на `tests/gramax/` и вижу шесть suite, из которых два зелёных подключены к `check.sh --full`, а четыре красных не подключены никуда и гниют три релиза подряд, я (сопровождающий репозиторий gramax-marketplace) хочу разделить каждый suite на архивное свидетельство приёмки релиза и живой suite инвариантов, подключить живую часть к `--full`, чтобы test harness достоверно отражал состояние поставленного плагина, а не накапливал молчаливый долг.

**Story 2 — продуктовые дефекты v4.1.1:**
Когда разбор красных suite вскрывает, что часть их падений — не устаревшие ассерты, а реальные дефекты поставленного v4.1.0 (недомигрированный формат drawio-тега в двух живых файлах, отсутствующий WARNING из ADR-0008), я (сопровождающий репозиторий) хочу исправить эти дефекты в патч-релизе 4.1.1, чтобы плагин не противоречил собственной документации.

**Story 3 — чистота docs-путей в content/:**
Когда я вижу 55 упоминаний старых `docs/`-путей внутри `content/` после миграции на nauta, из которых 41 — нерабочие указатели, а 14 — исторические записи, я (сопровождающий репозиторий) хочу починить указатели, сохранить записи дословно и поставить гейт, который не даст такому расхождению повториться, чтобы читатель ADR и требований не упирался в несуществующие пути.

**Story 4 — онбординг на чистой машине:**
Когда новый контрибьютор клонирует репозиторий и не находит в `CLAUDE.md` или `README.md` инструкции, как включить роли `nauta`, я (сопровождающий репозиторий) хочу дать явный, проверяемый онбординг-путь (marketplace, локальное включение, `uv`, git-хуки), чтобы первый запуск не зависел от устной передачи знаний.

## Описание

Репозиторий `gramax-marketplace` держит в `tests/gramax/` шесть suite. Два — `orphan-references/` и `nauta-integration/` — зелёные и подключены к `bash scripts/check.sh --full`. Четыре — `remove-diagram-skills/`, `routing-mermaid-drawio/`, `mermaid-file-based/`, `diagram-on-demand/` — красные (31 упавший ассерт из 59) и не подключены ни к чему. Их никто не запускает начиная с релиза, для которого они писались.

Разбор красных suite показал, что падения смешивают три разные природы: версионные пины на давно ушедшую версию (`2.0.0`/`3.0.0`/`4.0.0` вместо текущей `4.1.0`), ассерты на устаревший синтаксис, которые сами суть свидетельство того, что было верно на момент приёмки, — и два живых дефекта в текущей поставке. Смешение этих трёх природ в одном suite не позволяет отличить «исторический факт» от «то, что нужно чинить прямо сейчас».

Параллельно миграция ADR/требований/отчётов из `docs/` в `content/` (задача nauta-integration) оставила 55 упоминаний старых `docs/`-путей внутри уже переехавших документов. Часть — нерабочие указатели (trace-шапки, футеры «Связанные артефакты»), часть — исторические записи о том, что было найдено или сделано на момент решения. Смешение этих двух ролей в одной правке рискует переписать историю задним числом.

Итог требования — четыре независимых, но согласованных изменения: (1) реорганизация `tests/gramax/` на архив и живые suite; (2) патч-релиз gramax 4.1.1, закрывающий два найденных дефекта; (3) гейт `doc-paths` с allowlist для сохраняемых записей; (4) документированный онбординг nauta для новых контрибьюторов.

## Что обнаружено (факты, HEAD = c6f15ec)

| Suite | Счёт | Подключён к `--full`? | Природа падений |
|---|---|---|---|
| `orphan-references` | зелёный | да | — |
| `nauta-integration` | зелёный | да | — |
| `remove-diagram-skills` | 11/16 | нет | версионные пины 2.0.0 (×2), устаревший формат тега (×2), реальный пробел в README (×1) |
| `routing-mermaid-drawio` | 14/18 | нет | версионные пины 3.0.0 (×2), устаревший формат тега (×1), невыполнимое требование про поле `skills` (×1) |
| `mermaid-file-based` | 2/13 | нет | ручной harness (TODO-заглушки, требуют реального вызова skill'а), версионный пин 4.0.0 (×1) |
| `diagram-on-demand` | 1/12 | нет | покрывает фичу, удалённую по ADR-0008 |

Два живых дефекта в v4.1.0:

1. **Миграция формата drawio-тега не доведена.** `plugins/gramax/skills/writer/SKILL.md` (строки 229, 234, 235, 243) и `plugins/gramax/README.md` (строка 39) всё ещё учат синтаксису `[drawio:./file.svg:alt:WxHpx]` / `<Image src="…"/>`, хотя `writer/references/drawio.md` и `skills/drawio/SKILL.md` уже используют канонический `<drawio path="…" width="…" height="…"/>`, а `writer/references/blocks.md:232` прямо называет старый формат «устаревшим (до v4.1.0)».
2. **WARNING из ADR-0008 «Решение 6» не добавлен.** `plugins/gramax/README.md` не предупреждает о конфликте триггеров `gramax:mermaid` с `Agents365-ai/mermaid-skill`, хотя ADR предписывает этот блок дословно.

Побочно: `scripts/check.sh` (строки 38-39, 75) содержит три мёртвых guard'а для submodule `plugins/claude-mermaid/`, удалённого в v3.0.0.

## Согласованные решения — статус

Дизайн этого требования согласован с пользователем на брейншторме (четыре развилки закрыты явными ответами 2026-08-09). Ниже — не предложения, а спецификация согласованного дизайна в терминах FR/AC. Решения о версионировании и о ретировке AC-014 (поле `skills`) закрепятся формально в **ADR-0011** (следующий по порядку) — SA формализует по брифу в конце документа.

## Scope

### In scope

- Реорганизация `tests/gramax/` на `archive/` (3 suite, git mv, не редактируются) + удаление `diagram-on-demand/` (git rm) + два новых живых suite (`plugin-contract/`, `doc-paths/`).
- Состав `plugin-contract/`: перегруппировка живых ассертов из трёх suite + новая проверка согласованности манифестов + явная ретировка невыполнимого AC.
- Расширение `tests/gramax/orphan-references/sunset-registry.txt` и схлопывание `EXCLUDE_RE`.
- Расщепление `mermaid-file-based` на статический контракт (в `plugin-contract/`) и параметризованный `archive/mermaid-file-based/verify.sh <output-dir>`.
- Продуктовые фиксы gramax 4.1.1: тег в двух файлах, WARNING в README, мёртвые guard'ы в `check.sh`, CHANGELOG, оба манифеста версий (`plugin.json`, корневой `marketplace.json` — только поле `version`).
- Гейт `tests/gramax/doc-paths/` с allowlist для 14 записей и починкой 41 указателя внутри `content/`.
- Онбординг: документ с инструкцией для чистой машины, `.claude/settings.local.json.example`, указатели из `CLAUDE.md` и корневого `README.md`.

### Out of scope

- ADR — создаёт SA (ADR-0011).
- Тесты (`ac-*.sh`, `run.sh`, `verify.sh` тело) — создаёт QA-author.
- Любые правки `scripts/*.py` и `scripts/apply-overlay.sh` — чужие файлы под `.nauta-scripts-basis.yaml`.
- Любые правки корневого `marketplace.json` за пределами поля `metadata.version`.
- Точная regex-формулировка паттернов `sunset-registry.txt` (см. открытый вопрос — риск ложных срабатываний).

## Функциональные требования

### A. Таксономия `tests/gramax/`

- **FR-001:** целевая структура `tests/gramax/`:

  | Suite | Судьба | Место в `check.sh` |
  |---|---|---|
  | `orphan-references/` | без изменений (реестр расширяется — FR-013) | `--full` |
  | `nauta-integration/` | без изменений, не трогать | `--full` |
  | `plugin-contract/` | новый | `--full` |
  | `doc-paths/` | новый | `--full` |
  | `archive/remove-diagram-skills/` | `git mv`, не редактируется | не запускается |
  | `archive/routing-mermaid-drawio/` | `git mv`, не редактируется | не запускается |
  | `archive/mermaid-file-based/` | `git mv` + один новый файл `verify.sh` в том же коммите | не запускается |
  | `diagram-on-demand/` | `git rm -r` целиком | — |

- **FR-002:** `tests/gramax/archive/README.md` — новый файл. Для каждого архивного suite фиксирует: исходный путь, версию релиза, приёмку которой suite подтверждал (2.0.0 / 3.0.0 / 4.0.0), явную формулировку «не редактировать, не запускать, не считать в отчётах». Отдельно фиксирует ретировку AC про поле `skills` в `plugin.json` (было `routing-mermaid-drawio` ac-014) с обоснованием: поле не встречается ни в одном из проверенных установленных плагинов — AC опиралось на ложную посылку и никогда не было выполнимым.
- **FR-003:** архивные suite перемещаются исключительно `git mv`, содержимое не меняется байт-в-байт — версионные пины `2.0.0`/`3.0.0`/`4.0.0` остаются как написаны, без `>=` и без обновления до `4.1.x`. Единственное разрешённое дополнение — новый файл `archive/mermaid-file-based/verify.sh`, добавляемый в том же коммите, что и переезд (см. FR-015); после этого коммита архив, включая `verify.sh`, не редактируется.
- **FR-004:** `tests/gramax/diagram-on-demand/` удаляется целиком через `git rm -r` (не архивируется). Обоснование: покрывает функциональность, удалённую по ADR-0008; факт приёмки уже зафиксирован в `content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md`; история доступна через `git log`.
- **FR-005:** ни один suite под `tests/gramax/archive/` не вызывается никаким агрегатором (`scripts/check.sh` в любом режиме, `run.sh` любого другого suite) и не входит ни в один количественный отчёт «N passed / M failed».

### B. Состав `plugin-contract/`

- **FR-006 (роутинг):** suite проверяет: `plugins/gramax/skills/drawio/SKILL.md` существует; его `description` несёт явные триггерные формулировки и явную границу «не для mermaid»; `description` содержит подсказку об установке внешнего плагина (`Agents365-ai`); тело файла содержит секцию workflow и секцию fallback с перекрёстной ссылкой на `gramax:mermaid`; `description` `mermaid/SKILL.md` ограничивает scope синтаксисом Mermaid DSL и перекрёстно ссылается на `gramax:drawio`. Заменяет `routing-mermaid-drawio` ac-001…008 и `remove-diagram-skills` ac-014.
- **FR-007 (формат тега):** suite проверяет позитивно — `writer/references/drawio.md` показывает `<drawio path="…" width="…" height="…"/>`; негативно — ни один живой документ плагина (кроме `CHANGELOG.md` и помеченного «устаревший формат» абзаца в `references/blocks.md`) не показывает `[drawio:` или `<Image src`. Заменяет `remove-diagram-skills` ac-008 (часть про тег) и `routing-mermaid-drawio` ac-005.
- **FR-008 (структура writer-справочника):** `writer/references/drawio.md` содержит: Prerequisites, draw.io desktop, Python 3, обе команды установки (`marketplace add`, `plugin install`), двухшаговый workflow, примечание «drawio-skill не вставляет тег сам». Заменяет `remove-diagram-skills` ac-008 (структурная часть).
- **FR-009 (README плагина):** `plugins/gramax/README.md` содержит блок prerequisites (заменяет `remove-diagram-skills` ac-009) и WARNING из ADR-0008 «Решение 6» — дословный текст (см. FR-019).
- **FR-010 (контракт mermaid SKILL.md — статическая половина `mermaid-file-based`):** `mermaid/SKILL.md` документирует: naming `<page-slug>-<diagram-slug>.mermaid` рядом со статьёй; правило `_index.md` → имя родительского каталога; самозакрывающийся тег с `width`/`height` и дефолтными значениями (`800px`/`450px` по `blocks.md`); запрет молчаливой перезаписи существующего `.mermaid`-файла; отсутствие устаревшей формулировки «inline DSL, без файла».
- **FR-011 (согласованность манифестов):** `plugins/gramax/.claude-plugin/plugin.json` поле `version` совпадает с `.claude-plugin/marketplace.json` полем `metadata.version` (правило синхронного версионирования ADR-0006); `plugins/gramax/CHANGELOG.md` содержит секцию `## <текущая версия>`. Поглощает все шесть версионных пинов трёх suite и `mermaid-file-based` ac-012 одной проверкой на согласованность, а не на конкретное число.
- **FR-012 (ретировка):** `plugin-contract` НЕ содержит проверку присутствия поля `skills` в `plugin.json`. Обоснование ретировки фиксируется в `archive/README.md` (FR-002), не в `plugin-contract`.
- **FR-013 (расширение `sunset-registry.txt`):** в `tests/gramax/orphan-references/sunset-registry.txt` добавляются записи для удалённого submodule `claude-mermaid` и удалённых skill'ов `diagram-on-demand`, `diagrams`.

  **Правило формулировки паттерна (проверено замером на HEAD=c6f15ec, PM 2026-08-09):** паттерн реестра опознаёт артефакт **по пути или по способу вызова**, никогда по голому слову. Голое слово ловит имена документов *об удалении* и прозу о текущем workflow — то есть ровно те упоминания, которые обязаны остаться. Замер по фактическим `SEARCH_PATHS` (`plugins scripts tests CLAUDE.md AGENTS.md README.md`) даёт для голых слов:

  | Голый паттерн | Ложные срабатывания | Последствие |
  |---|---|---|
  | `diagrams` | `writer/references/staging.md:30`, `writer/references/drawio.md:60` — проза о действующем workflow | гейт краснеет на живой документации |
  | `diagram-on-demand` | `nauta-integration/ac-005:27`, `ac-006:23`, `ac-006:32`, `ac-007:7`, `ac-007:21` — имена *переехавших документов* в ассертах зелёного suite | **ломает сегодня зелёный `orphan-references`** |
  | `claude-mermaid` | `tests/gramax/doc-paths/allowlist.txt` (появится по FR-026) — запись ссылается на `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md`, имя которого содержит строку | новый гейт ломает соседний гейт |

  Требуемая форма — по артефакту: `skills/diagrams` / `gramax:diagrams`, `skills/diagram-on-demand` / `gramax:diagram-on-demand`, `plugins/claude-mermaid`. Точная regex-формулировка — за SA (ADR-0011), проверка обоих направлений (ловит удалённое, не ловит перечисленное выше) — за QA-author.

  **Ограничение порядка:** паттерн `plugins/claude-mermaid` совпадает с `scripts/check.sh:39` и `:75` — мёртвыми guard'ами, которые удаляет FR-020. Расширение реестра (FR-013) не может быть закоммичено раньше очистки `check.sh` (FR-020), иначе промежуточный коммит красный вопреки NFR-001. Либо один коммит, либо FR-020 первым.
- **FR-014 (схлопывание `EXCLUDE_RE`):** `EXCLUDE_RE` в `tests/gramax/orphan-references/run.sh` заменяет два ad-hoc исключения (`^tests/gramax/remove-diagram-skills/`, `^tests/gramax/diagram-on-demand/`) на один принципиальный паттерн `^tests/gramax/archive/`. Исключение для `diagram-on-demand` становится избыточным и удаляется вместе с самим suite.
- **FR-015 (расщепление `mermaid-file-based`):** статически проверяемая половина (FR-010) переезжает в `plugin-contract`. Динамическая половина (реальный результат вызова skill'а: файл создан, DSL валиден, тег вставлен корректно, имя файла соответствует конвенции на реальных данных, файл не содержит markup, DSL не содержит конфликтного list-syntax) оформляется как единый параметризованный скрипт `tests/gramax/archive/mermaid-file-based/verify.sh <output-dir>`. Скрипт принимает путь к каталогу с артефактами, полученными от ручного вызова `gramax:mermaid` на тестовой статье; не входит ни в один режим `check.sh` (требует живого вызова skill'а, не может быть автоматизирован в pre-commit); ссылка на него и его назначение фиксируются в `archive/README.md`.
- **FR-016:** `plugin-contract` подключается к `bash scripts/check.sh --full` тем же способом, что `orphan-references` и `nauta-integration` — через собственный агрегатор (`tests/gramax/plugin-contract/run.sh`), результат которого учитывается в общем `FAILED`-счётчике `check.sh`.

### C. Продуктовые фиксы gramax 4.1.1

- **FR-017:** `plugins/gramax/skills/writer/SKILL.md` (строки 229, 234, 235, 243 на момент HEAD=c6f15ec) — устаревший синтаксис `[drawio:./file.svg:alt:WxHpx]` и `<Image src="…"/>` заменяется на канонический `<drawio path="…" width="…" height="…"/>`, включая оба примера в блоке «Примеры» и формулировку шага 4 двухшагового workflow.
- **FR-018:** `plugins/gramax/README.md` (строка 39 на момент HEAD) — секция «Diagrams (Draw.io)» показывает канонический тег вместо `[drawio:...]`.
- **FR-019:** `plugins/gramax/README.md` получает WARNING-блок из ADR-0008 «Решение 6» дословно:

  > **Warning:** Не устанавливайте `Agents365-ai/mermaid-skill` из 365-skills одновременно с `gramax:mermaid`. Оба skill'а описывают одинаковые триггеры (flowchart, sequence, gantt и др.) — Claude может выбрать не тот, поведение становится недетерминированным. Для drawio устанавливайте только `drawio` из 365-skills (не `mermaid`).

- **FR-020:** `scripts/check.sh` — удаляются три мёртвых guard'а для `plugins/claude-mermaid/` (submodule удалён в v3.0.0): комментарий и условие в JSON-проверке (строки ~38-39), фильтр в списке shellcheck-файлов (строка ~75).
- **FR-021:** `plugins/gramax/CHANGELOG.md` — новая секция `## 4.1.1` с подразделом `### Fixed`, перечисляющим: миграцию формата тега в `writer/SKILL.md` и `README.md` и добавление WARNING по ADR-0008.

  **Ограничение области (уточнено 2026-08-09 по итогам ревью задачи 4):** CHANGELOG плагина описывает только то, что получает установивший плагин. Правка `scripts/check.sh` (удаление мёртвых guard'ов, FR-020) в него **не входит**: `scripts/` — инфраструктура marketplace-репозитория, у потребителя плагина этого файла нет. Первоначальная редакция FR-021 требовала такую запись; ревью показало, что за всю историю `plugins/gramax/CHANGELOG.md` (секции 3.0.0, 4.0.0, 4.1.0) в нём не было ни одной записи о файле вне плагина. Запись о правке `check.sh` остаётся в git-истории (коммит `e695a46`).
- **FR-022:** `plugins/gramax/.claude-plugin/plugin.json` → `"version": "4.1.1"`.
- **FR-023:** корневой `.claude-plugin/marketplace.json` → `metadata.version: "4.1.1"`. Жёсткое ограничение: меняется только поле `version`; поля `name`, `owner`, `plugins` (структура, `name`, `source`, `description` внутри записи `gramax`) не трогаются. Разрешающий документ — ADR-0006 (синхронное версионирование) по прецеденту ADR-0008 «Решение 7»; дополнительная явная санкция получена от пользователя 2026-08-09 (см. «Инварианты и Safeguards»).

### D. Гейт `doc-paths`

- **FR-024:** новый suite `tests/gramax/doc-paths/` проверяет отсутствие устаревших `docs/`-путей **только внутри `content/**`**. Область не пересекается с `tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh` (покрывает `plugins`, `tests`, корневые `CLAUDE.md`/`AGENTS.md`/`README.md`) — тот файл не трогается.
- **FR-025:** 41 упоминание с ролью POINTER (диспозиция, раздел «POINTER — чиним») переносится по карте переездов:

  | Старый префикс/имя | Новый путь |
  |---|---|
  | `docs/adr/` | `content/00-project/adr/` |
  | `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` |
  | `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` |
  | `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` |
  | `docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` |
  | `docs/qa-reports/` | `content/60-implementation/test-reports/` |
  | `docs/acceptance/` | `content/60-implementation/acceptance/` |
  | `docs/research/` | `content/10-domain/research/` |
  | `docs/lessons-learned.md` | `content/lessons-learned.md` |

  Построчный список всех 41 файла/строки — в приложенной диспозиции
  (`docs/doc-paths-disposition.md`, раздел «POINTER — чиним»), не дублируется здесь построчно.

- **FR-026:** 14 упоминаний с ролью RECORD (диспозиция, раздел «RECORD — сохраняем дословно») остаются без изменений. Allowlist `tests/gramax/doc-paths/allowlist.txt` поддерживает две формы записи:
  - `file:line — причина` — точечная защита одной из 14 исторических записей диспозиции;
  - `file — причина` — защита файла целиком, для документов, чья тема — сама миграция путей (это требование, будущий ADR-0011, будущие отчёты QA-runner о его реализации). Такой документ не содержит указателей, приглашающих читателя перейти дальше по старому пути, — он содержит таблицу соответствия старого и нового путей или диспозицию переезда, то есть по критерию «роль предложения» (см. диспозицию) сам является RECORD, а не POINTER. Гейт для файла с whole-file записью не сканирует его построчно.
- **FR-027:** гейт `doc-paths` при построчной сверке allowlist обязан: если содержимое указанной строки файла не совпадает с ожидаемым паттерном записи allowlist — упасть с сообщением вида «allowlist устарел: строка N в файле F больше не содержит ожидаемого паттерна», не пропустить молча и не считать несовпадение отсутствием нарушения. Это поведение проверяется на фикстуре (`tests/gramax/doc-paths/fixtures/stale-allowlist/` — заведомо рассинхронизированная пара «файл + allowlist»), не мутацией живого `content/` — так проверка остаётся автоматизируемой и пригодной для `--full` (см. AC-028).
- **FR-028:** `doc-paths` подключается к `bash scripts/check.sh --full` через собственный агрегатор, аналогично `plugin-contract` (FR-016).
- **FR-029:** замена префикса `docs/` применяется только к точным именам файлов из карты переездов (FR-025), никогда по префиксу `docs/superpowers/specs/`. Два спека, остающиеся в `docs/` (`2026-05-08-apply-project-template-design.md`, `2026-08-07-nauta-integration-design.md`), не задеваются ни гейтом, ни правками.

### E. Онбординг

- **FR-030:** новый документ `docs/onboarding-nauta.md` (мета-артефакт о тулинге репозитория — не о домене продукта, поэтому `docs/`, не `content/`) описывает для контрибьютора на чистой машине: регистрацию marketplace `nauta` в `~/.claude/settings.json` с `ref: v0.3.1`; включение плагина локально через `.claude/settings.local.json` (файл в `.gitignore`, не коммитится); `uv` как жёсткий пререквизит — его отсутствие уже сегодня проваливает `scripts/check.sh --fast` (поведение реализовано, документ его фиксирует, не создаёт заново); запуск `bash scripts/install-hooks.sh`.
- **FR-031:** в репозиторий коммитится `.claude/settings.local.json.example` — шаблон для копирования пользователем в `.claude/settings.local.json`.
- **FR-032:** корневой `CLAUDE.md` (абзац после таблицы ролей, строки 19-22 на момент HEAD) получает ссылку-указатель на `docs/onboarding-nauta.md` — не дублирует его содержимое.
- **FR-033:** корневой `README.md` получает короткий указатель на `docs/onboarding-nauta.md`, адресованный контрибьютору (не потребителю плагина — установочные шаги README для потребителя не меняются). Место — новый короткий раздел после «Установка», перед «Skills (плагин gramax)». Не дублирует содержимое онбординг-документа.

### F. Задача 9 — осмысленный и зелёный шаг shellcheck (добавлено 2026-08-10 по итогам финального ревью)

Задача появилась по ходу цикла, не была описана исходной постановкой. Основание: разбор
показал, что шаг `==> shellcheck` в `bash scripts/check.sh --full` был красным независимо от
suite'ов этого требования — 94 замечания shellcheck на момент замера. Из них 62 из 94 —
ложные `SC1091` («Not following: ./lib/assert.sh»), вызванные способом вызова: shellcheck по
умолчанию ищет `source`-цели относительно текущего каталога (repo root), а не каталога
проверяемого скрипта. 70 из 94 — замечания внутри `tests/gramax/archive/**`, замороженного по
BR-001/ADR-0011 Решение 1: этот код не редактируется ни при каких обстоятельствах, замечания
там нечинимы принципиально, а не по недосмотру.

- **FR-034:** шаг `==> shellcheck` в `scripts/check.sh --full` вызывает `shellcheck` с флагами
  `-x -P SCRIPTDIR` (шеллчек идёт по `source` и резолвит путь от каталога скрипта — это починка
  вызова, снимающая все 62 ложных `SC1091`, а не подавление находок) и исключает
  `tests/gramax/archive/` из списка проверяемых файлов тем же принципом, каким `EXCLUDE_RE`
  гейта `tests/gramax/orphan-references/run.sh` исключает архив: это замороженное свидетельство
  приёмки прошлых релизов, а не сопровождаемый код. Оставшиеся 11 настоящих замечаний в 5 живых
  файлах (`SC2164`, `SC2059`, `SC2012`, `SC2086`) чинятся по существу, не исключением.

**Отдельно зафиксированный факт.** `bash scripts/check.sh --full` был красным **до начала
цикла** — проверено прогоном в отдельном worktree на стартовом коммите `c9be893` (родитель
коммитов требования/ADR/плана этого цикла): падал шаг `shellcheck`, оба suite
(`orphan-references`, `nauta-integration`) были зелёными. Постановка задачи цикла утверждала,
что гейт `--full` зелёный целиком — это разошлось с фактом. Задача 9 закрывает расхождение.

## Нефункциональные требования

- **NFR-001:** ни один промежуточный коммит в рамках реализации не ломает `bash scripts/check.sh --fast`; после подключения новых suite (FR-016, FR-028) то же верно для `bash scripts/check.sh --full`.
- **NFR-002:** все перемещения файлов/каталогов выполняются только через `git mv`; все удаления — только через `git rm`. Создание нового файла на месте старого без сохранения истории переезда недопустимо.
- **NFR-003:** все запуски Python-валидаторов из `scripts/` — только через `uv run`, не напрямую `python3`.
- **NFR-004:** suite под `tests/gramax/archive/` не исполняется ни одним автоматическим или ручным агрегатором и не входит ни в один количественный отчёт «N passed / M failed».
- **NFR-005:** правка корневого `marketplace.json` (FR-023) затрагивает исключительно поле `metadata.version`; любое иное изменение договорных полей требует отдельного ADR и отдельной явной санкции пользователя — вне периметра этого требования.
- **NFR-006:** `tests/gramax/doc-paths/` и `tests/gramax/plugin-contract/` выполняются без сетевых обращений и без интерактивного ввода — пригодны для pre-commit/CI контекста наравне с `orphan-references` и `nauta-integration`.

## Бизнес-правила

- **BR-001:** архивные suite — append-only историческая запись; после коммита переезда никаких правок содержимого, включая обновление версионных пинов до текущей версии плагина.
- **BR-002:** правка корневого `marketplace.json` требует ADR как разрешающего документа (красная линия CLAUDE.md). Для этого требования разрешающий документ — ADR-0006, применённый по прецеденту ADR-0008 «Решение 7», плюс явная санкция пользователя от 2026-08-09.
- **BR-003:** `tests/gramax/doc-paths/` не дублирует область `nauta-integration/ac-007` — граница проходит по каталогу `content/`, а не по паттерну пути.
- **BR-004:** замена `docs/`-путей никогда не выполняется по префиксу — только по точному имени файла из согласованной карты переездов.
- **BR-005:** `EXCLUDE_RE` в `orphan-references/run.sh` выражает один принцип («содержимое архива не считается остаточной ссылкой»), не список конкретных исторических имён suite.

## Доменные события

- Suite перемещён в `archive/` → suite исключён из всех агрегаторов и количественных отчётов.
- `plugin-contract` / `doc-paths` подключены к `check.sh --full` → красный результат блокирует релиз до фикса.
- Версия плагина поднята до 4.1.1 → CHANGELOG и оба манифеста синхронно отражают новую версию.
- Строка файла расходится с записью `allowlist.txt` → гейт `doc-paths` падает с явным сообщением «allowlist устарел», не пропускает молча.

## User Journey

1. Сопровождающий запускает `bash scripts/check.sh --full` и видит 2 зелёных + фиксирует, что ещё 4 suite существуют, но никуда не подключены (сегодняшнее состояние — точка отсчёта, не шаг реализации).
2. Дев проводит реорганизацию: `git mv` трёх suite в `archive/`, `git rm` `diagram-on-demand/`, пишет `archive/README.md`.
3. QA-author пишет `plugin-contract/` и `doc-paths/` по составу из FR-006…FR-015 и FR-024…FR-027.
4. Дев вносит продуктовые фиксы v4.1.1 (FR-017…FR-023) — `plugin-contract` должен позеленеть от исправления продукта, а не от смягчения ассертов.
5. Дев чинит 41 указатель и добавляет `allowlist.txt` на 14 записей (FR-025…FR-027).
6. Дев пишет `docs/onboarding-nauta.md` + `.claude/settings.local.json.example` + указатель в `CLAUDE.md`.
7. `bash scripts/check.sh --full` — зелёный, включает четыре suite вместо двух.

Альтернативный путь: если на шаге 4 `plugin-contract` не зеленеет после продуктовых фиксов — это сигнал, что найдены не все дефекты v4.1.0; фикс расширяется, ассерт не ослабляется.

## Acceptance Criteria

### Таксономия

- [ ] **AC-001:** новые директории существуют: `test -d tests/gramax/plugin-contract && test -d tests/gramax/doc-paths && test -d tests/gramax/archive && echo PASS`
- [ ] **AC-002:** `archive/README.md` существует и фиксирует ретировку AC про поле `skills`: `test -f tests/gramax/archive/README.md && grep -qi 'skills' tests/gramax/archive/README.md && echo PASS`
- [ ] **AC-003:** содержимое каждого архивного suite побайтово совпадает с состоянием непосредственно перед `git mv` (инвариант BR-001 — не «пины где-то в каталоге присутствуют», а полное совпадение с историческим коммитом), кроме нового `archive/mermaid-file-based/verify.sh` (FR-003, FR-015): для каждого файла `f` suite `s` (`remove-diagram-skills`, `routing-mermaid-drawio`, `mermaid-file-based`)
  `git show "$BASE_REV:tests/gramax/$s/$f" | diff -q - "tests/gramax/archive/$s/$f" && echo PASS`
  где `BASE_REV` — коммит непосредственно перед переездом (первый родитель коммита с `git mv`). Способ определения `BASE_REV` и обвязка цикла по файлам suite — на усмотрение QA-author; здесь фиксируется инвариант побайтового совпадения, не конкретный скрипт.
- [ ] **AC-004:** `diagram-on-demand/` удалён: `test ! -d tests/gramax/diagram-on-demand && echo PASS`
- [ ] **AC-005 (переформулирован 2026-08-10 по итогам финального ревью, см. FR-034):** архив не *вызывается* из `check.sh` — инвариант FR-005/NFR-004 про исполнение, не про упоминание. Задача 9 добавила в `check.sh` исключение `tests/gramax/archive/` из shellcheck-скана (комментарий + `grep -v`) — это упоминание, не вызов, и инвариант не нарушает. Проверка: `! grep -qE 'bash +tests/gramax/archive' scripts/check.sh && echo PASS`
- [ ] **AC-006:** `verify.sh` существует и требует параметр: `test -f tests/gramax/archive/mermaid-file-based/verify.sh && bash tests/gramax/archive/mermaid-file-based/verify.sh 2>&1 | grep -qi 'output-dir' && echo PASS`

### plugin-contract

- [ ] **AC-007 (роутинг, ожидаемо зелёный уже сегодня — regression guard):** `grep -qi 'не для.*mermaid\|НЕ для mermaid' plugins/gramax/skills/drawio/SKILL.md && grep -q 'gramax:mermaid' plugins/gramax/skills/drawio/SKILL.md && grep -q 'gramax:drawio' plugins/gramax/skills/mermaid/SKILL.md && echo PASS`
- [ ] **AC-008 (формат тега, позитив):** `grep -qE '<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>' plugins/gramax/skills/writer/references/drawio.md && echo PASS`
- [ ] **AC-009 (формат тега, негатив — падает до FR-017/FR-018):** `! grep -rE '\[drawio:|<Image src' plugins/gramax/skills/ plugins/gramax/README.md --include='*.md' | grep -v 'references/blocks.md' && echo PASS`
- [ ] **AC-010 (структура writer-справочника, ожидаемо зелёный уже сегодня):** `grep -q 'Prerequisites' plugins/gramax/skills/writer/references/drawio.md && grep -qi 'draw.io desktop' plugins/gramax/skills/writer/references/drawio.md && grep -q 'Python 3' plugins/gramax/skills/writer/references/drawio.md && grep -q 'marketplace add Agents365-ai/365-skills' plugins/gramax/skills/writer/references/drawio.md && grep -qi 'не вставляет' plugins/gramax/skills/writer/references/drawio.md && echo PASS`
- [ ] **AC-011 (README prerequisites + WARNING — падает до FR-019):** `grep -q 'marketplace add Agents365-ai/365-skills' plugins/gramax/README.md && grep -qi 'Warning' plugins/gramax/README.md && grep -qi 'mermaid-skill' plugins/gramax/README.md && grep -qi 'недетерминированным' plugins/gramax/README.md && echo PASS`
- [ ] **AC-012 (mermaid-контракт, ожидаемо зелёный уже сегодня):** `grep -q '<page-slug>-<diagram-slug>.mermaid' plugins/gramax/skills/mermaid/SKILL.md && grep -qi '_index.md' plugins/gramax/skills/mermaid/SKILL.md && grep -q '800px' plugins/gramax/skills/mermaid/SKILL.md && grep -q '450px' plugins/gramax/skills/mermaid/SKILL.md && ! grep -q 'inline DSL, без файла' plugins/gramax/skills/mermaid/SKILL.md && echo PASS`
- [ ] **AC-013 (согласованность манифестов):** `python3 -c "import json; p=json.load(open('plugins/gramax/.claude-plugin/plugin.json')); m=json.load(open('.claude-plugin/marketplace.json')); assert p['version']==m['metadata']['version'], (p['version'], m['metadata']['version']); print('PASS')"`
- [ ] **AC-014 (CHANGELOG-секция для текущей версии):** `V=$(python3 -c "import json; print(json.load(open('plugins/gramax/.claude-plugin/plugin.json'))['version'])"); grep -q "## $V" plugins/gramax/CHANGELOG.md && echo PASS`
- [ ] **AC-015 (ретировка):** ретировка означает, что `plugin-contract` не содержит ассерта на поле `skills` (а не что поля нет в манифесте — манифест мы не трогаем): `test -d tests/gramax/plugin-contract && ! grep -rlE "get\('skills'\)|\['skills'\]" tests/gramax/plugin-contract/ 2>/dev/null | grep -q . && echo PASS`
- [ ] **AC-016 (sunset-registry расширен, без ложных срабатываний):** реестр содержит нужные паттерны, и гейт зелёный целиком — зелёный результат исключает ложные срабатывания на `staging.md:30` и `drawio.md:60` (иначе `run.sh` вернул бы ненулевой код именно на них): `grep -qi 'claude-mermaid' tests/gramax/orphan-references/sunset-registry.txt && grep -qi 'diagram-on-demand' tests/gramax/orphan-references/sunset-registry.txt && bash tests/gramax/orphan-references/run.sh && echo PASS`
- [ ] **AC-017 (EXCLUDE_RE схлопнут, переформулирован 2026-08-10 по итогам финального ревью):** проверяется сам паттерн `EXCLUDE_RE`, а не файл целиком — комментарий в строке 4 (`# Обобщение ac-016 из remove-diagram-skills.`) легитимно упоминает старое имя suite и не должен ловиться проверкой: `EXCLUDE_RE` выражает принцип (`^tests/gramax/archive/`), а не список конкретных имён: `! grep 'EXCLUDE_RE=' tests/gramax/orphan-references/run.sh | grep -qE 'remove-diagram-skills|tests/gramax/diagram-on-demand' && grep 'EXCLUDE_RE=' tests/gramax/orphan-references/run.sh | grep -q 'tests/gramax/archive' && echo PASS`
- [ ] **AC-018 (подключение к `--full`):** `grep -q 'plugin-contract' scripts/check.sh && grep -q 'doc-paths' scripts/check.sh && echo PASS`

### Продуктовые фиксы v4.1.1

- [ ] **AC-019:** `writer/SKILL.md` не содержит устаревший синтаксис и содержит канонический тег: `! grep -qE '\[drawio:|<Image src' plugins/gramax/skills/writer/SKILL.md && grep -qE '<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>' plugins/gramax/skills/writer/SKILL.md && echo PASS`
- [ ] **AC-020:** `README.md` не содержит устаревший синтаксис и содержит канонический тег: `! grep -qE '\[drawio:|<Image src' plugins/gramax/README.md && grep -qE '<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>' plugins/gramax/README.md && echo PASS`
- [ ] **AC-021:** `scripts/check.sh` не упоминает `claude-mermaid`: `grep -c 'claude-mermaid' scripts/check.sh | grep -q '^0$' && echo PASS`
- [ ] **AC-022:** `CHANGELOG.md` содержит секцию `## 4.1.1` с `### Fixed`: `grep -q '## 4.1.1' plugins/gramax/CHANGELOG.md && grep -q '### Fixed' plugins/gramax/CHANGELOG.md && echo PASS`
- [ ] **AC-023:** `plugin.json` версии 4.1.1: `python3 -c "import json; d=json.load(open('plugins/gramax/.claude-plugin/plugin.json')); assert d['version']=='4.1.1', d['version']; print('PASS')"`
- [ ] **AC-024:** корневой `marketplace.json` — только `version` изменился: `python3 -c "
import json
d=json.load(open('.claude-plugin/marketplace.json'))
assert d['name']=='gramax-marketplace'
assert d['owner']=={'name':'mdemyanov','email':'qutask@gmail.com'}
assert d['metadata']['version']=='4.1.1', d['metadata']['version']
assert len(d['plugins'])==1
assert d['plugins'][0]['name']=='gramax'
assert d['plugins'][0]['source']=='./plugins/gramax'
print('PASS')"`

### doc-paths

- [ ] **AC-025:** указатели из карты переездов (FR-025) заменены на новые пути — точечная проверка на репрезентативных точках, не подсчёт «ровно N». Общее число упоминаний `docs/`-путей в `content/` не является метрикой этой задачи: оно растёт вместе с документами, которые *описывают* саму миграцию (это требование, будущий ADR-0011, будущие отчёты QA-runner) — такие документы легитимно называют старые пути и защищены whole-file записью allowlist (FR-026), не входят в счёт 14 точечных RECORD-записей диспозиции:
  `grep -q 'content/00-project/adr/0006' content/00-project/adr/0010-mermaid-file-based-workflow.md && ! grep -q 'docs/adr/0006' content/00-project/adr/0010-mermaid-file-based-workflow.md && grep -q 'content/30-requirements/2026-05-11-remove-diagram-skills.md' content/00-project/adr/0008-drop-internal-drawio-skills.md && ! grep -q 'docs/superpowers/specs/2026-05-11-remove-diagram-skills.md' content/00-project/adr/0008-drop-internal-drawio-skills.md && bash tests/gramax/doc-paths/run.sh && echo PASS`
- [ ] **AC-026:** `allowlist.txt` содержит ровно 14 точечных записей формата `file:line — причина` (whole-file записи формата `file — причина` — отдельная форма из FR-026, в этот счёт не входят): `test $(grep -cE '^[^#].+:[0-9]+ — ' tests/gramax/doc-paths/allowlist.txt) -eq 14 && echo PASS`
- [ ] **AC-027:** гейт зелёный на чистом дереве: `bash tests/gramax/doc-paths/run.sh && echo PASS`
- [ ] **AC-028:** гейт падает внятно при рассинхроне allowlist — проверяется на фикстуре, не на живом `content/` (мутировать рабочее дерево в pre-commit/CI нельзя): каталог `tests/gramax/doc-paths/fixtures/stale-allowlist/` содержит пару «файл + allowlist», где содержимое allowlisted строки заведомо не совпадает с ожидаемым паттерном. Тест-кейс (пишет QA-author) прогоняет логику гейта против этой фикстуры и подтверждает: код возврата ≠0, вывод содержит подстроку «allowlist устарел». Структурная проверка на уровне требования: `test -d tests/gramax/doc-paths/fixtures/stale-allowlist && echo PASS`
- [ ] **AC-029:** два спека вне периметра не задеты: `test -f docs/superpowers/specs/2026-05-08-apply-project-template-design.md && test -f docs/superpowers/specs/2026-08-07-nauta-integration-design.md && echo PASS`

### Онбординг

- [ ] **AC-030:** онбординг-документ существует и содержит ключевые пункты: `test -f docs/onboarding-nauta.md && grep -q 'v0.3.1' docs/onboarding-nauta.md && grep -q 'settings.local.json' docs/onboarding-nauta.md && grep -qi 'uv' docs/onboarding-nauta.md && grep -q 'install-hooks.sh' docs/onboarding-nauta.md && echo PASS`
- [ ] **AC-031:** пример settings закоммичен: `test -f .claude/settings.local.json.example && echo PASS`
- [ ] **AC-032:** `CLAUDE.md` указывает на онбординг-документ: `grep -q 'onboarding-nauta.md' CLAUDE.md && echo PASS`
- [ ] **AC-033:** корневой `README.md` указывает на онбординг-документ: `grep -q 'onboarding-nauta.md' README.md && echo PASS`

### Композитный AC

- [ ] **AC-034:** `bash scripts/check.sh --full` завершается с exit code 0 после всех изменений: `bash scripts/check.sh --full && echo PASS`
- [ ] **AC-035 (задача 9, добавлен 2026-08-10):** шаг `shellcheck` в `scripts/check.sh --full` вызывается с флагами `-x -P SCRIPTDIR` и исключает `tests/gramax/archive/` из проверяемых файлов: `grep -q -- '-x -P SCRIPTDIR' scripts/check.sh && grep -qF "grep -v '^tests/gramax/archive/'" scripts/check.sh && echo PASS`

## Инварианты и Safeguards

**Содержательные:**
- Архивные suite (`tests/gramax/archive/**`) не редактируются после коммита переезда — единственное исключение зафиксировано явно (FR-003, `verify.sh`).
- Корневой `.claude-plugin/marketplace.json` в рамках этого требования меняет ровно одно поле (`metadata.version`); любое иное изменение — вне периметра, требует отдельного ADR и отдельной санкции.
- Гейт `doc-paths` никогда не пропускает молча несовпадение allowlist — либо совпадение с ожидаемым паттерном, либо явный отказ с диагностикой.
- Замена `docs/`-путей — только по точному имени файла из карты переездов (FR-025), никогда по префиксу.

**Sensitive content:** N/A — требование не вводит PII, секретов, NDA-контента. `.claude/settings.local.json.example` — шаблон без реальных значений; сам `.claude/settings.local.json` уже в `.gitignore` и не коммитится.

**Жизненный цикл:** ревизия не запланирована отдельно от следующего релиза плагина. Owner изменений — сопровождающий репозиторий (PM). При следующем major/minor bump gramax проверить, не накопился ли новый долг в test harness по той же схеме (два зелёных / N красных не подключённых).

## Открытые вопросы

1. **Точная формулировка паттерна `diagrams` в `sunset-registry.txt`.** Согласованное решение (Р2) говорит «добавить имена удалённых skill'ов», но голый паттерн `diagrams` как отдельная строка реестра создаст ложные срабатывания: `plugins/gramax/skills/writer/references/staging.md:30` и `plugins/gramax/skills/writer/references/drawio.md:60` легитимно упоминают «подкаталог `diagrams/`» в прозе о текущем (не удалённом) workflow. Старый тест `remove-diagram-skills/ac-010` уже наступал на эти грабли и обходил их точечным паттерном `/gramax:diagrams`, а не голым словом. Зафиксировал как ограничение в FR-013, но точную regex-формулировку оставляю QA-author — это уровень реализации теста, не архитектурное решение.

2. **`archive/README.md` как «новый файл» внутри директории, которая после этого не редактируется.** FR-002/FR-003 требуют создать `archive/README.md` в момент реорганизации и затем никогда не трогать его — как и остальной архив. Это самосогласованно (README создаётся один раз в коммите реорганизации, как и `verify.sh`), но стоит явно проговорить в брифе Dev: `README.md` и `verify.sh` — единственные два новых файла в `archive/`, оба появляются в одном коммите, дальше архив полностью заморожен целиком, включая эти два файла.

3. **`plugin-contract` — плоская структура или подкаталоги.** Целевое дерево в Р1 показывает `plugin-contract/` как один каталог без вложенных поддиректорий на шесть категорий проверок (роутинг / тег / structure / README / mermaid-контракт / манифесты). Это решение оставлено QA-author при написании конкретных `ac-*.sh` — FR-006…FR-011 описывают, что проверяется, не как физически разложены файлы.

## Definition of Done

- Все FR-001…FR-034 реализованы, AC-001…AC-035 проходят.
- `bash scripts/check.sh --full` зелёный, включает 4 suite вместо 2.
- `archive/README.md` фиксирует ретировку AC про поле `skills` и назначение `verify.sh`.
- Ни один живой файл плагина не показывает устаревший синтаксис drawio-тега.
- ADR-0011 формализует таксономию test harness, ретировку AC и разрешение на правку `marketplace.json` — готовит SA.

## Бриф для SA

**Требование:** `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md`
**Фаза:** реорганизация test harness + патч-релиз 4.1.1 + гейт doc-paths + онбординг.

**Спроектировать:**
- ADR-0011: формализовать таксономию `archive/` vs живые suite (FR-001…FR-005), ретировку AC про поле `skills` (FR-012), точку решения о `plugin-contract` как плоском suite vs подкаталогах (открытый вопрос №3), разрешение на правку `metadata.version` в корневом `marketplace.json` (FR-023, по прецеденту ADR-0008 «Решение 7»).
- Точную regex-формулировку для записи `diagrams` в `sunset-registry.txt`, разрешающую открытый вопрос №1 (не голый `diagrams`, а паттерн, не задевающий `staging.md:30` / `drawio.md:60`).
- Формат агрегатора `run.sh` для `plugin-contract/` и `doc-paths/`, согласованный со стилем существующих `orphan-references/run.sh` и `nauta-integration/run.sh`.

**Бизнес-правила для валидаций:**
- Архив не редактируется после коммита переезда (BR-001).
- `marketplace.json` — только поле `version` (BR-002, NFR-005).
- `doc-paths` не дублирует `nauta-integration/ac-007` (BR-003).
- Замена `docs/`-путей — только по точному имени файла (BR-004).

**Acceptance Criteria для проверки архитектуры:** AC-001, AC-003, AC-005, AC-013, AC-017, AC-018, AC-024, AC-027, AC-034, AC-035.

## Бриф для QA-author

**Требование:** `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md`

**Покрыть тестами:**
- `plugin-contract/` — по FR-006…FR-011, с учётом, что часть проверок (AC-007, AC-010, AC-012) ожидаемо зелёные уже сегодня — оформить как regression guard, не как новый failing stub (см. `content/lessons-learned.md`, запись «TDD-stubs могут быть частично зелёными от старта»).
- `doc-paths/` — по FR-024…FR-027, включая сценарий рассинхрона allowlist (AC-028) как отдельный тест-кейс на поведение гейта, не только на happy path.
- `archive/mermaid-file-based/verify.sh` — параметризованный скрипт, не `ac-*.sh`; описать usage при вызове без аргументов (AC-006).
- Паттерн `diagrams` в `sunset-registry.txt` — явно протестировать оба legit-упоминания (`staging.md:30`, `drawio.md:60`) как negative test case (открытый вопрос №1).

**Особое внимание:**
- `plugin-contract` должен позеленеть от исправления продукта (FR-017…FR-023), не от смягчения ассертов — verification-before-completion обязателен перед claim «готово».
