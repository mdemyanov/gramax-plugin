---
title: "`_index.md` в корне каталога: исполняемый probe на движке Gramax"
order: 1
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---

# `_index.md` в корне каталога: исполняемый probe на движке Gramax

**Дата:** 2026-08-11
**Исследователь:** researcher-agent
**Запрос PM/BA:** превратить вывод «корневой `_index.md` инертен для движка Gramax» (сделанный чтением
кода в RES-003, «Подтема 6») в воспроизводимое доказательство — исполняемый тест на самом движке
и/или ссылку на официальную документацию вендора.
**Глубина:** standard (клонирование движка, сборка нативного модуля, запуск теста; точечная сверка
с документацией)

## TL;DR

Гипотеза RES-003 подтверждена **исполняемым тестом**, не только чтением кода. Собран минимальный
Jest-тест поверх `FileStructure` того же коммита движка (`95d5d6d2`), с фикстурой: корневой
`_index.md` с маркерным текстом + обычная статья в корне + подпапка со своим `_index.md` (контрольная
группа). Наблюдение раннера: `root.content === null` (маркер корневого `_index.md` в контент корневой
категории не попал), имя `_index` ни разу не встречается среди файлов статей — ни в корне, ни где-либо
в дереве, а маркер `_index.md` подпапки **читается** в `content` её категории. Значит: корневой
`_index.md` физически не мешает (ошибки нет), но и не становится содержимым/титульной страницей —
он инертен именно так, как показало чтение кода. Официальная документация gram.ax (5 целевых
страниц, включая построчное описание всех полей `.doc-root.yaml`) нигде явно не описывает поведение
корневого `_index.md` — установленное отсутствие документации, не пробел поиска.

## Что проверялось и как

### Task 1 — исполняемый probe

1. Клонирован `github.com/Gram-ax/gramax` (`git clone --depth 1`) во временный рабочий каталог —
   получен тот же коммит, что и в RES-003: `95d5d6d2bb6db285160f0c33c1f2fb9ecaedbfef`,
   2026-06-08, "Changes from apr-2026 to may-2026".
2. Найдена тестовая обвязка: `core/logic/FileStructue/FileStructure.unit.test.ts` — Jest,
   строит фикстуру каталогов **на диске** через `MountFileProvider.fromDefault(new Path(resolve(
   __dirname, "catalogs")))` и `fp.write(...)` в `beforeAll`, читает через `FileStructure`/`Catalog`
   напрямую (без HTTP/UI слоя), чистит через `fp.delete(Path.empty)` в `afterAll`. Раннер — `jest`
   (`jest.config.js`: preset `ts-jest`, `testMatch: **/*.test.ts`); собственный `scripts/testRunner.js`
   репозитория оборачивает `jest` и поднимает git-mock-сервер, но это не обязательно для
   `FileStructure`-тестов (флаг `--no-server`/`-n`). У теста нет фикстуры с `_index.md`
   непосредственно в корне каталога — это уже отмечено в RES-003 как пробел.
3. Собрана отдельная фикстура (новый файл-тест рядом с шипованным, не редактирующий его), с той же
   схемой (`MountFileProvider.fromDefault` + `fp.write` в `beforeAll`):
   - `probe-catalog/doc-root.yaml` — корневой маркер каталога (движок принимает и `doc-root.yaml`,
     и `.doc-root.yaml` — `app/config/const.ts:19-26`, `DOC_ROOT_FILENAMES`);
   - `probe-catalog/_index.md` — фронтматтер + маркерный текст `MARKER-ROOT-INDEX-CONTENT-1a2b3c`;
   - `probe-catalog/article.md` — обычная статья рядом;
   - `probe-catalog/subfolder/_index.md` — фронтматтер + маркерный текст
     `MARKER-SUBFOLDER-INDEX-CONTENT-4d5e6f` (контрольная группа: для подпапки чтение `_index.md`
     ожидается по коду);
   - `probe-catalog/subfolder/nested-article.md` — статья в подпапке.
4. Тест грузит каталог (`entry.load()`), читает `catalog.getRootCategory()`, `catalog.getItems()`,
   `catalog.getCategories()`, логирует JSON-наблюдение и ассертит гипотезу.
5. Запущен **только** этот тест-файл: `jest --testMatch "**/RootIndexProbe.probe.test.ts"`.

### Task 2 — точечная сверка с документацией вендора

Прочитаны напрямую (WebFetch) 5 целевых страниц `gram.ax/resources/docs` — не общий скан (тот уже
сделан в RES-003), а страницы, которые по смыслу ближе всего к теме: changelog «Что нового», «Создать
каталог», «Основные параметры» каталога, и главное — страница, целиком посвящённая `.doc-root.yaml`
(`catalog/settings/doc-root-yaml`), поле за полем. Отдельно перечитаны локально (без WebFetch, прямым
чтением файла) `README.md` движка и вся директория локализации (`core/extensions/localization/locale/
locale.ru.ts`) на предмет строк про корневую категорию/титульную страницу каталога.

## Результат probe: команды и наблюдаемый вывод

Установка зависимостей (bun, т.к. в репозитории `bun.lock`):

```
$ bun install
2162 packages installed [18.61s]
```

Первый запуск (до сборки нативного Rust-модуля) — **упал**, и упал одинаково что на шипованном
`FileStructure.unit.test.ts`, что на пробе — это среда, не дефект пробы:

```
$ DEBUG_JEST=1 NODE_ENV=test ./node_modules/.bin/jest --ci --runInBand \
    --testMatch "**/FileStructure.unit.test.ts"
...
Cannot find module './gramax-core.node' from 'apps/next/crates/next-gramax-core/index.ts'
Test Suites: 1 failed, 1 total
Tests:       19 failed, 19 total
```

`MountFileProvider` → `DiskFileProvider` → `DFPIntermediateCommands` → `rustcall` требует
скомпилированный нативный аддон (`crates/`, napi-rs). В окружении оказались `cargo`/`rustc`
(rustup, stable-aarch64-apple-darwin) и сеть до `crates.io`, поэтому вместо остановки на этом шаге
был выполнен сборочный шаг, документированный в `install-deps.sh` этого же репозитория:

```
$ npm --prefix apps/next/crates/next-gramax-core run build
> napi build --release --strip && mv index.node gramax-core.node
   Compiling <~180 крейтов, включая gramax-git/gramax-fs/gramax-core, libgit2-sys (vendored C), openssl-src>
    Finished `release` profile [optimized] target(s) in 2m 44s
```

Результат — `gramax-core.node`, 9 997 088 байт. После этого повторный запуск пробы:

```
$ DEBUG_JEST=1 NODE_ENV=test ./node_modules/.bin/jest --ci --runInBand \
    --testMatch "**/RootIndexProbe.probe.test.ts"

  console.log
    PROBE_OBSERVATION_JSON={
      "rootCategoryContent": null,
      "rootItemsFileNames": [
        "article",
        "nested-article",
        "subfolder"
      ],
      "rootIndexAppearsAsArticle": false,
      "subfolderCategoryContent": "MARKER-SUBFOLDER-INDEX-CONTENT-4d5e6f",
      "subfolderContentContainsMarker": true
    }

PASS core/logic/FileStructue/RootIndexProbe.probe.test.ts (7.094 s)
  PROBE: _index.md в корне каталога
    ✓ наблюдение (21 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

**Разбор наблюдения:**

- `rootCategoryContent: null` — корневая категория загружена с `content === null`, несмотря на то,
  что физический `probe-catalog/_index.md` с маркером `MARKER-ROOT-INDEX-CONTENT-1a2b3c` в фикстуре
  присутствует. Маркер нигде в наблюдении не появился — [established, воспроизведено исполнением].
- `rootIndexAppearsAsArticle: false`, `_index` отсутствует и в `rootItemsFileNames` — имя `_index` не
  встречается как имя статьи нигде в дереве каталога (список получен через `catalog.getItems([],
  root)`, который у этого движка рекурсивно обходит все категории — поэтому в списке кроме `article`
  оказались и `subfolder` (категория как элемент родителя), и `nested-article` (статья внутри
  подпапки); важен сам факт: `_index` как имя статьи не всплывает ни на одном уровне) —
  [established, воспроизведено исполнением].
- `subfolderCategoryContent`/`subfolderContentContainsMarker: true` — контрольная группа: `_index.md`
  подпапки **читается** в `content` её категории, маркер `MARKER-SUBFOLDER-INDEX-CONTENT-4d5e6f`
  найден целиком — [established, воспроизведено исполнением].

**Вывод probe:** гипотеза RES-003 **подтверждена исполнением**, не только чтением кода. Корневой
`_index.md` — физически безвреден (тест зелёный, ошибки при чтении каталога нет), но функционально
инертен: его содержимое не появляется ни в `content` корневой категории, ни как отдельная статья.
Поведение подпапки — контрастный контроль, показывающий, что механизм чтения `_index.md`
в принципе работает и целенаправленно не применяется к корню.

Тестовый файл-проба (`RootIndexProbe.probe.test.ts`) не является частью репозитория `gramax` и не
закоммичен ни в клон движка (артефакт временный, вне этого репозитория), ни тем более в этот
репозиторий — это одноразовый инструмент подтверждения, а не поставляемый тест.

## Результат сверки с документацией вендора

Прочитаны напрямую 5 страниц официальной документации и связанные исходники движка:

1. `gram.ax/resources/docs/whats-new` (changelog «Что нового», охват записей с ноября 2024 по
   июнь 2026 — весь видимый диапазон) — упоминаний корневой/титульной страницы каталога,
   `_index.md` в корне, того, что показывается при открытии каталога верхнего уровня, не найдено —
   [secondary, WebFetch].
2. `gram.ax/resources/docs/quick-start/create-catalog` («Создать каталог») — только шаги «Нажмите
   Создать новый → добавьте статьи → настройте внешний вид», без раскрытия структуры/начального
   содержимого — [secondary, WebFetch].
3. `gram.ax/resources/docs/catalog/settings/main-parameters` («Основные параметры») — упоминает
   `.doc-root.yaml` и то, что «если не заполнять [настройку расположения], папка со статьями
   добавится в корень папки репозитория» — это про параметр `docroot` (куда физически кладутся
   статьи), не про то, что делает `_index.md` в этом корне — [secondary, WebFetch].
4. `gram.ax/resources/docs/catalog/settings/doc-root-yaml` — страница целиком про `.doc-root.yaml`,
   построчно перечисляет все поля (`code`, `title`, `logo`, `order`, `description`, `style`,
   `relatedLinks`, `versions`, `properties`, `language`, `supportedLanguages`); ни `_index.md`, ни
   титульная/главная страница каталога в этом перечислении не упомянуты ни разу — это самая близкая
   по смыслу страница документации к вопросу, и именно на ней отсутствие зафиксировано отчётливее
   всего: `title`/`description`/`logo` каталога, по документации, задаются `.doc-root.yaml`, а не
   `_index.md` — [secondary, WebFetch, но high-relevance страница, не общий скан].
5. `README.md` движка (корень клонированного репозитория, прочитан напрямую, не через WebFetch) —
   строка `_index` не встречается — [primary].
6. `core/extensions/localization/locale/locale.ru.ts` (вся строка локализации UI, прочитана
   напрямую) — единственное близкое совпадение по смыслу: ключ `titlePage: "Титульная страница"`
   (`export.pdf.form.title.titlePage`, строка 2421) — но это настройка **PDF-экспорта**
   («Добавить титульную страницу с названием каталога/раздела и основной информацией» — генерируемая
   в момент экспорта, не связана с `_index.md`), не описание поведения корня каталога в редакторе —
   [primary, но не по теме после проверки контекста].
7. Сплошной `grep` по всему клонированному репозитону движка на использования
   `CATEGORY_ROOT_FILENAME`/`CATEGORY_ROOT_REGEXP` (14 файлов, не только `FileStructure.ts`) не
   содержит ни одного описательного комментария о специфике корневой категории — все использования
   чисто механические (построение путей, регэксп-фильтры) — [primary].

**Вывод сверки:** это установленное отсутствие документации, а не недостаток поиска. Официальная
документация описывает свойства каталога (`title`, `description`, `logo`, `order` — то, что видно
«на главной») через `.doc-root.yaml`, включая страницу, построчно перечисляющую каждое поле этого
файла, и ни разу не упоминает `_index.md` как источник содержимого корня. Формулировка вендора для
конечного пользователя вообще не оперирует именем файла `_index.md` — как отмечено уже в RES-003
(«Подтема 4»), в интерфейсе Gramax это скрытая деталь git-хранилища.

## Что не удалось выяснить

- **Визуальный рендер в работающем приложении** по-прежнему не проверен (см. RES-003, тот же
  пробел). Probe подтверждает поведение `FileStructure`/`Catalog` — слоя построения модели каталога;
  не исключён (хотя и маловероятен, учитывая, что UI обычно потребляет именно эту модель) отдельный
  путь в рендер-слое (`SitePresenter`, React), который читал бы корневой `_index.md` в обход
  `FileStructure`. Причина: нет доступа к запуску `app.gram.ax`/`editor.nau.im`/десктоп-приложения в
  этой среде.
- **Полнота документационного скана.** Проверено 5 целевых + ранее (RES-003) общий скан
  `gram.ax/resources/docs` — не все страницы портала документации прочитаны построчно (несколько
  сотен статей). Утверждение «вендор нигде явно не описывает» опирается на наиболее релевантные
  найденные страницы, а не на исчерпывающий обход всего портала.
- **Соответствие версии клона версии продукта.** Как и в RES-003: коммит `95d5d6d2` — `HEAD`
  публичного репозитория на момент клонирования, не обязательно то, что развёрнуто на
  `app.gram.ax`/`editor.nau.im` сегодня.

## Источники

- [primary] [github.com/Gram-ax/gramax](https://github.com/Gram-ax/gramax), коммит `95d5d6d2` —
  клонирован повторно, тот же коммит, что в RES-003; `core/logic/FileStructue/FileStructure.ts`,
  `core/logic/FileStructue/FileStructure.unit.test.ts`, `core/logic/FileStructue/Catalog/Catalog.ts`,
  `app/config/const.ts`, `jest.config.js`, `scripts/testRunner.js`, `install-deps.sh`, `README.md` —
  прочитаны напрямую; исполняемый Jest-тест — результат приведён построчно выше.
- [primary] `core/extensions/localization/locale/locale.ru.ts` — прочитан напрямую, полный текстовый
  поиск по ключевым словам.
- [secondary] [Что нового | Gramax Docs](https://gram.ax/resources/docs/whats-new) — WebFetch,
  охват записей ноябрь 2024 — июнь 2026.
- [secondary] [Создать каталог | Gramax Docs](https://gram.ax/resources/docs/quick-start/create-catalog)
  — WebFetch.
- [secondary] [Основные параметры | Gramax Docs](https://gram.ax/resources/docs/catalog/settings/main-parameters)
  — WebFetch.
- [secondary] [.doc-root.yaml | Gramax Docs](https://gram.ax/resources/docs/catalog/settings/doc-root-yaml)
  — WebFetch, наиболее релевантная страница вопросу.
- [primary] `content/10-domain/research/2026-08-11-index-md-at-catalog-root.md` (RES-003) — входной
  артефакт, чей вывод («Подтема 6», «Что НЕ удалось выяснить») этот probe закрывает частично
  (исполняемое подтверждение) и частично оставляет открытым (визуальный рендер).
