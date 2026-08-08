---
title: Переход gramax-marketplace на nauta как ролевую команду
status: draft
date: 2026-08-07
plugin: marketplace
---

# Переход gramax-marketplace на nauta

## JTBD

Когда я развиваю плагин `gramax` и запускаю ролевую работу (требования, архитектура, TDD, QA,
документация), я хочу вызывать роли из плагина `nauta` и получать артефакты в предсказуемых
местах, проверяемых автоматическим гейтом, — чтобы не поддерживать собственную копию восьми
агентских промптов и не сверять руками, где какой документ должен лежать.

## Описание

Репозиторий содержит локальный плагин `project` (8 агентов + 8 команд в
`.claude/plugins/project/`), который дублирует роли из `nauta`. Плагин **не загружается**:
`.claude/settings.json` объявляет marketplace `gramax-plugin-internal-local`, но записи о нём нет
в `~/.claude/plugins/known_marketplaces.json`, и в сессии отсутствуют как команды `project:*`,
так и типы агентов `project:*-agent`. При этом `CLAUDE.md` и `AGENTS.md` продолжают описывать эти
роли как рабочие — документация обещает `/pm`, `/ba`, `/sa`, которых нет.

`nauta` v0.2.1 установлена на user-scope и активна (`"nauta@nauta": true`), то есть команды
`/nauta:*` и агенты `nauta:*-agent` доступны уже сейчас. Функционально nauta — надмножество
локального `project`: те же семь ролей в более свежих редакциях (ba 267 строк против 173, sa 215
против 150), плюс compliance, devops, devsecops, три pipeline-команды и три скилл-пакета.

Единственное содержательное расхождение — конвенция путей. Агенты nauta ссылаются на `content/…`
больше сотни раз, тогда как артефакты gramax живут в `docs/`. Правило разделения задаёт сам nauta
(`sa-agent.md:124`, `dev-agent.md:89`): артефакты о репозитории и его инструментарии — в `docs/`,
предметные артефакты продукта или домена — в `content/`. Для gramax продукт — это сам плагин,
поэтому ADR о сплите скиллов, выборе drawio-бэкенда и mermaid-workflow относятся ко второй
категории. Прецедент такого переезда есть: `project_template` сделал его в PT-EPIC-17.

Переход состоит из четырёх независимо проверяемых частей: удаление мёртвого плагина, миграция
документов в `content/`, подключение гейта `validate-content.py`, актуализация `CLAUDE.md` и
`AGENTS.md`.

## Функциональные требования

### FR-1. Удаление локального плагина `project`

Удаляются `.claude/plugins/project/` целиком (8 агентов, 8 команд, манифест),
`.claude/.claude-plugin/marketplace.json` и обе записи из `.claude/settings.json`
(`extraKnownMarketplaces.gramax-plugin-internal-local`, `enabledPlugins.project@…`).

Файл `.claude/settings.json` после правки остаётся валидным JSON. Если после удаления обеих
записей объект пустеет — файл остаётся с `{}`, не удаляется.

### FR-2. Пиннинг nauta на тег релиза

В `~/.claude/settings.json` источник marketplace `nauta` получает `"ref": "v0.2.1"`. Сейчас поле
отсутствует, из-за чего берётся ветка репозитория по умолчанию и `/plugin marketplace update`
может подменить версию без следа. `ref` — единственный узел пиннинга у nauta: источник плагина
внутри её `marketplace.json` задан относительным путём `"./"`, который полей не несёт.

Это правка пользовательского конфига вне репозитория; она не попадает в коммит и выполняется
явным шагом.

### FR-3. Миграция документов в `content/`

24 файла переезжают, 2 остаются. Переезд выполняется через `git mv` (сохранение истории), затем
каждому файлу проставляется frontmatter.

| Назначение | Источник | Файлов |
|---|---|---|
| `content/00-project/adr/0001…0010-*.md` | `docs/adr/0001…0010-*.md` | 10 |
| `content/00-project/adr/_index.md` | `docs/adr/README.md` | 1 |
| `content/lessons-learned.md` | `docs/lessons-learned.md` | 1 |
| `content/10-domain/research/2026-05-11-drawio-skill-external.md` | `docs/research/` | 1 |
| `content/30-requirements/` | `docs/superpowers/specs/` (4 предметных) | 4 |
| `content/60-implementation/test-reports/` | `docs/qa-reports/` | 4 |
| `content/60-implementation/acceptance/` | `docs/acceptance/` | 3 |

`docs/adr/.gitkeep` удаляется вместе с опустевшим каталогом.

Остаются в `docs/` как мета-артефакты о самом репозитории:
`docs/superpowers/specs/2026-05-08-apply-project-template-design.md`,
`docs/superpowers/plans/2026-05-08-apply-project-template.md`, эта спека и её план.

Путь `content/lessons-learned.md` — корень `content/`, а не `content/00-project/`: именно так на
него ссылаются агенты nauta (10 вхождений).

`content/40-architecture/` не создаётся: класть туда нечего, а каталог с `_index.md` без статей
даст сироту. Его заведёт первый вызов `/nauta:sa`.

Подкаталог `content/60-implementation/acceptance/` — расширение таксономии nauta (та явно
называет только `test-reports/`). Отчёты приёмки отделены от отчётов прогона, потому что это
разные артефакты разных ролей: приёмка — вердикт BA по AC, тест-отчёт — результат прогона QA.

### FR-4. Контракт `.doc-root.yaml`

Создаётся `content/.doc-root.yaml`. Схема вычитана из `validate-content.py`: в `.doc-root.yaml`
enum объявляется ключом `values` при `type: "Enum"` (с заглавной E — сравнение точное), в
frontmatter статьи элемент `properties` несёт ровно ключи `name` и `value`.

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

`Архитектура` объявлена заранее под будущий `content/40-architecture/`. `Historical` в статусах
нужен: ADR-0002 и ADR-0003 помечены в реестре именно так. `Active` — для живых документов, у
которых нет конечного состояния: журнал уроков, будущий roadmap.

`sizeBudgets` не задаётся — при пустом списке проверка C11 отключается, а калибровать пороги под
gramax сейчас не на чем.

### FR-5. Frontmatter мигрируемых статей

Проверка C12 требует непустое свойство «Тип контента» у каждой не-`_index` статьи. Frontmatter
сейчас есть только у 4 файлов из 24 и в произвольной схеме (`feature:`, `plugin:`, `created:`).
Каждому мигрируемому файлу добавляется блок `properties` в object-нотации:

```yaml
---
properties:
  - name: Тип контента
    value: [ADR]
  - name: Статус
    value: [Accepted]
  - name: Плагин
    value: [gramax]
---
```

Существующие произвольные ключи верхнего уровня (`title`, `status`, `date`, `feature`) не
удаляются: C4 и C5 читают только `fm["properties"]` и на прочие ключи не смотрят.

Значение «Тип контента» определяется каталогом назначения:

| Каталог | Тип контента |
|---|---|
| `content/00-project/adr/` | `ADR` |
| `content/lessons-learned.md` | `Урок` |
| `content/10-domain/research/` | `Research` |
| `content/30-requirements/` | `Требование` |
| `content/60-implementation/test-reports/` | `Тест-отчёт` |
| `content/60-implementation/acceptance/` | `Приёмка` |

Значение «Статус» для ADR берётся из реестра `docs/adr/README.md`, не назначается заново:
`Accepted` — 0006, 0008, 0009, 0010; `Superseded` — 0001, 0004, 0005, 0007; `Historical` — 0002,
0003.

### FR-6. Файлы `_index.md`

Проверка C1 требует `_index.md` в каждом каталоге, содержащем `.md` рекурсивно. Создаются девять:
`content/`, `content/00-project/`, `content/00-project/adr/`, `content/10-domain/`,
`content/10-domain/research/`, `content/30-requirements/`, `content/60-implementation/`,
`content/60-implementation/test-reports/`, `content/60-implementation/acceptance/`.

Из них `content/00-project/adr/_index.md` — это переехавший `docs/adr/README.md` с поправленными
относительными ссылками; остальные восемь создаются заново.

Каждый `_index.md` перечисляет ссылками свои статьи и подразделы. Это не косметика: проверка C10
помечает несвязанные статьи как сирот, и полный перечень в индексе закрывает предупреждение.

Файлы `_index.md` не несут `properties` — проверки C3, C4, C5, C12 их пропускают, а C2 явно
запрещает им properties.

### FR-7. Гейт `validate-content.py`

Выполняется `/nauta:sync-scripts`. Команда кладёт 10 валидаторов в `scripts/`, создаёт
`.nauta-scripts-basis.yaml` с sha256-трекингом и `docs/overlays/profiles/.gitkeep`. Собственные
`scripts/check.sh`, `scripts/install-hooks.sh` и `.githooks/pre-commit` не перезаписываются:
`deliver.sh` не находит их в базисе и относит к «чужим».

`scripts/check.sh` дополняется третьей проверкой в режиме `--fast`:

```
whitespace → json → uv run scripts/validate-content.py
```

Вызов через `uv run` обязателен: скрипт объявляет зависимости по PEP 723 (`pyyaml>=6.0,<7.0`) и
на голом `python3` упадёт при отсутствии pyyaml в текущем окружении.

Восемь остальных доставленных файлов (`validate-profile.py`, `apply-overlay.sh`,
`_apply_profile.py`, `_apply_yaml_patch.py`, `_drift_check.py`, `_init_helpers.py`,
`_resolve_agents.py`, `check-status-drift.py`) остаются неиспользованными — это принятая цена
официального канала поставки в обмен на конфликт-детекцию и путь обновления. `check.sh` их не
вызывает.

### FR-8. Замена sunset-теста на постоянный orphan-гейт

`tests/project/sunset-pattern-in-agents/run.sh` ассертит наличие слов «sunset», «orphan» и
`grep -rn` в текстах `.claude/plugins/project/agents/qa-author-agent.md` и `dev-agent.md`. Он
проверяет формулировку промпта, а не поведение, и умирает вместе с плагином. В агентах nauta
этого паттерна нет (проверено: ни `sunset`, ни `orphan`).

Тест и каталог `tests/project/` удаляются. Взамен создаётся `tests/gramax/orphan-references/`:

- `sunset-registry.txt` — реестр удалённых артефактов, по одному regex-паттерну на строку, строки
  с `#` — комментарии. Стартовое наполнение переносится из
  `tests/gramax/remove-diagram-skills/ac-016-no-orphan-references.sh`: `drawio_convert`,
  `find_doc_root`, `save_diagram`, `insert_diagram_ref`, `validate_diagram_type`.
- `run.sh` — грепает репозиторий по каждому паттерну реестра и падает на любом совпадении.

Область поиска — `plugins/`, `scripts/`, `tests/`, `CLAUDE.md`, `AGENTS.md`, `README.md`.
Исключаются места, где историческое упоминание легитимно: `*/CHANGELOG.md`,
`content/00-project/adr/`, `content/60-implementation/`, `docs/`, сам `sunset-registry.txt` и два
исторических suite — `tests/gramax/remove-diagram-skills/` (проверяет ровно эти же имена как
предмет своих AC) и `tests/gramax/diagram-on-demand/` (покрывает удалённую фичу; 11 его файлов
содержат все пять паттернов реестра). Без второго исключения гейт красный с первого прогона.

Существующий `ac-016-no-orphan-references.sh` не удаляется: он привязан к AC своей фичи. Новый
гейт — его обобщение, действующее постоянно и пополняемое при каждом следующем sunset.

Правило фиксируется в «Красных линиях» `CLAUDE.md`: удаляя skill или script, добавь его имя в
`tests/gramax/orphan-references/sunset-registry.txt` и прогони `grep -rn` по репозиторию.
`CLAUDE.md` загружается автоматически, в отличие от `AGENTS.md`.

### FR-9. Актуализация `CLAUDE.md` и `AGENTS.md`

`CLAUDE.md`:
- «Карта команды» — команды `/nauta:*`, колонка артефактов указывает на пути `content/`.
- «Архитектурные правила» — убрать строку про `.claude/plugins/project/`, добавить правило
  разделения `content/` и `docs/`.
- «Когда какой скилл звать» — без изменений.
- «Красные линии» — добавить sunset-правило из FR-8; поправить упоминание `docs/adr/`.
- «Self-improvement» — журнал уроков теперь `content/lessons-learned.md`.
- «Команды сборки» — упомянуть, что `--fast` включает `validate-content.py`.

`AGENTS.md`:
- «Каталог ролей» — 7 core-ролей с промпт-файлами из nauta, devsecops как opt-in, devops и
  compliance выключены с обоснованием (плагин не деплоится, compliance-скоупа нет).
- «Контракт вызова субагента» — усилить: проектные конвенции передаются **в промпте**, потому что
  из 10 агентов nauta только 3 упоминают `CLAUDE.md` (точечно, для секций «Стек» и «Команды
  сборки»), а `AGENTS.md` не читает ни один.
- Пример промпта для `/nauta:dev` — обновить пути на `content/`.

### FR-10. Обновление ссылок на переехавшие файлы

После миграции чинятся ссылки в: `plugins/gramax/CHANGELOG.md` (2 строки с `docs/adr/…`),
комментарии-заголовки в `tests/gramax/remove-diagram-skills/*.sh` (`# Spec:`, `# ADR:`),
внутренние относительные ссылки в переехавшем реестре ADR.

Ссылки вида `docs/auth/overview.md` в `plugins/gramax/skills/mermaid/SKILL.md` и
`plugins/gramax/README.md` **не трогаются**: это примеры чужого Gramax-каталога в документации
скилла, а не пути этого репозитория.

## Нефункциональные требования

- `scripts/check.sh --fast` остаётся пригодным для pre-commit: добавленный валидатор укладывается
  в секунды.
- `git mv` сохраняет историю файлов; переезд не выполняется через delete + create.
- Правки `~/.claude/settings.json` (FR-2) выполняются отдельно от коммита в репозиторий.
- Корневой `.claude-plugin/marketplace.json` не изменяется — это публичный договор с
  пользователями, его правка требует ADR.

## Затронутые файлы

Удаляются: `.claude/plugins/project/` (17 файлов), `.claude/.claude-plugin/marketplace.json`,
`tests/project/`, `docs/adr/.gitkeep`.

Создаются: `content/.doc-root.yaml`, 9 файлов `_index.md`,
`tests/gramax/orphan-references/{run.sh,sunset-registry.txt}`, 10 файлов от `/nauta:sync-scripts`,
`.nauta-scripts-basis.yaml`, `docs/overlays/profiles/.gitkeep`.

Перемещаются: 24 файла из `docs/` в `content/`.

Изменяются: `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `scripts/check.sh`,
`plugins/gramax/CHANGELOG.md`, комментарии в `tests/gramax/remove-diagram-skills/*.sh`.

Не изменяются: `plugins/gramax/` (кроме CHANGELOG), `.claude-plugin/marketplace.json`,
`scripts/install-hooks.sh`, `.githooks/pre-commit`.

## Acceptance Criteria

- **AC-1.** `.claude/plugins/project/` отсутствует; `.claude/settings.json` — валидный JSON без
  упоминаний `gramax-plugin-internal-local` и `project@`.
- **AC-2.** `~/.claude/settings.json` содержит `"ref": "v0.2.1"` в источнике marketplace `nauta`.
- **AC-3.** `content/` содержит 24 мигрированных файла по маппингу FR-3; `docs/adr/`,
  `docs/acceptance/`, `docs/qa-reports/`, `docs/research/`, `docs/lessons-learned.md`
  отсутствуют.
- **AC-4.** `git log --follow` на любом мигрированном файле показывает историю до переезда.
- **AC-5.** `docs/superpowers/specs/2026-05-08-apply-project-template-design.md` и
  `docs/superpowers/plans/2026-05-08-apply-project-template.md` на месте.
- **AC-6.** `uv run scripts/validate-content.py` — exit 0, ноль errors. Warnings допустимы.
- **AC-7.** Каждая не-`_index` статья в `content/` объявляет непустое «Тип контента»; значения
  соответствуют таблице FR-5.
- **AC-8.** Статусы ADR в `content/00-project/adr/` совпадают с реестром из `docs/adr/README.md`
  до переезда.
- **AC-9.** `bash scripts/check.sh --fast` — exit 0, и в выводе присутствует шаг
  `validate-content.py`.
- **AC-10.** Собственные `scripts/check.sh`, `scripts/install-hooks.sh` и `.githooks/pre-commit`
  после `/nauta:sync-scripts` не изменились (sha256 совпадает с досинковым).
- **AC-11.** `tests/project/` отсутствует; `bash tests/gramax/orphan-references/run.sh` — exit 0.
- **AC-12.** `tests/gramax/orphan-references/run.sh` падает, если добавить в отслеживаемый файл
  ссылку на паттерн из реестра (проверка того, что гейт живой).
- **AC-13.** `grep -rn 'plugins/project' CLAUDE.md AGENTS.md` — пусто; обе таблицы ролей ссылаются
  на `nauta`.
- **AC-14.** `grep -rnE 'docs/(adr|qa-reports|acceptance|research)'` по `plugins/`, `tests/`,
  `CLAUDE.md`, `AGENTS.md`, `README.md` — пусто. Вне области: `scripts/` (доставленные
  валидаторы — чужие файлы под управлением базиса синка, `validate-content.py` несёт `docs/adr/`
  в собственном комментарии) и `tests/gramax/nauta-integration/` (его ассерты обязаны называть
  старые пути). Примеры вида `docs/auth/overview.md` в `plugins/gramax/skills/mermaid/SKILL.md`
  и `plugins/gramax/README.md` под паттерн не подпадают и остаются нетронутыми.
- **AC-15.** Существующие suite в `tests/gramax/` не деградируют относительно замеренного
  baseline: `remove-diagram-skills` 11 passed / 5 failed, `routing-mermaid-drawio` 15 / 3,
  `mermaid-file-based` 2 / 11, `diagram-on-demand` 1 / 11. Числа passed не уменьшаются, числа
  failed не растут.

  Ни один из четырёх suite сейчас не зелёный, и это не следствие перехода. Причины разные:
  часть ассертов привязана к версии плагина и устарела (ждут `2.0.0`, в манифесте `4.1.0`);
  `mermaid-file-based` — ручной харнесс, который печатает `TODO: …` и требует реального вызова
  скилла, шеллом не автоматизируется; `diagram-on-demand` покрывает фичу, удалённую по ADR-0008.
  Приводить их в порядок — отдельная работа, см. «Вне скоупа».

## Открытые вопросы

Нет. Три развилки закрыты решением пользователя 2026-08-07: миграция в `content/` (а не маппинг
путей), `/nauta:sync-scripts` целиком (а не cherry-pick валидатора), удаление локального плагина
с переносом sunset-урока в гейт (а не сохранение тонкого оверлея).

## Вне скоупа

- Подъём sunset-паттерна в промпты самой `nauta` — работа в другом репозитории
  (`tools-ai/nauta`), отдельный PR и релиз.
- Профили и оверлеи nauta — не заводятся, gramax остаётся вне профильной модели. Каталог
  `docs/overlays/profiles/` появится с пустым `.gitkeep` как побочный эффект
  `/nauta:sync-scripts` (FR-7); ни одного профиля в нём не создаётся и `validate-profile.py` не
  подключается к `check.sh`.
- `content/00-project/roadmap.md` и `content/40-architecture/` — создаются при первой реальной
  надобности соответствующей ролью.
- Правка `plugins/gramax/` (код скиллов) — переход инфраструктурный.
- Починка красных suite в `tests/gramax/` — 30 падающих ассертов из 59 существовали до перехода.
  Три отдельные задачи: обновить version-pinned ассерты под текущий манифест, решить судьбу
  ручного харнесса `mermaid-file-based`, удалить или заархивировать `diagram-on-demand` (его
  фича удалена по ADR-0008). Здесь фиксируется только baseline, чтобы переход не ухудшил его.

## Бриф для планирования

Порядок фаз диктуется зависимостями: гейт нельзя включить до появления `content/`, а `content/`
бессмысленно наполнять без `.doc-root.yaml`.

1. Удаление мёртвого плагина и замена sunset-теста (FR-1, FR-8) — независимо от остального.
2. Каркас `content/`: `.doc-root.yaml` и девять `_index.md` (FR-4, FR-6).
3. Миграция файлов и frontmatter (FR-3, FR-5, FR-10).
4. Подключение гейта (FR-7) — после того, как `content/` валиден, иначе pre-commit заблокирует
   собственные коммиты миграции.
5. Документация (FR-9).
6. Пиннинг nauta (FR-2) — вне репозитория, в любой момент.
