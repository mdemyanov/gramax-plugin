# tests/gramax/writer-sync-470/ — синхронизация writer 4.7.0 с движком 48592b36

Suite тест-дизайна (QA-author, до реализации Dev) для требования
`docs/30-requirements/2026-11-18-writer-sync-470-requirement.md` (FR-161…FR-182,
AC-073…AC-096). Покрывает все 24 AC: AC-073…AC-095 — integration-скрипты по дереву
`plugins/gramax/skills/writer/` + `gramax-tags.json`, AC-096 — e2e-композит
(`bash scripts/check.sh --fast`, код возврата). Уровни назначены
[контрактом с QA-author](../../../docs/40-architecture/2026-11-18-writer-sync-design.md)
дизайна; таксономия — ADR-0011 (плоская структура, `run.sh`-glob, таблица цветов
в README).

**Файл `ac-NNN-*.sh` = AC-NNN требования один к одному** — номера AC требования
глобальные (073–096), отдельная таблица соответствия не нужна. Один AC — один
скрипт; внутри скрипта ассерты AC плюс design-derived ассерты из таблицы
«FR → файл» и решений Q1–Q6 дизайна, каждый помечен источником.

## Размещение suite'а — решение QA-author

**Новый suite**, не расширение существующего. Дизайн называет формат
(«прецедент `tests/gramax/*`»), но не называет suite-цель расширения;
прецедент catalog-validator (расширение волной с продолженной нумерацией)
применён не был — там расширяемый suite и требование валидатора совпадали по
предмету. Здесь предмет — контент скилла writer, а `tests/gramax/writer-consumer-rules/`
принадлежит другому требованию (2026-08-11) и уже подключён к
`scripts/check.sh --full`: 22 красных ассерта там сломали бы живой гейт.
«Одно требование — один suite» — прецедент README catalog-validator.

## Стартовое состояние (2026-11-18, red on a59db10 — до реализации Dev)

| Скрипт | AC | Цвет при создании | Почему |
|---|---|---|---|
| `ac-073-searchphrases-frontmatter.sh` | AC-073 | 🔴 КРАСНЫЙ | `searchPhrases` нигде в дереве writer не упомянут; stub сильнее формулы AC (требует SKILL.md, не любой файл) — по раскладке FR-161 дизайна |
| `ac-074-aliases-frontmatter.sh` | AC-074 | 🔴 КРАСНЫЙ | `aliases` нигде не упомянут; оба места из таблицы FR → файл (structure.md + SKILL.md) |
| `ac-075-quizzes-reference.sh` | AC-075 | 🔴 КРАСНЫЙ | `references/quizzes.md` не существует; NFR-072: question/questionAnswer нет в pairedTags |
| `ac-076-quiz-twelve-types.sh` | AC-076 | 🔴 КРАСНЫЙ | маркерам ranking/matrix негде жить — файла нет (зависимость от AC-075) |
| `ac-077-cut-property-inline-property.sh` | AC-077 | 🔴 КРАСНЫЙ | `<cut`/`<property`/`<inline-property` в blocks.md нет; NFR-072: cut/property/inline-property нет в контракте |
| `ac-078-view-defs-hiding-rewrite.sh` | AC-078 | 🔴 КРАСНЫЙ | переигрывание 3 RES-008 не исполнено: orderby/Kanban/«скрыт»/select/hierarchy-form отсутствуют, старый пример с перевёрнутой семантикой — 2 живых вхождения (негатив) |
| `ac-079-no-gallery-no-gantt.sh` | AC-079 | 🟢 **ЗЕЛЁНЫЙ — warden** | негативное ожидание (чего быть НЕ должно): литеральные формы `<gallery` и `display="Gantt"` в дереве отсутствуют и обязаны остаться отсутствующими (BR-016); Dev формулирует избегание без литеральной формы |
| `ac-080-cmd-kbd-xml-forms.sh` | AC-080 | 🔴 КРАСНЫЙ | XML-форм `<cmd text=`/`<kbd text=` нет; NFR-072: cmd/kbd/alfa/beta нет в selfClosingTags. Под-ассерт `[cmd:` — зелёная регрессия NFR-071 (скобочные формы переживают rewrite) |
| `ac-081-image-scale-size-semantics.sh` | AC-081 | 🔴 КРАСНЫЙ | `scale=` и дословной фразы «реальный размер» нет; img-h/img-v (Q2) нет; NFR-072: img-h/img-v нет в selfClosingTags |
| `ac-082-video-hostings-cover-negative.sh` | AC-082 | 🔴 КРАСНЫЙ | dropbox/mega/cover/embed в blocks.md нет. Внутри — 🟢 warden-ассерт негатива Q4: форма `cover=` (атрибут отсутствует в движке) не воспроизводится нигде в дереве |
| `ac-083-openapi-showschemas-showinfo.sh` | AC-083 | 🔴 КРАСНЫЙ | showSchemas/showInfo в blocks.md нет |
| `ac-084-code-block-section.sh` | AC-084 | 🔴 КРАСНЫЙ | раздела «Блок кода» и highlight.js нет |
| `ac-085-heading-anchors.sh` | AC-085 | 🔴 КРАСНЫЙ | `{#` в blocks.md нет; + SKILL.md-указатель из таблицы FR → файл |
| `ac-086-fragment-canonical-legacy.sh` | AC-086 | 🔴 КРАСНЫЙ | переигрывание 1 RES-008 не исполнено: `<fragment id=`/`fragment-link` нет, «фрагмент» в SKILL.md нет; NFR-072: fragment/fragment-link нет в контракте. Под-ассерты-регрессии зелёные: 'legacy' в blocks.md (legacy-раздел формул), snippet в selfClosingTags (NFR-071), schemaVersion=2 |
| `ac-087-link-md-caveat-rule-preserved.sh` | AC-087 | 🔴 КРАСНЫЙ | оговорки нет; **ловушка**: текущее «без `.md`» формулу `grep 'без .md'` НЕ матчится (бэктик между словами) — Dev обязан дать форму без бэктиков. Регрессия BR-017 зелёная (правило переживает вставку оговорки) |
| `ac-088-doc-root-new-keys.sh` | AC-088 | 🔴 КРАСНЫЙ | logo_dark/relatedLinks/versions/hidden/filterProperty/emoji: в doc-root-schema.md нет; из filter-ключей есть только непрочитываемая filterProperties |
| `ac-089-syntax-enum-style-palette.sh` | AC-089 | 🔴 КРАСНЫЙ | переигрывание (Q1а/Q1г): syntax=XML/Markdown и палитра 11 значений без двухцветных; GitHub Flavored Markdown/Legacy/blue-pink нет |
| `ac-090-gramax-views-storage.sh` | AC-090 | 🔴 КРАСНЫЙ | `.gramax/views` в дереве writer не упомянут |
| `ac-091-lfs-gitattributes.sh` | AC-091 | 🔴 КРАСНЫЙ | lfs/.gitattributes в doc-root-schema.md нет; + LFS-указатели в Guardrails SKILL.md |
| `ac-092-multilanguage-rules.sh` | AC-092 | 🔴 КРАСНЫЙ | мультиязычности в references/ нет; размещение ужесточено до doc-root-schema.md (перенос в structure.md отклонён дизайном) |
| `ac-093-property-types-engine-names.sh` | AC-093 | 🔴 КРАСНЫЙ | docportalVisible, Flag/Many/Text/Numeric/Date нет (справочник описывает Enum\|String); под-ассерт Enum — зелёная регрессия |
| `ac-094-icons-folder.sh` | AC-094 | 🔴 КРАСНЫЙ | `.icons/` в дереве writer не упомянут |
| `ac-095-guardrails-template-inbox-mr.sh` | AC-095 | 🔴 КРАСНЫЙ | template:/.gramax/templates/.gramax/inbox/.gramax/mr в SKILL.md нет (FR-181/FR-182, Q3) |
| `ac-096-composite-check-fast.sh` | AC-096 | 🟡 **ЗЕЛЁНЫЙ — warden, цвет внешне обусловлен** | послепубликационный гейт `check.sh --fast`; на авторской предпроверке (a59db10) — зелёный (тот же старт, что catalog-validator/ac-036), к завершению авторской задачи может быть красным по ВНЕШНЕЙ причине: бриф потока допускает персистентный C1 незарегистрированного дизайн-документа writer-sync до PM-wiring, плюс находки параллельных потоков. Красный результат — триаж по шапке скрипта |

**Итог:** `run.sh` при первом запуске завершается `exit=1` — 22 красных / 2
зелёных скрипта (AC-079 — warden негатива; AC-096 — композитный гейт, зелёный
на авторской предпроверке). Ожидаемое стартовое состояние TDD-цикла, не поломка
suite'а. Зелёные ассерты от рождения внутри красных скриптов и оба зелёных
скрипта — только негативные ожидания (`<gallery`/`display="Gantt"`/`cover=`) и
регрессии существующего контента writer (скобочные `[cmd:`, 'legacy', Enum,
snippet в контракте, schemaVersion=2, правило «без `.md`» backtick-толерантно)
— по прецеденту lessons-learned 2026-05-08 («stubs могут быть частично
зелёными от старта»). Красный цвет каждого из 22 — на a59db10 (2026-11-18),
причина — в сообщении ассерта и шапке скрипта.

## Четыре переигрывания RES-008 и негатив cover — закодированы ассертами, не прозой

| Переигрывание (BR-015) | Где закодировано |
|---|---|
| 1. Фрагменты: канон `<fragment>` + `.gramax/fragments/`, `<snippet>` legacy | `ac-086` — позитивные маркеры канона + NFR-071-regression snippet |
| 2. Ссылки: обе формы резолвятся, правило «без .md» остаётся | `ac-087` — оговорка (одна из трёх фраз) + регрессия правила |
| 3. `<view>`: defs — сокрытие, не отбор | `ac-078` — маркеры orderby/Kanban/«скрыт» + select/hierarchy-form + байтовый негатив старого примера |
| 4. Изображения: `scale`, семантика width/height, без `<gallery>` | `ac-081` (scale + «реальный размер») + `ac-079` (негатив `<gallery`) |
| Негатив `cover` (Q4, по образцу AC-079) | `ac-082` — позитив grep слова в негативной пометке + warden: форма `cover=` отсутствует в дереве |

## NFR-072: контракт тегов едет одним изменением с writer

Дизайн («Контракт тегов», «Контракт с QA-author») включает `gramax-tags.json`
в поверхность integration-проверок. Отдельного AC на контракт требование не
заводит, поэтому диф контракта закодирован внутрь тех AC-скриптов, чьи FR
вводят теги (маркировано `NFR-072` в сообщениях ассертов):

| Скрипт | Контрактные ассерты |
|---|---|
| `ac-075` | pairedTags ⊇ {question, questionAnswer} |
| `ac-077` | selfClosingTags ⊇ {property, inline-property}; pairedTags ⊇ {cut} |
| `ac-080` | selfClosingTags ⊇ {cmd, kbd, alfa, beta} |
| `ac-081` | selfClosingTags ⊇ {img-h, img-v} |
| `ac-086` | selfClosingTags ⊇ {fragment}; pairedTags ⊇ {fragment-link}; **snippet остаётся** (NFR-071); **schemaVersion = 2** |

Все проверки — SUBSET (контракт вправе быть шире), по уроку «неубиваемого
теста» catalog-validator/ac-011: равенство со списками не проверяется никогда,
состояние ADR-0024 (diagramTags, plant-uml/bpmn, schemaVersion 2) не
затрагивается и не противоречит ему. Диф ожидаемо красный до одного изменения
Dev, закрывающего и writer, и контракт (NFR-072: «одним изменением с правками
writer»; запись `Contract:` в CHANGELOG — прецедент NFR-004).

## Ловушки и границы, найденные авторской предпроверкой (для Dev и ревьюера)

1. **AC-087 backtick-ловушка.** Текущая строка правила «Внутренние (без
   `.md`)» не матчится формулой `grep 'без .md'`: `.` паттерна съедает ровно
   один символ, а между «без » и «.md» стоят ДВА (бэктик и точка литерала).
   Зелёный AC-087 требует хотя бы одного вхождения «без .md» без бэктиков —
   естественное место: сама оговорка FR-173. Регрессия правила проверяется
   отдельным backtick-толерантным ассертом, чтобы ловушка не провоцировала Dev
   стирать существующую формулировку.
2. **AC-082 (cover) — амбивалентность позитивного grep** (контракт с
   QA-author дизайна): тест не различает позитивное и негативное употребление
   слова. Дизайн отвечает негативной формой: warden `cover=` запрещает
   воспроизведение формы атрибута; позитивное употребление («cover работает
   так: …») ловится. Смысловый контроль пометки — ревьюер (процессная
   проверка), не гейт.
3. **markdown-`{scale=…}`** (контракт с QA-author): если Dev задокументирует
   `{scale=…}` как рабочую markdown-форму, `'scale='` AC-081 сматчится и на
   неё — по engine-факту (imgSizePlugin.ts:24-25) аннотация применяет только
   width/height. Осознанная слепая зона дизайна; ревью-пункт, НЕ новый гейт.
4. **AC-079 — байтовый негатив без markdown-семантики**: литеральные формы
   запрещены в том числе в код-спанах и код-блоках; негативная проза — без
   воспроизведения формы («тег галереи», «значение Gantt»). То же правило
   применено к старому примеру `<view>` (ac-078) и к `cover=` (ac-082).
5. **AC-075/GES-поверхность**: showIf, mode, shuffleQuestions — docs-only
   утверждения о модуле обучения GES; тест проверяет наличие строк в
   справочнике, не engine-семантику (открытый вопрос 3 дизайна).
6. **Параллельный Dev-поток** добавляет одну строку в «Ресурсы» SKILL.md —
   ни один ассерт suite'а не зависит от порядка/состава списка ресурсов
   (проверено: все привязаны к маркерам контента, не к строкам навигации).

## Находки вне периметра задачи (не чинятся этим suite'ом)

- **Регистрация suite'а.** `scripts/check-gramax.sh` (и заголовок, и секция
  `--full`) НЕ правился — общие скрипты вне зоны потока. Подключение
  `tests/gramax/writer-sync-470/run.sh` — шаг Dev/PM после позеленения
  (прецедент: catalog-validator подключается DEV-002, writer-consumer-rules —
  DEV-004).
- **at-design.md в `docs/`** не создавался по жёсткому правилу изоляции
  потока («только файлы suite'а»); тест-дизайн (сценарий → ассерт → уровень →
  hint) — этот README + шапки скриптов. PM вправе перенести раздел
  «Стартовое состояние» + «Ловушки» в `docs/60-implementation/acceptance/`
  при wiring (прецедент writer-consumer-rules).
- **`docs/.doc-root.yaml:27`** использует непрочитываемую движком форму
  `filterProperties` — эскалация PM из дизайна (открытый вопрос 1), вне среза
  writer; suite её не проверяет.
- **Молчаливое состояние `grammar`**: после публикации writer-sync контент
  writer перестанет называть `syntax: Markdown` валидным значением — если
  собственный `docs/.doc-root.yaml` несёт `Markdown`, это follow-up PM вне
  этого suite'а.

## Запуск

```bash
bash tests/gramax/writer-sync-470/run.sh; echo "exit=$?"
```

Автономен из любого рабочего каталога (`git rev-parse --show-toplevel`,
`$(dirname "${BASH_SOURCE[0]}")`). Каждый скрипт запускается и отдельно:
`bash tests/gramax/writer-sync-470/ac-0NN-*.sh`. Зависимостей, кроме bash/grep/
python3/git, нет; фикстур нет — поверхность проверки: пять md-файлов навыка,
один JSON-контракт, офлайн.

В `scripts/check.sh --fast` / `--full` suite НЕ подключён (см. «Находки вне
периметра»); глобальный гейт на этот suite не опирается.
