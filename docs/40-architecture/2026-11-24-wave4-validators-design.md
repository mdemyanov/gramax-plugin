---
title: "Контракты валидаторов и резолвера волны-4 — факты движка, замеры-основания, целевые значения, контракт с QA-author, бриф Dev"
order: 13
status: draft
date: 2026-11-24
plugin: gramax
properties:
  - name: Тип контента
    value: [Архитектура]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# Контракты валидаторов и резолвера волны-4 — факты движка, замеры-основания, целевые значения, контракт с QA-author, бриф Dev

**Опоры:** `docs/00-project/epics/2026-11-24-wave4-tails-genesis-tree.md`,
`plugins/gramax/gramax-tags.json`, `plugins/gramax/scripts/lib/md_link_parser.py`,
`plugins/gramax/scripts/lib/md_code_mask.py`, `plugins/gramax/scripts/lib/link_resolver.py`,
`plugins/gramax/scripts/lib/read_page.py`, `plugins/gramax/scripts/validate_structure.py`,
`plugins/gramax/scripts/validate_render.py`, `plugins/gramax/scripts/validate_comments.py`

## Контекст

Исполнительская расшифровка [ADR-0028](../00-project/adr/0028-wave4-validator-link-contracts.md) к
[дереву волны-4](../00-project/epics/2026-11-24-wave4-tails-genesis-tree.md) (D1–D15) и к требованию
волны-4 `docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md` (вне индекса на момент
письма). ADR несёт решения и строки `Contract:`; этот документ несёт то, что ADR намеренно не несёт:

- факты движка с `файл:строка` на пине `48592b36` и команды их воспроизведения;
- замеры-основания решений — каждая цифра с командой, которая её дала;
- целевые значения контрактов дословно (регулярные выражения, сообщения, сигнатуры, JSON);
- мэппинг NFR и бизнес-правил, совместимость, контракт с QA-author и бриф для Dev.

Карточки цитируются по id в сторе beads (`gramax-4jf.14`, `gramax-o0q.21`, `.22`, `.25`, `.27`, `.29`,
`.33`, `.35`) и по трём решениям, переданным координатором в ходе задачи: пункт 9 — временное
протокол ADR-0016 Решение 2, пункт 10 — реестр тегов, пункт 11 — `--strict` валидатора комментариев.
Сестринские ADR-0029 и ADR-0030, дайджест RES-010 и обе половины требования волны-4 — параллельные
артефакты, вне индекса на момент письма; здесь они названы по id без ссылок.

**Условия замеров.** База — коммит `f551d87`. Рабочее дерево в момент задачи меняли остальные роли
волны, поэтому замеры по `docs/` и по коду исполнены на снимке базы:
`git archive f551d87 docs plugins scripts tests | tar -x -C <снимок>` (в `docs/` снимка 131 файл
`.md`: `find <снимок>/docs -name '*.md' | wc -l`). Файлы `plugins/gramax/scripts/**` в рабочем дереве
не менялись (`git status --short -- plugins/gramax/scripts | wc -l` → 0), поэтому строки кода
действительны и для базы, и для дерева. Строки статей `docs/*.md` приведены по коммиту `f551d87`: в
рабочем дереве они сдвинуты на 2–6 строк вставками маркера `**Опоры:**`.

**Корпус сравнения** — приватный эталонный каталог волны-3; его путь в репозиторий не пишется
(ADR-0014, D8), в командах он обозначен `<корпус>`: `find <корпус> -name '*.md' | wc -l` → 786, из них
20 лежат в `.gramax/` и 766 вне его. Числа по корпусу — только счётчики, без содержимого и имён.

**Движок** читался 2026-11-24 в разреженном клоне на коммите `48592b36bb0b16ec6dca248fb76dd0d5a37526a5`;
движок не запускался — все факты суть чтение исходника, не прогон. Пути фактов — от корня
`github.com/Gram-ax/gramax`; приняты сокращения: `elements/…` =
`core/extensions/markdown/elements/…`, `…/Prosemirror/…` =
`core/extensions/markdown/core/edit/logic/Prosemirror/…`, `…/Markdoc/src/…` =
`core/extensions/markdown/core/render/logic/Markdoc/src/…`, `MdParser.ts` =
`core/extensions/markdown/core/Parser/MdParser/MdParser.ts`, `linkCreator.ts` =
`core/extensions/markdown/elements/link/render/logic/linkCreator.ts`, `Healthcheck.ts` =
`core/extensions/healthcheck/logic/Healthcheck.ts`. Тексты официального скилла вендора
(`gramax-article-syntax.md`, 336 строк, и `gramax-catalog-structure.md`, 182 строки) получены
исследователем 2026-11-24 из архива синтаксис-страницы портала; строки ниже — по
`gramax-article-syntax.md`, если не названо иное.

## 1. Факты движка на пине 48592b36

«Решение» в последней колонке — номер решения ADR-0028, опирающийся на факт.

| № | Факт | Файл:строка движка | Решение |
|---|---|---|---|
| 1 | Грамматика тега: самозакрытый даёт `tag` с вложенностью 0, парный — `tag_open` с вложенностью 1; атрибуты читаются из открывающего тега в обеих формах | `…/Markdoc/src/grammar/tag.pegjs:19-36` | Р3 |
| 2 | Конец тега — первый `>` вне кавычек; форма записи до него безразлична | `…/Markdoc/src/utils.ts:18-42` | Р3 |
| 3 | Модель диаграммного тега регистрирует `path` как ресурс и возвращает тег без детей — тело парного тега отбрасывается | `elements/diagrams/getters/markdocModel.ts:17-29` | Р3 |
| 4 | Проверка на ошибки обходит ресурсы, проверяет существование и группирует по расширению; `.yaml` — класс диаграмм | `Healthcheck.ts:85-88`, `:238-252`; `core/logic/Resource/ResourceExtensions.ts:3` | Р3, Р10 |
| 5 | Резолв ссылки: цель с расширением — литерал; без расширения — `цель.md`, затем `цель/_index.md`, затем существующий файл (не папка); иначе запасной `href` | `linkCreator.ts:99-176` (`:117-119`, `:121-139`, `:141-154`, `:156-162`, `:178-181`, `:175`, `:230-238`) | Р4 |
| 6 | Только реальный файл подходит целью без расширения: папка, зарегистрированная как ресурс, уезжала бы вместе со статьёй | `linkCreator.ts:156-162`, `:178-181` | Р4 |
| 7 | Проверка на ошибки судит цель без расширения по `цель/_index.md`; корень раздела — `_index.md` | `Healthcheck.ts:192-201`, `:212-227`; `app/config/const.ts:32-33` | Р4 |
| 8 | Папка без `_index.md` без флага разделом не становится — дети поднимаются к родителю; с флагом раздел создаётся с виртуальным `_index.md` | `core/logic/FileStructue/FileStructure.ts:528-531`, `:653`, `:669` | Р4 |
| 9 | Заголовок страницы: первый H1 извлекается в `title` и вырезается из тела, только если у статьи нет `title` | `core/logic/FileStructue/Article/parseContent.ts:49-54`; `core/logic/FileStructue/Article/extractHeader.ts:4-31` | Р6 |
| 10 | H1 в теле рендерится элементом `h2`: каждый заголовок статьи идёт через этот компонент; в оглавление H1 входит уровнем 2 | `elements/heading/render/components/ArticleContentHeader.tsx:3-7`; `core/extensions/markdown/core/render/components/getComponents/getComponents.tsx:31`; `core/extensions/navigation/article/logic/createTocItems.ts:82` | Р6 |
| 11 | Препарсер защищает от своих подстановок только однострочный code-span; флаги его регулярных выражений — `gm`, без `s` | `MdParser.ts:56`, `:347-358`; `markdown-it` `^14.1.1` — `package.json:108` | Р2 |
| 12 | Реестр тегов рендера: 17 ключей контекстного блока и 41 ключ статического | `core/extensions/markdown/core/render/logic/getRenderElements/getTagElementRenderModels.ts:55-122` | Р10 |
| 13 | Тег без схемы не токенизируется как тег; проверка на ошибки пишет «неподдерживаемое» только для узла `Unsupported` (импортированный контент), не для неизвестных тегов | `…/Markdoc/src/tokenizer/plugins/annotations.ts:37-54`, `:56-80`; `…/Markdoc/src/transformer.ts:57-69`; `Healthcheck.ts:303-320` | Р10 |
| 14 | Редактор хранит тег без собственной узловой схемы как общий блок и пишет его текст обратно; псевдонимы переписываются при сохранении: `snippet-link` → `fragment-link`, `snippet` → `fragment` | `…/Prosemirror/transformer.ts:211-264`, `:206-209`; `elements/md/edit/logic/blockMdFormatter.ts:3-6` | Р10 |
| 15 | Сериализация общего тега: без `selfClosing: false` — самозакрытый; `formula` пишется своим сырым содержимым | `core/extensions/markdown/core/edit/logic/Formatter/Formatters/getMarkdocFormatter.ts:8-38` (`:9-13`, `:23`) | Р10 |
| 16 | Схемы: `alert` — парный блок `type`, `title`; `block-property` и `block-field` — парные блоки `bind`, `placeholder`; `db-diagram` — `path`, `tags`, `moreTags`; `db-table` — `name`, `path`; `when`, `who` — `text`; `see` — `link`, `name`, `lang`; `term` — `code`, `title`; `issue` — `id`; `module` — `id`; `include` — `path`, `gratings` | `elements/alert/render/model/alert.ts:4-15`; `elements/blockProperty/render/models/blockProperty.ts:6-21`; `elements/blockContentField/render/models/blockField.ts:6-21`; `elements/diagramdb/model/diagramdb.ts:6-54`; `elements/tabledb/model/tabledb.ts:5-42`; `elements/whowhen/model/whowhen.ts:3-15`; `elements/see/model/see.ts:3-10`; `elements/term/model/term.ts:4-28`; `elements/issue/model/issue.ts:3-8`; `elements/module/model/module.ts:3-10`; `elements/include/model/include.ts:6-35` | Р10 |
| 17 | Редактор знает `alert`, `block-property`, `block-field` как собственные узлы и пишет их парными; `db-diagram` и `db-table` поименованы в форматировщике общего блока | `…/Prosemirror/schema.ts:104`, `:124`, `:126`; `…/Prosemirror/tokens.ts:79-81`; `elements/alert/edit/model/alertToken.ts:1-11`; `elements/blockProperty/edit/logic/blockPropertyFormatter.ts:7-13`; `elements/blockContentField/edit/logic/BlockFieldFormatter.ts:7-10`; `elements/md/edit/logic/inlineMdComponentFormatter.ts:3-9` | Р10 |
| 18 | `<br>` и `<br/>` препарсер превращает в тег `br`, а редактор пишет разрыв строки обратным слешем; `$…$` препарсер превращает в `formula` | `MdParser.ts:78`, `:113`, `:239-243`; `elements/br/edit/logic/brFormatter.ts:3-9`; `MdParser.ts:276-283`, `:315-324` | Р10 |

Команды воспроизведения (клон разреженный, только `core/`; файл константы — через `git show`;
любая строка факта — одной из двух последних команд с путём и образцом из таблицы):

```bash
git clone --filter=blob:none --no-checkout --sparse https://github.com/Gram-ax/gramax <dir>
git -C <dir> sparse-checkout set core
git -C <dir> checkout --detach 48592b36
git -C <dir> rev-parse HEAD                      # 48592b36bb0b16ec6dca248fb76dd0d5a37526a5
git -C <dir> show 48592b36:app/config/const.ts | grep -n CATEGORY_ROOT_FILENAME   # факты 7, 8
grep -n "_tagAliases" -A 3 <dir>/core/extensions/markdown/core/edit/logic/Prosemirror/transformer.ts   # факт 14
git -C <dir> grep -n -E '<образец>' 48592b36 -- '<путь>'
git -C <dir> show 48592b36:<путь> | sed -n '<строки>p'
```

## 2. Замеры-основания

Все команды исполнены 2026-11-24. `<снимок>` — каталог снимка базы (см. «Контекст»), `<корпус>` —
корпус сравнения, `<плагин>` — `plugins/gramax/scripts` снимка. Фикстуры карточек построены в
scratch-каталоге вне репозитория.

| Карточка | Что измерено | Команда → результат |
|---|---|---|
| `gramax-o0q.21` | Слепое пятно на фикстуре с отсутствующей целью | `python3 -B <плагин>/validate_structure.py <фикстура>` → самозакрытый тег: W031 = 1; парный: 0; без закрывающего `>`: 0 |
| `gramax-o0q.21` | Формы диаграммных тегов в корпусах | `<корпус>`: 68 открывающих тегов, все самозакрытые с `path`, 0 парных, 0 незакрытых; `docs/` базы: 1 парный без `path`, 0 с `path` |
| `gramax-o0q.21` | Детектор: старое и новое регулярное выражение | `<корпус>`: 68 и 68 совпадений, списки совпадают; имена атрибутов тегов: `height`, `path`, `scale`, `title`, `width` |
| `gramax-o0q.22` | Ложный ERROR на многострочном спане | `python3 -B <плагин>/validate_render.py <файл>` → `FAIL`, `ERROR L6: Инлайновый <note>…</note> в одну строку`, rc=1 |
| `gramax-o0q.22` | Спаны, которые маскирует вторая фаза | `docs/` базы: 116 спанов в 44 файлах; строк в спане: 2 — 108, 3 — 5, 4 — 1, 9 — 1, 10 — 1; длина ≤ 64 символов — 35, ≤ 128 — 63, ≤ 256 — 15, ≤ 512 — 2, ≤ 1024 — 1; `<корпус>`: 1 спан в 1 файле (15 строк, 1743 символа) |
| `gramax-o0q.22` | Находки до и после (двухфазная маска) | `docs/` базы: структура 0 ERROR / 0 WARNING, рендер 0 ERROR / 130 WARN — до и после; `<корпус>`: 96 / 539 и 5 / 151 — до и после; файлов с изменившимися находками: 0 и 0 |
| `gramax-o0q.22` | Однопроходный вариант (отклонён) | `docs/` базы: +2 ERROR «битая ссылка», +2 W031, +2 W034, +2 ERROR рендера (несбалансированные `<note>`, `<tabs>`) |
| `gramax-o0q.25` | Каталог без `_index.md` без флага | `python3 -B <плагин>/validate_structure.py <фикстура>` → rc=1 лишь от `missing _index.md`; находок по ссылке: 0 |
| `gramax-o0q.25` | Тот же каталог с `optionalCategoryIndex: true` | rc=0, находок по ссылке: 0 |
| `gramax-o0q.25` | Одноимённые файл `section.md` и каталог `section/` | ссылка резолвится в каталог; `section.md` получает WARNING «статья-сирота» |
| `gramax-o0q.25` | Вердикты по каждой ссылке: текущий и целевой резолвер | `docs/` базы: 567 ссылок (548 файловых, 19 через `.md`), расхождений 0; `<корпус>`: 911 ссылок — 42 битые и битые, 485 файловых, 90 через `_index.md`, 294 через `.md`; смен вердикта 0; путь резолва меняется у 90 |
| `gramax-o0q.25` | Ссылки на каталог с `_index.md`, несущие `#якорь` | `docs/` базы: 0; `<корпус>`: 0 |
| `gramax-o0q.27` | Кандидат правила на корпусах (сырой текст, без маски кода) | `docs/` базы: 2 находки в 2 файлах, обе внутри code-span; `<корпус>`: 10 находок в 3 файлах, та же форма |
| `gramax-o0q.27` | Кандидат правила на синтетическом наборе | 17 случаев, все как ожидается: 9 находок (macOS, Linux, Windows), 8 без находки (маскированные формы, `/Users/...`, `$USER`, адреса с `/home/` и `/Users/`, относительные пути) |
| `gramax-o0q.29` | Шум правила H1 | `python3 -B <плагин>/validate_render.py docs \| grep -c 'H1'` → 130; с `--errors-only` → 0; `Итого: файлов=131, ERROR=0` |
| `gramax-o0q.29` | H1 и `title` в корпусах | `docs/` базы: 131 файл, 13 страниц-индексов; H1 несут 130, из них H1 = `title` у 129, H1 ≠ `title` у 1, без H1 1; `<корпус>`: 766 файлов, 220 индексов; H1 несут 55 (равен `title` — 19, не равен — 36), без H1 710 |
| `gramax-o0q.29` | Ассерт `h1` в приборе рендер-проб | `git grep -n -i -E "\bh1\b\|'h1'\|\"h1\"" -- tests/gramax/render-quality scripts/render-quality` → пусто |
| `gramax-4jf.14` | Парсер на каталоге с битым UTF-8 | `parse_md_resources(<каталог>)` → исключение `UnicodeDecodeError`; контроль без битого файла → 2 ресурса |
| `gramax-4jf.14` | Стаб ac-133 на снимке базы (ноги повторены вручную) | rc=1, `Traceback` — 0 строк, `E036` — 1 строка с именем битого файла, `unpaired <html>` — 1 |
| `gramax-4jf.14` | Копии `_mask_code` | `grep -c 'def _mask_code' <плагин>/lib/md_code_mask.py <плагин>/lib/md_link_parser.py <плагин>/migrate_nav_codespans.py` → 1, 1, 1 |
| `gramax-o0q.33` | gen_comment_id.py и slugify.py | пробы CLI — инварианты §3.7; 2000 запусков генератора: 2000 различных ID, все `^[A-Za-z0-9]{5}$` |
| `gramax-o0q.35` | Несколько legacy-блоков в одном файле | отчёт: rc=1, 3 строки, `To-migrate: 3`; `--fix --yes`: rc=0, `Migrated: 3`, файлы `-existing-2`…`-existing-4` (первое имя занято), DSL побайтово; повторный отчёт: rc=0, `To-migrate: 0`, `Already-compliant: 3` |
| `gramax-o0q.35` | Перечисление без маркера | ``Требования: `a.md`, `b.md` `` → `SUBJECT: 2`, в отчёте нет; в маркированных строках NAV получает только первый спан после слова-маркера |
| `gramax-o0q.35` | Обходы дерева | `git grep -n -E 'rglob\("\*\.md"\)' -- plugins/gramax/scripts` → 7 мест |
| пункт 9 | Временный протокол ADR-0016 Решение 2 | `PYTHONDONTWRITEBYTECODE=1 python3 -B scripts/validate-content.py <scratch>` → C9 печатает только `missing`; `[b](b)` проходит; `git log -S'def _resolve_link_target' -- scripts/validate-content.py` → `38fe3e6`, 2026-08-31 |
| пункт 9 | Ссылки с `.md` в `docs/` | `git grep -c -E '\]\([^)]+\.md\)' -- docs \| wc -l` → 108 файлов; `git grep -o -E '\]\([^)]+\.md\)' -- docs \| wc -l` → 704 вхождения; перепись ссылок на снимке: 548 с расширением (518 `.md`, 30 `_index.md`) и 19 без расширения из 567 |
| пункт 10 | Реестр движка против известного набора плагина | скрипт по `getTagElementRenderModels.ts` и двум JSON плагина: 58 ключей движка (17 + 41), известный набор плагина 36, вне набора 24 |
| пункт 10 | Ложный W034 | `python3 -B <плагин>/validate_structure.py <фикстура>` со всеми 24 ключами реестра и фиктивным тегом: W034 на 25 именах при нынешнем контракте, на 13 при целевом (12 оставшихся ключей и фиктивный тег) |
| пункт 10 | Упоминания в текстах вендора | `grep -c -F -- <имя> gramax-article-syntax.md gramax-catalog-structure.md` → 0 и 0 для каждого из 12 входящих имён |
| пункт 11 | `--strict` не эскалирует | `UV_OFFLINE=1 uv run plugins/gramax/scripts/validate_comments.py --strict <scratch>` → строка `WARNING … dateTime not ISO 8601 UTC`, rc=0 |
| пункт 11 | Предупреждения на корпусах | `docs/` базы: 0 файлов `.comments.yaml`, rc=0; `<корпус>`: 100 файлов, rc=1, 144 ERROR, 17 WARNING (12 «duplicate answer», 5 «у ответа нет user.id»); под `--strict` rc=1 и там, и там |

## 3. Целевые значения контрактов

Нумерация решений — как в ADR-0028.

### 3.1 Чтение в парсере (Решение 1, `gramax-4jf.14`)

`plugins/gramax/scripts/lib/md_link_parser.py`:

- читает страницы только через `lib.read_page.read_page`; собственные `_mask_code` (`:43-60`),
  `_FENCE_RE` и `_INLINE_CODE_RE` (`:13-14`) удаляются — маска импортируется из `lib.md_code_mask`;
- новый тип и две функции:

```python
@dataclass(frozen=True)
class MdPageError:
    source: Path            # файл, который не прочитался
    error: PageReadError    # первый неверный байт, позиция, размер — lib/read_page.py

def scan_md_resources(root: Path,
                      diagram_tags: tuple[str, ...] = _DEFAULT_DIAGRAM_TAGS,
                      *, exclude: Callable[[Path], bool] | None = None,
                      ) -> tuple[list[MdResource], list[MdPageError]]: ...

def parse_md_resources(root: Path,
                       diagram_tags: tuple[str, ...] = _DEFAULT_DIAGRAM_TAGS,
                       *, exclude: Callable[[Path], bool] | None = None) -> list[MdResource]: ...
```

`parse_md_resources` сохраняет тип результата и служит обратной совместимостью: возвращает первый
элемент пары `scan_md_resources`. `exclude` добавляется к встроенному исключению `.gramax`.

Инварианты:

1. Файл, не являющийся валидным UTF-8, не возбуждает исключения: он даёт один `MdPageError` и ни
   одного ресурса; остальные файлы сканируются в отсортированном порядке.
2. Маскирование и извлечение ресурсов — одни и те же выражения для всех потребителей; вторая фаза
   маски (§3.2) действует и здесь.

`plugins/gramax/scripts/validate_structure.py`:

- `_parse_resources` (`:331-371`) удаляется; `check_broken_links`, `check_images`, `check_diagrams`
  получают ресурсы от тонкого адаптера: он передаёт в `scan_md_resources` предикат исключений
  валидатора и превращает каждый `MdPageError` в
  `Issue("error", source, f"E036: {utf8_message(err)}")`; `_dedupe_utf8_findings` (`:68-84`)
  оставляет одну находку на файл (BR-004);
- `_collect_links` (`:625-663`) не ведёт собственного прохода по регулярному выражению: строит
  `LinkRef` из ресурсов типа `link` того же адаптера, резолв — общей функцией §3.4;
- `_resolve_link_target` (`:607-622`) удаляется; фильтры владения (`_is_excluded_walk_path`,
  `_in_nested_subtree`) остаются у валидатора и передаются предикатом.

Число проходов по каталогу не меняется и предметом решения не является.

### 3.2 Маска многострочного code-span (Решение 2, `gramax-o0q.22`, пункт б)

`plugins/gramax/scripts/lib/md_code_mask.py`, `_mask_code` (`:34-56`) становится двухфазной.

Фаза 1 — без изменений, дословно сегодняшняя:

```text
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")
```

Фаза 2 — по остатку текста после фазы 1; спаривает только бэктики, оставшиеся одинокими на своей
строке:

```text
R2  (?<!`)(`+)((?:[^\n]|\n(?![ \t]*\n))*?)(?<!`)\1(?!`)
```

Замена фазы 2 сохраняет переводы строк: `re.sub(r"[^\n]", " ", m.group(0))`.

Правила:

1. Всё, что маскируется сегодня, маскируется и после правки: фаза 1 не меняется, фаза 2 только
   добавляет маски. Находки могут лишь исчезать, появляться не могут.
2. Фаза 2 спаривает ряд бэктиков со следующим рядом той же длины в пределах блока — пустая строка
   (перевод, за которым идут только пробелы и перевод) обрывает поиск.
3. Границы ряда точные: ряд из N бэктиков не закрывается частью ряда из N+1.
4. Числовых пределов нет. Граница одна — пустая строка, как в CommonMark: code-span не переходит из
   одного абзаца в другой. Замер §2 показывает, почему предел по числу строк не подходит:
   настоящий перенос команды занимает 2–3 строки, а пара одиночных бэктиков через пункты списка
   дала 4 и 9 строк. Условие возврата: замер, где фаза 2 скрыла реальную находку, — тогда вводится
   предел строк со своим замером.

Побочное действие: примитив общий, поэтому фаза 2 действует и в `validate_comments.py`,
`parse_comments.py`. Побайтовая копия в `migrate_nav_codespans.py:89-108` не меняется (Решение 8).

### 3.3 Детектор диаграммного тега (Решение 3, `gramax-o0q.21`)

`_diagram_tag_re` (`plugins/gramax/scripts/lib/md_link_parser.py:24-30`). Было:

```text
<({names})\s[^>]*path="([^"]+)"[^>]*/>
```

Стало:

```text
<({names})(?:\s[^>]*?)?\s+path="([^"]+)"[^>]*>
```

`{names}` — имена `diagramTags` через `|`, как прежде. Группа 1 — имя тега, группа 2 — цель.

Что меняется: (1) открывающий тег с `path`, записанный парным (`<plant-uml path="…">…</plant-uml>`)
или без закрывающего `>`, распознаётся наравне с самозакрытым; (2) атрибут, чьё имя оканчивается на
`path` (`data-path=`), целью не считается — перед `path` обязан стоять пробельный символ. На корпусах
(§2) второе изменение даёт 0 расхождений.

Находка та же, дословно (`validate_structure.py:947-951`):

```text
W031: файл диаграммы не найден (тег <{tag}>): "{raw}" → {resolved}
```

Уровень — warning (ADR-0024 Решение 2). Тест `DiagramPathWithoutSelfClosingTests`
(`plugins/gramax/scripts/tests/test_validators_parity.py:116-132`) переводится (NFR-084): форма без
слэша с отсутствующей целью даёт W031; парная форма с существующей целью даёт 0 находок.

### 3.4 Резолвер ссылки (Решение 4, `gramax-o0q.25`)

Единственный резолвер — в `plugins/gramax/scripts/lib/link_resolver.py`:

```python
def resolve_link_target(source_dir: Path, target: str, *, index_optional: bool = False) -> Path | None:
```

Порядок кандидатов; возвращается первый подошедший, иначе `None`:

| Шаг | Кандидат | Условие | Движок |
|---|---|---|---|
| 1 | литерал `(source_dir / target).resolve()` | `is_file()` | `linkCreator.ts:117-119` |
| 2 | `source_dir / (target + ".md")` — только для цели без `.md` на конце | `is_file()` | `linkCreator.ts:121-139` |
| 3 | литерал `/ "_index.md"` | `is_file()` | `linkCreator.ts:141-154` |
| 4 | литерал — каталог, только при `index_optional=True` | `is_dir()` | `FileStructure.ts:653` |

`index_optional=True` передаёт `validate_structure.py` из `_doc_root_flag_true` (`:381-396`) —
строго булев `true` флага `indexPolicy.subfolderOptionalFlag` корня каталога.

Правила:

1. Каталог не считается файлом: без `_index.md` и без флага цель не резолвится. Сегодня шаг 1
   возвращает каталог по `exists()` (`validate_structure.py:619-621`).
2. При одноимённых файле и каталоге побеждает файл: каталог не проходит шаг 1, файл находится на
   шаге 2. Сегодня каталог побеждает и статья остаётся «сиротой» (замер §2).
3. Цель с `.md` на конце резолвится только буквально — второго `.md` не появляется (AC-011b).
4. Форма с завершающим слешем обрабатывается как без него: `pathlib` его отбрасывает.
5. Ссылка на раздел резолвится в `_index.md`, поэтому `#якорь` раздела проверяется как у статьи
   (`resolved.suffix == ".md"`, `validate_structure.py:735`); в корпусах таких ссылок 0.
6. `check_orphans` не считает `_index.md` сиротой (`validate_structure.py:774-775`) — раздел не
   мог стать «сиротой» и до правки; меняется только путь в `LinkRef.resolved`.

`resolve_no_ext` (`link_resolver.py:80-106`) удаляется. Единственная живая ветка (`with_suffix`,
`:99-101`) поглощается шагом 2; ветки с `index.md` (`:92`, `:103`) мертвы: корень раздела движка —
`_index.md` (`app/config/const.ts:32-33`), а шаг 3 не мог совпасть — функцию вызывали лишь при
несуществующем литерале, под которым нет и `index.md`.

`check_broken_links` (`validate_structure.py:698-748`): `resolved = resolve_link_target(...)`; при
`None` — одна из двух формулировок, дословно:

```text
битая ссылка (broken link) на "{raw}" — файл не найден: {resolved}
битая ссылка (broken link) на "{raw}" — каталог без _index.md (раздела в дереве нет): {resolved}
```

Вторая — когда литерал `(source.parent / target).resolve()` существует и это каталог; `{raw}` — цель
как в файле, `{resolved}` — литеральный путь. Обе — `error` (FR-048); W033 не меняется.

### 3.5 Утечка абсолютных путей (Решение 5, `gramax-o0q.27`)

Новая проверка `check_absolute_paths` в `plugins/gramax/scripts/validate_structure.py`; вызывается в
`_validate_catalog_root` после `check_placeholders`. Читает сырой текст статьи через
`_read_page_or_report` — без маски кода: обе находки собственного корпуса стоят внутри code-span.

```python
_ABS_PATH_RE = re.compile(
    r"(?<![\w/.\-])(?:/(?:Users|home)/|[A-Za-z]:(?:\\Users\\|/Users/))"
    r"(?P<seg>[A-Za-z0-9._-]*[A-Za-z0-9][A-Za-z0-9._-]*)(?=[\\/\s`\"')\],;:]|$)")
```

- Код `E037`, уровень `error`, одна находка на строку (первое совпадение строки), rc=1.
- Сообщение дословно; `{N}` — номер строки, `{form}` — одна из форм `/Users/<имя>/…`,
  `/home/<имя>/…`, `C:\Users\<имя>\…`:

```text
E037: абсолютный локальный путь контрибьютора на строке {N} (форма {form}) — не публикуй: утечка идентификационных данных и битая ссылка при рендеринге (FR-072)
```

- Сам путь и имя в сообщение и вывод не попадают.
- Маскированные формы не совпадают: `<имя>` не входит в класс имени; сегмент из одних точек
  (`/Users/...`) отвергается требованием хотя бы одной буквы или цифры; `$USER` и `%USERNAME%` не
  совпадают; адрес (`https://example.com/home/…`) отсечён запретом буквы, точки или слеша перед
  путём.
- Группа таксономии — `content` (`incorrects-content`): в `_ERROR_GROUPS["content"]["pattern"]`
  (`validate_structure.py:1063`) добавляется альтернатива `абсолютн`. В группах движка
  (`Healthcheck.ts:50-57`) отдельной группы приватности нет.
- Уровень: детерминированный признак, класс риска — приватность; прецедент — плейсхолдер, доехавший
  до каталога, `error` безусловно (ADR-0012 Решение 2, `:73` по `f551d87`).

Порядок с чисткой D8: правило попадает в `--full`-шаг догфудинга (ADR-0027 Решение 4, порог 0
ERROR), пока в `docs/` есть две строки — `docs/lessons-learned.md:440` и
`docs/30-requirements/2026-11-17-docs-layout-inversion.md:138` (по `f551d87`). Правка кода входит
после коммита чистки или тем же коммитом.

### 3.6 Правило H1 (Решение 6, `gramax-o0q.29`)

Кода это решение не меняет: `validate_render.py:202-205`, уровень WARN и текст без изменений.

Фикстуры именованного шага замеров (D12) для `tests/gramax/render-quality/fixtures/`:

| Фикстура | Тело | Вопрос замера |
|---|---|---|
| `h1-equals-title.md` | frontmatter `title` и первым в теле `#` с тем же текстом | сколько элементов `h1` и `h2` несут текст `title` |
| `h1-absent.md` | та же страница без строки `#` | то же |

Прибор судит ассертом `{"name", "selector", "count"}` (`scripts/render-quality/tier1_dom.py:15-36`);
селекторы — `h1:has-text('<title>')` и `h2:has-text('<title>')`. По чтению исходника ожидается
«на один больше» на странице с H1: там один `h2` с текстом `title` (факт 10 §1). Оба числа пишутся
в журнал приёмки; исходы — в ADR-0028, Решение 6.

### 3.7 Контракты gen_comment_id.py и slugify.py (Решение 7, `gramax-o0q.33`)

`plugins/gramax/scripts/slugify.py` — поведение не меняется, закрепляется тестами.

Сигнатуры: `TRANSLIT` (`:11-19`, 33 буквы); `slugify(text: str) -> str` (`:22-39`); `main()`
(`:42-58`) с позиционным `text` и флагами `--filename`, `--folder`.

Инварианты:

1. Кириллица транслитерируется, регистр нижний: `Привет мир` → `privet-mir`, `Ёжик и Щука` →
   `yozhik-i-shchuka`, ` подъезд ` → `podezd`.
2. Каждый символ вне буквы и цифры становится дефисом, дефисы схлопываются, крайние срезаются:
   `C# и .NET` → `c-i-net`, `a-b---c` → `a-b-c`, `foo_bar baz` → `foo-bar-baz`, `tab<TAB>x` →
   `tab-x`, `a  b` → `a-b`.
3. Пустая или пробельная строка: `ValueError("empty input: slug requires non-empty string")`, в CLI —
   эта строка в stderr и rc=2.
4. `--filename` добавляет `.md`; при обоих флагах действует `--filename`; `--folder` ничего не
   добавляет.
5. Ошибки аргументов argparse — rc=2: без аргументов, лишний позиционный, неизвестный флаг. Аргумент,
   начинающийся с `-`, передаётся после `--`: `-- -lead-` → `lead`.

Крайний случай, поведением не меняется и стабом не закрепляется: буквы вне кириллицы и ASCII
остаются как есть (`Ünïcödé` → `ünïcödé`, CJK остаётся CJK — `isalnum()` истинно), тогда как
`slugify_heading` (`lib/link_resolver.py:50-77`) снимает диакритику. Два слагификатора плагина
расходятся на не-ASCII буквах; решения о выравнивании в волне нет.

`plugins/gramax/scripts/gen_comment_id.py`. Сигнатуры: `ALPHABET` (`:14`, 62 знака), `MAX_ATTEMPTS`
(`:15`, 100), `generate_id() -> str` (`:18-19`), `load_existing_ids(yaml_path: Path) -> set[str]`
(`:22-37`), `generate_unique_id(existing: set[str]) -> str` (`:40-46`).

Инварианты:

1. ID — 5 знаков `[A-Za-z0-9]`; совпадает с `ID_RE` валидатора комментариев
   (`validate_comments.py:33`).
2. С `--check <файл>` напечатанный ID не совпадает ни с одним ключом верхнего уровня файла.
3. Файла нет — пустое множество, rc=0 (штатно для нового файла комментариев).
4. Файл — не отображение (список, пустой) — пустое множество, rc=0; так же молчит и валидатор
   (`validate_comments.py:119`).
5. Ошибка YAML — `yaml parse error in {path}: {e}` в stderr, rc=2.
6. По коду, не измерено: отсутствие `pyyaml` — `pyyaml required for --check`, rc=3 (`:26-29`);
   исчерпание 100 попыток — `failed to generate unique ID after 100 attempts`, rc=1 (`:40-46`); в CLI
   недостижимо, закрепляется на уровне функции.

Одна правка контракта — две границы `--check` сегодня дают traceback с rc=1: путь-каталог
(`IsADirectoryError`) и файл с битым UTF-8 (`UnicodeDecodeError`). Цель — чтение через
`lib.read_page.read_page` и именованный отказ:

```text
not a file: {yaml_path}                                                     rc=2
{yaml_path}: файл не является валидным UTF-8 (байт 0xNN на позиции P из S)   rc=2
```

Вторая строка собирается из `utf8_message(err)` (`lib/read_page.py:48-50`).

### 3.8 Миграторы (Решение 8, `gramax-o0q.35`)

Исход «не объединять»: обход дерева остаётся семью копиями с разными фильтрами. Основание каждой:

| Место | Исключения | Основание раздельной копии |
|---|---|---|
| `lib/md_link_parser.py:63-64` | `.gramax` | канон контура ресурсов; получает предикат `exclude` (Решение 1) |
| `validate_structure.py:587-595` | `.gramax`, `.git`, `node_modules`, `tests/`, фикстуры, поддеревья вложенных root | владелец правил границ (ADR-0020, FR-120); тот же предикат передаёт парсеру |
| `validate_render.py:238-243` | `.gramax` | иная модель входа: список путей, файлы и каталоги, объединение через множество |
| `validate_comments.py:175-178` | `.gramax` | одиночный путь — файл или каталог |
| `parse_comments.py:141-143` | `.gramax` | одиночный путь; фильтр внутри цикла |
| `migrate_mermaid.py:170-171` | `.git`, `.gramax` | самодостаточный stdlib-инструмент потребителя (ADR-0013, NFR-052); читает произвольную часть репозитория |
| `migrate_nav_codespans.py:285-286` | `.gramax` | замороженный ручной диагност (ADR-0029 Решение 3); побайтовая копия — прецедент RES-005 |

Карточка и требование называют пять копий; `git grep` находит семь — обходы валидатора и парсера
комментариев существуют с 2026-05-08 (`git log --diff-filter=A` → `d8eb851`) и в свёрку не попали.
Дрейф, давший ложную находку, не найден. Условие возврата: восьмая копия либо расхождение фильтров,
давшее ложную находку.

Ожидаемое поведение двух непокрытых случаев (замер §2):

1. `migrate_mermaid.py`, N legacy-блоков в одном файле: отчёт даёт N строк `путь:строка` и rc=1;
   `--fix --yes` создаёт N файлов `<page-slug>-existing[-N].mermaid` (нумерация продолжает
   существующие файлы), DSL побайтово с завершающим LF, на месте каждого блока — самозакрытый тег с
   `width="800px" height="450px"`, rc=0; повторный отчёт — `To-migrate: 0`.
2. `migrate_nav_codespans.py`, перечисление без маркера (нет слова направления в окне и нет пункта
   списка с меткой): спаны остаются SUBJECT — в отчёте их нет, `--fix --yes` их не трогает, счётчик
   `SUBJECT:` растёт; если NAV в каталоге нет — rc=0, `To-migrate: 0`. Основание — Решение 3
   ADR-0016 (без маркера направления классификация не отличает NAV от SUBJECT) и точечный проход
   FR-235, который судит такие спаны вручную.

Копия маски кода в `migrate_nav_codespans.py:89-108` не получает вторую фазу (Решение 2).

### 3.9 Временный протокол ADR-0016 Решение 2 (Решение 9, пункт 9 координатора)

Протокол снят: его условие конца исполнено. Инференс `.md` и `_index.md` пришёл в payload nauta
коммитом `38fe3e6` (2026-08-31) и стоит в доставленном файле: `scripts/validate-content.py:512-544`
(`:537-539` — `+.md`, `:540-543` — `_index.md`, `is_file()` на всех трёх шагах); базис скриптов
дерева — `.nauta-scripts-basis.yaml`: `nauta_version: "2.27.0"`, `synced_at: "2026-11-22T07:40:40Z"`.

Что предписывает контракт после снятия:

1. Обе формы валидны и в движке (факты 5–7 §1), и в обоих валидаторах гейта.
2. Новые и правимые ссылки следуют FR-080 — без расширения; это план самого ADR-0016: Решение 2
   «лишь откладывает момент, с которого новые ссылки этого репозитория переходят на канонический
   синтаксис».
3. Массовой перелинковки нет: FR-080 не требует миграции существующих ссылок с `.md`; в `docs/` их
   108 файлов (704 вхождения), в переписи снимка — 548 из 567.

Остановленная ветвь (расхождение двух измеренных сторон, решение — за координатором). Текущий
официальный текст вендора предписывает форму с расширением — `gramax-article-syntax.md:91` («На
статью: путь относительно текущего файла, с `.md`»), `:92` («На раздел:
`[текст](./section/_index.md)`»), `:332` («Ссылки на статьи -- относительный путь с `.md`»), тогда
как FR-080 опирается на то, что редактор срезает `.md` при пересохранении (ADR-0016, Context:
«штатный редактор при пересохранении сам срезает `.md`»). Что редактор пина пишет в файл при
сохранении, не измерено; замер — в шаге D12: открыть в редакторе страницу с обеими формами,
сохранить без правок, прочитать diff.

Вывод мигратора `migrate_nav_codespans.py` (href с `.md`) не меняется: это валидная форма, сам скрипт
— ручной диагност (ADR-0029 Решение 3); абзац его докстринга со ссылкой на временное рассогласование
(`:38-44`) синхронно переписывается Dev.

### 3.10 Реестр тегов (Решение 10, пункт 10 координатора)

Правило членства (решение координатора): тег входит в `plugins/gramax/gramax-tags.json`, когда на
пине исполнены все три условия — он есть в реестре движка; он доступен автору статейной разметки по
записи реестра и схеме (не внутренний ключ компонента); он не legacy-форма, которую редактор
переписывает при сохранении. Документация вендора условием не является. W034 — утверждение о
рендере, поэтому следует реестру движка; «не описан вендором» — иное утверждение, и W034 его не
делает.

Все 24 ключа реестра вне известного набора плагина, с вердиктом:

| Вердикт | Имена | Основание (факты §1) |
|---|---|---|
| входит, `pairedTags` | `alert`, `block-field`, `block-property` | 16, 17: `selfClosing: false`, собственные узлы редактора, парная запись |
| входит, `selfClosingTags` | `db-diagram`, `db-table`, `include`, `term`, `module`, `issue`, `when`, `who`, `see` | 14–16: общий блок редактора, самозакрытая запись |
| не входит: legacy-форма, переписывается при сохранении | `br`, `snippet-link` | 14, 18: `br` → обратный слеш и перевод строки; `snippet-link` → `fragment-link` |
| не входит: внутреннее представление | `formula` | 15, 18: пишется сырым содержимым `$…$` |
| не входит: внутренние ключи компонента | `answer`, `error`, `unsupported`, `inlineHtmlTagComponent`, `blockWithInlineHtmlTag`, `blockHtmlTagComponent`, `selfClosingHtmlTag`, `inlineHtmlTag`, `blockHtmlTag` | не являются синтаксисом автора; W034 на них — верный сигнал |

Документация вендора не описывает ни одно из двенадцати входящих имён; все они рендерятся движком —
доказательство — запись реестра и схема (факты 12, 16, 17). `issue` ведёт на внешний трекер, адрес
которого зашит в коде движка (`elements/issue/logic/getIssueLink.ts:1-3`); `module` — метка
с иконкой (`elements/module/render/Module.tsx:3-9`); `term` читает свойство
каталога `terms` (`elements/term/model/term.ts:14`); `db-diagram` и `db-table` читают схему через
менеджер таблиц, зависимости которого не установлены (RES-010). Для автора это значит: тег
отрендерится при нужных данных, плагин его не документирует и не проверяет, кроме названного ниже.

Целевой `gramax-tags.json` (три списка; остальные ключи без изменений):

```json
"pairedTags": ["note", "tabs", "tab", "html", "comment", "color", "highlight", "fragment-link", "cut", "question", "questionAnswer", "table", "tr", "td", "alert", "block-field", "block-property"],
"selfClosingTags": ["view", "snippet", "openapi", "mermaid", "video", "icon", "image", "drawio", "plant-uml", "bpmn", "fragment", "property", "inline-property", "img-h", "img-v", "cmd", "kbd", "alfa", "beta", "db-diagram", "db-table", "include", "term", "module", "issue", "when", "who", "see"],
"diagramTags": ["drawio", "mermaid", "plant-uml", "bpmn", "db-diagram"],
```

- `schemaVersion` остаётся `3`: ключи не менялись, списки расширены (прецедент — дизайн writer-sync:
  «расширение списков аддитивно, смена схемы не нужна»). Пины равенства `schemaVersion == 3`
  (`tests/gramax/catalog-validator/ac-135-table-tags-contract.sh:53-54`,
  `tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh:57-61`) остаются зелёными.
- Что W034 больше не сообщает: неподдерживаемую разметку для двенадцати имён. Проверено подменой
  контракта в процессе на фикстуре со всеми 24 ключами: W034 остаются на `br`, `snippet-link`,
  `formula`, `answer`, `error`, `unsupported`, шести внутренних ключах компонента `htmlTag` и
  фиктивном теге.
- Что появляется без правки кода: `alert`, `block-field`, `block-property` входят в
  `pairedTags − balanceTags`, поэтому `check_tags` балансирует их — несбалансированная пара даёт
  ERROR `unpaired <тег>: N open, M close`, как `cut` и `question`. `db-diagram` входит в
  `diagramTags`: тег с `path` и отсутствующей целью даёт W031 (подмена контракта даёт находку
  `W031: файл диаграммы не найден (тег <db-diagram>)`). Правки кода нет.
- Что не проверяется и остаётся именованным пробелом: цель `path` тегов `db-table` и `include` (нет
  точного класса находки — сообщение W031 назвало бы таблицу диаграммой); схема внутри YAML
  `db-diagram` (формат не установлен, RES-010). Условие возврата — первый потребитель или вхождение
  в корпус.
- Существующее исключение не пересматривается: `snippet` остаётся в `selfClosingTags` по FR-172
  (NFR-071), хотя редактор переписывает его в `fragment` на том же основании, что `snippet-link`.

### 3.11 `--strict` валидатора комментариев (Решение 11, пункт 11 координатора)

`plugins/gramax/scripts/validate_comments.py::main()` (`:186-188`). Было:

```python
if any(i.level == "error" for i in issues):
    sys.exit(1)
sys.exit(0)
```

Стало:

```python
has_errors = any(i.level == "error" for i in issues)
has_warnings_strict = args.strict and any(i.level == "warning" for i in issues)
if has_errors or has_warnings_strict:
    sys.exit(1)
sys.exit(0)
```

- Текст справки `--strict` (`:167`, «Warnings → errors.») становится истинным и не меняется.
- Под `--strict` находки `dateTime not ISO 8601 UTC` (`:141-142`) и «у ответа нет user.id»
  (`:153-154`) печатаются с прежней меткой `WARNING` и дают rc=1 — та же модель, что у
  `validate_structure.py:1121-1131`.
- Уровень `info` не эскалируется (AC-129, `tests/gramax/comments/ac-129-multiposition-id.sh:42-48`).
- Строки `:157` (дубликат ответа — `error` под `--strict`) и `:160-161` (отсутствие ключа `answers`
  под `--strict`) не меняются: метка `ERROR` у них была и остаётся.
- Коды выхода: 0 — нет ошибок и под `--strict` нет предупреждений; 1 — есть ошибка либо
  предупреждение под `--strict`; 2 — некорректный вызов.

Ни одна нога стабов волны-3 не закрепляет нынешнее поведение: `ac-139-reply-user-id.sh:39` держит
rc=0 у запуска без `--strict`; единственная нога с `--strict` — `ac-129:43-48` на фикстуре без
предупреждений (1 строка `info`), она остаётся rc=0.

## 4. Совместимость — для пользователей валидаторов

| Решение | Что меняется | Что ломает | Замер «до → после» |
|---|---|---|---|
| 1 | парсер толерантен к битому UTF-8; у валидатора один путь чтения | ничего: прежде вызов парсера падал | traceback → `MdPageError`; ac-133 зелёный до и после |
| 2 | многострочный спан под маской | ничего: находки только исчезают | 0/0 и 96/539 — без изменений |
| 3 | тег с `path` без слэша распознаётся | каталоги с такой формой и битой целью получают W031 | 0 → 0 на корпусах (формы нет) |
| 4 | каталог не резолвится без `_index.md`; файл побеждает каталог | ссылки на каталог без индекса дают ERROR | 0 смен вердикта на 1478 ссылках |
| 5 | новое правило E037 | каталоги с личным путём получают ERROR | `docs/`: 0 после чистки D8; `<корпус>`: 10 |
| 7 | `--check`: отказ вместо traceback | ничего: rc 1 с traceback → rc 2 с именованной строкой | 2 границы |
| 10 | W034 снят на 12 именах; баланс трёх парных; W031 у `db-diagram` | несбалансированные `alert`, `block-field`, `block-property` дают ERROR | `<корпус>`: имена не встречаются |
| 11 | `--strict` эскалирует предупреждения | прогон с `--strict` и предупреждением даёт rc=1 | rc на корпусах не меняется |

Коды выхода всех скриптов сохраняют форму 0/1/2 (rc=3 у `gen_comment_id.py` — отсутствие `pyyaml`).

## 5. Мэппинг NFR и бизнес-правил

| Правило | Чем закрыто |
|---|---|
| BR-004 (одна находка на дефект) | Решения 1, 5: дубликаты E036 гасит `_dedupe_utf8_findings`; E037 — одна на строку |
| BR-025, BR-026, BR-027 (волна-3) | целевые значения — §3 дословно; каждое изменение уровня опирается на факт движка (§1) или замер (§2); баланс новых парных тегов ведёт `check_tags`, в `balanceTags` они не входят |
| NFR-001 (не добавлять ошибок там, где было «ок») | Решения 2, 4, 11: 0 смен вердикта на корпусах; ветка «с флагом — тишина» сохранена |
| NFR-084 (перевод, не удаление) | таблица переводов ниже |
| FR-072, FR-073 | Решение 5: предупреждение writer остаётся под замком `ac-009`; ручная форма (`docs/40-architecture/2026-08-11-writer-rules-disposition.md:103`, по `f551d87`) заменена правилом по замеру |
| FR-196, BR-021…BR-024 (протокол «сначала замер») | Решение 6: вердикт не меняется, протокол не запускается; именованный шаг замеров назван |
| FR-080, FR-082, NFR-002 | Решение 4 — уточнение FR-082 (`is_file()` вместо `exists()`); до трёх обращений к файлу и одного к каталогу на ссылку; Решение 9 — FR-080 без изменений |
| BR-029, BR-030 (волна-4, требование вне индекса) | каждый исход назван — «расширить», «снять», «входит / не входит», «не объединять», «не меняется» — с замером-основанием |

Существующие ассерты, которые меняют цвет или текст (переводятся, NFR-084):

| Ассерт | Сегодня | Цель |
|---|---|---|
| `plugins/gramax/scripts/tests/test_validators_parity.py:116-132` | тег с `path` без слэша — 0 находок | W031; парная форма с существующей целью — 0 |
| `plugins/gramax/scripts/lib/test_link_resolver.py:25-38`, `:43-57` | `resolve_no_ext`, `index.md` | `resolve_link_target`, `_index.md` |
| `tests/gramax/link-form-resolver/ac-009b-section-implicit-index-resolves.sh:19-26` | комментарий «ветку не проверяет» | комментарий переведён, стаб остаётся зелёным |
| `tests/gramax/link-form-resolver/README.md:57-69` | «поведение не specified» | раздел переписан QA-author |

Без изменений остаются: `plugins/gramax/scripts/lib/test_md_link_parser.py` (5 тестов),
`tests/gramax/catalog-validator/ac-133-broken-utf8-traversal.sh`, стабы маски `ac-137`, `ac-137b`,
`ac-144`, пины `schemaVersion == 3`, `test_validators_parity.py:102-113` (`<br/>`), ноги `--strict`
`ac-129` и `ac-139`.

## 6. Контракт с QA-author

Уровни названы; фреймворк и инструмент — выбор QA-author. Имена стабов предложительные: `NNN` —
номер по карте AC требования волны-4. Прецедент in-process проверки — `ac-151`
(`tests/gramax/catalog-validator/ac-151-index-properties-verdict.sh:7-8`).

### 6.1 `gramax-4jf.14` — чтение в парсере (unit, integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-parser-utf8-tolerant.sh` | `tests/gramax/catalog-validator/` | каталог: `a.md` со ссылкой на битый `broken.md` и на `c.md` | `scan_md_resources` возбуждает исключение | одна `MdPageError` с путём `broken.md`, ресурс из ссылки на `c.md` на месте, ни одного traceback | вернуть в `scan_md_resources` строгий `read_text` |
| `ac-NNN-parser-single-mask.sh` | там же | исходники плагина | в `lib/md_link_parser.py` есть `def _mask_code` | 0 определений; одно — в `lib/md_code_mask.py` | вернуть копию в парсер |
| `ac-NNN-parser-no-second-reading.sh` | там же | исходники плагина | есть `_parse_resources` | в `validate_structure.py` нет `_parse_resources` и `_resolve_link_target` | вернуть обёртку |

Вторая и третья — статические проверки исходника; ac-133 остаётся замком интеграционного уровня.

### 6.2 `gramax-o0q.22` (пункт б) — маска (unit, integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-multiline-span-masked.sh` | `tests/gramax/render-linter/` | страница с `<note>…</note>` внутри code-span, разорванного переносом строки | `FAIL`, `ERROR L6: Инлайновый <note>…</note>` | `OK`, rc=0 | убрать фазу 2 |
| `ac-NNN-mask-single-line-unchanged.sh` | unit, `lib/` | 6 спанов: однострочный, перенесённый, два одиночных бэктика в разных абзацах, ряд из 2 против ряда из 3, fence вокруг | — | инварианты 1–3 §3.2; длина текста и число переводов строк сохраняются | применить R2 одним проходом до фазы 1 |

### 6.3 `gramax-o0q.21` — детектор (unit, integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-diagram-tag-without-self-closing.sh` | `tests/gramax/catalog-validator/` | три статьи: тег парный с битой целью, тег без `>` с битой целью, тег парный с существующей целью | 0 находок у первых двух | W031 у первых двух, 0 у третьей; rc=0 | вернуть `/>` в регулярное выражение |

Перевод `DiagramPathWithoutSelfClosingTests` — на уровне unit, с теми же красным и зелёным.

### 6.4 `gramax-o0q.25` — резолвер (unit, integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-dir-without-index-broken.sh` | `tests/gramax/link-form-resolver/` | `[x](section)`, `section/` без `_index.md`, без флага | по ссылке 0 находок | ERROR «каталог без _index.md (раздела в дереве нет)», rc=1 | вернуть `exists()` на шаге 1 |
| `ac-NNN-dir-without-index-flag-ok.sh` | там же | то же с `optionalCategoryIndex: true` | — | находок по ссылке нет (regression guard) | убрать шаг 4 |
| `ac-NNN-file-wins-over-dir.sh` | там же | `section.md` и `section/` без индекса | `section.md` — «сирота» | входящей считается `section.md`, сирот нет | вернуть `exists()` на шаге 1 |
| `ac-NNN-dir-with-index-resolves.sh` | там же | `section/_index.md` и `child.md` | — | rc=0, находок нет (regression guard) | удалить шаг 3 |

Перевод `test_resolve_no_ext_*` (`plugins/gramax/scripts/lib/test_link_resolver.py`) — на уровень unit.

### 6.5 `gramax-o0q.27` — утечка абсолютных путей (integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-absolute-path-leak.sh` | `tests/gramax/catalog-validator/` | четыре статьи: путь в прозе, путь внутри code-span, три формы; отдельно — маскированные формы, `/Users/...`, `$USER`, адрес с `/home/` | находок нет | E037 по одному на строку с находкой; в выводе нет ни имени, ни пути; rc=1; статьи с маскированными формами чисты | удалить вызов `check_absolute_paths` |
| тот же стаб, нога догфудинга | там же | `docs/` | — | 0 находок E037 после чистки D8 | применить маску кода до проверки — нога code-span краснеет |

Имя в фикстуре — фиктивное, из `[a-z]`; реальный путь участника в фикстуру не кладётся. Нога
догфудинга включается после чистки D8 (§3.5).

### 6.6 `gramax-o0q.29` — правило H1

Стаба нет: вердикт не меняется (решение координатора). Прибору нужны две фикстуры §3.6 и ожидания
тира 1; числа ставит шаг замеров D12.

### 6.7 `gramax-o0q.33` — comments-скрипты (unit, integration)

| Стаб | Сюита | Красный | Зелёный | Мутация |
|---|---|---|---|---|
| `ac-NNN-slugify-contract.sh` | `tests/gramax/comments/` | — | инварианты 1–5 §3.7 (таблица «вход → выход, rc») | заменить в `TRANSLIT` значение `ё` на пустую строку — `yozhik…` краснеет |
| `ac-NNN-gen-comment-id-contract.sh` | там же | — | инварианты 1–5 §3.7; 200 ID: все 5 знаков, все различные | сузить `ALPHABET` до цифр — нога формата краснеет |
| `ac-NNN-gen-comment-id-refusals.sh` | там же | `--check <каталог>` и `--check <файл с битым UTF-8>`: traceback, rc=1 | именованная строка в stderr, rc=2 | вернуть `read_text` в `load_existing_ids` |

Первые два стаба рождаются зелёными (тесты на существующее поведение); красным рождается только
стаб отказов.

### 6.8 `gramax-o0q.35` — миграторы (integration)

| Стаб | Сюита | Фикстура | Красный | Зелёный | Мутация |
|---|---|---|---|---|---|
| `ac-NNN-multiple-legacy-blocks.sh` | `tests/gramax/mermaid-adoption/` | страница с тремя legacy-блоками и существующим `page-existing.mermaid` | — | поведение 1 §3.8 (regression guard: код уже ведёт себя так) | взять только первое совпадение `find_occurrences` |
| `ac-NNN-enumeration-without-marker.sh` | `tests/gramax/link-form-migration/` | ``Требования: `a.md`, `b.md` `` без маркера | — | `SUBJECT: 2`, строк `NAV ->` нет, rc=0 | принять метку с двоеточием за маркер пункта |

Оба — regression guards: фикстур с такими случаями в сюитах нет (в каждой не больше одного блока).

### 6.9 Пункты 10 и 11 координатора

| Стаб | Сюита | Красный | Зелёный | Мутация |
|---|---|---|---|---|
| `ac-NNN-engine-tags-known.sh` | `tests/gramax/catalog-validator/` | W034 на 12 именах | 0 W034 на 12 именах; W034 остаётся на `br`, `snippet-link`, `formula` и фиктивном теге; несбалансированный `<alert>` — ERROR `unpaired <alert>`; `<db-diagram path="./missing.yaml" />` — W031 | убрать одно имя из списка; убрать `db-diagram` из `diagramTags` |
| `ac-NNN-comments-strict-escalates.sh` | `tests/gramax/comments/` | `--strict` на фикстуре с плохим `dateTime`: rc=0 | rc=1, метка `WARNING`; нога `info` остаётся rc=0 | убрать `has_warnings_strict` |

По пункту 9 стаба нет: поведение скриптов не меняется.

## 7. Бриф для Dev

**Архитектура:** этот документ; **ADR:** ADR-0028; **Требование:** волна-4 (вне индекса на момент
письма). **Порядок:** заглушки QA-author рождаются красными → код и JSON по §3 → позеленение →
строки `Contract:` из ADR-0028 в `plugins/gramax/CHANGELOG.md` тем же коммитом, что и код.

| Шаг | Карточка | Файлы |
|---|---|---|
| 1 | `gramax-4jf.14` | `plugins/gramax/scripts/lib/md_link_parser.py`, `validate_structure.py` |
| 2 | `gramax-o0q.22` (б) | `lib/md_code_mask.py` |
| 3 | `gramax-o0q.21` | `lib/md_link_parser.py` (`_diagram_tag_re`) |
| 4 | `gramax-o0q.25` | `lib/link_resolver.py`, `validate_structure.py` |
| 5 | `gramax-o0q.27` | `validate_structure.py` — после коммита чистки D8 |
| 6 | `gramax-o0q.33` | `gen_comment_id.py` (две границы `--check`) |
| 7 | пункт 10 | `plugins/gramax/gramax-tags.json` |
| 8 | пункт 11 | `validate_comments.py` (`main`) |

Без правки кода: `gramax-o0q.29` (Решение 6), `gramax-o0q.35` (Решение 8 — «не объединять»), пункт 9
(Решение 9).

Документы к синхронной правке:

- `plugins/gramax/scripts/lib/link_resolver.py:1-7` — докстринг называет `index.md`; заменить на
  `_index.md` и новую сигнатуру.
- `plugins/gramax/scripts/migrate_nav_codespans.py:38-44` — абзац о временном рассогласовании (href
  с `.md` «пока апстрим nauta не инферит расширение»): протокол снят Решением 9.
- `plugins/gramax/README.md`, раздел «Валидация каталога» (`:82` по `f551d87`) — E037, `--strict`
  валидатора комментариев, имена новых тегов реестра.
- `plugins/gramax/skills/writer/SKILL.md:445` (по `f551d87`) — предупреждение остаётся; следующей
  строкой: ту же форму ловит `validate_structure.py` кодом `E037`.
- `tests/gramax/link-form-resolver/README.md:57-69` — раздел «Находка для Dev/SA» закрывается.

Файлы тестов, которые переводятся: `plugins/gramax/scripts/tests/test_validators_parity.py`,
`plugins/gramax/scripts/lib/test_link_resolver.py`.

## Допущения

- Поведение движка в рантайме не измерялось ни по одному факту §1: все факты — чтение исходника на
  пине. Решения 3, 4 и 10 опираются на грамматику, реестр и проверку на ошибки движка, как они
  написаны; живой прогон не делался.
- Проверка на ошибки движка под флагом `optionalCategoryIndex: true` по чтению даёт ложный
  `InvalidRef` на ссылку раздела без индекса: раздел получает виртуальный `_index.md`
  (`FileStructure.ts:653`), а `ResourceManager.exists` спрашивает файл у провайдера
  (`core/logic/Resource/ResourceManager.ts:175-177`). Плагин повторяет рендер-резолв, не эту ветку
  проверки; рантайм не проверялся.
- Поведение `markdown-it` 14.1.1 для многострочного code-span не измерялось: исходник библиотеки в
  репозитории движка на пине отсутствует. Опора Решения 2 — CommonMark и замер «находки не
  меняются» на двух корпусах.
- Что редактор пина пишет в файл при сохранении ссылок без расширения, не измерено (остановленная
  ветвь Решения 9); замер отнесён к шагу D12.
- Форма `/home/<имя>/…` как путь на сервере в документации Linux-сервисов даст находку E037: в двух
  корпусах таких вхождений 0, ложное срабатывание не измерялось. Условие пересмотра — первый такой
  случай у потребителя.
- `docs/` после чистки D8 по правилу E037 не замерялось: чистка шла параллельно. Ожидание — 0
  находок; команда та же, что в §2.
- Числа по `docs/` относятся к базе `f551d87`; рабочее дерево в момент письма содержало ещё статьи
  параллельных ролей.
