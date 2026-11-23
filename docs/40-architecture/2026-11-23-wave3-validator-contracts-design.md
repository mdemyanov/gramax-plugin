---
title: "Калибровка контрактов валидаторов по движку 48592b36 — целевые значения, факты движка, AC/NFR-мэппинг, контракт с QA-author, бриф Dev и рецепт реестра иконок"
order: 12
status: draft
date: 2026-11-23
plugin: gramax
properties:
  - name: Тип контента
    value: [Архитектура]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# Калибровка контрактов валидаторов по движку 48592b36 — целевые значения, факты движка, AC/NFR-мэппинг, контракт с QA-author, бриф Dev и рецепт реестра иконок

**Опоры:** `docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`,
`plugins/gramax/gramax-tags.json`, `plugins/gramax/gramax-catalog-rules.json`,
`plugins/gramax/gramax-render-rules.json`, `plugins/gramax/scripts/validate_structure.py`,
`plugins/gramax/scripts/validate_render.py`

## Контекст

Исполнительская расшифровка [ADR-0026](../00-project/adr/0026-validator-contracts-engine-pin.md)
к требованию
[волны-3](../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md)
(FR-208…FR-218, AC-129…AC-140, AC-151; NFR-084; BR-025…BR-027). ADR несёт решения и строки
`Contract:`; этот документ несёт то, что ADR намеренно не несёт:

- факты движка с `файл:строка` на пине `48592b36` и команды их воспроизведения;
- целевые значения контрактов и сообщений валидаторов дословно;
- рецепт генератора реестра кодов иконок и его контрольные дайджесты;
- AC/NFR-мэппинг, совместимость, контракт с QA-author и бриф для Dev.

Гейт `--full`, статусы сюит и мёртвый overlay-тулинг — предмет отдельного ADR (AC-141…AC-150),
здесь не рассматриваются. Стор задач — beads (`bd show gramax-4jf.N`); `openspec/` в этом дереве
нет, поэтому списком сценариев служат AC самого требования.

## 1. Факты движка на пине 48592b36

Пути — от корня репозитория движка `github.com/Gram-ax/gramax`. Все факты прочитаны 2026-11-23
в разреженном клоне на коммите `48592b36bb0b16ec6dca248fb76dd0d5a37526a5`; движок не
запускался — факты чтения исходника, не прогона.

| № | Факт | Файл:строка движка | Решение |
|---|---|---|---|
| 1 | `language` необязателен: `language?: ContentLanguage` | `core/extensions/localization/core/events/FSLocalizationEvents.ts:19-22` | Р1 |
| 2 | Схема формы каталога: `language: z.optional(z.string().nullable())` | `core/extensions/catalog/actions/propsEditor/logic/createFormSchema.ts:61` | Р1 |
| 3 | `TABLE_TAGS = ["table", "tr", "td", "th"]` | `core/extensions/markdown/elements/table/logic/tableTransform.ts:11` | Р2 |
| 4 | Тип кода иконки — ключи `dynamicIconImports` пакета `lucide-react` плюс ключи `customIcons` | `core/components/Atoms/Icon/LucideIcon.ts:9-11` | Р3 |
| 5 | Резолв кода: библиотека ищется через `toCamelCase(code)` по экспорту `lucide-react` | `core/components/Atoms/Icon/LucideIcon.ts:13-17`, `:36-42` | Р3 |
| 6 | Файл иконки — `.icons/<code>.svg` от корня каталога, дословно по коду | `core/extensions/markdown/elements/icon/logic/IconProvider.ts:23-31`, `:39-41` | Р3 |
| 7 | При рендере сначала файл, затем библиотека | `core/extensions/markdown/elements/icon/render/model/icon.ts:11`; `core/extensions/markdown/elements/icon/render/components/HTMLIcon.tsx:9-25` | Р3 |
| 8 | Собственная проверка движка: иконка бита, только если нет файла и `LucideIcon(code)` пуст | `core/extensions/healthcheck/logic/Healthcheck.ts:258-263` | Р3 |
| 9 | Пикер пишет код голым kebab-case: `camelToKebabCase(code)` | `core/components/Atoms/Icon/lucideIconList.tsx:97-111` (`:103`, `:106`) | Р3 |
| 10 | Версия библиотеки движка: `lucide-react` `^0.525.0`, зафиксирована `0.525.0` | `package.json:105`; `bun.lock:3155` | Р3 |
| 11 | Формы кода с префиксом `lucide-` нет: все 19 вхождений литерала — импорты и CSS-классы | команда ниже | Р3 |
| 12 | Тип и умолчание флага: `optionalCategoryIndex?: boolean`; каталогу без `.doc-root.yaml` — `true` | `core/logic/FileStructue/Catalog/CatalogProps.ts:36`; `core/logic/FileStructue/FileStructure.ts:719-725` (`:722`) | Р4 |
| 13 | Без флага папка без `_index.md` не становится разделом: дети поднимаются к родителю | `core/logic/FileStructue/FileStructure.ts:528-531` | Р4 |
| 14 | С флагом раздел создаётся и без индекса; при создании индекс не пишется | `core/logic/FileStructue/FileStructure.ts:226-235`; `:669` | Р4 |
| 15 | Пустому разделу движок сам подставляет список детей; заголовок — имя папки | `core/logic/FileStructue/Article/parseContent.ts:13-17`, `:44-47`; `core/logic/FileStructue/Item/Item.ts:106-112` | Р4 |
| 16 | `Category` наследует `Article`; `CategoryProps` включает `ArticleProps` | `core/logic/FileStructue/Category/Category.ts:24-29` | Р5 |
| 17 | `properties` входит в `ArticlePropsKeys` | `core/logic/FileStructue/Article/Article.ts:43-53` | Р5 |
| 18 | Frontmatter `_index.md` читается тем же событием `item-read`, что и у статьи | `core/logic/FileStructue/FileStructure.ts:649-650` | Р5 |
| 19 | Свойства нормализуются; необъявленные в каталоге — отбрасываются | `core/extensions/properties/logic/events/FSPropertyEvents.ts:29-36` (`:33-35`) | Р5 |
| 20 | Разделы — элементы родителя: проходят `item-filter` и попадают в `items` | `core/logic/FileStructue/FileStructure.ts:536-553` | Р5 |
| 21 | Фильтр каталога судит раздел по его собственным свойствам, если ни один ребёнок не прошёл | `core/extensions/catalog/views/logic/utils/CategoryItemFilter.ts:7-36` | Р5 |
| 22 | Строки `<view>` с системным свойством `hierarchy` строятся из элементов раздела, включая подразделы, и несут их свойства | `core/extensions/properties/logic/ViewFilter.ts:90-105`, `:116-141`, `:259-281` | Р5 |
| 23 | Корневая категория строится с `content: null` и свойствами из `.doc-root.yaml` — корневой `_index.md` не читается | `core/logic/FileStructue/FileStructure.ts:469-478` | Р5 |

Команды воспроизведения (клон — разреженный, только `core/`):

```bash
git clone --filter=blob:none --no-checkout --sparse https://github.com/Gram-ax/gramax <dir>
git -C <dir> sparse-checkout set core
git -C <dir> checkout --detach 48592b36
grep -rn "lucide-" core --include=*.ts --include=*.tsx | grep -v test   # 19 строк, факт 11
grep -n "optionalCategoryIndex" core                                      # 4 строки: факты 12–13
grep -n "TABLE_TAGS" core                                                 # факт 3
git rev-parse HEAD:core/components/Atoms/Icon/customIcons.tsx             # 5f40c5ab2a904d52b1da30d764f23fcee9cdeb58
```

## 2. Целевые значения контрактов

### 2.1 `plugins/gramax/gramax-catalog-rules.json`

Было (HEAD `7553da1`, строки 2–8):

```json
  "schemaVersion": 1,
  "docRootRequiredFields": ["title", "language", "syntax"],
  "frontmatterRequiredFields": ["order", "title"],
  "indexPolicy": {
    "root": "optional",
    "subfolder": "required"
  },
```

Стало:

```json
  "schemaVersion": 2,
  "docRootRequiredFields": ["title", "syntax"],
  "docRootOptionalFields": ["language"],
  "frontmatterRequiredFields": ["order", "title"],
  "indexPolicy": {
    "root": "optional",
    "subfolder": "required",
    "subfolderOptionalFlag": "optionalCategoryIndex"
  },
```

Ключи `garbageFiles` и `nonMdContentFiles` не меняются. Семантика:

- `docRootRequiredFields` — отсутствие поля даёт `missing field: <имя>`, как прежде.
- `docRootOptionalFields` — новый ключ: отсутствие поля допустимо; присутствующее поле
  проверяется на непустую строку правилом FR-121 (ADR-0020). Нужно потому, что
  `check_doc_root` проверяет тип только по списку обязательных
  (`plugins/gramax/scripts/validate_structure.py:96-113`): без ключа присутствующий `language`
  выпал бы из проверки и AC-134 («присутствующее поле неверного типа по-прежнему даёт находку»)
  не закрылся бы. Отсутствие ключа в контракте — пустой список, поведение как прежде.
- `indexPolicy.subfolderOptionalFlag` — имя флага `.doc-root.yaml`, снимающего требование
  `_index.md` у подпапок. Отсутствие ключа — правило безусловно. Сегодня `indexPolicy` кодом не
  читается вовсе: докстринг `validate_structure.py:285` и проверка наличия ключа в `ac-012`.

### 2.2 `plugins/gramax/gramax-tags.json`

Было (строки 2–3): `"schemaVersion": 2`; `pairedTags` — 11 имён от `"note"` до
`"questionAnswer"`. Стало: `"schemaVersion": 3` и

```json
  "pairedTags": ["note", "tabs", "tab", "html", "comment", "color", "highlight", "fragment-link", "cut", "question", "questionAnswer", "table", "tr", "td"],
```

`th` в `pairedTags` не входит. Правки кода для этого решения нет: `known_tags` получает три тега
через `pairedTags` (`validate_structure.py:654-657`), а `check_tags` балансирует только разность
`pairedTags − balanceTags` (`:664`) — все три уже в `balanceTags`
(`plugins/gramax/gramax-render-rules.json:10`).

### 2.3 `plugins/gramax/gramax-lucide-icons.json` — новый файл данных

Схема (в квадратных скобках — пояснение объёма, не содержимое файла):

```text
{
  "schemaVersion": 1,
  "source": {
    "lucideReact": "0.525.0",
    "enginePin": "48592b36"
  },
  "lucide": [ 1826 имён, отсортированных, уникальных ],
  "engineCustom": [ 38 ключей, отсортированных, уникальных ]
}
```

Файл генерируется (рецепт — §3), руками не правится. Замер эталонной генерации 2026-11-23:
35 903 байта в виде JSON с отступом 2 (1875 строк); те же списки текстом через LF — 22 275 и
436 байт. Отсутствующий или повреждённый файл — явная ошибка контракта тем же путём, что и у
остальных (`load_json_contract`, `validate_structure.py:49-68`: `contract file not found`),
без молчаливого fallback.

### 2.4 Сообщения валидаторов (дословно)

```text
missing _index.md (раздела в дереве нет, статьи подняты выше; без optionalCategoryIndex: true в .doc-root.yaml файл обязателен)
W035: файл иконки не найден: код "{code}" → ожидается .icons/{code}.svg (кода нет в реестре встроенных иконок lucide-react {lucideReact})
W035: код "{code}" не является встроенным: префикс lucide- движок не читает — уберите префикс: "{stem}"
E036: файл не является валидным UTF-8 (байт 0x{hex} на позиции {start} из {size})
ERROR L0: Файл не является валидным UTF-8 (байт 0x{hex} на позиции {start} из {size})
WARNING: {path}: файл не является валидным UTF-8 (байт 0x{hex} на позиции {start} из {size}) — файл пропущен
```

- Первое сообщение заменяет текст `validate_structure.py:313`; префикс `missing _index.md`
  сохранён — на него опираются существующие ассерты.
- Второе — когда файла нет и кода нет в реестре; `{lucideReact}` — значение из `source` реестра.
- Третье — когда код начинается с `lucide-`, файла нет и `{stem}` (код без префикса) есть в реестре.
- `E036` печатается как `ERROR  <путь>  E036: …` (класс `Issue`, уровень `error`); нумерация 03x
  общая с W030–W035, буква — уровень.
- `{hex}` — два шестнадцатеричных разряда со строчными буквами и префиксом `0x` (`0xd0`);
  `{start}` — позиция первого неверного байта, считая с нуля (`UnicodeDecodeError.start`);
  `{size}` — размер файла в байтах. Форма — апстрим-линтера (задача `gramax-4jf.5`).
- Последняя строка — `parse_comments.py`, stderr; в сводку (`--summary`) добавляется строка
  «Пропущено файлов с битым UTF-8: N».

### 2.5 Что меняется в скриптах (правила, без кода)

`validate_structure.py`:

- `check_doc_root` читает второй список — необязательные поля с проверкой типа при наличии.
- `check_subfolders_have_index` получает флаг из контракта и значение флага из `.doc-root.yaml`
  своего catalog root; строго булево `true` снимает проверку для подпапок этого root. Флаг
  читается на каждый catalog root отдельно (рекурсивное обнаружение, ADR-0020).
- `check_frontmatter`: запрет `properties` в `_index.md` (`:337-338`) удаляется; условия
  `md_file.name != "_index.md"` у V3 и V4–V5 (`:341`, `:353`) заменяются на «не индекс корня
  catalog root». Сообщения V3–V5 не меняются.
- `check_icons`: реестр загружается как контракт; W035 — нет файла И кода нет в реестре;
  членство проверяется по коду в нижнем регистре, файл ищется по коду дословно. Условие
  `code.startswith("lucide-")` (`:779-780`) уходит.
- Чтение каждого файла — через общий примитив (§6, AC-132/AC-133); на файл с битым UTF-8 — ровно
  одна находка `E036`, проверки текста этого файла пропускаются, обход продолжается.
- Паттерн группы `content` в `_ERROR_GROUPS` (`:838`) получает альтернативу `UTF-8`.

`validate_render.py`: `check()` для файла с битым UTF-8 возвращает одну ошибку `(0, сообщение)`;
вывод `FAIL <путь>` и `ERROR L0: …`; обход и rc-контракт 0/1/2 не меняются.

`validate_comments.py`: та же находка `E036` для `.md` и `.comments.yaml`; код маскируется общим
примитивом `_mask_code` до извлечения якорей (иллюстрация в коде — не разметка, ADR-0019 Решение 5).
`parse_comments.py`: маска кода; файл с битым UTF-8 пропускается со строкой на stderr, rc=0.

## 3. Рецепт генератора реестра иконок

### Входы

- Пакет `lucide-react` версии из движка: `https://registry.npmjs.org/lucide-react/-/lucide-react-0.525.0.tgz`.
- Контроль целостности — `bun.lock` движка (`:3155`), base64 от SHA-512 архива:

```text
Tm1txJ2OkymCGkvwoHt33Y2JpN5xucVq1slHcgE6Lk0WjDfjgKWor5CdVER8U6DvcfMwh4M8XxmpTiyzfmfDYQ==
```

- Файл пакета `package/dynamicIconImports.d.ts`.
- Файл движка `core/components/Atoms/Icon/customIcons.tsx` на пине (blob
  `5f40c5ab2a904d52b1da30d764f23fcee9cdeb58`).

### Шаги

1. Распаковать архив и сверить SHA-512 с контрольной суммой из `bun.lock` (замер 2026-11-23 —
   совпал):

```bash
openssl dgst -sha512 -binary lucide-react-0.525.0.tgz | base64
```

2. Собрать ключи `dynamicIconImports`: строки блока от строки с `declare const dynamicIconImports`
   до первой строки `};`, попадающие под регулярное выражение R1.
3. Собрать ключи `customIcons`: строки блока от `const customIcons = {` до первой строки `};`
   (ровно один таб отступа), попадающие под R2.
4. В каждом списке убрать дубликаты и отсортировать; каждое имя обязано подходить под R3.
5. Записать JSON с порядком ключей `schemaVersion`, `source.lucideReact`, `source.enginePin`,
   `lucide`, `engineCustom`; отступ 2, `ensure_ascii=False`, завершающий перевод строки.
   `source.lucideReact` — версия пакета, `source.enginePin` — короткий хэш пина движка.

Регулярные выражения дословно:

```text
R1  ^\s+(?:'([a-z0-9]+(?:-[a-z0-9]+)*)'|([a-z][a-z0-9]*)):\s*\(\) => Promise<typeof __icons_[a-z0-9_]+>;\s*$
R2  ^\t(?:"([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)"|([A-Za-z][A-Za-z0-9]*)):\s*\(
R3  ^[a-z0-9]+(?:-[a-z0-9]+)*$
```

### Контрольные значения

Дайджест списка — SHA-256 от UTF-8-текста «имена через LF плюс завершающий LF». Эталонная
генерация SA 2026-11-23 даёт ровно две строки:

```text
lucide 1826 e0e949e2ecd8ab256553b488484512228979a11f48a60cbe3249ed04bffacdfe
engineCustom 38 72e593dad67aa467516980905d11ae17e193d9874408e9cee224fa5e0894d2de
```

Четыре кода корпуса сравнения (`check`, `ban`, `aperture`, `info`) входят в `lucide`; ключ
`loader` входит в оба списка (объединение — 1863 уникальных кода). Сгенерированный файл
проверяется одной командой (прогнана SA на эталонном файле; ожидаемый вывод — две строки выше):

```bash
python3 -I -c 'import json,hashlib,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); [print(k, len(d[k]), hashlib.sha256(("\n".join(d[k])+"\n").encode()).hexdigest()) for k in ("lucide","engineCustom")]' plugins/gramax/gramax-lucide-icons.json
```

### Пересборка при смене пина движка

Та же процедура с новыми версией пакета, контрольной суммой из `bun.lock` и blob `customIcons.tsx`;
новые дайджесты фиксируются строкой `Contract:` в `plugins/gramax/CHANGELOG.md`. Пока реестр не
пересобран, иконки, появившиеся в новой версии библиотеки, дают ложный W035 — уровень warning и
версия в сообщении позволяют отличить это от битой иконки.

## 4. AC/NFR-мэппинг

| AC | FR | Задача | Чем закрывается | Уровень теста |
|---|---|---|---|---|
| AC-129 | FR-210 | `gramax-4jf.3` | решения в ADR-0026 не требует (D8: заглушки параллельно); граница — §6 | unit |
| AC-130 | FR-211 | `gramax-4jf.4` | решения не требует; граница — §6 | unit |
| AC-131 | FR-211 | `gramax-4jf.4` | решения не требует; граница — §6 | integration |
| AC-132 | FR-212 | `gramax-4jf.5` | ADR-0026 Решение 6 | unit |
| AC-133 | FR-212 | `gramax-4jf.5` | Решение 6 | integration |
| AC-134 | FR-213 | `gramax-4jf.6` | Решение 1; `docRootOptionalFields` — §2.1 | integration |
| AC-135 | FR-214 | `gramax-4jf.7` | Решение 2 | integration |
| AC-136 | FR-215 | `gramax-4jf.8` | Решение 3; реестр — §2.3, §3 | unit, integration |
| AC-137 | FR-216 | `gramax-4jf.9` | применённое решение ADR-0019 Решение 5 (общий примитив маски); граница — §6 | unit |
| AC-138 | FR-217 | `gramax-4jf.10` | Решение 4 | integration |
| AC-139 | FR-218 | `gramax-4jf.11` | решения не требует; граница — §6 | unit |
| AC-140 | FR-221 | `gramax-4jf.12` | решения не требует (тексты) | integration |
| AC-151 | FR-209 | `gramax-4jf.2` | Решение 5 (вердикт) | unit, integration |

FR-208 — сам ADR-0026: критерий задачи `gramax-4jf.1` — регистрация в
`docs/00-project/adr/_index.md`, пять решений зафиксированы, `check.sh --fast` PASS.
AC-141…AC-150 — гейт и сюиты волны, вне этого документа.

NFR и бизнес-правила:

- **NFR-084** — ассерты, меняющие цвет, переводятся на новую семантику, а не удаляются:
  таблица ниже. rc-контракты всех валидаторов сохраняются.
- **BR-025** — целевые значения лежат дословно в ADR-0026 и в §2–§3 этого документа; JSON и код
  правит Dev под заглушками QA-author.
- **BR-026** — каждое изменение severity опирается на факт движка (§1) или замер; замеры
  корпуса взяты из задач `gramax-4jf.N` и SA не повторялись.
- **BR-027** — баланс `table`/`tr`/`td` ведёт только `validate_render.py` (Решение 2).

Существующие ассерты, которые меняют цвет (переводятся, NFR-084):

| Ассерт | Что закрепляет сегодня | Целевое состояние |
|---|---|---|
| `tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh:57-61` | `schemaVersion == 2` | `== 3` |
| `tests/gramax/catalog-validator/ac-030-icon-lucide-boundary.sh` | `lucide-zap` не упоминается в выводе | голый `zap` не упоминается; `lucide-zap` даёт W035 с подсказкой |
| `plugins/gramax/scripts/tests/test_validators_parity.py:78-91` | `lucide-zap` — библиотечный, к `.icons/` не резолвится | тот же перевод; `xlucide-zap` остаётся пользовательским |
| `plugins/gramax/scripts/tests/test_validate_structure.py:101-103` и фикстура `tests/fixtures/bad/index-with-properties/` | ERROR «не должен содержать properties» | фикстура переносится в `good/`; для V4/V5 — новая фикстура с необъявленным свойством |
| AC-066 требования паритета (после `gramax-o0q.19` — AC-157) | `lucide-`-код не даёт находок | superseded в части ADR-0026; помечается в требовании, не переписывается |

## 5. Совместимость — для пользователей валидаторов

Коды выхода валидаторов (`0/1/2`) не меняются ни одним решением.

| Решение | Вердикты | schemaVersion | Что ломает |
|---|---|---|---|
| 1 | каталог без `language`: ERROR и rc=1 → нет находки | `gramax-catalog-rules.json` 1 → 2 | потребителей, полагавшихся на запрет; читателей строгого равенства версии |
| 2 | W034 по `table`/`tr`/`td` уходит; под `--strict` таблицы перестают краснеть | `gramax-tags.json` 2 → 3 | читателей `schemaVersion == 2` (в дереве — `ac-086`) |
| 3 | голые коды Lucide: W035 уходит; коды `lucide-` без файла: W035 появляется | новый файл, `schemaVersion: 1` | каталоги, написанные по форме `lucide-` прошлых версий writer: предупреждение об истинном дефекте |
| 4 | с флагом ложный ERROR уходит; без флага — новый текст сообщения | (в счётчике решения 1) | grep по старому тексту сообщения |
| 5 | запрет `properties` снят; V3–V5 охватывают `_index.md` подпапок | — | `_index.md` с необъявленным свойством даёт ERROR |
| 6 | traceback → находка, полный обход, rc=1 | — | ничего: раньше запуск падал |

## 6. Контракт с QA-author

### Сценарии приёмки

`openspec/` в этом дереве нет; сценарии — AC требования волны-3 в части контрактов:
AC-129, AC-130, AC-131, AC-132, AC-133, AC-134, AC-135, AC-136, AC-137, AC-138, AC-139, AC-140,
AC-151.

### Архитектурный контекст

- Компоненты: `validate_structure.py` (структура, frontmatter, теги, ссылки, иконки),
  `validate_render.py` (рендер-киллеры и баланс), `validate_comments.py`, `parse_comments.py`,
  общий примитив `lib/md_code_mask.py`, новый примитив чтения в `plugins/gramax/scripts/lib/`.
- Контракты: `gramax-catalog-rules.json`, `gramax-tags.json`, `gramax-render-rules.json`,
  новый `gramax-lucide-icons.json`.
- Интеграции внешние отсутствуют: валидаторы офлайн; источник истины о движке — §1, не рантайм.
- Граница доверия одна: файлы каталога (в том числе с битым UTF-8, битым YAML, чужими тегами) —
  вход, который нельзя обрывать исключением.

### Границы для задач без решения в ADR-0026 (AC-129…131, 137, 139, 140)

- **AC-129.** Проверка уникальности ID в `validate_comments.py:61-67` снимается. «Показывает ID с
  его позициями» — информационная строка уровня `info` (третий уровень класса `Issue`): на rc не
  влияет, `--strict` не эскалирует. `parse_md_anchors` хранит один якорь на ID
  (`parse_comments.py:31-38`) — при нескольких позициях выдаются все.
- **AC-130.** Обе формы блочного комментария распознают `parse_comments.py` (`:17-18`) и
  `validate_comments.py` (`:16-17`): XML — самозакрывающийся открывающий тег `<comment id="ID"/>`,
  пустая строка, текст, пустая строка, закрывающий `</comment>`; скобочная — открывающий маркер
  «`[comment:` + ID + `]`» и парный закрывающий. Навыки называют XML-форму каноном для
  `syntax: XML`, скобочную — legacy.
- **AC-131.** В `check_tags` (`validate_structure.py:391-392`) открывающий regex не считает
  самозакрывающий тег открывающим, закрывающий считается — возникает «unpaired». Цель:
  самозакрывающий открывающий тег считается открывающим только для тега `comment`; скобочная
  форма (`:396-399`) считается, как прежде.
- **AC-137.** Маска тела `<html>…</html>` — новая функция того же модуля `lib/md_code_mask.py`
  (содержимое между внешней парой заменяется пробелами той же длины): применяется после
  `_mask_code`, поэтому `<html>` внутри fenced- или inline-кода маску не переключает. Читают
  маску построчные проверки и баланс `validate_render.py`, W034 и W035; `check_tags` продолжает
  балансировать внешнюю пару `html`. Провенанс апстрим-механики `html_mask` — по ADR-0019.
  Вторая половина FR-216 (AC-148) — три плейсхолдера `docs/`, найденные маской валидатора:
  `docs/00-project/adr/0021-docs-layout-inversion.md:389` (`<home>`, дважды, без code-span),
  `docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md:191` (`<file>`),
  `docs/60-implementation/2026-08-13-doc-root-discovery-dev-notes.md:42` (`<raw>`); в двух
  последних строках нечётное число бэктиков разрывает code-span.
- **AC-139.** Предупреждение об ответе без `user.id` — уровень `warning`; обе формы пустых
  `answers` находок не дают.
- **AC-140.** Тексты README и докстринга; проверка версии README сравнивает её с `plugin.json`.

### Граничные случаи

- UTF-8: неверный байт в первом байте файла; оборванный многобайчный символ в конце (фикстура
  `tests/gramax/render-quality/fixtures/invalid-utf8.md`); битый `.doc-root.yaml`; битый
  `.comments.yaml`; файл с битым UTF-8 как цель ссылки с `#якорем` (`check_hash_anchor`,
  `plugins/gramax/scripts/lib/link_resolver.py:109`); пустой файл (не ошибка).
- На файл с битым UTF-8 — ровно одна находка, сколько бы проверок его ни читали (шесть читателей
  текста: `validate_structure.py:329`, `:383`, `:494`, `:530`, `:776`, `:819`).
- Реестр иконок: движок резолвит библиотечный код без приведения к нижнему регистру
  (`LucideIcon.ts:13-17`), поэтому членство проверяется по `code.lower()`, а файл — по коду
  дословно; пустой код и код `icon` движок считает неверными (`LucideIcon.ts:19-21`) — W035;
  файл есть и код входит в реестр — находки нет (файл при рендере приоритетнее).
- `optionalCategoryIndex`: флаг снимает проверку только при значении YAML `true`; строка `"true"`
  и `false` не снимают; каталог без `.doc-root.yaml` валидатор и раньше останавливал
  (`validate_structure.py:672-674`).
- `properties` в `_index.md`: индекс корня catalog root и индекс корня вложенного root — вне
  проверок V3–V5; `properties: []` находок не даёт; плоская нотация — V3 (warning).
- `docRootOptionalFields`: поле отсутствует — нет находки; `null`, число, пустая строка —
  находка FR-121; непустая строка — нет находки.

### Рекомендация по пирамиде

| Группа | Уровень | Почему |
|---|---|---|
| AC-129, AC-130, AC-139 | unit | чистый разбор фикстур комментариев, без окружения |
| AC-132 | unit | `validate_render.py` на каталоге из двух файлов: битый и здоровый |
| AC-136 (членство, дайджесты, реестр отсутствует) | unit | данные и одна функция проверки |
| AC-137 | unit | примитив маски на фикстурах: тело блока, `<html>` внутри кода |
| AC-131, AC-133, AC-134, AC-135, AC-136 (CLI), AC-138, AC-151 | integration | CLI валидатора на фикстуре каталога, rc и текст вывода |
| AC-140 | integration | тексты манифестов и README в дереве |

## 7. Бриф для Dev

**Архитектура:** этот документ; **ADR:** ADR-0026; **Требование:** волна-3 (FR-208…FR-218).
**Порядок:** заглушки QA-author рождаются красными → контракты и код по §2 → позеленение →
строки `Contract:` из ADR-0026 в `plugins/gramax/CHANGELOG.md` тем же коммитом, что и JSON.

Что реализовать, по задачам:

| Задача | Файлы |
|---|---|
| `gramax-4jf.6` (Решение 1) | `plugins/gramax/gramax-catalog-rules.json`; фикстуры `tests/gramax/catalog-validator/` |
| `gramax-4jf.7` (Решение 2) | `plugins/gramax/gramax-tags.json`; комментарий `check_tags` в `validate_structure.py` |
| `gramax-4jf.8` (Решение 3) | новый `plugins/gramax/gramax-lucide-icons.json` (§3); `check_icons` в `validate_structure.py`; генератор — инструмент сопровождения в `scripts/` репозитория, в payload плагина не входит |
| `gramax-4jf.10` (Решение 4) | `plugins/gramax/gramax-catalog-rules.json`; `check_subfolders_have_index` в `validate_structure.py` |
| `gramax-4jf.2` → `gramax-4jf.1` (Решение 5) | `check_frontmatter` в `validate_structure.py` |
| `gramax-4jf.5` (Решение 6) | новый примитив чтения в `plugins/gramax/scripts/lib/`; `validate_render.py`; `validate_structure.py`; `validate_comments.py`; `parse_comments.py` |
| `gramax-4jf.3`, `.4`, `.9`, `.11`, `.12` | файлы по задачам в beads; границы — §6 |

Документы к синхронной правке (writer, README, валидатор говорят одно):

- `plugins/gramax/skills/writer/SKILL.md:76` — правило подпапки с флагом; `:158` — `properties` в
  `_index.md` разрешены, эффект назван; `:331` — форма кода иконки без префикса.
- `plugins/gramax/skills/writer/references/blocks.md:402-409` — пример иконки и заметка о префиксе.
- `plugins/gramax/skills/writer/references/doc-root-schema.md:19` — `language` необязателен
  (источник — факты 1–2); новая строка `optionalCategoryIndex`; `:151` — заметка о `.icons/`.
- `plugins/gramax/skills/writer/references/structure.md` — правило подпапки (задача `gramax-4jf.10`).
- `plugins/gramax/README.md:79`, `:89` — состав обязательных полей; `:145` — версия (задача
  `gramax-4jf.12`).
- `plugins/gramax/scripts/LICENSE.upstream.md` — провенанс переноса `read_page` и `html_mask`.
- `plugins/gramax/scripts/validate_render.py:5-9` (докстринг), `:170` (запасной текст) — задача
  `gramax-4jf.12`.
- `docs/70-operations/2026-11-21-render-quality-runbook.md:236-240` — исключение байтовой
  фикстуры из прогона валидатора перестаёт быть обязательным (Решение 6).

## Допущения

- Замеры корпуса сравнения (999, 90, 43, 16) — из задач `gramax-4jf.N`; SA их не повторял.
- Число находок V3–V5 на `_index.md` в корпусе сравнения — `N/A — корпус не входит во входы SA`;
  команда замера после правки: `python3 -B plugins/gramax/scripts/validate_structure.py <корпус>`.
- Совпадение множества ключей `dynamicIconImports` с рантайм-набором движка —
  `N/A — движок не запускался`; опора — тип `IconCode` движка (`LucideIcon.ts:9-11`).
- Чтение `language: null` движком в рантайме — `N/A — не прослеживал`; правило «непустая строка»
  сохраняет сегодняшний вердикт для присутствующего поля.
- Отсутствие формы `lucide-` — факт чтения исходника, живым прогоном не проверялся.
- Объём реестра (35 903 байта) — замер эталонной генерации, не оценка.
