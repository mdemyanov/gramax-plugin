---
title: writer 4.7.0 — массовая синхронизация скилла с окном движка 48592b36 и документацией gram.ax
order: 24
status: draft
date: 2026-11-18
plugin: gramax
properties:
  - name: Тип контента
    value: [Требование]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# writer 4.7.0 — массовая синхронизация скилла с окном движка 48592b36 и документацией gram.ax

**Опоры:** `docs/40-architecture/2026-11-18-writer-sync-design.md`,
`docs/10-domain/research/2026-11-18-writer-docs-divergence-audit.md`,
`docs/10-domain/research/2026-11-18-enterprise-server-skill-gap.md`,
`plugins/gramax/skills/writer/SKILL.md`

**Контур И:** файл целиком уезжает в стор (Фаза 3) — собственной capability у него нет.

## Уезжает в стор (Фаза 3)

Каркас требования (все разделы ниже) целиком уезжает в стор в Фазе 3; собственной capability у
документа нет, поэтому пара дрейфа с openspec/ не объявляется.

## JTBD

Когда я создаю или редактирую статью Gramax-каталога и использую возможности, задокументированные в
документации gram.ax — вопрос-блоки и тесты, фрагменты, дашборды `<view>` с сортировкой и выбором
колонок, якоря заголовков, поисковые фразы, `aliases` при переносе, — я (автор статьи, человек или
агент) хочу, чтобы навык `writer` нёс полный набор элементов с семантикой, подтверждённой исходником
движка, — чтобы не собирать синтаксис по кусочкам из вендорской документации и памяти, не
воспроизводить формы, которых в движке нет, и не писать статьи, падающие при рендере или
расходящиеся с родной сериализацией редактора.

**Story 2 — сопровождающий каталога.** Когда я настраиваю каталог (`.doc-root.yaml`) и сопровождаю
его служебные зоны, я хочу, чтобы `writer` описывал полную схему конфигурации (логотипы, версии,
кнопки действия, LFS, мультиязычность, типы свойств по именам движка) и однозначно называл зоны «не
трогать» (`.gramax/inbox/`, `.gramax/mr/`, собранный текст `template:`-статей), — чтобы агент не
нанёс ущерба служебному состоянию каталога и не изобретал ключи конфигурации сам.

## Описание

`writer` 4.6.0 был синхронизирован с окном движка jul→sep 2026 точечно — три добавления (см. запись
4.6.0 в `plugins/gramax/CHANGELOG.md` как прецедент scope и формулировок). Сплошной аудит покрытия
(RES-007) показал, что за пределами этих точечных правок навык покрывает заметно меньше половины
задокументированной поверхности продукта: строки «частично» §2 RES-007 — это бэклог К1a (каждая
строка называет, чего именно в writer нет), строка «Элементы и свойства полного синтаксиса вне
writer» §3 — бэклог К1b (перечень отсутствующих элементов). Параллельный аудит пяти расхождений
writer ↔ docs (RES-008) проверил спорные пункты по исходнику движка на пине `48592b36` с
`путь:строка`-доказательствами; его вердикты — ground truth и переигрывают и текущий текст writer, и
docs там, где две стороны расходятся.

Четыре переигрывания существенны для содержания этого требования. (1) Фрагменты: движок поддерживает
оба тега, канон — `<fragment>` + `.gramax/fragments/`, форма `<snippet>` writer — помеченный в коде
legacy-путь с автомиграцией при первой правке. (2) Ссылки: обе формы (с `.md` и без) резолвятся на
пине — правило writer «без `.md`» (FR-080 [контракта формы ссылки](2026-08-13-link-form-contract))
остаётся, примирение, не противоречие. (3) `<view>`: семантика `defs` в writer описана с точностью
до наоборот (фильтр сокрытия, не отбора); docs точнее в наборе атрибутов, но ошибаются в `Gantt` (в
движке нет) и `hierarchy` (не атрибут, а запись системного свойства в `defs`). (4) Изображения:
`width`/`height` — реальные размеры файла (резерв места), ширина на странице — отдельный `scale`;
`<gallery>` в движке на пине не найден — не документируется.

Это требование — массовая догоняющая синхронизация writer 4.7.0: кластер A закрывает К1a+К1b на
уровне элементов статьи и вносит пять аудиторных правок RES-008; кластер B — уровень каталога (схема
`.doc-root.yaml`, служебные пути, мультиязычность, типы свойств, иконки); кластер C — guardrails
против порчи служебного состояния. Границы с параллельными требованиями сегодняшнего среза:
офлайн-проверки новых поверхностей — зона [требования паритета
валидаторов](2026-11-18-validators-error-check-parity-requirement) (writer отвечает за документацию,
валидатор — за проверку); авторство PlantUML/BPMN-диаграмм — отдельное требование;
inline-диаграммные блоки в этот срез не входят.

## Факты

Все факты — из RES-007 (`../10-domain/research/2026-11-18-enterprise-server-skill-gap`) и RES-008
(`../10-domain/research/2026-11-18-writer-docs-divergence-audit`); переизмерений нет. Вердикты
RES-008 доказаны чтением кода движка на пине `48592b36` (`путь:строка` в §1–§5 аудита).

| # | Пробел или расхождение | Источник |
|---|---|---|
| 1 | Вопрос-блоки `<question>`/`<questionAnswer>` (12 типов, `showIf`) и frontmatter `quiz` в writer не упоминаются ни в SKILL.md, ни в references | RES-007 §2 «Пространство → Обучение», §3 «Модуль обучения» |
| 2 | Frontmatter-ключи `searchPhrases` и `aliases` в writer отсутствуют; `aliases` движок пишет при переносе/переименовании | RES-007 §2 «Поисковые фразы», §2 «URL», §4 «Frontmatter статьи» |
| 3 | Элементы `<cut>`, `<property/>`, `<inline-property/>`, якоря `{#…}` — в writer нет | RES-007 §3 «Элементы и поля полного синтаксиса вне writer» |
| 4 | `<view>`: writer знает только `defs`/`groupby`/`display="List"`, семантика `defs` перевёрнута; движок — атрибуты ровно `defs, orderby, groupby, select, display`, `display` = List/Table/Kanban, Gantt отсутствует, `hierarchy` — через `defs` | RES-008 §3 (вердикт 3) |
| 5 | cmd/kbd: writer знает только скобочные формы; движок поддерживает обе, у `<cmd>` есть атрибут `color` | RES-008 §4 (вердикт 4) |
| 6 | Изображения: `scale` writer не знает; `width`/`height` — intrinsic-размер файла; `<gallery>` в движке отсутствует; парные `<img-h>`/`<img-v>` существуют | RES-008 §5 (вердикт 5) |
| 7 | Фрагменты: канон движка — `<fragment>` + `.gramax/fragments/` + `<fragment-link>`; `snippet`/`snippets/` — legacy с автомиграцией при правке | RES-008 §1 (вердикт 1) |
| 8 | Ссылки: обе формы резолвятся на пине; правило «без `.md`» остаётся (примирение с FR-080) | RES-008 §2 (вердикт 2) |
| 9 | Видео: docs добавляют Dropbox, Mega и атрибуты `title`, `scale`, `cover` сверх набора writer | RES-007 §2 «Видео», §4 «Список видео-хостингов и атрибуты» |
| 10 | OpenAPI: `showSchemas`, `showInfo`, формат JSON — в writer нет | RES-007 §2 «Описание API (OpenAPI)» |
| 11 | Выделенного раздела о блоках кода в writer нет; docs: полные имена языков highlight.js, обёртка в четыре кавычки | RES-007 §2 «Блок кода», §3 |
| 12 | Ключи `.doc-root.yaml` вне writer: `logo`/`logo_dark` (формы `icon:<код>`, `emoji:<символ>`), `versions`, `relatedLinks`, `lfs` (`auto`, `exclude`), `hidden`, `filterProperty` (одиночный id); палитра `style` — 20 значений с двухцветными (writer: 11); `syntax` — `XML`, `Legacy`, `GitHub Flavored Markdown` (writer: `XML`, `Markdown`) | RES-007 §2 «`.doc-root.yaml`», «Основные параметры», «Кнопки действия», «Версионирование», «Хранилище»; §4 «Схема `.doc-root.yaml`» |
| 13 | Свойства: имена типов по движку — `Flag`, `Enum`, `Many`, `Text`, `Numeric`, `Date` + `options.docportalVisible`; значение в frontmatter по `id`; свойство нельзя переименовать; writer описывает `Enum`/`String` | RES-007 §2 «Свойства», §4 «Типы свойств» |
| 14 | Мультиязычность: структура папки языка один-в-один, `order`/`properties` перевода совпадают с оригиналом, файл без `title` — непереведён, разделы не называют кодами языков | RES-007 §2 «Мультиязычность» |
| 15 | Представления каталога хранятся в `.gramax/views`; заметки — `.gramax/inbox`, состояние ревью — `.gramax/mr` (обе папки «не редактировать»); LFS — `.gitattributes` рядом с `.doc-root.yaml` | RES-007 §2 «Представление каталога», «История каталога, Заметки», «Хранилище»; §3 |
| 16 | Шаблоны: файлы `.gramax/templates/<id>.md`; статья с frontmatter `template: <id>` текста в файле не хранит; агентам запрещено править такой текст, менять можно только `properties` | RES-007 §2 «Шаблоны», §3 «Шаблоны и поисковые фразы», §4 «Официальные скиллы из docs» |
| 17 | Собственные SVG-иконки: папка `.icons/` рядом с `.doc-root.yaml`, `.icons/<code>.svg` | RES-007 §2 «Иконки», §3 |
| 18 | Граница аудита: `doc-root-schema.md` против движка на пине не проверялся (в аудит RES-008 не вошёл) — engine-вердиктов по ключам каталога нет | RES-008 §7 |
| 19 | Вендор-чеклист «Что агенту не трогать»: `<comment id>`, `*.comments.yaml`, `.gramax/mr`, `.gramax/inbox`, текст `template:`-статей, указатели Git LFS | RES-007 §4 «Официальные скиллы из docs» |

## Scope

### In scope

- Кластер A — элементы статьи: frontmatter `searchPhrases`, `aliases`; вопрос-блоки и `quiz` (новый
  `references/quizzes.md`); `<cut>`, `<property/>`, `<inline-property/>`; переписанный раздел `<view>`
  по вердикту 3; XML-формы cmd/kbd с `color`; изображения (`scale`, семантика `width`/`height`, без
  `<gallery>`); видео (Dropbox, Mega, `title`/`scale`/`cover`); OpenAPI (`showSchemas`/`showInfo`,
  JSON); выделенный раздел блоков кода; якоря заголовков; фрагменты по вердикту 1; оговорка о
  `.md`-форме ссылок.
- Кластер B — уровень каталога: отсутствующие ключи `.doc-root.yaml`; палитра и enum `syntax` по
  таблице docs; `.gramax/views`; `.gitattributes`/LFS; правила мультиязычности; типы свойств по именам
  движка; собственные иконки `.icons/` (документация механизма).
- Кластер C — guardrails `SKILL.md`: запрет правки собранного текста `template:`-статей; запрет
  трогать `.gramax/inbox/` и `.gramax/mr/`.
- Синхронизация машиночитаемого контракта тегов плагина с новыми тегами (NFR-072) — одним изменением
  с правками writer.

### Out of scope

- `<gallery>` и `display="Gantt"` — не документируются как возможности writer 4.7.0: в движке на
  пине `48592b36` отсутствуют (RES-008 §3, §5); правило — BR-016, негативный контроль — AC-078.
- Inline-диаграммные блоки и `<plant-uml>`/`<bpmn>`: авторство — требование PlantUML/BPMN,
  офлайн-проверка целей — [требование паритета
  валидаторов](2026-11-18-validators-error-check-parity-requirement); writer их не переизлагает.
- Серверная сторона обучения: панель GES, PostgreSQL, результаты прохождения, рассылка (RES-007 §3
  «Модуль обучения» — «результаты только серверные») — writer документирует только авторский
  синтаксис.
- Лимит видео 500MB и конвертация в MP4 — поведение приложения, не исходный синтаксис (RES-007 §2
  «Видео»).
- Форма видео «любая ссылка со словом embed» (RES-007 §4) — формулировка docs расплывчата для
  hard-правила; не включена в FR-168 (открытый вопрос 4).
- Frontmatter-поля статьи `description`, `hidden`, `expanded` (`_index.md`), `orderAsc`, служебные
  `welcome`/`external`/`shouldBeCreated` — названы в RES-007 §4, но в срез не входят; кандидат
  следующего цикла. (Ключ `hidden` в FR-174 — ключ `.doc-root.yaml`, не поле статьи.)
- Миграция существующих `.md`-ссылок — не вводится (RES-008 §2); массовая превентивная миграция
  `<snippet>` → `<fragment>` у потребителей — открытый вопрос 5.
- Детали синтаксиса вне перечня среза (тире `--`, перенос `\` в конце строки, экранирование `\$`,
  HTML-компонент изнутри, встроенный просмотр DOCX/PDF, типографика редактора) — RES-007 §3, вне брифа
  среза.

## Функциональные требования

### A. Элементы статьи (SKILL.md, references/blocks.md, references/quizzes.md)

- **FR-161:** writer обязан документировать frontmatter-ключ `searchPhrases` статьи: список
  поисковых фраз; эффект — подъём статьи в поиске по тексту, регистр не важен, срабатывание по части
  слова. Место по умолчанию — секция Frontmatter `SKILL.md` (точное — SA/Dev). Источник: RES-007 §2,
  строка «Поисковые фразы»; §3, строка «Шаблоны и поисковые фразы».
- **FR-162:** writer обязан документировать frontmatter-ключ `aliases` — список старых путей без
  `.md` относительно корня контента: при переносе/переименовании статьи через UI движок записывает
  старый путь сам; при ручном переименовании агент добавляет его сам. Правило вписывается в разделы
  «Переместить статью»/«Переместить раздел» `references/structure.md`. Источник: RES-007 §2, строка
  «URL».
- **FR-163:** writer обязан получить выделенный справочник `references/quizzes.md` для
  вопрос-блоков: тег `<question>` (атрибуты `id`, `type`, `required`) и `<questionAnswer>` (атрибуты
  `answerId`, `correct`; camelCase-имена тегов обязательны); 12 типов `one`, `many`, `select`, `text`,
  `date`, `user`, `number`, `slider`, `scale`, `rating`, `ranking`, `matrix`; условие показа `showIf`
  (список `answerId`); frontmatter-ключ `quiz` статьи: `mode` (`test` или `survey`), `showAnswers`,
  `canRetake`, `shuffleQuestions`, `countOfCorrectAnswers`. Результаты прохождения — вне справочника
  (серверная сторона, Out of scope). Источник: RES-007 §2, строка «Пространство → Обучение»; §3,
  строка «Модуль обучения».
- **FR-164:** `references/blocks.md` обязан пополниться элементами: `<cut>` (инлайн-скрытый
  фрагмент, атрибуты `text`, `expanded`); `<property/>` с атрибутами `id`, `value` (привязка
  вкладок/контента к свойству каталога — в т.ч. механизм подстановки версии); `<inline-property/>` с
  атрибутом `bind` (значение свойства в тексте статьи). Источник: RES-007 §3, строка «Элементы и поля
  полного синтаксиса вне writer»; §3, строка «Версионирование и представления каталога».
- **FR-165:** раздел `<view>` (`SKILL.md` + `references/blocks.md`) обязан быть переписан по
  вердикту 3 RES-008: (а) семантика `defs` — сокрытие: перечисленные значения исключают статьи из
  выборки; `none` — остаются только статьи, у которых свойство есть; `yes` — только статьи без него;
  (б) атрибут `orderby` — сортировка (формат `свойство=v1&v2` или голое имя свойства); (в) атрибут
  `select` — перечень показываемых колонок свойств; (г) `display` — `List`, `Table`, `Kanban`, дефолт
  `List`; (д) иерархическая выборка — записью системного свойства в `defs` (форма
  `defs="hierarchy=child-to-current"`), не атрибутом тега. Текущая формулировка writer (`defs` как
  фильтр отбора, `none` как «и статьи без значения») заменяется как противоречащая движку. Источник:
  RES-008 §3, вердикт 3.
- **FR-166:** `references/blocks.md` обязан документировать XML-формы UI-токенов как канон для
  `syntax: XML`: `<cmd text="…" icon="…" color="…"/>` (атрибут `color` — новое знание, не упомянутое
  ни writer 4.6.0, ни RES-007), `<kbd text="…"/>`, `<alfa/>`, `<beta/>`. Скобочные формы
  (`[cmd:Label]`, `[cmd:Label:Icon]`, `[kbd:Keys]`, `[alfa]`, `[beta]`) сохраняются как валидные
  (механизм препарсера, позиционные аргументы маппятся на атрибуты по порядку); парность
  `[color:…]…[/color]` отмечается; legacy HTML-форма `<kbd>текст</kbd>` — короткая пометка «читается
  движком». Источник: RES-008 §4, вердикт 4.
- **FR-167:** раздел изображений (`SKILL.md` + `references/blocks.md`) обязан быть приведён к
  вердикту 5 RES-008: атрибут `scale` документируется в обеих формах (markdown-аннотация и `<image …/>`):
  значение в px — ширина на странице (не больше ширины колонки), число — проценты ширины колонки;
  `width`/`height` описываются как реальные размеры файла в px (резерв места до загрузки, ограничение
  шириной колонки), не как «размер отображения». `<gallery>` не документируется (BR-016). Кандидат
  отдельной строки справочника — парные теги `<img-h>`/`<img-v>` (атрибуты `imageFirst`/`imageSecond`,
  две картинки рядом/столбиком) — решение SA (открытый вопрос 2). Источник: RES-008 §5, вердикт 5.
- **FR-168:** раздел «Видео» (`references/blocks.md` и строка таблицы блоков `SKILL.md`) обязан
  пополниться: хостинги Dropbox и Mega (к существующим mp4/webm/ogg, YouTube, Rutube, Google Drive,
  Instagram); атрибуты `title`, `scale`, `cover`. Источник: RES-007 §2, строка «Видео»; §4, строка
  «Список видео-хостингов и атрибуты».
- **FR-169:** раздел OpenAPI (`references/blocks.md`) обязан пополниться атрибутами `showSchemas` и
  `showInfo` тега `<openapi/>` и явным указанием, что формат спецификации — YAML или JSON. Источник:
  RES-007 §2, строка «Описание API (OpenAPI)».
- **FR-170:** `references/blocks.md` обязан получить выделенный раздел «Блок кода»: блок и строка,
  подсветка по языку; в код-блоках — полные имена языков highlight.js; когда содержимое содержит
  тройные кавычки — обёртка в четыре. Источник: RES-007 §2, строка «Блок кода»; §3, строка «Элементы и
  поля полного синтаксиса вне writer».
- **FR-171:** writer обязан документировать якоря заголовков — суффикс `{#имя}` на заголовке любого
  уровня — и ссылку на якорь из текста статьи. Источник: RES-007 §3, строка «Элементы и поля полного
  синтаксиса вне writer»; §2, строка «Ссылки».
- **FR-172:** раздел фрагментов переписывается по вердикту 1 RES-008: канон — `<fragment id="…"/>` +
  каталог `.gramax/fragments/`; ссылка на фрагмент — `<fragment-link id>текст</fragment-link>`; форма
  `<snippet id="…"/>` / `.gramax/snippets/` сохраняется с пометкой «legacy: движок читает, при первой
  правке мигрирует в `fragments/`»; staging-чеклист `SKILL.md` («НЕ удалять `.gramax/` (содержит
  сниппеты)») уточняется до «фрагменты/сниппеты». Источник: RES-008 §1, вердикт 1.
- **FR-173:** правило внутренних ссылок без `.md` (FR-080 [контракта формы
  ссылки](2026-08-13-link-form-contract)) остаётся без изменения; раздел «Ссылки» `SKILL.md`
  дополняется оговоркой: форма с `.md` тоже резолвится движком (и офлайн-валидатором) — валидный, но
  не канонический для XML/Legacy-каталогов вид. Обязательная миграция существующих `.md`-ссылок не
  вводится. Источник: RES-008 §2, вердикт 2.

### B. Уровень каталога (references/doc-root-schema.md, references/structure.md)

- **FR-174:** `references/doc-root-schema.md` обязан пополниться ключами, отсутствующими в
  справочнике: `logo` и `logo_dark` (формы `icon:<код>` и `emoji:<символ>`); `versions` (шаблоны
  веток/тегов, glob-паттерны); `relatedLinks` (кнопки действия каталога); `lfs` с полями `auto` и
  `exclude`; `hidden`. Источник: RES-007 §2 (строки «Основные параметры», «`.doc-root.yaml`», «Кнопки
  действия», «Версионирование», «Хранилище»); §4, строка «Схема `.doc-root.yaml`».
- **FR-175:** справочник обязан синхронизироваться с полной таблицей ключей docs в трёх
  расхождениях, с явной пометкой источника каждого значения: (а) `syntax` — enum `XML`, `Legacy`,
  `GitHub Flavored Markdown` (writer сегодня перечисляет `XML`/`Markdown`; существование GFM в движке
  косвенно подтверждено RES-008 §2 — `Syntax.github` в сериализаторе ссылок); (б) палитра `style`
  расширяется до 20 значений docs, включая двухцветные (`blue-pink`, `orange-red`, …), с пометкой,
  какие значения подтверждены writer-практикой сегодня; (в) ключ `filterProperty` (одиночный id) из
  таблицы docs документируется рядом с `filterProperties` (список имён) с явной пометкой расхождения
  до engine-вердикта (открытый вопрос 1). Молчаливая замена значений writer на значения docs без
  пометки запрещена — engine-аудита doc-root-уровня нет (факт 18). Источник: RES-007 §4, строки «Схема
  `.doc-root.yaml`» и «Формы ссылок на статьи» (контекст GFM); RES-008 §2, §7.
- **FR-176:** writer обязан документировать хранилище представлений каталога: именованные фильтры,
  переменные и группировка навигации хранятся в каталоге по пути `.gramax/views`; агент не изобретает
  собственное место хранения и не удаляет папку. Источник: RES-007 §2, строка «Представление
  каталога»; §3, строка «Версионирование и представления каталога».
- **FR-177:** writer обязан документировать файловые следы Git LFS: `.gitattributes` рядом с
  `.doc-root.yaml` определяет отслеживаемые файлы; ключ `lfs` конфигурации (перекрёстная ссылка на
  FR-174); указатели LFS входят в перечень «что агенту не трогать». Источник: RES-007 §2, строка
  «Хранилище»; §3, строка «Хранилище»; §4, строка «Официальные скиллы из docs».
- **FR-178:** writer обязан документировать правила мультиязычности: структура папки языка повторяет
  основную один-в-один; `order` и `properties` файла перевода совпадают с оригиналом; файл перевода
  без `title` считается непереведённым; разделы (папки структуры) нельзя называть кодами языков.
  Размещение по умолчанию — раздел «Мультиязычность» в `references/doc-root-schema.md`; перенос в
  `references/structure.md` — решение SA. Источник: RES-007 §2, строка «Мультиязычность».
- **FR-179:** справочник property-типов обязан быть приведён к исходным именам движка по таблице
  docs: `Flag`, `Enum`, `Many`, `Text`, `Numeric`, `Date`, плюс опция `options.docportalVisible: true`;
  значения в frontmatter пишутся по `id` (Flag — только id, Date — ISO 8601); ограничение «свойство
  нельзя переименовать» включается в справочник. Расхождение с текущим изложением writer
  (`Enum`/`String`, `name`-нотация frontmatter) фиксируется явно как расхождение с пометкой
  «engine-вердикта нет» (факт 18) — не переписывается молча; разрешение — открытый вопрос 1. Источник:
  RES-007 §2, строка «Свойства»; §4, строка «Типы свойств (исходные имена)».
- **FR-180:** writer обязан документировать собственные SVG-иконки: папка `.icons/` рядом с
  `.doc-root.yaml`, файл на код — `.icons/<код>.svg`; коды `<icon code="…"/>` без префикса `lucide-`
  резолвятся против неё. Граница: офлайн-проверку существования файлов иконок вводит [требование
  паритета валидаторов](2026-11-18-validators-error-check-parity-requirement) (там FR-153–FR-155) —
  writer отвечает за документацию механизма, не за проверку. Источник: RES-007 §2, строка «Иконки»;
  §3, строка «Элементы и поля полного синтаксиса вне writer».

### C. Guardrails (SKILL.md — hard rules)

- **FR-181:** в `SKILL.md` обязан появиться hard rule: никогда не править собранный текст статьи,
  чей frontmatter содержит `template: <id>` — тело такой статьи хранится в
  `.gramax/templates/<id>.md`, файл статьи собственного текста не содержит; правка допустима только в
  frontmatter-блоке `properties`. Механизм шаблонов (расположение файлов) описывается рядом с
  правилом. Источник: RES-007 §2, строка «Шаблоны»; §3, строка «Шаблоны и поисковые фразы»; §4, строка
  «Официальные скиллы из docs».
- **FR-182:** в `SKILL.md` (Guardrails + staging-чеклист) обязаны появиться hard rules: не
  создавать, не редактировать и не удалять служебные папки `.gramax/inbox/` (личные заметки
  пользователей) и `.gramax/mr/` (состояние ревью и согласования) — обе помечены вендорской
  документацией как «не редактировать». Источник: RES-007 §2, строка «История каталога, Заметки»; §4,
  строка «Официальные скиллы из docs».

## Нефункциональные требования

- **NFR-070 (навигационная дисциплина):** объёмные темы уходят в `references/` (новый `quizzes.md`,
  пополнение `blocks.md` и `doc-root-schema.md`); `SKILL.md` остаётся короткой навигацией плюс hard
  rules — прецедент NFR-001 [требования writer-consumer-rules](2026-08-11-writer-consumer-rules). Поле
  `description` фронтматтера `SKILL.md` не растёт пропорционально числу тем — только если меняется
  триггер выбора навыка целиком.
- **NFR-071 (аддитивность, non-breaking):** синхронизация не переобъявляет валидное невалидным и не
  отменяет действующие правила: скобочные формы UI-токенов остаются валидными (FR-166); правило ссылок
  FR-080 сохраняется (FR-173); `<snippet>` помечается legacy, не удаляется (FR-172); существующие
  каталоги потребителей продолжают рендериться. Semver-категория релиза (ожидаемо Minor — прецеденты
  4.2.0 и 4.6.0 в `plugins/gramax/CHANGELOG.md`) — решение PM/SA при выпуске, не этого требования.
- **NFR-072 (согласованность с валидаторами и контрактом тегов):** новые теги (`<fragment>`,
  `<fragment-link>`, `<cut>`, `<property>`, `<inline-property>`, `<question>`, `<questionAnswer>`, при
  принятии — `<img-h>`/`<img-v>`) входят в машиночитаемые контракты плагина одним изменением с
  правками writer: тег, задокументированный writer, не должен получать W034 «неподдерживаемая
  разметка» (паритет — FR-156 [требования паритета
  валидаторов](2026-11-18-validators-error-check-parity-requirement)); тот же инвариант BR-003
  render-killer-линтера — расхождение документации и кода закрывается правкой одной из сторон, никогда
  молчанием.
- **NFR-073 (язык и форма примеров):** новые фрагменты — на русском, в стиле существующего writer
  (короткие абзацы, таблицы для перечислений, рабочие примеры вместо плейсхолдеров); каждый пример
  синтаксиса — в ограждённом код-блоке или inline code-span (внешний RENDER-LINTER-гейт).

## User Journey

1. Агент создаёт обучающую статью → берет `<question>`/`<questionAnswer>` из
  `references/quizzes.md`, ставит `quiz` в frontmatter (FR-163) — раньше изобретал синтаксис по памяти
  вендорских страниц.
2. Агент правит дашборд `_index.md` → трактует `defs` как сокрытие (`status=done` убирает
  выполненные), использует `orderby`, `select`, `Table`/`Kanban` (FR-165) — раньше семантика была
  перевёрнута, а представление сведено к `List`.
3. Агент вставляет скриншот → задаёт `scale` для ширины на странице и реальные `width`/`height`
  файла (FR-167); `<gallery>` не изобретает, даже встретив его в вендорской странице (BR-015, BR-016).
4. Агент переименовывает статью по `structure.md` → добавляет старый путь в `aliases` руками;
  UI-перенос делает это сам (FR-162).
5. Агент встречает статью с `template` в frontmatter → не правит её текст (FR-181); встречает
  `.gramax/inbox/` или `.gramax/mr/` → не трогает (FR-182).
6. Потребитель со старым каталогом: `<snippet>`, `[cmd:Label]` и ссылки с `.md` продолжают работать
  — legacy/валидные формы, миграция не обязательна (NFR-071).

Альтернативный путь: элемент, отсутствующий в движке на пине (`<gallery>`, `display="Gantt"`),
writer не предлагает даже если вендорская страница его описывает — приоритет источников BR-015.

## Бизнес-правила

- **BR-015:** приоритет источников этой синхронизации: вердикт RES-008 (исходник движка, пин
  `48592b36`) — выше docs gram.ax; docs — выше текущего текста writer 4.6.0. Четыре переигрывания
  выполняются буквально: `<gallery>` — в движке нет, не документировать; `display="Gantt"` — в движке
  нет, не документировать; семантика `defs` — по движку (сокрытие, `none`/`yes`); канон фрагментов —
  `<fragment>` + `.gramax/fragments/`, `<snippet>` — legacy.
- **BR-016:** `<gallery>` и значение `Gantt` атрибута `display` не документируются как возможности
  writer 4.7.0; попадают в справочник только после нового engine-window-исследования, подтвердившего
  их в движке.
- **BR-017:** правило «внутренние ссылки без `.md`» (FR-080 [контракта формы
  ссылки](2026-08-13-link-form-contract)) — канон; оговорка о резолве `.md`-формы — информационная, не
  смена правила; обязательная миграция существующих ссылок не вводится.
- **BR-018:** служебные зоны каталога — `.gramax/inbox/`, `.gramax/mr/`, содержимое
  `.gramax/templates/` и собранный текст `template:`-статей — вне зоны правки writer-агента;
  единственное исключение — frontmatter-блок `properties` `template:`-статьи.

## Acceptance Criteria

- [ ] **AC-073 (FR-161, `searchPhrases`):**

  ```bash
  grep -qF 'searchPhrases' plugins/gramax/skills/writer/SKILL.md plugins/gramax/skills/writer/references/*.md && echo PASS
  ```
- [ ] **AC-074 (FR-162, `aliases`):**

  ```bash
  grep -qF 'aliases' plugins/gramax/skills/writer/SKILL.md plugins/gramax/skills/writer/references/*.md && echo PASS
  ```
- [ ] **AC-075 (FR-163, справочник тестов):**

  ```bash
  test -f plugins/gramax/skills/writer/references/quizzes.md && grep -qF 'questionAnswer' plugins/gramax/skills/writer/references/quizzes.md && grep -qF 'showIf' plugins/gramax/skills/writer/references/quizzes.md && grep -qF 'countOfCorrectAnswers' plugins/gramax/skills/writer/references/quizzes.md && echo PASS
  ```
- [ ] **AC-076 (FR-163, 12 типов):** редчайшие типы как маркер полного перечня:

  ```bash
  grep -qF 'ranking' plugins/gramax/skills/writer/references/quizzes.md && grep -qF 'matrix' plugins/gramax/skills/writer/references/quizzes.md && echo PASS
  ```
- [ ] **AC-077 (FR-164, новые элементы):**

  ```bash
  grep -qF '<cut' plugins/gramax/skills/writer/references/blocks.md && grep -qF '<property' plugins/gramax/skills/writer/references/blocks.md && grep -qF '<inline-property' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-078 (FR-165, переписанный `<view>`):**

  ```bash
  grep -q 'orderby' plugins/gramax/skills/writer/references/blocks.md && grep -q 'Kanban' plugins/gramax/skills/writer/references/blocks.md && grep -qi 'скрыт' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-079 (BR-015/BR-016, негативный контроль отсутствующих в движке):** в дереве writer нет
  форм `<gallery` и `display="Gantt"`; проза об отсутствии элементов допустима — проверяются формы
  тега/значения:

  ```bash
  ! grep -rq '<gallery' plugins/gramax/skills/writer/ && ! grep -rq 'display="Gantt"' plugins/gramax/skills/writer/ && echo PASS
  ```
- [ ] **AC-080 (FR-166, XML-формы + скобочные):**

  ```bash
  grep -qF '<cmd text=' plugins/gramax/skills/writer/references/blocks.md && grep -qF '<kbd text=' plugins/gramax/skills/writer/references/blocks.md && grep -qF '[cmd:' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-081 (FR-167, `scale` и семантика размеров):**

  ```bash
  grep -q 'scale=' plugins/gramax/skills/writer/references/blocks.md && grep -q 'реальный размер' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-082 (FR-168, видео):**

  ```bash
  grep -qi 'dropbox' plugins/gramax/skills/writer/references/blocks.md && grep -qi 'mega' plugins/gramax/skills/writer/references/blocks.md && grep -qi 'cover' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-083 (FR-169, OpenAPI):**

  ```bash
  grep -qF 'showSchemas' plugins/gramax/skills/writer/references/blocks.md && grep -qF 'showInfo' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-084 (FR-170, раздел блоков кода):**

  ```bash
  grep -qi 'блок кода' plugins/gramax/skills/writer/references/blocks.md && grep -qi 'highlight.js' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-085 (FR-171, якоря):**

  ```bash
  grep -qF '{#' plugins/gramax/skills/writer/references/blocks.md && echo PASS
  ```
- [ ] **AC-086 (FR-172, канон фрагментов + legacy-пометка):**

  ```bash
  grep -qF '<fragment id=' plugins/gramax/skills/writer/references/blocks.md && grep -qF 'fragment-link' plugins/gramax/skills/writer/references/blocks.md && grep -qi 'legacy' plugins/gramax/skills/writer/references/blocks.md && grep -q 'фрагмент' plugins/gramax/skills/writer/SKILL.md && echo PASS
  ```
- [ ] **AC-087 (FR-173, правило ссылок сохранено + оговорка):**

  ```bash
  grep -q 'без .md' plugins/gramax/skills/writer/SKILL.md && grep -qiE 'обе формы|тоже резолв|резолвятся обе' plugins/gramax/skills/writer/SKILL.md && echo PASS
  ```
- [ ] **AC-088 (FR-174, новые ключи схемы):**

  ```bash
  grep -qF 'logo_dark' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qF 'relatedLinks' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qF 'versions' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qF 'hidden' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qE 'filterProperty([^i]|$)' plugins/gramax/skills/writer/references/doc-root-schema.md && echo PASS
  ```
- [ ] **AC-089 (FR-175, enum `syntax` и палитра):**

  ```bash
  grep -qF 'GitHub Flavored Markdown' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qE 'blue-pink|orange-red' plugins/gramax/skills/writer/references/doc-root-schema.md && echo PASS
  ```
- [ ] **AC-090 (FR-176, `.gramax/views`):**

  ```bash
  grep -rqF '.gramax/views' plugins/gramax/skills/writer/ && echo PASS
  ```
- [ ] **AC-091 (FR-177, LFS):**

  ```bash
  grep -qF 'lfs' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qF '.gitattributes' plugins/gramax/skills/writer/references/doc-root-schema.md && echo PASS
  ```
- [ ] **AC-092 (FR-178, мультиязычность):**

  ```bash
  grep -qi 'мультиязыч' plugins/gramax/skills/writer/references/*.md && grep -qi 'непереведён' plugins/gramax/skills/writer/references/*.md && echo PASS
  ```
- [ ] **AC-093 (FR-179, типы свойств):**

  ```bash
  grep -qF 'docportalVisible' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qw 'Flag' plugins/gramax/skills/writer/references/doc-root-schema.md && grep -qw 'Numeric' plugins/gramax/skills/writer/references/doc-root-schema.md && echo PASS
  ```
- [ ] **AC-094 (FR-180, `.icons/`):**

  ```bash
  grep -rqF '.icons/' plugins/gramax/skills/writer/ && echo PASS
  ```
- [ ] **AC-095 (FR-181/FR-182, guardrails):**

  ```bash
  grep -qF 'template:' plugins/gramax/skills/writer/SKILL.md && grep -qF '.gramax/templates' plugins/gramax/skills/writer/SKILL.md && grep -qF '.gramax/inbox' plugins/gramax/skills/writer/SKILL.md && grep -qF '.gramax/mr' plugins/gramax/skills/writer/SKILL.md && echo PASS
  ```
- [ ] **AC-096 (композитный):** — зелёный после публикации этого требования.

  ```bash
  bash scripts/check.sh --fast && echo PASS
  ```

## Инварианты и Safeguards

**Содержательные:**
- Четыре переигрывания BR-015 выполняются буквально: утверждение docs, противоречащее вердикту
  RES-008, в writer 4.7.0 не попадает (негативный контроль — AC-079).
- Ни одно из текущих валидных правил writer 4.6.0 не помечается невалидным без engine-вердикта:
  расхождения doc-root-уровня документируются с явной пометкой «расхождение», не молчаливой заменой
  (NFR-071, FR-175, FR-179).
- Каждое новое утверждение writer несёт проверяемый источник — строку RES-007 или вердикт RES-008 с
  `путь:строка`; фактов «из общих соображений» нет.
- Документация и код плагина синхронны: тег в writer — тег в контракте (NFR-072, BR-003
  render-killer-линтера).
- Служебные зоны каталога защищены hard rules до любых других правок (BR-018, FR-181, FR-182).

**Sensitive content:** N/A — требование описывает документацию синтаксиса публичного продукта; ни
PII, ни секретов, ни NDA-контента не вводит; примеры используют фиктивные пути и значения.

**Жизненный цикл:** ревизия — при следующем окне движка (прецедент цикла RES-006 → 4.6.0, RES-008 →
4.7.0): проверить, не появились ли в движке `<gallery>`/`Gantt` (тогда пересмотреть BR-016), и
получить engine-вердикты по doc-root-расхождениям (открытый вопрос 1). Owner — сопровождающий
репозитория (PM).

## Открытые вопросы

1. **Engine-проверка doc-root-ключей, не покрытых RES-008** (факт 18: `doc-root-schema.md` в аудит
  не вошёл): значение `Legacy` в enum `syntax`; `filterProperty` (одиночный id) против
  `filterProperties` (список имён); нотация property в frontmatter (`id`+`value` по docs против
  `name`-нотации writer 4.6.0); полный состав 20 значений палитры; резолв форм
  `icon:<код>`/`emoji:<символ>` (пересекается с вопросом 4 [требования паритета
  валидаторов](2026-11-18-validators-error-check-parity-requirement)). Решение SA: точечный probe на
  пине/следующем окне; до вердикта — расхождения с пометкой, не замена (FR-175, FR-179).
2. **`<img-h>`/`<img-v>`** — парная вставка картинок существует в движке (RES-008 §5), но не описана
  ни writer, ни выкачкой docs; RES-008 называет строку справочника «кандидатом». Включать ли — решение
  SA (AC на неё нет, FR-167 формулирует как кандидата).
3. **Политика правки самих файлов шаблонов** `.gramax/templates/<id>.md`: FR-181 замораживает
  собранный текст статьи-потребителя; правка же файла шаблона меняет все статьи-потребители разом.
  Заморозить и файлы шаблона или разрешить с оговоркой — решение SA/PM.
4. **Видео-форма «любая ссылка со словом embed»** (RES-007 §4, строка «Список видео-хостингов и
  атрибуты») — формулировка docs расплывчата для hard-правила; в FR-168 не включена. Уточнить
  формулировку и включить — SA.
5. **Массовая превентивная миграция `<snippet>` → `<fragment>`** у потребителей: движок мигрирует
  фрагмент при первой правке (RES-008 §1); нужен ли в writer рецепт превентивной миграции корпусов —
  PM/SA.
6. **Детали синтаксиса вне среза** (тире `--`, перенос `\`, экранирование `\$`, блочные комментарии,
  раздел «чего нет в синтаксисе» — RES-007 §3) — кандидат следующего цикла writer 4.8.0; здесь не
  решается.

## Бриф для SA

**Требование:** `docs/30-requirements/2026-11-18-writer-sync-470-requirement.md`
**Фаза:** массовая синхронизация writer 4.7.0 — К1a+К1b (RES-007) плюс пять аудиторных правок
RES-008.

**Спроектировать:**
- Раскладку тем по файлам навыка (навигация `SKILL.md` против `references/`) для FR-161–FR-182;
  состав нового `references/quizzes.md` (FR-163) — авторский синтаксис без серверной стороны.
- Точную формулировку переписанного раздела `<view>` по вердикту 3 (FR-165): таблица атрибутов
  `defs`/`orderby`/`groupby`/`select`/`display` с форматами значений из RES-008 §3 (разделители
  `&`/`,`, дефолт `List`, `hierarchy` как запись в `defs`).
- Изображения: согласование `scale` (px и проценты) с существующей `{width height}`-аннотацией и
  `<image …/>` (FR-167); судьба `img-h`/`img-v` (открытый вопрос 2).
- Синхронизацию `gramax-tags.json` с новыми тегами одним изменением с правками writer (NFR-072) —
  координация с FR-156/FR-157 [требования паритета
  валидаторов](2026-11-18-validators-error-check-parity-requirement), чтобы новые теги не попали в
  W034.
- Позицию по doc-root-расхождениям (FR-175, FR-179, открытый вопрос 1): что документировать с
  пометкой «расхождение», что ждать engine-вердикта; нужен ли точечный engine-проб (метод
  RES-004/RES-008) для `filterProperty` и нотации свойств.
- Нужен ли ADR: прецеденты — writer-синки 4.2.0/4.6.0 шли без отдельных ADR, но правка
  машиночитаемого контракта тегов может требовать оформления (граница — по прецеденту ADR-0012) —
  решение SA.

**Бизнес-правила для валидаций:** BR-015, BR-016, BR-017, BR-018.

**Acceptance criteria для проверки архитектуры:** AC-075, AC-078, AC-079, AC-081, AC-086, AC-088,
AC-089, AC-093, AC-096.
