---
title: "RES-005: Формы ссылок на артефакты в корпусе content/ — код-спаны, markdown-ссылки, голые идентификаторы"
order: 4
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---

# RES-005: Формы ссылок на артефакты в корпусе content/ — код-спаны, markdown-ссылки, голые идентификаторы

**Дата:** 2026-08-13
**Исследователь:** researcher-agent
**Запрос PM/BA:** для задачи BA-001 «форма ссылки на артефакт» — измерить и классифицировать все
ссылки-текстом (код-спаны с путями) в `content/`, найти протухшие пути, невидимые валидатору, и
установить, есть ли другие классы деградации ссылочности.
**Глубина:** standard (сплошной проход по всем 52 статьям, без выборок)

## TL;DR

Корпус — 52 файла. **136** код-спанов вида `` `content/<путь>.md` `` указывают на **28** уникальных
целей; **26** из них существуют, **2** — нет (один подтверждённый протухший путь, один намеренный
пример). Из 136 код-спанов **103** — навигационные отсылки, которые следовало оформить как
markdown-ссылку; **19** — уместное упоминание файла как предмета обсуждения (часто про **другой**
репозиторий с той же структурой `content/`); **13** — самоссылка документа на себя в шапке «Spec/
ADR/Требование:»; 1 спорный. Настоящих markdown-ссылок в `content/` — **60** внутренних (все
резолвятся, 0 битых) плюс 8 внешних URL; **79% статей (33 из 42)** не-`_index.md` не имеют ни одной
входящей ссылки, кроме навигационной из своего `_index.md`, — формально не сироты (C10 зелёный), но
содержательно на них никто не ссылается из прозы. Код-спаны на пути вне `content/`
(`plugins/`, `tests/`, `scripts/`, `docs/`, манифесты) дают **157** уникальных целей и почти 900
вхождений; 55 целей не существуют физически, но **все 55** объяснимы (устаревшая раскладка `docs/`
до миграции, историческое упоминание удалённого/переименованного артефакта, отклонённый вариант
архитектуры, омоним пути из другого репозитория или неполная короткая форма) — необъяснимых мёртвых
путей в этом классе не найдено. Отдельно — самая частая форма ссылки в корпусе вообще без пути:
голый идентификатор `ADR-NNNN` (380 вхождений, работает — есть таблица-реестр в
`content/00-project/adr/_index.md`) и `FR-/AC-/BR-/NFR-NNN` (тысячи вхождений — но номера **не
уникальны глобально**: `FR-001`…`FR-011` переиспользованы в 8 разных требованиях).

## Метод (воспроизводимо)

Все команды — из корня репозитория (рабочее дерево этой волны).

1. **Перечень корпуса:** `find content -name "*.md" | wc -l` → 52.
2. **Извлечение код-спанов с путями.** Написан скрипт, повторяющий маскирование fenced-блоков и
   inline-кода **дословно** по регуляркам обоих живых валидаторов (`_FENCE_RE`, `_INLINE_CODE_RE` из
   `scripts/validate-content.py:270-274` и `plugins/gramax/scripts/validate_structure.py:242-243`):
   fenced-блок обнуляется построчно, затем `(`+)([^\n]+?)\1` вырезает inline-код (внимание: класс
   символов внутри — **весь текст без переноса строки**, а не «без бэктика»; более узкий вариант
   ломается на двойных бэктиках `` `` `[X](Y)` `` `` — конкретно эта ловушка обсуждается в
   FR-065/FR-066, `content/30-requirements/2026-08-11-writer-consumer-rules.md:125` и
   `content/40-architecture/2026-08-11-writer-rules-disposition.md:56`; первая версия моего
   инструмента наступила на неё же и дала 3 ложных «битых» markdown-ссылки, пока regex не поправил).
   Каждый оставшийся код-спан на строке проверяется эвристикой «похож на путь» (содержит `/` или
   известное голое имя файла).
3. **Фильтр по цели `content/*.md`:** `re.match(r'^content/[^\s\`]+\.md$', span)` — даёт ровно 136
   спанов на 28 уникальных целей (совпадает с числом из брифа PM, что подтверждает метод).
4. **Существование цели:** `os.path.exists(target)` относительно корня репозитория — для всех 28
   целей класса `content/*.md` и отдельно для целей вне `content/`.
5. **Пути вне `content/`:** внутри каждого код-спана регуляркой
   `[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+/?` ищутся подстроки, начинающиеся с `plugins/`, `tests/`,
   `scripts/`, `docs/`, `.claude-plugin/`, `.githooks/`, либо равные `plugin.json`/`marketplace.json`
   (это ловит и составные спаны вида `` `bash scripts/check.sh --fast` ``, где путь — часть команды).
   Хвостовые `:NN` (номер строки) и пунктуация отрезаются перед дедупликацией — 157 уникальных целей,
   899 вхождений (без учёта 12 явно вымышленных иллюстративных путей вида `docs/auth/login-flow.md`
   из сценариев user-story в [Diagram on Demand](../../30-requirements/2026-05-08-diagram-on-demand-design.md) и
   [Mermaid skill — file-based workflow](../../00-project/adr/0010-mermaid-file-based-workflow.md) — они не претендуют быть путём в этом
   репозитории, это условный пример «представь, что у тебя есть статья»).
6. **Markdown-ссылки:** тот же маскированный текст, `!?\[[^\]\n]*\]\(([^)\n]+)\)`, внешние цели
   (`^(?:[a-z][a-z0-9+.\-]*:|//)`) исключены, оставшиеся резолвятся `(source.parent / target).resolve()`
   и проверяются на существование — 60 внутренних (0 битых), плюс 8 внешних URL = 68 всего markdown-
   ссылок в корпусе (бриф PM оценивал 77 — разница объяснима grep-подсчётом без маскирования кода,
   моя цифра воспроизводима командой выше и совпадает с `Errors: 0 | Warnings: 0` реального
   `uv run scripts/validate-content.py`).
7. **Граф входящих ссылок:** для каждой не-`_index.md` статьи проверено, есть ли входящая
   markdown-ссылка НЕ из `_index.md` того же раздела.
8. **Голые идентификаторы:** `grep -rohE 'ADR-[0-9]{4}' content/ | wc -l` и аналогично для
   `FR-/AC-/BR-/NFR-/RES-/OQ-[0-9]{3}`, `G[0-9]{1,2}`.

Полный список файлов (52), оба скрипта извлечения и результирующие JSON-дампы оставлены в
scratch-директории сессии; таблицы ниже — их прямой вывод, без ручного редактирования цифр.

## Ключевые находки

1. Метод масок обоих живых валидаторов совпадает дословно (тот же `_FENCE_RE`/`_INLINE_CODE_RE`),
   поэтому подсчёт код-спанов, приведённый ниже, — это ровно то, что **не видят** C9/C10 —
   [established], перепроверено запуском `uv run scripts/validate-content.py` (0 errors/0 warnings).
2. 136 код-спанов `content/*.md` — 103 навигационные (75%), должны быть markdown-ссылкой —
   [established], полная таблица в разделе «Задача 1».
3. Оба протухших пути в код-спанах `content/*.md`, названные в брифе PM, подтверждены и это —
   единственные два во всём классе `content/*.md` — [established].
4. Класс «путь вне `content/`» (plugins/tests/scripts/docs/манифесты) даёт 55 несуществующих целей
   из 157 уникальных, но при разборе каждой — 0 необъяснимых: все относятся к одной из 5 известных
   причин (устаревший `docs/`-layout, историческое упоминание удалённого, отклонённый архитектурный
   вариант, омоним чужого репозитория, укороченная форма) — [established], таблица в «Задача 2».
5. 33 из 42 (79%) содержательных статей не имеют ни одной прозаической входящей ссылки — только
   навигационную из `_index.md` своего раздела; C10 зелёный, но это не то же самое, что «читатель
   находит статью из текста другой статьи» — [established], раздел «Задача 3».
6. Голые идентификаторы `ADR-NNNN` (380) и `FR-/AC-/BR-/NFR-NNN` (тысячи, суммарно) — самая частая
   форма отсылки к другому артефакту в корпусе вообще, но она не входит ни в одну из трёх категорий
   из брифа PM (не код-спан-путь, не markdown-ссылка, не путь вне `content/`) — четвёртая форма,
   раздел «Задача 3». `ADR-NNNN` разрешается штатно (таблица-реестр в `adr/_index.md`); `FR-/AC-NNN`
   — нет глобального реестра, и номера переиспользуются между документами — [established].
7. Найден один случай точностного дрейфа: `content/30-requirements/2026-08-11-writer-consumer-rules.md:74`
   цитирует `content/00-project/adr/_index.md:11`, но на HEAD цитируемый текст стоит на строке 10, не 11
   — [established], off-by-one, вероятно из-за правки `_index.md` после того, как цитата была написана.

## Задача 1 — классификация код-спанов `content/*.md`

Полная таблица — все 136 код-спанов, найденные по регулярке `^content/[^\s\`]+\.md$` внутри
маскированного (после вырезания fenced/inline-кода) текста 52 статей. Классы:

- **NAV** — навигационная отсылка («spec:», «ADR:», «требование:», «см.», «зафиксировано в»,
  «обоснование в», «прецедент», «дополняет», «supersedes», «применяет semver-policy» и т. п.) —
  должна была быть markdown-ссылкой. Столбец «предлагаемая форма» даёт вычисленный относительный
  путь (`os.path.relpath` от каталога документа-источника до цели) — это черновик для DEV-задачи,
  не финальная формулировка текста ссылки.
- **SELF** — документ цитирует **сам себя** в шаблонной шапке `**Spec:**`/`**ADR:**`/
  `**Требование:**` (обычно в начале раздела «Бриф для SA/QA-author/Dev» — это повторяющийся
  паттерн-шаблон, не опечатка). Ссылка на себя внутри одного файла не несёт навигационной пользы —
  оставить код-спан.
- **SUBJECT** — статья говорит о файле/каталоге как о предмете (обсуждает его свойства, поведение,
  историю), а не отправляет читателя туда. Внутри этого класса скрыт нетривиальный подкласс:
  несколько строк относятся не к [Gramax Marketplace](../../_index.md) **этого** репозитория, а к одноимённому файлу
  в **другом** репозитории (эталонный вендорский корпус документации либо локальный потребитель,
  независимо проверенные PM) — тот же относительный путь, физически другой файл на другой машине.
  Разобрано подробнее в «Задаче 3» (там же — расшифровка меток «потребитель N»).
- **СПОРНО** — не удалось уверенно отнести к NAV или SUBJECT; см. пояснение под таблицей.

Существование цели проверено `os.path.exists()`; несуществующие цели помечены отдельно (их ровно 2
на весь класс `content/*.md` — обе внутри таблицы, строки 112 и 118).

| # | файл:строка | цель (код-спан) | класс | предлагаемая форма |
|---|---|---|---|---|
| 1 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:21` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 2 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:85` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 3 | `content/00-project/adr/0002-drawio-mcp-backend-selection.md:92` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 4 | `content/00-project/adr/0003-drawio-backend-vendoring-strategy.md:94` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 5 | `content/00-project/adr/0004-router-and-engine-selection.md:102` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 6 | `content/00-project/adr/0005-save-flow-script-api-contract.md:197` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 7 | `content/00-project/adr/0006-marketplace-json-semver-strategy.md:77` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 8 | `content/00-project/adr/0007-out-of-scope-phase2.md:90` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-08-diagram-on-demand-design.md)` |
| 9 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:25` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-remove-diagram-skills.md)` |
| 10 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:239` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-remove-diagram-skills.md)` |
| 11 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:240` | `content/00-project/adr/0008-drop-internal-drawio-skills.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 12 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:327` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-remove-diagram-skills.md)` |
| 13 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:328` | `content/10-domain/research/2026-05-11-drawio-skill-external.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-05-11-drawio-skill-external.md)` |
| 14 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:21` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-routing-mermaid-drawio.md)` |
| 15 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:362` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-routing-mermaid-drawio.md)` |
| 16 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:363` | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 17 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:382` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-11-routing-mermaid-drawio.md)` |
| 18 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:383` | `content/00-project/adr/0008-drop-internal-drawio-skills.md` | NAV | markdown-ссылка `[текст](./0008-drop-internal-drawio-skills.md)` |
| 19 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:384` | `content/00-project/adr/0004-router-and-engine-selection.md` | NAV | markdown-ссылка `[текст](./0004-router-and-engine-selection.md)` |
| 20 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:385` | `content/00-project/adr/0006-marketplace-json-semver-strategy.md` | NAV | markdown-ссылка `[текст](./0006-marketplace-json-semver-strategy.md)` |
| 21 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:21` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-12-mermaid-file-based-design.md)` |
| 22 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:236` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-12-mermaid-file-based-design.md)` |
| 23 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:237` | `content/00-project/adr/0010-mermaid-file-based-workflow.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 24 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:316` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-05-12-mermaid-file-based-design.md)` |
| 25 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:318` | `content/00-project/adr/0006-marketplace-json-semver-strategy.md` | NAV | markdown-ссылка `[текст](./0006-marketplace-json-semver-strategy.md)` |
| 26 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:319` | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` | NAV | markdown-ссылка `[текст](./0009-drawio-stub-and-claude-mermaid-removal.md)` |
| 27 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:320` | `content/00-project/adr/0008-drop-internal-drawio-skills.md` | NAV | markdown-ссылка `[текст](./0008-drop-internal-drawio-skills.md)` |
| 28 | `content/00-project/adr/0011-test-harness-taxonomy.md:30` | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md)` |
| 29 | `content/00-project/adr/0011-test-harness-taxonomy.md:65` | `content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md` | NAV | markdown-ссылка `[текст](../../60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md)` |
| 30 | `content/00-project/adr/0011-test-harness-taxonomy.md:431` | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md)` |
| 31 | `content/00-project/adr/0011-test-harness-taxonomy.md:432` | `content/00-project/adr/0006-marketplace-json-semver-strategy.md` | NAV | markdown-ссылка `[текст](./0006-marketplace-json-semver-strategy.md)` |
| 32 | `content/00-project/adr/0011-test-harness-taxonomy.md:434` | `content/00-project/adr/0008-drop-internal-drawio-skills.md` | NAV | markdown-ссылка `[текст](./0008-drop-internal-drawio-skills.md)` |
| 33 | `content/00-project/adr/0011-test-harness-taxonomy.md:436` | `content/00-project/adr/0008-drop-internal-drawio-skills.md` | NAV | markdown-ссылка `[текст](./0008-drop-internal-drawio-skills.md)` |
| 34 | `content/00-project/adr/0011-test-harness-taxonomy.md:437` | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` | NAV | markdown-ссылка `[текст](./0009-drawio-stub-and-claude-mermaid-removal.md)` |
| 35 | `content/00-project/adr/0011-test-harness-taxonomy.md:438` | `content/00-project/adr/0010-mermaid-file-based-workflow.md` | NAV | markdown-ссылка `[текст](./0010-mermaid-file-based-workflow.md)` |
| 36 | `content/00-project/adr/0012-catalog-validation-contract.md:21` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 37 | `content/00-project/adr/0012-catalog-validation-contract.md:22` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 38 | `content/00-project/adr/0012-catalog-validation-contract.md:45` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 39 | `content/00-project/adr/0012-catalog-validation-contract.md:255` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 40 | `content/00-project/adr/0012-catalog-validation-contract.md:256` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 41 | `content/00-project/adr/0012-catalog-validation-contract.md:257` | `content/00-project/adr/0006-marketplace-json-semver-strategy.md` | NAV | markdown-ссылка `[текст](./0006-marketplace-json-semver-strategy.md)` |
| 42 | `content/00-project/adr/0012-catalog-validation-contract.md:258` | `content/00-project/adr/0011-test-harness-taxonomy.md` | NAV | markdown-ссылка `[текст](./0011-test-harness-taxonomy.md)` |
| 43 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:21` | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-mermaid-file-based-adoption.md)` |
| 44 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:210` | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-mermaid-file-based-adoption.md)` |
| 45 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:211` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 46 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:212` | `content/00-project/adr/0010-mermaid-file-based-workflow.md` | NAV | markdown-ссылка `[текст](./0010-mermaid-file-based-workflow.md)` |
| 47 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:213` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](./0012-catalog-validation-contract.md)` |
| 48 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:214` | `content/00-project/adr/0006-marketplace-json-semver-strategy.md` | NAV | markdown-ссылка `[текст](./0006-marketplace-json-semver-strategy.md)` |
| 49 | `content/00-project/adr/0014-dual-publication-targets.md:159` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](./0012-catalog-validation-contract.md)` |
| 50 | `content/00-project/adr/0015-root-index-inert.md:26` | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-index-md-at-catalog-root.md)` |
| 51 | `content/00-project/adr/0015-root-index-inert.md:36` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 52 | `content/00-project/adr/0015-root-index-inert.md:42` | `content/10-domain/research/2026-08-11-index-md-root-probe.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-index-md-root-probe.md)` |
| 53 | `content/00-project/adr/0015-root-index-inert.md:58` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 54 | `content/00-project/adr/0015-root-index-inert.md:303` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](./0012-catalog-validation-contract.md)` |
| 55 | `content/00-project/adr/0015-root-index-inert.md:305` | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-index-md-at-catalog-root.md)` |
| 56 | `content/00-project/adr/0015-root-index-inert.md:307` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 57 | `content/00-project/adr/0015-root-index-inert.md:308` | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` | NAV | markdown-ссылка `[текст](./0009-drawio-stub-and-claude-mermaid-removal.md)` |
| 58 | `content/00-project/adr/0015-root-index-inert.md:309` | `content/00-project/adr/0013-mermaid-adoption-and-migration.md` | NAV | markdown-ссылка `[текст](./0013-mermaid-adoption-and-migration.md)` |
| 59 | `content/00-project/adr/0015-root-index-inert.md:317` | `content/10-domain/research/2026-08-11-index-md-root-probe.md` | NAV | markdown-ссылка `[текст](../../10-domain/research/2026-08-11-index-md-root-probe.md)` |
| 60 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:54` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 61 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:92` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 62 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:93` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 63 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:94` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](./2026-08-11-plugin-consumers-gaps.md)` |
| 64 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:97` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 65 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:151` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 66 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:162` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 67 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:167` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 68 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:257` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 69 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:269` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 70 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:320` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 71 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:322` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 72 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:324` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](./2026-08-11-plugin-consumers-gaps.md)` |
| 73 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:326` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 74 | `content/10-domain/research/2026-08-11-index-md-root-probe.md:234` | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md` | NAV | markdown-ссылка `[текст](./2026-08-11-index-md-at-catalog-root.md)` |
| 75 | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:127` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 76 | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:132` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 77 | `content/30-requirements/2026-05-08-diagram-on-demand-design.md:238` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 78 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:172` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 79 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:191` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 80 | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md:193` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 81 | `content/30-requirements/2026-05-12-mermaid-file-based-design.md:150` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 82 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:103` | `content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md` | NAV | markdown-ссылка `[текст](../60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md)` |
| 83 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:123` | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` | СПОРНО | спорно — см. пояснение в тексте |
| 84 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:155` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 85 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:156` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 86 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:157` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 87 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:158` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 88 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:162` | `content/lessons-learned.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 89 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:339` | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 90 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:357` | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 91 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:360` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../lessons-learned.md)` |
| 92 | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:33` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 93 | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:157` | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 94 | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:158` | `content/00-project/adr/0010-mermaid-file-based-workflow.md` | NAV | markdown-ссылка `[текст](../00-project/adr/0010-mermaid-file-based-workflow.md)` |
| 95 | `content/30-requirements/2026-08-11-validation-contract.md:45` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 96 | `content/30-requirements/2026-08-11-validation-contract.md:64` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 97 | `content/30-requirements/2026-08-11-validation-contract.md:200` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 98 | `content/30-requirements/2026-08-11-validation-contract.md:273` | `content/_index.md` | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 99 | `content/30-requirements/2026-08-11-validation-contract.md:395` | `content/30-requirements/2026-08-11-validation-contract.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 100 | `content/30-requirements/2026-08-11-writer-consumer-rules.md:43` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 101 | `content/30-requirements/2026-08-11-writer-consumer-rules.md:294` | `content/40-architecture/2026-08-11-writer-rules-disposition.md` | NAV | markdown-ссылка `[текст](../40-architecture/2026-08-11-writer-rules-disposition.md)` |
| 102 | `content/30-requirements/2026-08-11-writer-consumer-rules.md:345` | `content/30-requirements/2026-08-11-writer-consumer-rules.md` | SELF | оставить код-спан (самоссылка документа на себя в метаданных «Spec/ADR/Требование:») |
| 103 | `content/40-architecture/2026-08-11-writer-rules-disposition.md:21` | `content/30-requirements/2026-08-11-writer-consumer-rules.md` | NAV | markdown-ссылка `[текст](../30-requirements/2026-08-11-writer-consumer-rules.md)` |
| 104 | `content/40-architecture/2026-08-11-writer-rules-disposition.md:22` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md` | NAV | markdown-ссылка `[текст](../10-domain/research/2026-08-11-plugin-consumers-gaps.md)` |
| 105 | `content/40-architecture/2026-08-11-writer-rules-disposition.md:25` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../00-project/adr/0012-catalog-validation-contract.md)` |
| 106 | `content/40-architecture/2026-08-11-writer-rules-disposition.md:147` | `content/30-requirements/2026-08-11-writer-consumer-rules.md` | NAV | markdown-ссылка `[текст](../30-requirements/2026-08-11-writer-consumer-rules.md)` |
| 107 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:20` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../30-requirements/2026-08-11-validation-contract.md)` |
| 108 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:21` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../00-project/adr/0012-catalog-validation-contract.md)` |
| 109 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:22` | `content/00-project/adr/0015-root-index-inert.md` | NAV | markdown-ссылка `[текст](../00-project/adr/0015-root-index-inert.md)` |
| 110 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:23` | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md` | NAV | markdown-ссылка `[текст](./acceptance/2026-08-11-validation-contract-at-design.md)` |
| 111 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:39` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../lessons-learned.md)` |
| 112 | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:57` | `content/article.md` **(не существует)** | SUBJECT | оставить код-спан (статья говорит о файле/каталоге как о предмете, часто — про другой репозиторий) |
| 113 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:17` | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-mermaid-file-based-adoption.md)` |
| 114 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:19` | `content/00-project/adr/0013-mermaid-adoption-and-migration.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0013-mermaid-adoption-and-migration.md)` |
| 115 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:20` | `content/00-project/adr/0010-mermaid-file-based-workflow.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0010-mermaid-file-based-workflow.md)` |
| 116 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:55` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../../lessons-learned.md)` |
| 117 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:121` | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md` | NAV | markdown-ссылка `[текст](./2026-08-11-validation-contract-at-design.md)` |
| 118 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:148` | `content/60-implementation/acceptance/2026-08-11-mermaid-file-based-adoption.md` **(не существует)** | NAV | markdown-ссылка — цель отсутствует, чинить нельзя без правки цели |
| 119 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:17` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |
| 120 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:18` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 121 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:19` | `content/00-project/adr/0015-root-index-inert.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0015-root-index-inert.md)` |
| 122 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:66` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 123 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:96` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../../lessons-learned.md)` |
| 124 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:125` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 125 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:17` | `content/30-requirements/2026-08-11-writer-consumer-rules.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-writer-consumer-rules.md)` |
| 126 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:18` | `content/40-architecture/2026-08-11-writer-rules-disposition.md` | NAV | markdown-ссылка `[текст](../../40-architecture/2026-08-11-writer-rules-disposition.md)` |
| 127 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:86` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../../lessons-learned.md)` |
| 128 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:97` | `content/lessons-learned.md` | NAV | markdown-ссылка `[текст](../../lessons-learned.md)` |
| 129 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:156` | `content/40-architecture/2026-08-11-writer-rules-disposition.md` | NAV | markdown-ссылка `[текст](../../40-architecture/2026-08-11-writer-rules-disposition.md)` |
| 130 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:20` | `content/00-project/adr/0011-test-harness-taxonomy.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0011-test-harness-taxonomy.md)` |
| 131 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:125` | `content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md` | NAV | markdown-ссылка `[текст](../acceptance/2026-05-08-diagram-on-demand-acceptance.md)` |
| 132 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:243` | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md)` |
| 133 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:27` | `content/00-project/adr/0012-catalog-validation-contract.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0012-catalog-validation-contract.md)` |
| 134 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:28` | `content/00-project/adr/0013-mermaid-adoption-and-migration.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0013-mermaid-adoption-and-migration.md)` |
| 135 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:29` | `content/00-project/adr/0015-root-index-inert.md` | NAV | markdown-ссылка `[текст](../../00-project/adr/0015-root-index-inert.md)` |
| 136 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:195` | `content/30-requirements/2026-08-11-validation-contract.md` | NAV | markdown-ссылка `[текст](../../30-requirements/2026-08-11-validation-contract.md)` |

**Пояснение к спорной строке (# 83).** `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:123`
— таблица ложных срабатываний гейта `doc-paths`: «`claude-mermaid` | `tests/gramax/doc-paths/allowlist.txt`
(появится по FR-026) — запись ссылается на `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md`,
имя которого содержит строку». Спан описывает, что будет содержать **другой, ещё не созданный**
файл (`allowlist.txt`), а не отправляет читателя по цитируемому пути напрямую — с одной стороны это
ближе к SUBJECT (иллюстрация будущего содержимого чужого файла), с другой — путь называется
конкретно и по факту уже сейчас разрешим как markdown-ссылка. Оставляю на решение BA: обе трактовки
защитимы.

**Итог по классификации:** NAV — 103 (75.7%), SUBJECT — 19 (14.0%), SELF — 13 (9.6%), СПОРНО — 1
(0.7%). Сумма — 136.

**Существующие vs несуществующие цели (28 уникальных).** 26 существуют. Не существуют:

| цель | где встречается (все вхождения) | статус |
|---|---|---|
| `content/60-implementation/acceptance/2026-08-11-mermaid-file-based-adoption.md` | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:148` (строка 118 таблицы) | **протухший путь** — реальный файл лежит в `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md` (подтверждено брифом PM, не моя новая находка) |
| `content/article.md` | `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:57` (строка 112 таблицы) | намеренный пример в прозе, не дефект (подтверждено брифом PM) |

Оба случая обнаружены исключительно скриптовым сканом код-спанов на `content/` — ни C9, ни C10 их не
видят, потому что оба они внутри inline-кода.

## Задача 2 — staleness-скан

### 2.1. Класс `content/*.md` (28 целей)

Существование проверено для всех 28 — см. таблицу выше: 26 из 28 существуют, 2 не существуют (уже
разобраны в Задаче 1).

### 2.2. Класс «путь вне `content/`» (157 уникальных целей, 899 вхождений)

Полная таблица — каждая уникальная цель, факт существования, число вхождений и локации (при более
чем 3 вхождениях показаны первые три плюс точный итог — не сокращение находок, а сокращение
повторов одной и той же находки; итоговое число нигде не «примерно»). Строки исключают 12
вымышленных иллюстративных путей (`docs/auth/...`, `docs/api/endpoints.md`, `docs/infra/deploy.*`,
`docs/getting-started.md`, `docs/main.md` — 18 вхождений суммарно), которые появляются в user-story
сценариях `content/30-requirements/2026-05-08-diagram-on-demand-design.md` и
`content/00-project/adr/0010-mermaid-file-based-workflow.md` как условный пример «представь себе
проект с такой-то статьёй» — они не претендуют быть путём этого репозитория ни при какой трактовке.

| цель | сущ.? | вхожд. | локации (file:line; при >3 — первые 3 + итог) |
|---|---|---|---|
| `.claude-plugin/marketplace.json` | да | 39 | `content/00-project/adr/0006-marketplace-json-semver-strategy.md:21`; `content/00-project/adr/0006-marketplace-json-semver-strategy.md:44`; `content/00-project/adr/0006-marketplace-json-semver-strategy.md:79`; … ещё 36 (всего 39) |
| `.githooks/pre-commit` | да | 4 | `content/00-project/adr/0012-catalog-validation-contract.md:131`; `content/00-project/adr/0012-catalog-validation-contract.md:133`; `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:163`; … ещё 1 (всего 4) |
| `docs/` | да | 2 | `content/00-project/adr/0011-test-harness-taxonomy.md:235`; `content/00-project/adr/0011-test-harness-taxonomy.md:259` |
| `docs/acceptance/` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:160` |
| `docs/acceptance/2026-05-08-diagram-on-demand-acceptance.md` | **нет** | 2 | `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:62`; `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:89` |
| `docs/acceptance/2026-05-11-remove-diagram-skills-acceptance.md` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:88` |
| `docs/adr` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:74` |
| `docs/adr/` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:154` |
| `docs/adr/0001-0007` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:64` |
| `docs/adr/0006` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:291` |
| `docs/adr/0006-` | **нет** | 3 | `content/00-project/adr/0011-test-harness-taxonomy.md:242`; `content/00-project/adr/0011-test-harness-taxonomy.md:243`; `content/00-project/adr/0011-test-harness-taxonomy.md:244` |
| `docs/doc-paths-disposition.md` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:165` |
| `docs/lessons-learned.md` | **нет** | 4 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:162`; `content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md:94`; `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:66`; … ещё 1 (всего 4) |
| `docs/onboarding-nauta.md` | да | 8 | `content/00-project/adr/0014-dual-publication-targets.md:99`; `content/00-project/adr/0014-dual-publication-targets.md:158`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:176`; … ещё 5 (всего 8) |
| `docs/qa-reports/` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:159` |
| `docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md` | **нет** | 2 | `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:63`; `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:87` |
| `docs/qa-reports/2026-05-11-remove-diagram-skills-qa-report.md` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:86` |
| `docs/research/` | **нет** | 2 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:161`; `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:65` |
| `docs/superpowers` | да | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:74` |
| `docs/superpowers/` | да | 1 | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:34` |
| `docs/superpowers/plans/` | да | 1 | `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:66` |
| `docs/superpowers/specs/` | да | 2 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:172`; `content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md:66` |
| `docs/superpowers/specs/2026-05-08-apply-project-template-design.md` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:295` |
| `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:155` |
| `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` | **нет** | 2 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:156`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:291` |
| `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:157` |
| `docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md` | **нет** | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:158` |
| `docs/superpowers/specs/2026-08-07-nauta-integration-design.md` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:295` |
| `marketplace.json` | **нет** | 61 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:27`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:35`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:43`; … ещё 58 (всего 61) |
| `plugin.json` | **нет** | 56 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:32`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:64`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:68`; … ещё 53 (всего 56) |
| `plugins/claude-mermaid` | **нет** | 8 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:66`; `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:266`; `content/00-project/adr/0011-test-harness-taxonomy.md:217`; … ещё 5 (всего 8) |
| `plugins/claude-mermaid/` | **нет** | 22 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:25`; `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:24`; `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:264`; … ещё 19 (всего 22) |
| `plugins/gramax` | да | 5 | `content/00-project/adr/0012-catalog-validation-contract.md:106`; `content/30-requirements/2026-08-11-validation-contract.md:313`; `content/30-requirements/2026-08-11-validation-contract.md:317`; … ещё 2 (всего 5) |
| `plugins/gramax/` | да | 9 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:24`; `content/00-project/adr/0012-catalog-validation-contract.md:104`; `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:123`; … ещё 6 (всего 9) |
| `plugins/gramax/.claude-plugin/` | да | 1 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:120` |
| `plugins/gramax/.claude-plugin/plugin.json` | да | 43 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:42`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:86`; `content/00-project/adr/0002-drawio-mcp-backend-selection.md:93`; … ещё 40 (всего 43) |
| `plugins/gramax/CHANGELOG.md` | да | 31 | `content/00-project/adr/0006-marketplace-json-semver-strategy.md:79`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:269`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:332`; … ещё 28 (всего 31) |
| `plugins/gramax/README.md` | да | 31 | `content/00-project/adr/0003-drawio-backend-vendoring-strategy.md:96`; `content/00-project/adr/0007-out-of-scope-phase2.md:91`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:168`; … ещё 28 (всего 31) |
| `plugins/gramax/agents/` | да | 1 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:120` |
| `plugins/gramax/commands/` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:41` |
| `plugins/gramax/gramax-catalog-rules.json` | да | 4 | `content/00-project/adr/0012-catalog-validation-contract.md:98`; `content/00-project/adr/0012-catalog-validation-contract.md:260`; `content/00-project/adr/0015-root-index-inert.md:313`; … ещё 1 (всего 4) |
| `plugins/gramax/gramax-tags.json` | да | 3 | `content/00-project/adr/0012-catalog-validation-contract.md:95`; `content/00-project/adr/0012-catalog-validation-contract.md:259`; `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:111` |
| `plugins/gramax/scripts` | да | 1 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:72` |
| `plugins/gramax/scripts/` | да | 8 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:26`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:51`; `content/00-project/adr/0002-drawio-mcp-backend-selection.md:34`; … ещё 5 (всего 8) |
| `plugins/gramax/scripts/drawio_convert.py` | **нет** | 4 | `content/00-project/adr/0005-save-flow-script-api-contract.md:199`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:251`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:46`; … ещё 1 (всего 4) |
| `plugins/gramax/scripts/find_doc_root.sh` | **нет** | 2 | `content/00-project/adr/0005-save-flow-script-api-contract.md:198`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:247` |
| `plugins/gramax/scripts/insert_diagram_ref.sh` | **нет** | 1 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:249` |
| `plugins/gramax/scripts/migrate_mermaid.py` | да | 3 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:96`; `content/00-project/adr/0013-mermaid-adoption-and-migration.md:218`; `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:275` |
| `plugins/gramax/scripts/pre-commit.sh` | да | 3 | `content/00-project/adr/0012-catalog-validation-contract.md:130`; `content/00-project/adr/0012-catalog-validation-contract.md:260`; `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:113` |
| `plugins/gramax/scripts/save_diagram.sh` | **нет** | 1 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:248` |
| `plugins/gramax/scripts/slugify.py` | да | 2 | `content/00-project/adr/0005-save-flow-script-api-contract.md:199`; `content/00-project/adr/0010-mermaid-file-based-workflow.md:94` |
| `plugins/gramax/scripts/tests/` | да | 2 | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:90`; `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:83` |
| `plugins/gramax/scripts/tests/fixtures/inline-tag-mention/` | да | 1 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:182` |
| `plugins/gramax/scripts/tests/fixtures/root-index/` | да | 3 | `content/00-project/adr/0015-root-index-inert.md:209`; `content/00-project/adr/0015-root-index-inert.md:316`; `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:22` |
| `plugins/gramax/scripts/tests/test_validate_structure.py` | да | 10 | `content/00-project/adr/0015-root-index-inert.md:206`; `content/00-project/adr/0015-root-index-inert.md:315`; `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:76`; … ещё 7 (всего 10) |
| `plugins/gramax/scripts/validate_diagram_type.sh` | **нет** | 1 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:250` |
| `plugins/gramax/scripts/validate_structure.py` | да | 18 | `content/00-project/adr/0012-catalog-validation-contract.md:23`; `content/00-project/adr/0012-catalog-validation-contract.md:164`; `content/00-project/adr/0012-catalog-validation-contract.md:259`; … ещё 15 (всего 18) |
| `plugins/gramax/skills/` | да | 7 | `content/00-project/adr/0006-marketplace-json-semver-strategy.md:33`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:67`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:120`; … ещё 4 (всего 7) |
| `plugins/gramax/skills/comments-read/SKILL.md` | да | 1 | `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:39` |
| `plugins/gramax/skills/comments-write/SKILL.md` | да | 1 | `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:38` |
| `plugins/gramax/skills/diagram-drawio/` | **нет** | 1 | `content/00-project/adr/0004-router-and-engine-selection.md:30` |
| `plugins/gramax/skills/diagram-mermaid/` | **нет** | 1 | `content/00-project/adr/0004-router-and-engine-selection.md:30` |
| `plugins/gramax/skills/diagram-on-demand` | **нет** | 1 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:105` |
| `plugins/gramax/skills/diagram-on-demand/` | **нет** | 4 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:245`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:299`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:43`; … ещё 1 (всего 4) |
| `plugins/gramax/skills/diagram-on-demand/SKILL.md` | **нет** | 5 | `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:39`; `content/00-project/adr/0001-diagram-on-demand-plugin-split.md:86`; `content/00-project/adr/0004-router-and-engine-selection.md:104`; … ещё 2 (всего 5) |
| `plugins/gramax/skills/diagrams` | **нет** | 1 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:106` |
| `plugins/gramax/skills/diagrams/` | **нет** | 4 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:246`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:299`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:44`; … ещё 1 (всего 4) |
| `plugins/gramax/skills/diagrams/SKILL.md` | **нет** | 2 | `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:37`; `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:53` |
| `plugins/gramax/skills/drawio/` | да | 1 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:386` |
| `plugins/gramax/skills/drawio/SKILL.md` | да | 22 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:198`; `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:258`; `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:332`; … ещё 19 (всего 22) |
| `plugins/gramax/skills/mermaid/` | да | 2 | `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:124`; `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:132` |
| `plugins/gramax/skills/mermaid/LICENSE.upstream.md` | да | 1 | `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md:276` |
| `plugins/gramax/skills/mermaid/SKILL.md` | да | 23 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:149`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:259`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:332`; … ещё 20 (всего 23) |
| `plugins/gramax/skills/mermaid/references/jurisdiction-and-validation.md` | да | 2 | `content/00-project/adr/0013-mermaid-adoption-and-migration.md:217`; `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:276` |
| `plugins/gramax/skills/mermaid/references/syntax-rules.md` | да | 4 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:251`; `content/00-project/adr/0010-mermaid-file-based-workflow.md:283`; `content/00-project/adr/0010-mermaid-file-based-workflow.md:321`; … ещё 1 (всего 4) |
| `plugins/gramax/skills/writer/` | да | 12 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:332`; `content/30-requirements/2026-05-11-routing-mermaid-drawio.md:171`; `content/30-requirements/2026-08-11-writer-consumer-rules.md:235`; … ещё 9 (всего 12) |
| `plugins/gramax/skills/writer/SKILL.md` | да | 21 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:254`; `content/00-project/adr/0012-catalog-validation-contract.md:261`; `content/00-project/adr/0015-root-index-inert.md:312`; … ещё 18 (всего 21) |
| `plugins/gramax/skills/writer/references/` | да | 1 | `content/30-requirements/2026-08-11-writer-consumer-rules.md:285` |
| `plugins/gramax/skills/writer/references/authoritative-source.md` | да | 1 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:206` |
| `plugins/gramax/skills/writer/references/blocks.md` | да | 3 | `content/00-project/adr/0010-mermaid-file-based-workflow.md:23`; `content/00-project/adr/0010-mermaid-file-based-workflow.md:317`; `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:31` |
| `plugins/gramax/skills/writer/references/doc-root-schema.md` | да | 4 | `content/30-requirements/2026-08-11-writer-consumer-rules.md:279`; `content/30-requirements/2026-08-11-writer-consumer-rules.md:281`; `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:202`; … ещё 1 (всего 4) |
| `plugins/gramax/skills/writer/references/drawio.md` | да | 10 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:94`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:255`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:48`; … ещё 7 (всего 10) |
| `plugins/gramax/skills/writer/references/staging.md` | да | 6 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:256`; `content/00-project/adr/0012-catalog-validation-contract.md:89`; `content/30-requirements/2026-05-11-remove-diagram-skills.md:49`; … ещё 3 (всего 6) |
| `plugins/gramax/skills/writer/references/structure.md` | да | 3 | `content/00-project/adr/0015-root-index-inert.md:313`; `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:315`; `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:203` |
| `plugins/gramax/vendor/drawio-mcp/` | **нет** | 1 | `content/00-project/adr/0003-drawio-backend-vendoring-strategy.md:26` |
| `scripts/apply-overlay.sh` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:80` |
| `scripts/check.sh` | да | 73 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:272`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:295`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:308`; … ещё 70 (всего 73) |
| `scripts/deprecated/` | **нет** | 5 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:50`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:61`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:233`; … ещё 2 (всего 5) |
| `scripts/drawio_convert.py` | **нет** | 4 | `content/00-project/adr/0008-drop-internal-drawio-skills.md:41`; `content/00-project/adr/0008-drop-internal-drawio-skills.md:56`; `content/10-domain/research/2026-05-11-drawio-skill-external.md:73`; … ещё 1 (всего 4) |
| `scripts/install-hooks.sh` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:176` |
| `scripts/repair_png.py` | **нет** | 1 | `content/10-domain/research/2026-05-11-drawio-skill-external.md:32` |
| `scripts/test-central-plugin-checkout.sh` | **нет** | 1 | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:158` |
| `scripts/testRunner.js` | **нет** | 2 | `content/10-domain/research/2026-08-11-index-md-root-probe.md:47`; `content/10-domain/research/2026-08-11-index-md-root-probe.md:222` |
| `scripts/validate-content.py` | да | 20 | `content/00-project/adr/0012-catalog-validation-contract.md:24`; `content/00-project/adr/0012-catalog-validation-contract.md:29`; `content/00-project/adr/0012-catalog-validation-contract.md:164`; … ещё 17 (всего 20) |
| `scripts/validate_structure.py` | **нет** | 2 | `content/00-project/adr/0012-catalog-validation-contract.md:132`; `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:44` |
| `tests/gramax/` | да | 16 | `content/00-project/adr/0011-test-harness-taxonomy.md:21`; `content/00-project/adr/0011-test-harness-taxonomy.md:32`; `content/00-project/adr/0011-test-harness-taxonomy.md:42`; … ещё 13 (всего 16) |
| `tests/gramax/archive` | да | 4 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:246`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:252`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:267`; … ещё 1 (всего 4) |
| `tests/gramax/archive/` | да | 19 | `content/00-project/adr/0011-test-harness-taxonomy.md:45`; `content/00-project/adr/0011-test-harness-taxonomy.md:439`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:104`; … ещё 16 (всего 19) |
| `tests/gramax/archive/README.md` | да | 4 | `content/00-project/adr/0011-test-harness-taxonomy.md:92`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:101`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:247`; … ещё 1 (всего 4) |
| `tests/gramax/archive/mermaid-file-based/` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:47` |
| `tests/gramax/archive/mermaid-file-based/verify.sh` | да | 4 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:129`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:253`; `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:108`; … ещё 1 (всего 4) |
| `tests/gramax/archive/remove-diagram-skills/` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:45` |
| `tests/gramax/archive/routing-mermaid-drawio/` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:46` |
| `tests/gramax/catalog-validator` | да | 3 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:48`; `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:198`; `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:250` |
| `tests/gramax/catalog-validator/` | да | 11 | `content/00-project/adr/0012-catalog-validation-contract.md:146`; `content/00-project/adr/0012-catalog-validation-contract.md:262`; `content/60-implementation/2026-08-11-validation-contract-dev-notes.md:18`; … ещё 8 (всего 11) |
| `tests/gramax/catalog-validator/README.md` | да | 4 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:42`; `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:51`; `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:73`; … ещё 1 (всего 4) |
| `tests/gramax/catalog-validator/ac-001-dogfood-clean-exit.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:225` |
| `tests/gramax/catalog-validator/ac-002-placeholder-detected.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:226` |
| `tests/gramax/catalog-validator/ac-003-orphan-detected.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:227` |
| `tests/gramax/catalog-validator/ac-004-orphan-cross-catalog-boundary.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:228` |
| `tests/gramax/catalog-validator/ac-005-broken-link-detected.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:229` |
| `tests/gramax/catalog-validator/ac-006-no-bloat-flag-in-help.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:230` |
| `tests/gramax/catalog-validator/ac-007-readme-discoverability.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:231` |
| `tests/gramax/catalog-validator/ac-008-help-doc-pointer.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:232` |
| `tests/gramax/catalog-validator/ac-009-hook-template-discoverable.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:233` |
| `tests/gramax/catalog-validator/ac-010-tags-contract-exists.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:234` |
| `tests/gramax/catalog-validator/ac-011` | **нет** | 1 | `content/lessons-learned.md:124` |
| `tests/gramax/catalog-validator/ac-011-tags-contract-content-sync.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:235` |
| `tests/gramax/catalog-validator/ac-012-catalog-rules-contract-exists.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:236` |
| `tests/gramax/catalog-validator/ac-013-adr-resolves-root-index.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:237` |
| `tests/gramax/catalog-validator/fixtures/orphan-cross-catalog-boundary/` | да | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:145` |
| `tests/gramax/catalog-validator/run.sh` | да | 2 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:240`; `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:68` |
| `tests/gramax/diagram-on-demand` | **нет** | 3 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:251`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:267`; `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:35` |
| `tests/gramax/diagram-on-demand/` | **нет** | 6 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:103`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:128`; `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:126`; … ещё 3 (всего 6) |
| `tests/gramax/diagram-on-demand/run.sh` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md:60` |
| `tests/gramax/doc-paths` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:246` |
| `tests/gramax/doc-paths/` | да | 6 | `content/00-project/adr/0011-test-harness-taxonomy.md:440`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:73`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:149`; … ещё 3 (всего 6) |
| `tests/gramax/doc-paths/allowlist.txt` | да | 4 | `content/00-project/adr/0011-test-harness-taxonomy.md:283`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:123`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:167`; … ещё 1 (всего 4) |
| `tests/gramax/doc-paths/fixtures/stale-allowlist` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:294` |
| `tests/gramax/doc-paths/fixtures/stale-allowlist/` | да | 2 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:170`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:294` |
| `tests/gramax/doc-paths/lib/scan.sh` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:230` |
| `tests/gramax/doc-paths/run.sh` | да | 4 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:291`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:293`; `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:44`; … ещё 1 (всего 4) |
| `tests/gramax/mermaid-adoption/` | да | 4 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:22`; `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:273`; `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:285`; … ещё 1 (всего 4) |
| `tests/gramax/mermaid-adoption/README.md` | да | 1 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:269` |
| `tests/gramax/mermaid-adoption/run.sh` | да | 2 | `content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md:267`; `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:69` |
| `tests/gramax/mermaid-file-based/` | **нет** | 2 | `content/60-implementation/test-reports/2026-05-12-mermaid-file-based-qa-report.md:33`; `content/60-implementation/test-reports/2026-05-12-mermaid-file-based-qa-report.md:102` |
| `tests/gramax/mermaid-file-based/run.sh` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-12-mermaid-file-based-qa-report.md:22` |
| `tests/gramax/nauta-integration/ac-003-doc-root-contract.sh` | да | 7 | `content/00-project/adr/0014-dual-publication-targets.md:83`; `content/00-project/adr/0014-dual-publication-targets.md:147`; `content/00-project/adr/0014-dual-publication-targets.md:157`; … ещё 4 (всего 7) |
| `tests/gramax/nauta-integration/ac-004` | **нет** | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:231` |
| `tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh` | да | 1 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:149` |
| `tests/gramax/nauta-integration/run.sh` | да | 2 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:42`; `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:65` |
| `tests/gramax/orphan-references/run.sh` | да | 7 | `content/00-project/adr/0011-test-harness-taxonomy.md:441`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:128`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:196`; … ещё 4 (всего 7) |
| `tests/gramax/orphan-references/sunset-registry.txt` | да | 4 | `content/00-project/adr/0011-test-harness-taxonomy.md:440`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:70`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:115`; … ещё 1 (всего 4) |
| `tests/gramax/plugin-contract` | да | 2 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:246`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:265` |
| `tests/gramax/plugin-contract/` | да | 5 | `content/00-project/adr/0011-test-harness-taxonomy.md:439`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:213`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:265`; … ещё 2 (всего 5) |
| `tests/gramax/plugin-contract/ac-002-drawio-tag-format.sh` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:228` |
| `tests/gramax/plugin-contract/ac-007` | **нет** | 1 | `content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md:159` |
| `tests/gramax/plugin-contract/ac-007-retired-skills-field.sh` | да | 1 | `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:229` |
| `tests/gramax/plugin-contract/run.sh` | да | 3 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:130`; `content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md:43`; `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:66` |
| `tests/gramax/remove-diagram-skills` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:34` |
| `tests/gramax/remove-diagram-skills/` | **нет** | 3 | `content/30-requirements/2026-05-11-remove-diagram-skills.md:193`; `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:128`; `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:118` |
| `tests/gramax/remove-diagram-skills/ac-011` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:180` |
| `tests/gramax/routing-mermaid-drawio` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:33` |
| `tests/gramax/routing-mermaid-drawio/README.md` | **нет** | 1 | `content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md:82` |
| `tests/gramax/writer-consumer-rules/` | да | 3 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:23`; `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:200`; `content/lessons-learned.md:216` |
| `tests/gramax/writer-consumer-rules/ac-002-cross-catalog-code-workflow-example.sh` | да | 1 | `content/60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md:90` |
| `tests/gramax/writer-consumer-rules/run.sh` | да | 1 | `content/60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md:70` |

### 2.3. Разбор 55 несуществующих целей вне `content/` — по причине

Ни одна из 55 не является необъяснимой «протухшей ссылкой» в обычном смысле (файл был и пропал
незамеченным). Каждая проверена чтением контекста; причины укладываются в пять групп:

| причина | сколько целей | примеры целей | как проверено |
|---|---|---|---|
| **Устаревшая раскладка `docs/` до миграции в `content/`** — упомянута либо в таблице соответствия старых/новых путей, либо в архивных QA-отчётах 2026-05-хх, либо как предмет самого гейта `doc-paths` (ADR-0011), который и существует, чтобы ловить такие упоминания | 17 | `docs/adr/`, `docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md`, `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`, `docs/lessons-learned.md` | прочитан контекст каждой строки — все либо в миграционной таблице (`content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md:154-162`), либо помечены явно «архив»/«допустимо» в QA-отчётах 2026-05-11 |
| **Историческое упоминание удалённого/переименованного артефакта**, задокументированное конкретным ADR/FR — на момент написания абзаца путь либо ещё существовал, либо обсуждается как то, что только что удалили | 25 | `plugins/claude-mermaid(/)` (ADR-0009, submodule снят), `plugins/gramax/scripts/{drawio_convert.py,find_doc_root.sh,insert_diagram_ref.sh,save_diagram.sh,validate_diagram_type.sh}` (ADR-0008), `plugins/gramax/skills/{diagram-on-demand,diagrams,diagram-drawio,diagram-mermaid}(/)` (ADR-0001→0004→0008), `tests/gramax/{diagram-on-demand,remove-diagram-skills,routing-mermaid-drawio}` без префикса `archive/` (ADR-0011, суффикс `run.sh`/`README.md`/`ac-011` включён) | найдено явное действие удаления/переезда в тексте той же или соседней строки («удалить каталог целиком», «git rm -r», «удалён (`git rm -r`) — не существует, ожидаемо») |
| **Явно отклонённый вариант архитектуры**, зафиксированный как «Отклонено» в теле ADR | 2 | `plugins/gramax/vendor/drawio-mcp/` (ADR-0003, вариант «git submodule» не выбран), `scripts/deprecated/` (ADR-0008: «Переход в `scripts/deprecated/` не выполняется») | цитата «Отклонено»/«не выполняется» находится в той же строке |
| **Омоним пути из другого репозитория** — строка выглядит как путь этого репозитория, но по контексту — путь на машине потребителя или в исследуемом внешнем проекте | 3 | `scripts/testRunner.js` (RES-004: чужой jest/TS-проект, у этого репозитория нет `jest.config.js`), `scripts/test-central-plugin-checkout.sh` (RES-002 G9: сторонний каталог-потребитель — шаблон проекта), `scripts/repair_png.py` (RES-001: prerequisite стороннего skill `Agents365-ai/drawio-skill`, не этого репозитория) | у каждого — соседняя фраза называет чужой репозиторий/проект явно |
| **Укороченная форма без полного пути** — бэктик несёт не полный путь, а бытовое сокращение (номер AC без расширения, имя манифеста без директории) внутри абзаца, где полная форма уже была дана | 8 | `marketplace.json`/`plugin.json` (полные формы — `.claude-plugin/marketplace.json` и `plugins/gramax/.claude-plugin/plugin.json`, обе существуют и упомянуты рядом), `scripts/validate_structure.py` без префикса `plugins/gramax/` (полная форма — двумя строками ниже в том же абзаце), 4× голый `ac-0NN` без `.sh` | полная форма цели физически присутствует в том же документе (не в другом репозитории) |

**Вывод:** в классе «путь вне `content/`» не обнаружено ни одной ссылки, которая выглядела бы
актуальной, но по факту протухла незамеченной. Риск для BA/SA здесь не в staleness, а в том, что
читатель (или наивный скрипт) не отличит группу 4 (омоним другого репозитория) от настоящей ссылки
на этот репозиторий — см. Задачу 3.

## Задача 3 — другие классы деградации

### 3.1. Ссылки в `_index.md` на несуществующие файлы

Не найдено ни одной. Полный проход по 60 внутренним markdown-ссылкам корпуса (метод — п. 6) даёт
0 битых, включая все markdown-ссылки внутри самих `_index.md` (в них живёт большинство ссылок — 8
файлов `_index.md` несут суммарно 40+ из 60 внутренних ссылок). Подтверждено независимо реальным
прогоном `uv run scripts/validate-content.py` → `content/: OK (52 файлов проверены)`, `Errors: 0 |
Warnings: 0`.

### 3.2. Статьи, содержательно осиротевшие несмотря на зелёный C10

Проверено для 42 статей, не являющихся `_index.md`: есть ли хоть одна входящая markdown-ссылка **не
из** `_index.md` своего раздела.

- **Только навигационная ссылка из `_index.md` (33 из 42, 79%):** все 14 ADR кроме ADR-0008 (то
  есть 0001–0007, 0009–0015 — 13 статей), обе `_index.md`-неохваченные research-статьи
  (drawio-skill-external, index-md-at-catalog-root, index-md-root-probe, plugin-consumers-gaps —
  4 статьи), три requirement-статьи 2026-05-хх (diagram-on-demand-design, routing-mermaid-drawio,
  mermaid-file-based-design), writer-rules-disposition, validation-contract-dev-notes, три
  acceptance-статьи 2026-05-хх, шесть из семи test-report-статей, `lessons-learned.md`.
- **Есть хотя бы одна прозаическая входящая ссылка (9 из 42, 21%):** ADR-0008 и требования/AT-design
  wave 2026-08-11 (validation-contract, mermaid-file-based-adoption, writer-consumer-rules и их три
  AT-design-статьи) — но **всех девять** ссылаются только **один** источник:
  [QA Report — волна 4.2.0 (ADR-0012/0013/0015 + writer-consumer-rules)](../../60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md), плюс
  `2026-05-11-remove-diagram-skills-qa-report.md` (2 ссылки на requirement и ADR-0008) и
  `2026-08-10-test-harness-taxonomy-qa-report.md` (1 ссылка). Все содержательные cross-ссылки
  корпуса физически живут в этих трёх QA-отчётах.

Формально это не дефект — C10 определяет сироту как «нет вообще никакой входящей ссылки», а
навигация из `_index.md` — валидная ссылка. Но для BA-001 это значит: если цель новой формы ссылки —
«читатель находит связанные документы, читая прозу», то сегодня это работает только для эффекта QA
→ (ADR, требование, AT-design), и не работает ни для одной другой пары ролей (ADR→research,
requirement→ADR и обратно и т. д. — они все связаны только код-спанами, см. Задачу 1).

### 3.3. Упоминания артефактов без пути вообще

Голые идентификаторы — самая частая форма отсылки к другому артефакту во всём корпусе, на порядок
чаще, чем код-спан-путь или markdown-ссылка вместе взятые:

| идентификатор | вхождений (`grep -rohE`) | глобально уникален? | как читатель находит цель |
|---|---|---|---|
| `ADR-[0-9]{4}` | 380 | да — номер закреплён навсегда, `content/00-project/adr/_index.md` несёт таблицу-реестр «номер → файл → статус» с markdown-ссылками | работает: один переход в реестр, затем клик по номеру |
| `FR-[0-9]{3}` | 690 | **нет** | не гарантирован вне документа, см. ниже |
| `AC-[0-9]{3}` | 825 | нет | то же |
| `NFR-[0-9]{3}` | 140 | нет | то же |
| `BR-[0-9]{3}` | 82 | нет | то же |
| `RES-[0-9]{3}` | 44 | да (4 использованных номера, без реестра-таблицы, но их мало) | нужно грепать по корпусу |
| `OQ-[0-9]{3}` | 33 | нет (открытые вопросы нумеруются заново в каждом документе) | то же, в пределах документа |
| `G[0-9]{1,2}` (находки research) | 96 | нет (свои G1…G13 в каждом research-документе) | то же |

**Дубли `FR-NNN` между документами — подтверждено измерением:** `FR-001`…`FR-011` встречаются в
диапазоне от 4 до 8 разных requirement-файлов каждый (`for f in content/30-requirements/*.md; do
grep -ohE 'FR-[0-9]{3}' "$f" | sort -u; done | sort | uniq -c | sort -rn` — верхние строки: `FR-003`
× 8 файлов, `FR-004`/`FR-002`/`FR-001` × 7, `FR-005` × 6, `FR-006…FR-011` × 4–5). Это не дефект по
конструкции (каждый requirement-документ — свой замкнутый FR/AC-неймспейс, как секции в разных RFC),
но означает: голое `FR-003` без указания документа **не резолвится однозначно на уровне корпуса** —
работает только пока рядом (в том же документе, обычно в шапке «Требование:») стоит код-спан с
полным путём, задающий контекст. Этот код-спан из категории SELF (Задача 1) — не украшение, а
единственный якорь, снимающий неоднозначность FR/AC/BR/NFR-номеров.

### 3.4. Омонимы путей из другого репозитория

Помимо примеров из Задачи 2.3 (`scripts/testRunner.js` и т. п.), тот же эффект есть и внутри
префикса `content/` — путь синтаксически неотличим от пути этого репозитория, но по смыслу фразы
указывает на **другую** машину/репозиторий. Имена внешних репозиториев ниже заменены на устойчивые
метки «потребитель N» (номера 1–5 — по числу различённых внешних репозиториев, встретившихся в этом
исследовании, включая упоминание в классе SUBJECT выше) — один номер обозначает один и тот же
репозиторий во всех упоминаниях; конкретное имя не нужно для сути находки (по образцу
`content/lessons-learned.md`, запись 2026-08-11):

| код-спан | файл:строка | чей это путь |
|---|---|---|
| `content/_index.md` | `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md:54,97,167,257,326` | эталонный вендорский корпус документации и локальные потребители (потребитель 3, потребитель 4) |
| `content/00-project/adr/007-dr-cluster-topology.md:64` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:103` | сторонний каталог-потребитель («потребитель 1») |
| `content/00-project/adr/008-pii-masking-integration-log.md:159,243` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:104`, `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:45` | сторонний каталог-потребитель («потребитель 1») |
| `content/00-project/plans/deploy-1-stand-smoke.md:180` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:105`, `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:46` | сторонний каталог-потребитель («потребитель 2») |
| `content/70-operations/network-prerequisites.md:30` | те же строки | сторонний каталог-потребитель («потребитель 2») |
| `content/gramax-internal-docs/(.doc-root.yaml)` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:198`, `content/30-requirements/2026-08-11-writer-consumer-rules.md:88` | сторонний каталог-потребитель («потребитель 1», вложенный doc-root) |
| `content/00-project/handoffs/` | `content/10-domain/research/2026-08-11-plugin-consumers-gaps.md:107`, `content/30-requirements/2026-08-11-mermaid-file-based-adoption.md:47` | сторонний каталог-потребитель («потребитель 5») |

Эти пути в принципе непроверяемы существованием в этом репозитории (некоторые каталоги — `70-operations`,
`plans`, `handoffs` — в `content/` этого репозитория не существуют вовсе, и не должны). Риск —
не staleness, а то, что скрипт (или человек), сканирующий «все код-спаны на `content/...`»
без чтения контекста абзаца, спутает такую находку с внутренней ссылкой или с протухшим путём этого
репозитория (именно это едва не случилось с методом данного исследования на первом проходе).

### 3.5. Точностный дрейф в цитатах вида `файл:строка`

Помимо префиксов-путей встречается формат `путь:номер_строки` (grep-цитата) — найден один экземпляр
в `content/`: `content/30-requirements/2026-08-11-writer-consumer-rules.md:74` —
«`content/00-project/adr/_index.md:11` объявляет словарь тела ADR: `Proposed | Accepted | Superseded
by ADR-MMMM`». На HEAD эта фраза стоит на строке **10** файла `content/00-project/adr/_index.md`
(строка 11 — пустая). Формат `путь:строка` не проверяется ни одним валидатором (ни markdown-
ссылкой, ни существующим C9/C10 — он не входит ни в один `_LINK_PATTERN`), и в отличие от кода не
привязан к содержимому: правка `_index.md` молча сдвигает то, на что указывает цитата, без единого
предупреждения. Это тот же класс проблемы, что и `docs/adr/0006-...` в
`content/00-project/adr/0011-test-harness-taxonomy.md:242-244` — там ADR-0011 сам разбирает разницу
между POINTER («приглашение перейти», ссылка) и RECORD («на HEAD=X было верно», факт на момент
записи) для точно такой же строки-омонима; формулировка «на HEAD=X упоминание было найдено по
адресу…» правильно фиксирует запись как факт истории, а не как обещание навигации — но
`writer-consumer-rules.md:74` использует настоящее время («объявляет»), то есть претендует на статус
POINTER, а не RECORD, и именно поэтому дрейф на 1 строку — не «исторический факт», а не замеченная
опечатка/устаревание.

### 3.6. Голые упоминания каталога (без конкретного файла)

83 упоминания `` `content/` `` без продолжения (например, «репозиторий-плагин `content/` должен
проходить...»), плюс `` `content/00-project/adr/` ``, `` `content/40-architecture/` ``,
`` `content/60-implementation/test-reports/` ``, `` `content/**` `` (glob) — все обсуждают
**раздел** или **область сканирования**, не конкретную статью; ни markdown-ссылкой, ни staleness-
целью в привычном смысле они быть не могут (у Gramax нет общепринятого способа «сослаться на
раздел» кроме ссылки на его `_index.md`, которая бы тут ничего не добавила к тексту). Не дефект,
но стоит иметь в виду при проектировании формы ссылки: не любое упоминание пути — кандидат на замену.

## Что не удалось выяснить

- Не подтверждено число из брифа PM «~194 упоминания путей `plugins/...`» и «46 — `tests/...`»
  — воспроизводимым методом этого исследования получено иное распределение (289 код-спанов,
  начинающихся ровно с `plugins/`, и 132 — с `tests/`; либо 70 и 58 уникальных целей теми же
  подсчётами, либо 157 уникальных при объединении с `scripts/`/`docs/`/манифестами и разборе
  составных спанов). Сам PM пометил цифры брифа как предварительные («перепроверь и уточни») —
  расхождение ожидаемо, но точный метод исходного подсчёта PM не описан, поэтому нельзя сказать,
  какая часть разницы — от другого регэкспа, а какая — от другой единицы счёта (спан vs уникальная
  цель vs строка).
- Не проверено индивидуальное качество каждой из **103** предложенных markdown-форм в Задаче 1 —
  относительные пути вычислены механически (`os.path.relpath`) и синтаксически корректны, но текст
  ссылки (`[текст]`) не подобран — это сознательно оставлено BA/Dev, а не мне (не пишу требования и
  не проектирую форму ссылки).
- Не оценено, стабилен ли реестр `content/00-project/adr/_index.md` при будущем росте числа ADR
  (сегодня 15 записей, полностью синхронных с файлами) — то есть остаётся ли механизм «голый номер +
  таблица-реестр» рабочим за пределами измеренного состояния корпуса.
- Не проверено (не входило в задачу и не имею доступа), существуют ли на самом деле файлы
  внешних репозиториев из Задачи 3.4 (сторонние каталоги-потребители «потребитель 1»/«потребитель 2»/
  «потребитель 5», эталонный вендорский корпус документации) — их корректность/актуальность вне
  периметра этого корпуса.

## Рекомендации для BA/SA

**BA (форма ссылки на артефакт, BA-001):**

- Форма нужна прежде всего для класса NAV (103 находки, 75% всех код-спанов на `content/*.md`) —
  это основной объём переделки. Класс SELF (13) и SUBJECT (19) трогать не нужно: код-спан там
  содержательно верен.
- Реши явно судьбу спорной строки #83 (Задача 1) — трактовка «предмет» vs «ссылка» меняет итоговый
  подсчёт на ±1, но важнее прецедент: как классифицировать спан, описывающий *будущее* содержимое
  другого файла.
- Учти, что бо́льшая часть корпуса ссылается друг на друга не код-спаном и не markdown-ссылкой, а
  голым идентификатором (`ADR-NNNN`, `FR-NNN`, `AC-NNN` — Задача 3.3). Если форма ссылки на артефакт
  должна закрыть проблему навигации целиком, а не только код-спаны, стоит решить: будет ли новая
  форма распространяться и на голые идентификаторы, или на них сознательно не распространяется
  (тогда `ADR-NNNN` продолжает работать через реестр, а `FR-/AC-NNN` остаются локальными к
  документу — но тогда шапка `**Требование:** \`content/...\`` в начале документа, то есть класс
  SELF, — не украшение, а обязательный якорь, и трогать её нельзя).
- Учти находку 3.2: даже стопроцентное превращение всех 103 NAV-спанов в markdown-ссылки не решит
  «содержательное сиротство» 33 из 42 статей — оно вызвано отсутствием ссылок в **обратную**
  сторону (никто не ссылается на ADR из research, которая его породила, и наоборот), а не
  отсутствием формы ссылки как таковой.
- Формат `путь:номер_строки` (Задача 3.5) — если он останется легитимным способом цитирования
  (сейчас минимум 4 случая, включая осознанный пример в самом ADR-0011), стоит явно развести в
  правиле два режима цитаты — «на момент записи было верно» (RECORD, прошедшее время) и «сейчас
  верно» (POINTER, настоящее время) — по образцу разбора в `content/00-project/adr/0011-test-harness-taxonomy.md:242-244`;
  найденный дрейф на 1 строку — пример именно смешения этих двух режимов.

**SA (архитектура/паттерн, если форма ссылки повлечёт архитектурные решения):**

- Пять причин staleness во внешних путях (Задача 2.3) не нуждаются в починке ссылок — они верны как
  исторический/сравнительный текст. Если появится автоматический гейт для внешних путей (аналог
  `doc-paths` для `content/`, но для `plugins/`/`tests/`/`scripts/`), ему придётся отличать «путь
  этого репозитория» от «путь другого репозитория с тем же относительным именем» (Задача 3.4) —
  готового эвристического признака для этого различия сегодня нет (текст абзаца — единственный
  сигнал), содержательное решение здесь не про форму ссылки, а про доменную семантику разведочных
  статей.
- Маскирование кода в C9/C10 (единая логика в обоих валидаторах) — источник всей слепоты,
  описанной в этом исследовании; любое архитектурное решение, которое захочет **видеть** код-спаны
  как потенциальные ссылки, обязано сохранить нынешнее поведение для случаев SELF/SUBJECT (иначе
  136 существующих код-спанов в один момент превратятся в 136 ложных находок гейта).
- Готовый рабочий прецедент есть: реестр [Архитектурные решения](../../00-project/adr/_index.md) — таблица «номер →
  markdown-ссылка на файл → статус» решает проблему голого идентификатора для ADR. Тот же паттерн
  не существует для `FR-/AC-/BR-/NFR-NNN` и физически не может быть одной таблицей (номера не
  уникальны глобально) — если SA решит формализовать разрешение этих идентификаторов, потребуется
  либо составной ключ (документ+номер), либо отказ от идеи единого реестра.

## Источники

- [primary] `scripts/validate-content.py:270-306` (`_mask_code`, `_LINK_PATTERNS`, `_EXTERNAL_RE`) —
  эталонная логика маскирования и определения ссылки, дословно воспроизведена в методе этого
  исследования.
- [primary] `plugins/gramax/scripts/validate_structure.py:242-275` — та же логика во втором живом
  валидаторе; сверено на идентичность регулярных выражений.
- [primary] Прогон `uv run scripts/validate-content.py` на HEAD этой сессии — `content/: OK
  (52 файлов проверены)`, `Errors: 0 | Warnings: 0` — независимое подтверждение «0 битых markdown-
  ссылок» из этого исследования.
- [primary] `content/00-project/adr/0011-test-harness-taxonomy.md:242-244` — источник различия
  POINTER/RECORD для строк-омонимов путей, использованного в разделе 3.5.
- [primary] `content/30-requirements/2026-08-11-writer-consumer-rules.md:120-129` и
  `content/40-architecture/2026-08-11-writer-rules-disposition.md:50-60` (FR-065/FR-066) — тот же
  корпус уже заметил и задокументировал риск «код-спан с markdown-синтаксисом внутри неотличим от
  настоящей ссылки для чужого regex-валидатора»; на этот же риск наступил инструмент этого
  исследования на первом проходе (см. «Метод», п. 2).
- [primary] Бриф PM 2026-08-12 (текст задачи, HEAD=1264a16) — отправная точка чисел, часть из них
  подтверждена дословно (136/28 для `content/*.md`, оба протухших пути), часть — уточнена (77 →
  68 markdown-ссылок; ~194/~46 → 289/132 код-спанов по префиксу).
