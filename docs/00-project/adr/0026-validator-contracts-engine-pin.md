---
title: "ADR-0026: Калибровка контрактов валидаторов по движку 48592b36 — language, теги таблицы, реестр иконок, optionalCategoryIndex, properties в _index.md, битый UTF-8"
order: 26
status: accepted
date: 2026-11-23
properties:
  - name: Тип контента
    value: [ADR]
  - name: Статус
    value: [Accepted]
  - name: Плагин
    value: [gramax, marketplace]
---

# ADR-0026: Калибровка контрактов валидаторов по движку 48592b36 — language, теги таблицы, реестр иконок, optionalCategoryIndex, properties в _index.md, битый UTF-8

**Status:** Accepted — ратифицировано PM 2026-11-23 по санкции владельца «автономно до push включительно»
(волна-3, решение D6): решения 1–7 приняты как написаны; поправки при ратификации — ключ
`docRootOptionalFields` в решении 1 и решение 8 (маскирование кода в валидаторе комментариев).
**Date:** 2026-11-23
**Plugin:** gramax / marketplace
**Опоры:** `docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`,
`plugins/gramax/gramax-catalog-rules.json`, `plugins/gramax/gramax-tags.json`

## Context

Эпик `gramax-4jf` подтвердил 12 дефектов плагина 4.9.0 на корпусе сравнения (живой каталог,
766 страниц, `syntax: XML`) и исходниках движка: ложные 43 ERROR по `properties` в `_index.md`,
1 по `language`, 999 W034 на XML-таблицах, 90 W035 на встроенных иконках; traceback на битом
UTF-8. Требование [волны-3](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md)
(FR-208…FR-218, AC-129…AC-140, AC-151) и его D8: SA фиксирует целевые значения дословно, JSON и
код правит Dev под заглушками QA-author (BR-025). Факты движка читались на пине `48592b36`
2026-11-23; доказательная таблица, AC/NFR-мэппинг, контракт с QA-author и бриф Dev —
[дизайн-документ](../../40-architecture/2026-11-23-wave3-validator-contracts-design.md).

## Решение 1 — `language` уходит из обязательных полей `.doc-root.yaml` (FR-213, AC-134)

Движок объявляет поле необязательным: `language?: ContentLanguage`
(`core/extensions/localization/core/events/FSLocalizationEvents.ts:19-22`),
`language: z.optional(z.string().nullable())`
(`core/extensions/catalog/actions/propsEditor/logic/createFormSchema.ts:61`). Присутствующее поле
по-прежнему проверяется на непустую строку (ADR-0020) — через новый ключ контракта
`docRootOptionalFields: ["language"]`: проверка типов `check_doc_root` идёт только по спискам
контракта (`plugins/gramax/scripts/validate_structure.py:96-113`), без ключа присутствующее поле
не проверялось бы вовсе (поправка ратификации). ADR-0012 Решение 3 — superseded в части
состава `docRootRequiredFields`.

## Решение 2 — `table`, `tr`, `td` входят в `pairedTags`; schemaVersion 2 → 3 (FR-214, AC-135)

`TABLE_TAGS = ["table", "tr", "td", "th"]`
(`core/extensions/markdown/elements/table/logic/tableTransform.ts:11`). Двойного учёта нет без
правки кода: три тега попадают в `known_tags` через `pairedTags` (`validate_structure.py:654-657`)
— W034 молчит; `check_tags` балансирует только `pairedTags − balanceTags` (`:664`), а все три уже
в `balanceTags` (`gramax-render-rules.json:10`) — баланс ведёт один валидатор,
`validate_render.py:184-195` (BR-027). `th` не входит: его носитель — контракт рендера (киллер с
`severity: warn`). Подъём версии — по FR-214 и прецеденту ADR-0024 Решение 3; цена — пин
`schemaVersion == 2` в `tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh:57-61`
переводится QA-author, а не удаляется (NFR-084).

## Решение 3 — иконки: реестр кодов в поставке; W035 = нет файла И нет в реестре (FR-215, AC-136)

Движок: `IconCode` — ключи `dynamicIconImports` пакета `lucide-react` плюс ключи `customIcons`
(`core/components/Atoms/Icon/LucideIcon.ts:9-11`); код резолвится файлом `.icons/<код>.svg`, затем
библиотекой (`core/extensions/markdown/elements/icon/logic/IconProvider.ts:23-41`,
`LucideIcon.ts:36-42`); своя проверка движка считает иконку битой, только если нет ни того, ни
другого (`core/extensions/healthcheck/logic/Healthcheck.ts:257-270`). **Формы с префиксом `lucide-`
в движке нет:** все 19 вхождений литерала в `.ts`/`.tsx` — импорты и CSS-классы
(`grep -rn "lucide-" core --include=*.ts --include=*.tsx | grep -v test`); `lucide-zap` через
`toCamelCase` даёт `LucideZap`, которого в экспорте нет.

Механика — сгенерированный файл данных `plugins/gramax/gramax-lucide-icons.json` с провенансом
(`lucide-react` 0.525.0: `package.json:105`, `bun.lock:3155`): 1826 имён и 38 ключей `customIcons`
(замер 2026-11-23; рецепт — в дизайне). Уровень W035 прежний — warning (ADR-0024 Решение 2).
ADR-0024 Решение 5, BR-013 и FR-153/AC-066 требования паритета — superseded в части формы
префикса; writer переходит на голый kebab-case.

## Решение 4 — правило подпапки читает `optionalCategoryIndex`; без флага ERROR остаётся (FR-217, AC-138)

Без флага папка без `_index.md` не становится разделом — дети поднимаются выше
(`core/logic/FileStructue/FileStructure.ts:528`); с флагом `optionalCategoryIndex: true` она —
раздел со списком детей, который движок собирает сам (`:226-227`;
`core/logic/FileStructue/Article/parseContent.ts:13-17`). Имя флага переезжает из кода в контракт —
ключ `indexPolicy.subfolderOptionalFlag` (BR-002): сегодня `indexPolicy` кодом не читается (докстринг
`validate_structure.py:285`, проверка наличия ключа в `ac-012`). Нет ключа — правило безусловно.

## Решение 5 — `properties` в `_index.md`: запрет снят (вердикт gramax-4jf.2; FR-209, AC-151)

Вердикт: ключ штатный и видимый. `Category` наследует `Article`
(`core/logic/FileStructue/Category/Category.ts:24-29`), `properties` входит в `ArticlePropsKeys`
(`core/logic/FileStructue/Article/Article.ts:43-53`); frontmatter `_index.md` читается тем же
событием `item-read` и нормализуется (`FileStructure.ts:647-650`,
`core/extensions/properties/logic/events/FSPropertyEvents.ts:29-36`). Эффект: фильтр каталога
показывает или скрывает раздел по его собственным свойствам, если в фильтре не выжил ни один
ребёнок (`core/extensions/catalog/views/logic/utils/CategoryItemFilter.ts:10-36`); строки `<view>`
с системным свойством `hierarchy` строятся из дочерних разделов и несут их свойства
(`core/extensions/properties/logic/ViewFilter.ts:90-104`, `:259-281`).

Severity: ERROR снимается, WARN не вводится — законная конструкция не краснеет и под `--strict`.
V3–V5 (схема свойств) применяются к `_index.md` подпапок наравне со статьями: движок отбрасывает
необъявленные свойства и у раздела (`FSPropertyEvents.ts:33-35`); индекс корня остаётся вне
проверки — он инертен для движка (`FileStructure.ts:469-478`, ADR-0015). Правило C2 nauta
(`scripts/validate-content.py:170-190`) — конвенция скаффолда nauta для `docs/` этого репозитория.

## Решение 6 — битый UTF-8: именованная находка, обход продолжается, rc=1 (FR-212, AC-132, AC-133)

Один примитив чтения `read_page` в `plugins/gramax/scripts/lib/` (провенанс MIT-порта — по
ADR-0019). `validate_render.py` печатает `FAIL <путь>` и строку
`ERROR L0: Файл не является валидным UTF-8 (байт 0xNN на позиции P из S)` — форма апстрим-линтера
(gramax-4jf.5). `validate_structure.py` и `validate_comments.py` дают код `E036` (нумерация 03x
общая с W030–W035, буква — уровень), одна находка на файл (BR-004). P — позиция первого неверного
байта с нуля, S — размер файла в байтах. Читатель `parse_comments.py` пропускает файл с
предупреждением на stderr, rc=0.

## Решение 7 — версия 4.10.0 (Minor) и разрешение на `marketplace.json`

Нет удалённых навыков и изменений `mcpServers` (ADR-0006); ужесточения — только на генуинные
дефекты по факту движка (прецедент ADR-0024 Решение 7). Разрешаю правку
`.claude-plugin/marketplace.json`: `metadata.version` → `"4.10.0"`; `plugin.json` — синхронно.
Поправка ратификации PM 2026-11-23 (по находке независимого ревью): тем же решением разрешена
одна фактическая правка описания плагина в этом файле — перечень обязательных полей
`.doc-root.yaml` приводится к Решению 1 (`title`/`syntax`; `language` необязателен).

## Решение 8 — иллюстрации синтаксиса в коде не являются разметкой (поправка ратификации, OI-3 ADR-0027; gramax-4jf.13)

`validate_comments.py` и `parse_comments.py` маскируют code-span и fenced-блоки общим примитивом
`plugins/gramax/scripts/lib/md_code_mask.py` до поиска тегов; пробелы внутри тега ограничены одной
строкой — сегодня `INLINE_RE` с `re.DOTALL` мостит через абзацы и даёт ложные ID. Замер 2026-11-23 на
`docs/`: rc=1, 4 ERROR «invalid comment id format» на четырёх иллюстрациях. Для пользователей:
документация о синтаксисе комментариев перестаёт давать ложные ERROR.

## Целевые значения контрактов (дословно)

```text
plugins/gramax/gramax-catalog-rules.json — schemaVersion 1 → 2
  docRootRequiredFields: ["title", "language", "syntax"] → ["title", "syntax"]
  + docRootOptionalFields: ["language"] — необязательное поле, проверяется на непустую строку при наличии
  indexPolicy: {"root": "optional", "subfolder": "required"}
    → {"root": "optional", "subfolder": "required", "subfolderOptionalFlag": "optionalCategoryIndex"}
plugins/gramax/gramax-tags.json — schemaVersion 2 → 3
  pairedTags: ["note", "tabs", "tab", "html", "comment", "color", "highlight", "fragment-link", "cut", "question", "questionAnswer"]
    → ["note", "tabs", "tab", "html", "comment", "color", "highlight", "fragment-link", "cut", "question", "questionAnswer", "table", "tr", "td"]
plugins/gramax/gramax-lucide-icons.json (новый) — {"schemaVersion": 1, "source": {"lucideReact": "0.525.0", "enginePin": "48592b36"}, "lucide": [...], "engineCustom": [...]}
  lucide — 1826 имени, имена через LF с завершающим LF: sha256 e0e949e2ecd8ab256553b488484512228979a11f48a60cbe3249ed04bffacdfe
  engineCustom — 38 ключей, тот же вид: sha256 72e593dad67aa467516980905d11ae17e193d9874408e9cee224fa5e0894d2de
```

## Строки Contract: для CHANGELOG

Каждая строка блока — один абзац `plugins/gramax/CHANGELOG.md` под заголовком 4.10.0, дословно:
```text
Contract: `gramax-catalog-rules.json` — schemaVersion 1 → 2 (ADR-0026 Решения 1 и 4). `docRootRequiredFields`: `["title", "syntax"]` — поле `language` ушло из обязательных (движок объявляет его необязательным: `FSLocalizationEvents.ts:19-22`, `createFormSchema.ts:61` на пине 48592b36); присутствующее поле по-прежнему проверяется на непустую строку — через новый ключ `docRootOptionalFields: ["language"]` (список необязательных полей, проверяемых по типу при наличии). `indexPolicy` получает ключ `subfolderOptionalFlag: "optionalCategoryIndex"` — имя флага `.doc-root.yaml`, снимающего требование `_index.md` у подпапок; без ключа правило безусловно, как прежде.
Contract: `gramax-tags.json` — schemaVersion 2 → 3 (ADR-0026 Решение 2): `pairedTags` +3 (`table`, `tr`, `td` — TABLE_TAGS движка, `tableTransform.ts:11`); W034 на XML-таблицах уходит. Баланс этих тегов по-прежнему ведёт только `validate_render.py` (`balanceTags`), `validate_structure.py` их не балансирует — один дефект, одна находка (BR-027). `th` в `pairedTags` не входит: его носитель — `gramax-render-rules.json` (киллер с `severity: warn` с 4.9.0). Потребители, читающие `gramax-tags.json` напрямую, читают `schemaVersion` 3.
Contract: новый файл данных `gramax-lucide-icons.json` (schemaVersion 1; источник — `lucide-react` 0.525.0 по `bun.lock:3155` движка 48592b36 и ключи `customIcons` движка: 1826 имён и 38 ключей). W035 срабатывает только когда нет файла `.icons/<код>.svg` И кода нет в реестре — паритет с проверкой иконок движка (`Healthcheck.ts:258-263`). Коды Lucide — голый kebab-case, как пишет пикер движка; формы с префиксом `lucide-` движок не знает (`LucideIcon.ts:36-42`): такой код даёт W035 с подсказкой убрать префикс. ADR-0024 Решение 5 и BR-013 — superseded в части формы префикса.
Contract: `validate_structure.py` — правило «`_index.md` не должен содержать properties» снято (ADR-0026 Решение 5: движок читает свойства раздела как свойства статьи — `Category.ts:29`, `Article.ts:43-53`). Проверки свойств по схеме каталога (необъявленное свойство, значение вне enum, плоская нотация) применяются и к `_index.md` подпапок; `_index.md` корня каталога остаётся вне проверки (инертен для движка, ADR-0015).
Contract: `validate_render.py`, `validate_structure.py`, `validate_comments.py`, `parse_comments.py` — файл, не являющийся валидным UTF-8, больше не обрывает обход трейсбеком: именованная находка с путём и позицией байта (`ERROR L0: Файл не является валидным UTF-8 (байт 0xNN на позиции P из S)` у рендер-линтера; код `E036` у структурного валидатора и валидатора комментариев), остальные файлы проверяются, rc=1; `parse_comments.py` пропускает файл с предупреждением на stderr (ADR-0026 Решение 6).
Contract: `validate_comments.py`, `parse_comments.py` — примеры тегов внутри code-span и fenced-блоков не считаются разметкой (общий примитив маскирования кода, ADR-0026 Решение 8): документация о синтаксисе комментариев больше не даёт ложных «invalid comment id format». Два ужесточения объявляются тем же решением: самозакрывающий открывающий `<comment id="…"/>` без парного `</comment>` — ERROR `unpaired <comment>` у структурного валидатора (прежде — тишина); тег с переносом строки между `<comment` и `id=` — ERROR «тег разорван» у валидатора комментариев (прежде считался позицией комментария).
```

## Consequences

**Положительные:** ложные сигналы уходят по факту движка, а не по впечатлению (BR-026); реестр
иконок закрывает класс, который ADR-0024 оставил открытым; один дефект — одна находка.
**Совместимость:** коды выхода валидаторов не меняются. Решение 1 — каталог без `language` перестаёт
давать rc=1. Решение 2 — уходит только W034, под `--strict` таблицы перестают краснеть. Решение 3 —
голые коды Lucide перестают давать W035, коды `lucide-` без файла дают W035 с подсказкой убрать
префикс. Решение 4 — с флагом уходит ложный ERROR, без флага меняется текст сообщения. Решение 5 —
уходит 43 ложных ERROR, появляются истинные V3–V5 на `_index.md`. Решение 6 — traceback и обрыв
обхода заменяются полным обходом и rc=1.
**Отрицательные / trade-offs:** реестр (35 903 байта в виде JSON с отступом 2) пересобирается при смене пина движка, иначе новые
иконки Lucide дают ложный W035; V3–V5 на `_index.md` могут вскрыть истинные дефекты чужих
каталогов. **Mitigations:** W035 остаётся warning и называет версию реестра; изменения объявлены
строками `Contract:` тем же коммитом, что и JSON.

## Alternatives Considered

- Понижение W035 до INFO — отклонено: не отличает битую собственную иконку от кода Lucide.
- Проверка только «явно пользовательских» кодов — отклонено: маркера, кроме самого файла, нет.
- Не поднимать schemaVersion тегов — отклонено: требуют FR-214 и AC-135.
- WARN вместо снятия запрета `properties` — отклонено: законная конструкция краснеет под `--strict`.

## Связанные артефакты

- требование: [Волна-3 — релиз 4.10.0](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md)
- дизайн-документ (факты движка, AC/NFR-мэппинг, контракт с QA-author, бриф Dev):
  [Калибровка контрактов валидаторов — дизайн](../../40-architecture/2026-11-23-wave3-validator-contracts-design.md)
- гейт и сюиты волны: [ADR-0027](0027-full-gate-composition.md)
- применяет: [ADR-0012](0012-catalog-validation-contract.md), [ADR-0019](0019-render-killer-linter.md),
  [ADR-0020](0020-doc-root-recursive-discovery.md), [ADR-0024](0024-validators-error-check-parity.md),
  [ADR-0015](0015-root-index-inert.md), [ADR-0006](0006-marketplace-json-semver-strategy.md)
- superseded в части (тела старых ADR не редактируются): ADR-0012 Решение 3 — состав
  `docRootRequiredFields`; ADR-0024 Решение 5 и BR-013 — форма префикса `lucide-`
