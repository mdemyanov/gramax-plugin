---
title: "RES-008: Аудит расхождений writer ↔ docs по синтаксису — вердикты по исходнику движка (48592b36)"
order: 10
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Active]
  - name: Плагин
    value: [gramax]
---

# RES-008: Аудит расхождений writer ↔ docs по синтаксису — вердикты по исходнику движка (48592b36)

**Дата:** 2026-11-18. **Метод:** исходник движка как ground truth:
`github.com/Gram-ax/gramax`, blobless-клон, checkout на пин `48592b36` («Changes from
jul-2026 to sep-2026», 2026-10-06 — тот же пин окна движка, что в RES-006). Все пять
расхождений из RES-007 §4 проверены чтением кода парсера/рендера/фильтра на этом пине;
каждый вердикт несёт `путь:строка` в дереве движка. Исполнение (probe-тест как в RES-004) не
запускалось — только чтение кода; уровень уверенности по каждой группе указан в §7.
Требований и кандидатов на реализацию не пишу — правки writer исполняет отдельная
dev-стадия.

**Состав сторон спора:** «writer» — плагин 4.6.0 (`SKILL.md`, `references/blocks.md`);
«docs» — выкачка gram.ax из RES-007 (страница `article/editor/syntax` и страницы элементов);
«движок» — исходник на пине. Формулировки claims — из RES-007 §4 (строки «Нейминг
фрагментов», «Семантика `defs` у `<view>`», «Формы ссылок на статьи», «width/height/scale
картинок», «Скобочные токены vs теги») и из прямого чтения файлов writer.

## TL;DR — вердикты

| # | Пункт | Вердикт |
|---|---|---|
| 1 | Фрагменты: `<snippet>`/`.gramax/snippets/` vs `<fragment>`/`.gramax/fragments/` | Движок поддерживает оба тега (`snippet` — алиас); канон — `fragment` + `.gramax/fragments/`, `snippets/` — legacy-путь, мигрируется при правке |
| 2 | Внутренние ссылки: с `.md` vs без `.md` | writer соответствует движку: обе формы резолвятся на пине; правило «без `.md`» остаётся (примирение с контрактом FR-080, не противоречие) |
| 3 | Атрибуты `<view>` | Обе стороны расходятся с движком в разном направлении: docs точнее в наборе атрибутов и семантике `defs`; docs ошибаются в Gantt (в движке нет) и `hierarchy` (не атрибут); writer ошибается в семантике `defs` и не знает `orderby`/`select` |
| 4 | cmd/kbd: скобочные vs XML-формы | Движок поддерживает обе; writer неполон (только скобочные), XML-формы docs движку соответствуют |
| 5 | Изображения: width/height/scale, `<gallery>` | Семантике width/height/scale соответствует docs; writer не знает `scale`; `<gallery>` в движке на пине нет (есть парный `<img-h>/<img-v>`, не описанный ни одной из сторон) |

## 1. Фрагменты — `<snippet>` vs `<fragment>`

**writer (4.6.0):** `<snippet id="name"/>` — вставка из `.gramax/snippets/`, файлы —
обычный markdown без frontmatter (`references/blocks.md:104-110`); SKILL.md:286 — строка
«Сниппет» в таблице блоков; SKILL.md:356-357 — «НЕ удалять `.gramax/` (содержит сниппеты)».

**docs (RES-007 §4, строки «Нейминг фрагментов», «Фрагменты»):** файл
`.gramax/fragments/<id>.md`, теги `<fragment id="…"/>` и
`<fragment-link id>текст</fragment-link>`; термин «snippets» в выкачанных docs не
встречается.

**Движок (48592b36):**

- Реестр тегов парсера
`core/extensions/markdown/core/render/logic/getRenderElements/getTagElementRenderModels.ts:65-66`
— `fragment: fragment(context)` **и** `snippet: fragment(context)` (оба имени тега ведут в
одну схему); `:71-72` — `"fragment-link": fragmentLink(context)` и
`"snippet-link": fragmentLink(context)` (алиас и для ссылки).
- Схема вставки `core/extensions/markdown/elements/fragment/render/model/fragment.ts:5-30` —
атрибут `id` (String), контент подтягивается провайдером фрагментов; схема ссылки
`core/extensions/markdown/elements/fragment-link/render/model/fragmentLink.ts:4-15` —
атрибут `id` (String), `selfClosing: false`, дочерний текст трансформируется (форма
`<fragment-link id>текст</fragment-link>` работает).
- Хранение: `app/config/const.ts:6,10-11` — `GRAMAX_DIRECTORY=".gramax"`,
`FRAGMENTS_DIRECTORY="fragments"`, `SNIPPETS_DIRECTORY="snippets"`. Провайдер
`core/extensions/markdown/elements/fragment/logic/FragmentProvider.ts:26` — рабочий каталог
провайдера `FRAGMENTS_DIRECTORY`; корень путей — `ArticleProvider.ts:26` (
`core/extensions/articleProvider/logic/ArticleProvider.ts`):
`<каталог>/.gramax/<directory>` — новые фрагменты создаются в `.gramax/fragments/`.
- Legacy: `FragmentProvider.ts:27-31` — при чтении каталога дополнительно читается
`.gramax/snippets` (комментарий в коде: «legacy: old OPFS storage path»); `:149-151` —
`_isOldFragment` определяет старый путь по подстроке `.gramax/snippets`; `:129-144` — при
первой же правке такого фрагмента он удаляется из `snippets/` и пересоздаётся в `fragments/`
(автомиграция). Рядом
`core/extensions/markdown/elements/fragment/logic/getFragmentLegacyPath.ts:6-18` —
фолбэк-резолв путей из `fragments/` на `snippets/` для старых данных.

**Вердикт: движок поддерживает оба тега; docs соответствуют канону движка, writer — рабочая
legacy-форма.** `<snippet>` не ошибка — он парсится и `.gramax/snippets/` читается, но это
помеченный в коде legacy-путь: новые фрагменты движок кладёт в `.gramax/fragments/`, а
фрагмент из `snippets/` при первой правке переезжает туда же.

**Рекомендуемая правка writer (для dev-стадии):** в `references/blocks.md` и SKILL.md
заменить канон на `<fragment id="…"/>` + `.gramax/fragments/`; добавить
`<fragment-link id>текст</fragment-link>`; форму `<snippet>` / `.gramax/snippets/` —
сохранить с пометкой «legacy: движок читает, но при правке мигрирует в fragments/»; путь в
staging-чеклисте SKILL.md («НЕ удалять `.gramax/` (содержит сниппеты)») уточнить до
«фрагменты/сниппеты».

## 2. Внутренние ссылки — форма с `.md` и без

**writer (4.6.0):** внутренние ссылки без `.md` — `[Название](./другой-документ)`,
`[Название](./../app/_index)` (SKILL.md:210-212); для нового контента — целевая форма.

**docs (RES-007 §4, строка «Формы ссылок на статьи»):** синтаксис-страница называет
канонической форму **с** `.md` («Путь к статье — относительно текущего файла и с расширением
`.md`», примеры `[текст](./other.md)`).

**Контекст, не пересматриваемый:** RES-004 (исполняемый probe на `linkCreator.getLink()`)
установил: резолвятся обе формы, а штатный редактор при пересохранении для не-GFM синтаксиса
сам срезает `.md`; контракт формы — FR-080 (без `.md` для новых ссылок) контракта ссылок от
2026-08-13. Задача здесь — не переиграть контракт, а проверить, что резолвер на пине
4.6.0-окна не изменился.

**Движок (48592b36):** `core/extensions/markdown/elements/link/render/logic/linkCreator.ts`
:

- `:117-119` — если у цели есть расширение, путь резолвится напрямую (форма **с** `.md`
работает);
- `:121-139` — если расширения нет, движок дважды примеряет расширение статьи (
`testHrefPath`, `testAbsoluteHrefPath`) — форма **без** `.md` работает;
- `:141-154` — отдельные попытки `<цель>/_index.md` (`CATEGORY_ROOT_FILENAME = "_index.md"`
, `app/config/const.ts:32`);
- `:156-162` — бессуффиксный существующий файл → файл-ссылка на скачивание (gh#675, та же
семантика, что в RES-006 находка 4);
- сериализатор редактора на пине:
`core/extensions/markdown/elements/link/edit/logic/getLinkFormatter.ts:25,40` — для не-GFM (
`isGFM = formatter.type === Syntax.github`) ссылка при сохранении пишется через
`resourcePath.stripExtension`, т.е. без `.md`;
- вендорский тест на пине
`core/extensions/markdown/elements/link/render/logic/linkCreator.unit.test.ts:150,160`
покрывает обе формы (`./article.md`, `./456/_index`).

**Вердикт: writer соответствует движку; reconciliation, не противоречие.** Резолвер на пине
принимает обе формы — расхождение «docs называет каноном форму с `.md`» существует только
на уровне документации, не поведения движка. Правило writer «без `.md`» (FR-080) остаётся:
оно соответствует и резолверу, и родной сериализации редактора для `syntax: XML`. Форма с
`.md` — валидный, но не канонический для XML-каталогов вид; обязательной миграции
существующих `.md` -ссылок нет (та же позиция, что в FR-080 контракта).

**Рекомендуемая правка writer (для dev-стадии):** содержательно правки правила нет.
Опционально — одна оговорка в разделе «Ссылки» SKILL.md: «форма с `.md` тоже резолвится
движком; в новых ссылках — без `.md` (родная форма сериализации редактора для XML/Legacy)» —
чтобы страница синтаксиса вендора не выглядела для агента опровержением правила.

## 3. Атрибуты `<view>`

**writer (4.6.0):** `defs` / `groupby` / `display="List"` (`SKILL.md:293-307`,
`references/blocks.md:64-102`); семантика `defs`: «фильтр по property; `none` означает „и
статьи без значения“»; `display` — «на сегодня поддерживается `List`».

**docs (RES-007 §4, строка «Семантика `defs` у `<view>`», + §3 строка «Элементы и поля
полного синтаксиса»):** атрибуты `display: List/Table/Kanban/Gantt` («пишите всегда, даже
для List»), `orderby`, `select`, `hierarchy=none`; семантика `defs`: «перечисляются
значения, которые нужно скрыть» (`status=done` убирает статьи со статусом `done`;
`свойство=none` скрывает статьи без свойства).

**Движок (48592b36):**

- Схема тега: `core/extensions/markdown/elements/view/render/models/view.ts:7-13` — атрибуты
ровно `defs, orderby, groupby, select, display`; белый список ключей —
`core/extensions/markdown/elements/view/render/logic/attributesFormatter.ts:3`; дефолт
`display: "List"` — `core/extensions/markdown/elements/view/edit/models/viewSchema.ts:12`.
- Формат значений: `attributesFormatter.ts:51-64` — `defs` / `orderby` / `groupby` парсятся
как объекты `id=v1&v2` (разделитель `&` внутри значения, `,` между записями), `select` —
массив.
- Семантика `defs` — фильтр сокрытия:
`core/extensions/properties/logic/ViewFilter.ts:90-105` (`_filterArticle`): статья
**исключается**, если у неё есть свойство с одним из перечисленных значений (`:94-95`);
`none` — остаются только статьи, у которых свойство **есть** (`:101`,
`return !!articleProp`); `yes` — остаются только статьи, у которых свойства **нет** (
`:100`).
- `display`: enum `core/extensions/properties/models/display.ts` — `List, Table, Kanban`;
компоненты — `core/extensions/markdown/elements/view/render/components/Displays/` (List.tsx,
Table.tsx, Kanban.tsx), маппинг
`[Display.List]: List, [Display.Kanban]: Kanban, [Display.Table]: Table` —
`core/extensions/properties/models/displays.ts:7-13`, вызов — `ViewRenderContent.tsx:35` (
`core/extensions/markdown/elements/view/render/components/ViewRenderContent.tsx`). **Gantt
в движке нет:** `grep -rin gantt` по `core/`, `app/`, `apps/` на пине — 0 совпадений (не
тесты, не node_modules).
- `orderby` — сортировка: `ViewFilter.ts:283-290` (`_normalizeOrderby`) + `ViewSorter`;
`select` — какие колонки свойств показывать: `ViewFilter.ts:107-114` (`_filterProps`).
- `hierarchy` — **не атрибут тега** `<view>`: это системное property, передаваемое внутри
`defs` — `core/extensions/properties/models/index.ts:5-8` (`SystemProperties.hierarchy`),
обработка `ViewFilter.ts:259-281` (`_handleSystemProperty`: значение `child-to-current`
ограничивает выборку потомками текущего раздела; любое другое значение — элементы текущего
раздела); пример употребления — конвертер Notion
`core/extensions/markdown/elements/view/notion/databaseView.ts:9` (
`defs: [{ id: "hierarchy", value: ["none"] }]`).

**Вердикт: обе стороны расходятся с движком — в разных местах.**

- Набор атрибутов и семантика `defs` — **docs соответствуют движку** (кроме двух пунктов):
перечисленные значения действительно скрываются, `none` действительно оставляет только
статьи со свойством. Формулировка writer («фильтр» = оставить перечисленное; `none` = «и
статьи без значения») описывает поведение с точностью до наоборот — по коду
`ViewFilter.ts:94-101` пример writer `<view defs="Тип контента=ADR&Архитектура&none"/>`
скрыл бы статьи с `ADR` / `Архитектура` и статьи вовсе без свойства.
- **docs расходятся с движком** в двух пунктах: `Gantt` в enum `Display` и компонентах
отсутствует (на пине); `hierarchy=none` — не атрибут тега, а запись системного property
внутри `defs`.
- writer дополнительно неполон: нет `orderby`, `select`; `display` сведён к `List`, тогда
как движок рендерит List/Table/Kanban.

**Рекомендуемая правка writer (для dev-стадии):** в `SKILL.md` и `references/blocks.md`
переформулировать `defs` по движку («перечисленные значения скрываются; `none` — оставить
только статьи со свойством; `yes` — только без него»); добавить `orderby` (формат
`свойство=v1&v2` или голое имя) и `select` (колонки свойств); `display` — `List` / `Table` /
`Kanban` (дефолт `List`; «Gantt» не указывать — в движке на пине отсутствует); `hierarchy`
указывать как запись `defs` (`defs="hierarchy=child-to-current"`), не как атрибут.

## 4. cmd/kbd — скобочные токены vs XML-теги

**writer (4.6.0):** только скобочные формы — `[cmd:Label]`, `[cmd:Label:Icon]`,
`[kbd:Keys]`, `[alfa]`, `[beta]` (`references/blocks.md:256-264`, `SKILL.md:309`).

**docs (RES-007 §4, строка «Скобочные токены vs теги»):** страницы элементов дают
`[cmd:Это кнопка]`, `[kbd:Ctrl+Z]`, `[color:#FF0000]…[/color]`; синтаксис-страница —
`<cmd text="…" icon="…" />`, `<kbd text="Ctrl+S" />`, `<alfa />`, `<beta />`,
`<color color="#D32F2F">…</color>`.

**Движок (48592b36):**

- XML-формы — схемы тегов: `core/extensions/markdown/elements/cmd/model/cmd.ts:3-10` —
атрибуты `text`, `icon`, `color`;
`core/extensions/markdown/elements/kbd/model/kbd.ts:3-8` — атрибут `text`;
`core/extensions/markdown/elements/alfaBeta/alfaBeta.ts:3-9` — `alfa`, `beta` без
атрибутов; регистрация — `getTagElementRenderModels.ts:104-105,110,112` (`alfa`, `beta`,
`cmd`, `kbd`), `:90` (`color`).
- Скобочные формы — общий препарсер:
`core/extensions/markdown/core/Parser/MdParser/MdParser.ts:251-263` (
`_squareBracketsParser`): содержимое `[...]` разбивается по `:`, первый сегмент — имя
тега, ищется в реестре тегов (том же, что выше: `Parser.ts:199,210` —
`core/extensions/markdown/core/Parser/Parser.ts` передаёт
`getTagElementRenderModels(context)` в `MdParser`); позиционные аргументы маппятся на
атрибуты схемы по порядку объявления (`MdParser.ts:315-324`, `_parse`) —
`[cmd:Label:Icon]` → `text="Label" icon="Icon"`; форма `[.name]` закрывает парный тег (
`MdParser.ts:258-261`), поэтому `[color:#FF0000]…[/color]` работает — схема `color` парная
(`selfClosing: false`, `core/extensions/markdown/elements/color/render/model/color.ts`).
- Дополнительно: legacy HTML-форма `<kbd>…</kbd>` тоже парсится — `MdParser.ts:79` (
`_kbdRegExp`), `:114`, `:245-249` (`_kbdParser`).

**Вердикт: движок поддерживает обе формы; writer неполон, XML-формы docs движку
соответствуют.** Скобочные токены writer — не legacy-мусор, а рабочий вход препарсера (тот
же механизм, что у `[include:…]` и `[color:…]`); XML-формы docs — родные схемы тегов,
причём у `<cmd>` есть атрибут `color`, не упомянутый ни в writer, ни в RES-007.

**Рекомендуемая правка writer (для dev-стадии):** дополнить `references/blocks.md`
XML-формами (`<cmd text="…" icon="…" color="…"/>`, `<kbd text="…"/>`, `<alfa/>`,
`<beta/>`) как канон для `syntax: XML`, сохранив скобочные как валидные (механизм
препарсера); в UI-токенах отметить парность `[color:…]…[/color]`; про legacy `<kbd>…</kbd>`
— короткая пометка «читается».

## 5. Изображения — width/height/scale, `<gallery>`

**writer (4.6.0):** markdown `![](./screenshot.png){width=800 height=450}` и XML
`<image src crop objects width height float>` (`SKILL.md:241-253`,
`references/blocks.md:208-222`). Семантики размеров writer не формулирует (RES-007 §4
трактует пример writer как «размер отображения»); `scale` в writer отсутствует; `<gallery>`
отсутствует.

**docs (RES-007 §4, строка «width/height/scale картинок», + §3):** `width` / `height` —
«реальный размер файла в пикселях» (резервирование места); ширина на странице — отдельный
`scale=476px`; плюс элемент `<gallery view="carousel">` (карусель/плитка, до 10 медиа).

**Движок (48592b36):**

- Схема `<image>`: `core/extensions/markdown/elements/image/render/image.ts:11-22` —
атрибуты `src, alt, title, crop, scale, objects, width, height, float, renderSrc`; парсинг
значений — `render/logic/imageTransformer.ts:10-40` (`scale` может быть `"…px"` или
числом).
- Markdown-форма `![](){width height}`: плагин токенизатора
`core/extensions/markdown/core/render/logic/Markdoc/src/tokenizer/plugins/imgSizePlugin.ts:6-15,21-31`
— `{…}` -аннотация после картинки разбирается в атрибуты `width` / `height`.
- Семантика размеров: `core/ui-logic/utils/getAdjustedSize.ts:9-17` — если `scale` задан в
`px`, ширина на странице = `min(scale, ширина колонки)`; если `scale` — число, это
**проценты** ширины колонки (
`core/extensions/markdown/elements/image/render/logic/getScale.ts:1-3`:
`scale/100 × maxWidth`); без `scale` ширина = `min(width, ширина колонки)` с сохранением
пропорций. `width` / `height` — intrinsic-размер:
`core/extensions/markdown/elements/image/render/components/ImageRenderer.tsx:168-176` (
`intrinsicSize` вычисляется из `width` / `height`, ожидаемых в px), `:178-183` (итоговый
размер на странице из `getAdjustedSize`), `:190-193` (`reservesLayout` — место
резервируется до загрузки картинки именно по `width` / `height`).
- `<gallery>`: **в движке на пине нет.** Поиск `gallery|carousel|swiper` по `core/` и
`app/` (без тестов и node_modules) — единственные совпадения не о контенте: имя
lucide-иконки кнопки `gallery-vertical` (
`core/extensions/markdown/elements/inlineImage/edit/components/InlineImageActions.tsx:9`) и
UI-контрол Slider настроек. Ближайший реальный контентный элемент — парная вставка картинок:
теги `img-h` / `img-v` с атрибутами `imageFirst` / `imageSecond` (
`core/extensions/markdown/elements/imgs/model/imgs.ts:5-19`, рендер — две картинки
рядом/столбиком); регистрация — `getTagElementRenderModels.ts:55-56` (`"img-h"`, `"img-v"`
).

**Вердикт: по семантике width/height/scale docs соответствуют движку, writer расходится
(умолчанием и трактовкой из RES-007); `<gallery>` в движке отсутствует — claim docs на пине
не подтверждается.** `width` / `height` в движке — реальные размеры файла (резерв места до
загрузки, ограничение шириной колонки), размер на странице управляется `scale` (`px` —
абсолютная ширина, число — проценты); `scale` writer не знает вовсе. Тег `<gallery>` не
найден поиском по всему дереву движка (поиск описан выше); вместо него — парный `img-h` /
`img-v`, не описанный ни writer, ни docs-выкачкой RES-007.

**Рекомендуемая правка writer (для dev-стадии):** в `SKILL.md` / `references/blocks.md`
добавить `scale` (в обе формы — markdown-аннотация и `<image scale="…">`) с семантикой
движка: `scale="476px"` — ширина на странице, `scale="50"` — проценты ширины колонки;
`width` / `height` описать как реальные размеры файла в px (резерв места до загрузки), не
как размер отображения; `<gallery>` не документировать, пока тег не появится в движке;
кандидат на отдельную строку справочника — `<img-h imageFirst imageSecond>` / `<img-v …>`.

## 6. Сводная таблица вердиктов и правок

| # | Пункт | Вердикт | Правка writer (dev-стадия) |
|---|---|---|---|
| 1 | Фрагменты | Движок поддерживает оба тега; канон — `fragment`/`.gramax/fragments/` (docs); `snippet`/`snippets/` writer — legacy, читается, мигрируется при правке | Канон → `<fragment>` + `.gramax/fragments/`; добавить `<fragment-link>`; `<snippet>` пометить legacy |
| 2 | Ссылки | writer соответствует движку; обе формы резолвятся на пине; примирение с FR-080: правило «без `.md`» остаётся | Без содержательной правки; опционально оговорка, что `.md`-форма тоже резолвится |
| 3 | `<view>` | Обе стороны расходятся: docs точнее (атрибуты, семантика `defs`), но ошибаются в Gantt (нет в движке) и `hierarchy` (не атрибут); writer перевирает семантику `defs`, не знает `orderby`/`select`/Table/Kanban | Переформулировать `defs` (скрытие, `none`/`yes`), добавить `orderby`/`select`, `display` = List/Table/Kanban, `hierarchy` через `defs` |
| 4 | cmd/kbd | Движок поддерживает обе формы; XML-формы docs соответствуют движку; writer неполон | Дополнить XML-формами (`<cmd text icon color>`, `<kbd text>`, `<alfa>`, `<beta>`), скобочные сохранить как валидные |
| 5 | Изображения | По семантике width/height/scale docs соответствуют движку; writer не знает `scale`; `<gallery>` в движке нет (парный аналог — `img-h`/`img-v`) | Добавить `scale` (px и %), переописать `width`/`height` как реальные размеры файла; `<gallery>` не документировать; кандидат — `img-h`/`img-v` |

## 7. Источники и уверенность

| Источник | Детали |
|---|---|
| Движок (primary) | `github.com/Gram-ax/gramax`, коммит `48592b36bb0b16ec6dca248fb76dd0d5a37526a5` (2026-10-06, «Changes from jul-2026 to sep-2026») — тот же пин, что в RES-006. Blobless-клон в `/tmp/gramax-engine-audit` (вне дерева проекта). Все `путь:строка` выше — относительно корня движка на этом пине |
| Уверенность: вердикты 1-4 | Высокая: прямое чтение схем/реестров/препарсера на пине; механизмы (реестр тегов, препарсер, провайдер фрагментов, фильтр view) прочитаны целиком, не по фрагментам |
| Уверенность: вердикт 5, `<gallery>` | «Не найден в движке» — поиск `gallery|carousel|swiper` (grep -rin) по `core/` и `app/` на пине без тестов; полнота ограничена: тег мог бы строиться динамическим именем — таких механизмов в реестрах тегов не обнаружено (`getTagElementRenderModels` — единственная точка регистрации контентных тегов) |
| Уверенность: исполнение | Ниже, чем в RES-004: probe-тест на живом резолвере/парсере не запускался — только чтение кода; для пункта 2 компенсируется тем, что RES-004 уже исполнял резолвер (на коммите 95d5d6d2) и вендорский тест обеих форм присутствует на пине |
| writer (primary) | `plugins/gramax/skills/writer/SKILL.md`, `plugins/gramax/skills/writer/references/blocks.md` (4.6.0) — прочитаны напрямую в этом репозитории; `references/doc-root-schema.md` — без расхождений по пяти пунктам, в аудит не вошёл |
| docs (secondary) | RES-007 (`2026-11-18-enterprise-server-skill-gap.md`) §3-4 — формулировки claims; сама выкачка gram.ax в этом заходе не повторялась |
| Смежное | RES-004 (`2026-08-13-link-forms-probe.md`) — исполняемый probe резолвера и сериализатора (коммит 95d5d6d2); контракт `2026-08-13-link-form-contract.md` (FR-080) — позиция по форме ссылки, не пересматривалась; RES-006 — пин окна движка и метод |

