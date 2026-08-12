---
title: "Формы внутренней markdown-ссылки: что резолвит движок Gramax — исполняемый probe"
order: 5
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---

# Формы внутренней markdown-ссылки: что резолвит движок Gramax — исполняемый probe

**Дата:** 2026-08-13
**Исследователь:** researcher-agent
**Запрос PM/BA:** установить исполняемым тестом на движке Gramax, какие формы внутренней markdown-
ссылки движок реально резолвит — входные факты для BA-001 «форма ссылки на артефакт», вторично для
SA. Требований и правил не писать.
**Глубина:** standard (клонирование движка, исполняемый тест поверх реального резолвера; точечная
сверка с документацией вендора)

## TL;DR

Все 8 запрошенных форм проверены **исполняемым тестом** поверх реального, немодифицированного
`linkCreator.getLink()` — компонента-резолвера ссылок движка (не `FileStructure`). Резолвятся 7 из 8:
без расширения, с `./`, с `../`, с явным `.md`, на `_index`/`_index.md` секции — все резолвятся;
не резолвится только форма с префиксом имени каталога от уровня выше doc-root (`content/section/
doc.md`), она падает в буквальный fallback. Код-спан с путём — не ссылка, рендерится как
`<span><code>` без навигации (чтение кода, не исполнено в браузере). **Правило `SKILL.md:210`
(ссылка без `.md`) не противоречит движку — оно ему соответствует**: экзекьютед-пробой второго
уровня показал, что штатный сериализатор редактора Gramax (`getLinkFormatter.ts`) сам **срезает**
`.md` при сохранении для любого синтаксиса, кроме явного `GitHub Flavored Markdown` — а
`content/.doc-root.yaml` этого репозитория задаёт `syntax: XML`, то есть штатное поведение
редактора для ЭТОГО каталога — писать ссылки без расширения. Расходится с движком и с собственным
редактором Gramax именно офлайн-валидатор (и nauta C9, и наш `validate_structure.py`): оба требуют
буквального `.exists()` цели на диске без инференса `.md`/`_index.md`, поэтому корректная с точки
зрения движка ссылка `[X](doc)` получает у них error «битая ссылка».

## Таблица форм

| Форма | Резолвится движком | Как получен вывод | Достоверность |
|---|---|---|---|
| `[X](doc)` | Да | исполняемый тест | established |
| `[X](./doc)` | Да | исполняемый тест | established |
| `[X](doc.md)` | Да | исполняемый тест | established |
| `[X](./doc.md)` | Да | исполняемый тест | established |
| `[X](../section/doc.md)` | Да | исполняемый тест | established |
| `[X](section/_index)` | Да | исполняемый тест | established |
| `[X](section/_index.md)` | Да | исполняемый тест | established |
| `[X](content/section/doc.md)` (путь от уровня выше doc-root) | **Нет** — литеральный fallback, не навигируемый route | исполняемый тест | established |
| код-спан `` `content/foo.md` `` | Не ссылка — `<span class="inline-code"><code>` без `href`/навигации | чтение кода | established (не исполнено в браузере) |

Обе «резолвящиеся»/«не резолвящиеся» колонки относятся к слою `linkCreator`/`ParserContext`
(построение модели `href`/`resourcePath` при парсинге markdown в рендер-дерево). Видимое поведение
в реальном браузере (стили `<a>`, поведение при клике на нерезолвленную ссылку) прослежено ещё на
шаг дальше чтением кода (см. «Подтема 3»), но не воспроизведено в живом приложении — см. «Что не
удалось выяснить».

## Резолвер ссылок: какой компонент и какой коммит

Резолвер ссылок **не в `FileStructure`** — это отдельный класс-синглтон:

- `core/extensions/markdown/elements/link/render/logic/linkCreator.ts` (класс `LinkCreator`,
  экспортируется как `linkCreator`) — вызывается из
  `core/extensions/markdown/elements/link/render/model/link.ts:19` при трансформации Markdoc-тега
  `Link` в рендер-дерево. Метод `getLink(href, context)` — единственная точка входа.
- Коммит движка: `github.com/Gram-ax/gramax`, `95d5d6d2bb6db285160f0c33c1f2fb9ecaedbfef`,
  2026-06-08, «Changes from apr-2026 to may-2026» — тот же коммит, что и в предыдущем probe
  (`2026-08-11-index-md-root-probe.md`); клонирован заново, `HEAD` публичного репозитория не
  продвинулся с прошлого раза.
- `linkCreator.ts` — чистый логический модуль (только `Path`, `ApiUrlCreator`, типы), без
  зависимости от нативного Rust-модуля (`gramax-core.node`). Тест запускается без сборки
  `crates/` — в отличие от probe 2026-08-11, здесь сборка нативного аддона не понадобилась.

## Подтема 1 — метод и фикстура исполняемого теста форм ссылок

Использован тот же приём, что уже применяет собственный тест вендора
`linkCreator.unit.test.ts` (`describe("correctly resolves href path")`, коммит тот же): не
поднимать полноценный `FileStructure`/`Catalog` с диска, а вызывать реальный, немодифицированный
`linkCreator.getLink()` с рукописным объектом-контекстом (`getCatalog`/`getArticle`/`getBasePath`)
и рукописным фейковым `Catalog` (`findItemByItemPath`, `getPathname`, `getRootCategoryRef`,
`name`) — этот метод признан вендором в его собственном тестовом наборе, не изобретён для probe.

Фикстура топологии (файл-проба `LinkFormsProbe.probe.test.ts`, приложен ниже к репозиторию движка
не был — временный артефакт, как и в прошлом probe):

```
workspace-catalog/content/_index.md
workspace-catalog/content/article.md              <- источник ссылок для форм 1-4, 6-8
workspace-catalog/content/doc.md                  <- цель форм 1-4
workspace-catalog/content/section/_index.md       <- цель форм 6-7
workspace-catalog/content/section/doc.md          <- цель формы 5
workspace-catalog/content/origin/_index.md
workspace-catalog/content/origin/article-source.md <- источник для формы 5 (вложенный, для "../")
```

`workspace-catalog` — уровень выше `content` (doc-root), моделирует то, что в реальном репозитории
`content/.doc-root.yaml` — не верхний уровень репозитория, а подпапка внутри него (форма 8
`content/section/doc.md` целенаправленно проверяет именно это: что случится, если писатель повторит
имя doc-root-папки в тексте ссылки, думая, что путь считается от корня репозитория).

Команда запуска (без сборки нативного модуля, `bun install` — 9.46s):

```
$ DEBUG_JEST=1 NODE_ENV=test ./node_modules/.bin/jest --ci --runInBand \
    --testMatch "**/LinkFormsProbe.probe.test.ts"
```

Наблюдение (`console.log`, JSON на каждую форму) и итог прогона:

```
PROBE_LINK_FORM_JSON={"href":"doc","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/doc.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"./doc","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/doc.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"doc.md","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/doc.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"./doc.md","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/doc.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"../section/doc.md","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/section/doc.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"section/_index","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/section/_index.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"section/_index.md","resolved":true,"resultHref":"ROUTE:workspace-catalog/content/section/_index.md","isFile":false}
PROBE_LINK_FORM_JSON={"href":"content/section/doc.md","resolved":false,"resultHref":"content/section/doc.md","isFile":false}

Test Suites: 1 passed, 1 total
Tests:       16 passed, 16 total
```

(`"ROUTE:..."` — маркер, который вернула фейковая `getPathname` фикстуры, не реальный вид URL
Gramax; важен факт различения «резолвилось» vs «эхо буквального текста ссылки».)

Разбор форм 1 и 6 (без расширения) — по коду `_resolveHrefPath` (`linkCreator.ts:91-159`) не
находит совпадение с первой попытки (`testHrefPath`, путь относительно doc-root, не совпадает по
формату с полными путями элементов каталога), но находит его со второй (`testAbsoluteHrefPath`,
абсолютный путь от `FileProvider`-корня) — то есть расширение `.md` **инферится** движком двумя
проверочными попытками, а не одной; для форм с `_index` есть третья попытка
(`testIndexHrefPath`/`testAbsoluteIndexHrefPath`, добавляет `_index.md` как будто цель — папка), не
понадобившаяся в тесте, так как формы 6-7 уже указывали `_index` явно — [established, чтение кода
+ подтверждено исполнением].

Разбор формы 8: расширение `.md` присутствует → движок сразу пытается найти статью
`_buildArticleLink` по абсолютному пути `текущая_папка_статьи.join("content/section/doc.md")`,
что даёт `workspace-catalog/content/content/section/doc.md` (двойной `content`, так как соединение
— чисто файловое, относительно папки ТЕКУЩЕЙ статьи, не от корня репозитория и не от doc-root)
→ элемент не найден → `_getLinkByPath` возвращает `null` → `getLink` откатывается на
`_buildFallbackLink(path, hash)`, который возвращает `href`, буквально равный введённому тексту
ссылки — [established, подтверждено исполнением].

## Подтема 2 — код-спан с путём: не ссылка, чтение кода

`core/extensions/markdown/elements/code/render/model/code.ts` — схема Markdoc `Code` для inline-кода
(`` `текст` ``), трансформируется в тег `Code`, который рендерится компонентом
`core/extensions/markdown/elements/code/render/component/Code.tsx`:

```tsx
return (
  <Tooltip ...>
    <TooltipTrigger asChild>
      <span className="inline-code" onClick={onClickHandler} ...>
        <code>{children}</code>
      </span>
    </TooltipTrigger>
    ...
```

`onClickHandler` — копирование в буфер обмена (`tryCopyToClipboard`), не навигация; `<a>`/`href`
нигде не участвуют. Значит `` `content/foo.md` `` в прозе рендерится как некликабельный (в смысле
навигации) фрагмент кода с подсказкой «click to copy» — [established, чтение кода, не исполнено в
браузере — компонентный тест на реальном DOM не строился, см. «Что не удалось выяснить»].

## Подтема 3 — как реально выглядит нерезолвленная ссылка для читателя (чтение кода дальше по цепочке)

Проверка не останавливается на `linkCreator`: результат `getLink()` попадает в
`core/extensions/markdown/elements/link/render/model/link.ts:19-28` (тег `Link` с атрибутами
`href`, `isFile`, `resourcePath`) → компонент
`core/extensions/markdown/elements/link/render/components/Link.tsx:17-21` для `isFile === false`
рендерит `<Anchor href={null} {...otherProps} resourcePath={resourcePath} />`, но `otherProps`
(спред ПОСЛЕ `href={null}`) включает исходный `href` из тега — то есть реальный `href` (маршрут при
резолве или буквальный текст ссылки при fallback) всё-таки доходит до `Anchor` невредимым, потому
что перезаписывает `null`.

`core/components/controls/Anchor.tsx:33-53`: если `href != null` и не начинается с `#`/схемой/
`api` — оборачивается в кликабельный `<Link href={Url.from({pathname: href + hash})}>` **вне
зависимости от того, был ли href результатом успешного резолва или буквальным текстом из
fallback** — обе ветки `linkCreator` дают непустой `resourcePath`/`href`, и код в `Anchor` не имеет
сигнала «эта ссылка не резолвилась». Практическое следствие (если чтение кода верно): нерезолвленная
внутренняя ссылка выглядит и ведёт себя как обычная кликабельная ссылка вплоть до клика — узнать,
что она «битая», раньше клика (по вёрстке/цвету) неоткуда — [established по чтению кода трёх файлов
подряд, НЕ подтверждено в живом браузере/DOM — самое слабое звено этого probe, см. ниже].

## Подтема 4 — родное поведение редактора Gramax: он сам режет `.md` (кроме GFM)

Дополнительный целевой вопрос, не входивший в исходный список форм, но напрямую бьющий по вопросу
«кто прав — `SKILL.md:210` или валидаторы»: что пишет на диск **сам штатный редактор** Gramax, когда
пользователь создаёт внутреннюю ссылку через UI (или просто пересохраняет статью с уже
распарсенной, резолвленной ссылкой)?

`core/extensions/markdown/elements/link/edit/logic/getLinkFormatter.ts:37-41` (сериализатор
ProseMirror → markdown при сохранении):

```ts
const link: string =
  isFile || isUrl
    ? (resourcePath?.value ?? "")
    : ((isGFM ? resourcePath : resourcePath?.stripExtension) ?? mark.attrs.href) + (mark.attrs.hash ?? "");
```

`isGFM` берётся из `getFormatterTypeByContext(context)` →
`core/extensions/markdown/core/edit/logic/Formatter/Formatters/typeFormats/getFormatterType.ts:36-44`
— читает свойство статьи/каталога `syntax`; распознаёт `"GitHub Flavored Markdown"` и `"XML"`,
иначе — молчаливый fallback на `LegacyFormatter`. **Только** `GitHubFormatter` явно задаёт
`type: Syntax.github` (`GitHubFormatter.ts:12`) — у `XmlFormatter`/`LegacyFormatter` поле `type` не
задано вовсе, поэтому `isGFM = formatter.type === Syntax.github` ложно для обоих.

Исполняемый пробный тест (`LinkFormatterProbe.probe.test.ts`, вызывает тот же немодифицированный
`getLinkFormatter().close(...)`):

```
PROBE_FORMATTER_JSON={"syntax":"XML","closeToken":"](doc)"}
PROBE_FORMATTER_JSON={"syntax":"Legacy(default)","closeToken":"](./doc)"}
PROBE_FORMATTER_JSON={"syntax":"GitHub Flavored Markdown","closeToken":"](doc.md)"}

Tests: 3 passed, 3 total
```

`content/.doc-root.yaml` этого репозитория задаёт `syntax: XML` (не GFM) — значит для ЭТОГО
каталога штатный редактор Gramax при сохранении статьи с уже резолвленной внутренней ссылкой сам
пишет её **без** `.md` — то же самое поведение, что предписывает `SKILL.md:210`. Наблюдаемый корпус
каталога (77 ссылок, все с `.md`) этому родному поведению редактора не соответствует — что означает
(с осторожностью: это вывод, а не факт), что эти ссылки, вероятно, набраны вручную (человеком или
Claude), а не созданы/пересохранены через штатный picker-UI Gramax — [established, исполняемый тест
на сериализаторе; вывод про происхождение 77 ссылок — умозаключение, не факт, авторство файлов не
проверялось].

## Явный ответ: противоречит ли `SKILL.md:210` поведению валидаторов, и в чью пользу факт

Да, `SKILL.md:210` («Внутренние (без `.md`): `[Название](./другой-документ)`») формально
противоречит буквальному поведению **обоих** офлайн-валидаторов:

- `scripts/validate-content.py::check_broken_links` (nauta, C9, чужая территория —
  `_collect_references` → `check_broken_links`, строки 317-357): `resolved = (md_path.parent /
  target).resolve()`, ошибка, если `not resolved.exists()` — без инференса `.md`, без fallback на
  `_index.md`.
- `plugins/gramax/scripts/validate_structure.py::check_broken_links` (наш, FR-048): `resolved =
  (md.parent / target).resolve()`, тот же `.exists()`-контракт (строки 310, 340-344).

Ссылка `[X](doc)`, буквально написанная по правилу `SKILL.md:210`, **обязательно** получит error
«битая ссылка» у обоих валидаторов, потому что на диске нет файла `doc` (есть только `doc.md`) —
это не подозрение, это прямое следствие идентичного кода обоих чекеров, прочитанного напрямую.

**Факт — в пользу `SKILL.md:210`, не валидаторов.** Три независимых источника это подтверждают:
1. движок (`linkCreator.getLink`) резолвит `[X](doc)` — исполняемый тест, Подтема 1;
2. штатный редактор Gramax сам пишет ссылки без `.md` для не-GFM синтаксиса (наш каталог —
   `syntax: XML`) — исполняемый тест, Подтема 4;
3. официальная документация нигде не описывает `.md` как обязательную часть markdown-ссылки (см.
   ниже) — значит утверждение валидаторов «ссылка без `.md` = битая» не опирается на документированный
   контракт вендора, это самостоятельное (и в данном случае избыточно строгое относительно
   реального движка и реального редактора) допущение авторов офлайн-чекеров.

Из этого не следует вывод «валидаторы сломаны — почини их»: это территория SA/BA (изменение
контракта валидатора — решение, не факт). Установленный факт — расхождение и его направление.

## Что НЕ удалось выяснить

- **Визуальный рендер в живом приложении.** Как и в предыдущем probe (2026-08-11), нет доступа к
  запуску `app.gram.ax`/внутреннему инстансу редактора/десктоп-приложению в этой среде. Вывод Подтемы 3 («битая
  ссылка выглядит и ведёт себя как рабочая до клика») получен чтением кода трёх файлов подряд
  (`link.ts` → `Link.tsx` → `Anchor.tsx`) без верификации в реальном DOM/браузере — это самое слабое
  звено вывода и наиболее вероятное место, где рендер-слой мог бы вести себя иначе (например, если
  выше по дереву есть ещё один компонент-обёртка, добавляющий CSS-класс "битой" ссылки по какому-то
  другому сигналу, которого мы не нашли при чтении).
- **Происхождение 77 существующих ссылок корпуса.** Не проверено (не входило в объём этого probe),
  созданы ли они через штатный link-picker Gramax или напечатаны вручную — Подтема 4 даёт лишь
  косвенное умозаключение (наблюдаемая форма не совпадает с тем, что писал бы штатный редактор при
  `syntax: XML`), не прямое доказательство.
- **Кросс-каталожные ссылки — смежная находка, не проверена исполнением.** При чтении
  `linkCreator.ts` обнаружена логика `_getCatalogFromPath`/`getCatalogNameFromPath`, которая
  явно поддерживает резолв ссылок МЕЖДУ разными `.doc-root.yaml`-каталогами через
  `workspace.getBaseCatalog(catalogName)` (`linkCreator.ts:161-174`) — это на вид противоречит
  соседнему утверждению `SKILL.md:215` («Gramax не резолвит markdown-ссылки между разными
  `.doc-root.yaml`-каталогами»). Не входило в заказанный набор из 8 форм, отдельно не
  протестировано исполнением — фиксирую как смежный открытый вопрос, не как установленный факт.
- **Полнота документационного скана.** Проверены впрямую (WebFetch) 3 целевые страницы
  `gram.ax/resources/docs` в этом probe (`article`, `article/editor`, `article/editor/link-editor`)
  плюс 5 страниц из предыдущего probe (включая `.doc-root.yaml`) — не весь портал документации.
  Утверждение «вендор не описывает синтаксис ссылки построчно» опирается на наиболее релевантные
  найденные страницы (специально посвящённая ссылкам страница `link-editor` включительно), не на
  исчерпывающий обход всех статей портала.
- **Соответствие версии клона версии продукта в проде.** Коммит `95d5d6d2` — тот же, что и в
  прошлом probe (репозиторий не продвинулся); не обязательно то, что развёрнуто на
  `app.gram.ax`/внутреннем инстансе редактора сегодня.

## Рекомендации для BA/SA

- BA: факт установлен в пользу текущей формулировки `SKILL.md:210` (без `.md`) — она соответствует
  и движку, и штатному сериализатору редактора для синтаксиса каталога (`XML`/`Legacy`, не GFM).
  Решение, что делать с расхождением (менять правило, менять валидаторы, вводить обе формы как
  допустимые, помечать текущий корпус как технический долг) — вне зоны Researcher; это выбор BA/SA.
- BA: отдельно стоит вопрос, ЧТО считать «источником правды» для правила — поведение движка (более
  permissive: резолвит 7 форм из 8) или наблюдаемый корпус репозитория (77 ссылок с `.md`,
  фактически рабочих, потому что резолвятся тоже — форма 3/4 из таблицы). Обе формы работают у
  движка; вопрос конвенции (какую предпочесть) — решение BA, не факт.
- SA: если предполагается менять контракт валидатора (`validate_structure.py::check_broken_links`),
  учти обнаруженный механизм резолва — движок пробует расширение `.md` ДВУМЯ разными путями
  (относительно doc-root и абсолютно от `FileProvider`-корня) и ОТДЕЛЬНО пробует `_index.md` как
  вложенный файл директории; наивное «добавить `.md` и проверить `.exists()»` в валидаторе покроет
  бо́льшую часть случаев, но не воспроизводит 1:1 внутреннюю логику `_resolveHrefPath` (двойная
  попытка через доп. переменную `testAbsoluteHrefPath` актуальна только в многокаталожных
  сценариях, здесь не значима).
- SA: форма `content/section/doc.md` (путь как будто от корня репозитория) не резолвится вообще ни
  при каких условиях, которые мы проверили, — это чистый писательский антипаттерн, а не
  альтернативный валидный синтаксис; вероятно, стоит явно запретить его в правиле писателя (само
  правило — работа BA), а не полагаться на то, что валидатор его когда-нибудь поймает как ошибку
  (сегодня оба валидатора его действительно ловят, но по «случайному» совпадению — как и рабочую
  форму без `.md`, они одинаково требуют буквального `.exists()`, не различая «плохой путь» от
  «валидного пути без инференса расширения»).
- SA/BA: смежная находка про кросс-каталожные ссылки (Подтема выше, «Что не удалось выяснить») не
  проверена исполнением — при планировании работы над `SKILL.md:213-220` (кросс-каталожные ссылки)
  стоит завести отдельный research-заход, а не полагаться на нынешнюю формулировку без проверки.

## Источники

- [primary] [github.com/Gram-ax/gramax](https://github.com/Gram-ax/gramax), коммит `95d5d6d2` —
  клонирован повторно (тот же коммит, что в probe 2026-08-11). Прочитаны и исполнены напрямую:
  - `core/extensions/markdown/elements/link/render/logic/linkCreator.ts` (резолвер, полностью, 222
    строки) + существующий `linkCreator.unit.test.ts` (запущен как есть, 27/27 passed) — прецедент
    техники мокирования `Catalog`, использованный в этом probe.
  - `core/extensions/markdown/elements/link/render/model/link.ts`,
    `core/extensions/markdown/elements/link/render/components/Link.tsx`,
    `core/components/controls/Anchor.tsx` — цепочка «резолв → тег → React-компонент» (Подтема 3).
  - `core/extensions/markdown/elements/code/render/model/code.ts`,
    `core/extensions/markdown/elements/code/render/component/Code.tsx` — код-спан (Подтема 2).
  - `core/extensions/markdown/elements/link/edit/logic/getLinkFormatter.ts`,
    `core/extensions/markdown/core/edit/logic/Formatter/Formatters/typeFormats/getFormatterType.ts`,
    `.../typeFormats/model/Syntax.ts`, `.../typeFormats/GitHubFormatter.ts` — сериализация
    редактора (Подтема 4), плюс собственный исполняемый пробный тест
    (`LinkFormatterProbe.probe.test.ts`, 3/3 passed).
  - `core/logic/FileProvider/Path/Path.ts`, `core/logic/FileStructue/Catalog/Catalog.ts`,
    `core/logic/FileStructue/Catalog/CatalogItemSearcher.ts` — механика сравнения путей
    (`Path.compare`, `removeExtraSymbols`), использована для построения корректного фейкового
    `Catalog` в probe.
  - Исполняемые пробные тесты — `LinkFormsProbe.probe.test.ts` (16/16 passed, Подтема 1),
    `LinkFormatterProbe.probe.test.ts` (3/3 passed, Подтема 4) — оба временные артефакты, не
    закоммичены ни в клон движка, ни в этот репозиторий.
- [primary] `content/.doc-root.yaml` этого репозитория — `syntax: XML`, использовано как реальный
  вход для Подтемы 4.
- [primary] `plugins/gramax/skills/writer/SKILL.md:208-220`, `plugins/gramax/scripts/
  validate_structure.py:274-345` — прочитаны напрямую в этом репозитории.
- [primary] `scripts/validate-content.py:317-357` (nauta, чужая территория, только чтение) —
  `_collect_references`/`check_broken_links` (C9).
- [secondary] [Ссылки | Gramax Docs](https://gram.ax/resources/docs/article/editor/link-editor) —
  WebFetch; страница целиком посвящена ссылкам, описывает только UI-механику («выделить слово →
  иконка ссылки → выбрать статью»), синтаксис итогового markdown не приводит.
- [secondary] [Article | Gramax Docs](https://gram.ax/resources/docs/article) и [Article | Editor |
  Gramax Docs](https://gram.ax/resources/docs/article/editor) — WebFetch, использованы для навигации
  к целевой странице про ссылки, сами по себе markdown-синтаксиса ссылок не описывают.
- [primary] `content/10-domain/research/2026-08-11-index-md-root-probe.md` — входной прецедент по
  методу (клон движка, фикстура, исполняемый Jest-тест, точечная сверка с документацией); этот probe
  повторяет метод для другого компонента (резолвер ссылок вместо `FileStructure`) и на том же
  коммите движка.
