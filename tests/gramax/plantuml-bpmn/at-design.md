---
properties:
  - name: Тип контента
    value: [Прочее]
  - name: Связанное требование
    value: [Авторство PlantUML/BPMN-диаграмм в Gramax]
---

# AT-design: авторство PlantUML/BPMN — навык plantuml

**Размещение артефакта.** По умолчанию at-design живёт в `docs/20-requirements/<req>/`;
здесь он размещён внутри suite (`tests/gramax/plantuml-bpmn/at-design.md`) — бриф
координатора запретил создания файлов вне `tests/gramax/plantuml-bpmn/` (параллельные
потоки в дереве), прецедент — `tests/gramax/docs-migration/at-design.md`.

## Исходный запрос

[Авторство PlantUML/BPMN-диаграмм в Gramax (file-based, без конвертационных
пайплайнов)](../../../docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md)
(FR-141…FR-148, NFR-059…NFR-064, AC-051…AC-062, BR-008…BR-011). Дизайн:
[PlantUML/BPMN-авторство — навык plantuml](../../../docs/40-architecture/2026-11-18-plantuml-bpmn-design.md)
(«Контракт с QA-author» — группировка уровней, состав фикстур, edge cases;
«Контракт триггеров» — точные тексты description/fallback). Размещение —
[ADR-0023](../../../docs/00-project/adr/0023-plantuml-bpmn-skill.md) (вариант Q-1(a) —
форма AC-059 действует как есть). Таксономия suite —
[ADR-0011](../../../docs/00-project/adr/0011-test-harness-taxonomy.md) (плоская,
`ac-*.sh` + `run.sh`, независимая `lib/`). Все указатели резолвятся (проверено на
9355b69).

## Проверки задачи

Уровни — по группировке дизайна («Контракт с QA-author»): AC-051…AC-059,
AC-060/AC-061 — smoke/static на фикстурном каталоге и дереве навыков → integration;
AC-062 — e2e (код возврата композитного гейта). Unit неприменим ко всем AC —
исполняемого кода навык не несёт, скрипты запрещены BR-008; объект проверок —
контрактные тексты `SKILL.md` и фикстуры.

## Scenario coverage

| AC ID | Проверка из требования | Assertion outline | Type | Dev hint (что красит) |
|-------|------------------------|-------------------|------|------------------------|
| AC-051 | `test -f <dir>/<page-slug>-<diagram-slug>.puml` | гейт существования навыка; SKILL.md: target_page + .puml «в той же директории»; Naming convention (`<page-slug>-<diagram-slug>.puml`, `_index.md`→родитель, kebab-case/ASCII/≤30, кириллица→перевод/ввод, запрет автотранслитерации); фикстуры на месте | integration | plantuml/SKILL.md (Workflow + Naming convention) |
| AC-052 | `head -1 \| grep '^@start'` + нет `<plant-uml`/```` ```plant-uml ```` внутри | механика литералы на фикстуре дизайна (исполняется всегда); SKILL.md: @startuml/@enduml, «чистый… без разметки/обёрток» | integration | секция «PlantUML» SKILL.md |
| AC-053 | `grep '<plant-uml path="./' <page>.md` | SKILL.md: `<plant-uml path="./`, `/>` (самозакрывающийся), пустые строки, атрибуты «по явному запросу» (пин-язык Q-4), анти-копирование mermaid-формы «атрибуты width/height обязательны» | integration | секция «Теги вставки» |
| AC-054 | `grep '@startsalt' <file>.puml` | SKILL.md: @startsalt/@endsalt, Salt «в тот же .puml, штатный тег, отдельного механизма нет»; секция «Окружение рендера» (Q-5) | integration | подсекция Salt + «Окружение рендера» |
| AC-055 | `head -1 \| grep '<?xml'` + `bpmn:definitions\|<definitions` | механика литералы на синтетическом Camunda XML (temp, всегда); SKILL.md: BPMN/Camunda/.bpmn, запрет inline-варианта; references/plantuml-syntax.md существует и зарегистрирован (NFR-062) | integration | секция «BPMN (Camunda XML)» + references |
| AC-056 | `grep '<bpmn path="./' <page>.md` | SKILL.md: `<bpmn path="./`, самозакрывающийся; только path (негатив на width/height у bpmn); verify-оговорка «не подтверждён» (Q-4) | integration | секции «BPMN»/«Теги вставки» |
| AC-057 | `ls scripts/ \| grep -icE 'plantuml\|plant-uml\|bpmn'` = 0 | warden (зелёный по рождению, исполняется всегда) + SKILL.md: секция «Стоп-правило», запрет SVG/PNG-конвертаций и локальных рендеров, эскалация SA/PM, запрет императивов конвертации | integration | секция «Стоп-правило» (точка носителя BR-008 п.1) |
| AC-058 | `grep -rliE 'plant-uml\|plantuml\|bpmn' plugins/gramax/skills/` | гейт; description несёт 9 ключей FR-146 + «Только для PlantUML» + указатели gramax:mermaid/gramax:drawio; drawio: BPMN выведен из «сложных схем, BPMN», анти-триггер PlantUML/BPMN | integration | description plantuml + правки drawio/SKILL.md |
| AC-059 | `grep -icE '@startuml\|\.bpmn' mermaid/SKILL.md` = 0 | warden литералы (зелёный по рождению, всегда) + fallback: опции **plantuml**/**bpmn**, gramax:plantuml ≥ 2, «сложных схем, BPMN» убрано, анти-триггер в description; BR-011: «Только для… Mermaid DSL» и «По умолчанию — **mermaid**» сохранены | integration | правки mermaid/SKILL.md (fallback + description) |
| AC-060 | smoke: повторный вызов, ответ «нет» → diff пуст | контрактная половина: SKILL.md «5 строк», перезаписать/другое имя/отмена, «Без явного»; фикстура коллизии на месте | integration | алгоритм коллизии в «Workflow» |
| AC-061 | smoke: прогон без подтверждения на inline-фикстуре → diff пуст | самопроверка фикстуры (fence + {title, scale, float}); SKILL.md: Backward compatib/inline, ```plant-uml распознавание, existing-миграция, опции 1:1, «подтвержд» | integration | секция «Backward compatibility» |
| AC-062 | `bash scripts/check.sh --fast` rc 0 | guard: предмет suite отсутствует → отказ без запуска гейта (прецедент ac-050 export-skill: «зелёный впустую» — вакуумный PASS); после гейта — литеральная литерала AC | e2e | наличие навыка + зелёный --fast |

## Boundary cases

- AC-051: `target_page = _index.md` → page-slug из родительской директории — отдельный
  ассерт (`_index\.md`) и отдельная фикстура (`process/_index.md`).
- AC-051: кириллическая тема — правило «семантический перевод / ввод пользователем»
  проверено позитивно; автотранслитерация — негативный grep `автотранслитер`.
- AC-052/AC-055: механика литерал исполняется ДО гейта существования на валидном
  входе (фикстура / синтетический Camunda XML) — ловит masked failure «зелёно по
  пустоте»: если однострочность сломана, это видно сейчас, а не после Dev.
- AC-055: только файловая форма — негатив `inline[ -]bpmn|bpmn-блок|```bpmn`.
- AC-058: голая литераль AC зелёная на 9355b69 по ЛОЖНОЙ причине («BPMN» в
  «подходит»-строках drawio/fallback mermaid: drawio/SKILL.md:65, mermaid/SKILL.md:27)
  — проверка привязана к description владельца и к удалению BPMN из «подходит».
- AC-059: в mermaid/SKILL.md запрещены ТОЛЬКО литералы `@startuml`/`.bpmn`; слово
  «bpmn» и тег `<bpmn path>` в 4-опционном диалоге — допустимы (пин-текст дизайна).
- AC-060/AC-061: фиксация ответа «нет»/«без подтверждения» — поведенческая половина
  не автоматизируется (см. Error cases / Not covered).

## Error cases

- malformed/mistyped input: N/A в shell-половине — объекты проверок статичны
  (контрактные тексты и фикстуры). Пользовательский ввод существует в
  поведенческих сценариях (ответ «нет» на перезапись, отказ от миграции) — он
  недоступен из shell по построению (см. ниже) и покрыт контрактными ассертами
  («Без явного…», «подтвержд»).
- masked failure (именовано явно):
  - «зелёно по пустоте» у литерал AC-052/AC-055 — снято исполнением механики на
    валидном входе до гейта существования.
  - «зелёно по ложной причине» у литерал AC-058 — снято привязкой к description
    владельца и негативом на «сложных схем, BPMN».
  - «вакуумный зелёный» AC-062 (гейт без предмета suite) — снято guard'ом
    существования навыка до запуска check.sh.
  - копирование mermaid-дефолтов 800px/450px в plantuml (явный edge case дизайна)
    — снято негативом на дословную mermaid-формулу «Атрибуты width и height
    обязательны» + позитивом «по явному запросу».
  - ложный green от несуществующего файла в assert_no_grep — rehearsal-находка:
    аргументы file/pattern в пяти stub'ах были переставлены; исправлено до сдачи
    (см. Rehearsal).

## Not covered (out of scope)

- Поведенческие smokes AC-060/AC-061 в живой сессии («два прогона, diff до/после»):
  у навыка нет исполняемой точки входа, скрипт-эмулятор запрещён BR-008. Suite
  несёт контрактную половину; сам smoke — шаг qa-runner при приёмке (прецедент
  houses-смиоков mermaid AC-008/AC-009 ADR-0010). Артефактные половины
  AC-051…AC-056 (`test -f` на созданном файле, grep тега в статье) — та же
  граница: литералы исполняются qa-runner'ом над результатами сессии авторства.
- Runtime-probe `<bpmn>`/Salt в живом окружении — вне репозитория, релизный
  чек-лист PM (дизайн «Открытые вопросы» п.2). AC, требующего его в этом suite,
  нет.
- Правки drawio/SKILL.md не имеют отдельного AC (файл-план дизайна); их
  контрактная часть folding'ом включена в AC-058/AC-059 (FR-146). Отдельную
  проверку не изобретал — за пределами AC бриф запрещает.
- Негатив «description plantuml не ловит generic-триггеры „нарисуй диаграмму“»
  не проверяем negatively: владельчество generic'ов — свойство роутинга агента
  (ADR-0009 Решение 1), в тексте description его надёжно выразить нельзя.
- Точный синтаксис inline-опций (`{title="…", scale="…", float="…"}`) в фикстуре
  — правдоподобная форма; ground truth движка на форму inline-опций в этом
  дереве не читался. Фикстурные ассерты проверяют только наличие fence и имён
  опций — к синтаксису формы нечувствительны.
- Semver/plugin.json/marketplace.json (Q-3) — вне AC suite'а (release-flow
  Tech-writer).

## Правки существующих тестов

| Тест | Причина правки |
|------|----------------|
| правок нет — явное «нет» (export-skill/ не тронут — параллельный поток; остальные suite не пересекаются по предмету) |

## Добавленные тесты

| Тест | Вид | Почему выбран этот вид |
|------|-----|------------------------|
| `ac-051-puml-created-next-to-page.sh` | integration | контракт workflow + naming в SKILL.md, фикстуры |
| `ac-052-puml-pure-plantuml-content.sh` | integration | литераль-механика на фикстуре + контракт чистоты |
| `ac-053-article-embeds-plant-uml-tag.sh` | integration | контракт формы тега (Q-4) |
| `ac-054-salt-mockup-same-puml-path.sh` | integration | Salt-контур + оговорка окружения (Q-5) |
| `ac-055-bpmn-camunda-xml-authored.sh` | integration | литераль-механика на синтетике + BPMN-контракт + references |
| `ac-056-article-embeds-bpmn-tag.sh` | integration | контракт тега `<bpmn>` + verify-оговорка |
| `ac-057-no-conversion-scripts-invariant.sh` | integration | warden-инвариант + секция «Стоп-правило» (BR-008/BR-009) |
| `ac-058-plantuml-bpmn-trigger-keys.sh` | integration | 9 ключей FR-146 в description + демаркация drawio |
| `ac-059-mermaid-boundary-preserved.sh` | integration | warden литерал + fallback-контракт + BR-011 |
| `ac-060-overwrite-requires-consent.sh` | integration | контракт коллизии (FR-148/NFR-061) + фикстура |
| `ac-061-inline-not-silently-migrated.sh` | integration | inline-политика (FR-145/BR-010) + фикстура |
| `ac-062-composite-gate-fast-green.sh` | e2e | код возврата check.sh --fast под guard'ом предмета |
| `run.sh`, `lib/assert.sh` | инфраструктура | агрегатор и независимая копия lib (suite'ы не шарят lib/) |
| `fixtures/doc-root/*` (5 файлов) | фикстуры | состав задан дизайном, не изобретён |

## Красное состояние на 9355b69 (замерено, не предполагается)

База замера: `git rev-parse HEAD` = `9355b69` (дерево с параллельными потоками —
export-skill и др.; их краснота вне этого suite). Итог `bash run.sh`:
`Passed: 0`, `Failed: 12`, rc 1.

- ac-051…ac-056, ac-058, ac-060, ac-061 — rc 1, ровно одна строка-причина:
  «SKILL.md навыка plantuml отсутствует … (красная причина AC-0NN)» (гейт
  существования; россыпи «паттерн не найден» нет).
- ac-057 — rc 1: та же гейт-причина («секция „Стоп-правило“ … не написана»);
  warden-половина (счётчик скриптов) исполнена и зелёная (замер: 0).
- ac-059 — rc 1: 5 ассертов контрактной половины (нет **plantuml**/**bpmn**
  опций, gramax:plantuml = 0 < 2, «сложных схем, BPMN» присутствует, анти-триггера
  в description нет); warden-половина (литералы `@startuml`/`.bpmn`) исполнена и
  зелёная (замер: 0). Падение только о несделанной работе Dev, не о нарушенном
  запрете.
- ac-062 — rc 1: guard «предмет suite отсутствует — композитный гейт не
  принимается»; check.sh в этом состоянии не запускался (параллельные потоки
  держат дерево транзитно красным — их ошибки не предмет этого suite'а).

## Rehearsal — физическое доказательство достижимости зелёного

Симуляция реализации Dev на design-faithful материалах во временном git-репо
(рабочее дерево не тронуто): plantuml/SKILL.md по пин-текстам дизайна (description
из «Контракта триггеров», секции по скелету), references/plantuml-syntax.md,
mermaid/SKILL.md с 4-опционным fallback и анти-триггером (литералы не внесены),
drawio/SKILL.md без «сложных схем, BPMN», scripts/ без plantuml/bpmn, фикстуры
suite. Итог: ac-051…ac-061 — 11/11 PASS. ac-062 в rehearsal-среде не исполнялся
(требует настоящий scripts/check.sh; его post-gate-половина — дословный перенос
исполненной литералы из ac-050 export-skill).

Попутно rehearsal поймал и исправил до сдачи три класса дефектов моих же stub'ов
(mutation honesty):

1. Переставленные аргументы file/pattern в assert_grep/assert_no_grep пяти stub'ов
   (ac-052…ac-056) — инвертированные/тихо-пропускающие проверки (несуществующий
   файл в assert_no_grep «зелёнит» негатив). Ловится только исполнением на
   синтетике: ac-052/053/054/055/056 падали на simulated SKILL.md там, где должны
   были проходить.
2. Отсутствующий хелпер `assert_no_grep_regex_i` в lib (ac-055) — «command not
   found» вместо ассерта.
3. Сырые backticks в double-quoted строках трёх сообщений (ac-061 ×2 до исправления,
   + находка по всем файлам `bash -n`) — падение на парсинге, недопустимое красной
   линией «stub обязан падать на ассерте».

После исправлений: `bash -n` чист по всем файлам; rehearsal 11/11; замер красного
на 9355b69 — как выше.

## Матрица трассировки

| Критерий приёмки | Именованный якорь теста |
|------------------|--------------------------|
| AC-051 | `tests/gramax/plantuml-bpmn/ac-051-puml-created-next-to-page.sh` |
| AC-052 | `tests/gramax/plantuml-bpmn/ac-052-puml-pure-plantuml-content.sh` |
| AC-053 | `tests/gramax/plantuml-bpmn/ac-053-article-embeds-plant-uml-tag.sh` |
| AC-054 | `tests/gramax/plantuml-bpmn/ac-054-salt-mockup-same-puml-path.sh` |
| AC-055 | `tests/gramax/plantuml-bpmn/ac-055-bpmn-camunda-xml-authored.sh` |
| AC-056 | `tests/gramax/plantuml-bpmn/ac-056-article-embeds-bpmn-tag.sh` |
| AC-057 | `tests/gramax/plantuml-bpmn/ac-057-no-conversion-scripts-invariant.sh` |
| AC-058 | `tests/gramax/plantuml-bpmn/ac-058-plantuml-bpmn-trigger-keys.sh` |
| AC-059 | `tests/gramax/plantuml-bpmn/ac-059-mermaid-boundary-preserved.sh` |
| AC-060 | `tests/gramax/plantuml-bpmn/ac-060-overwrite-requires-consent.sh` |
| AC-061 | `tests/gramax/plantuml-bpmn/ac-061-inline-not-silently-migrated.sh` |
| AC-062 | `tests/gramax/plantuml-bpmn/ac-062-composite-gate-fast-green.sh` |

## Оценка риска

Главный риск предмета — тихое расширение mermaid на plantuml/bpmn-кейсы (ровно то,
что лечил routing-требование 2026-05-11) и тихое возвращение конвертационного
pipeline (анти-ADR-0008). Suite закрывает каждый класс отдельным stub'ом: AC-059 —
гибрид warden (литералы) + контракт (4-опционный диалог, анти-триггер, дефолт);
AC-057 — warden (нулевой счётчик скриптов) + секция «Стоп-правило». Второй риск —
«зелёные по пустоте» механики: снят исполнением литерал на валидных входах до
гейта. Третий — ложный green AC-058 по чужому упоминанию BPMN: снят привязкой к
description владельца. Остаточный риск: поведенческие smokes AC-060/AC-061 и
артефактные литералы AC-051…AC-056 требуют живой сессии qa-runner — это заявлено
в README/Not covered, не скрыто.

## Допущения

- Имена якорей секций SKILL.md взяты из скелета дизайна («Workflow», «PlantUML»,
  «BPMN (Camunda XML)», «Теги вставки», «Naming convention», «Backward
  compatibility», «Окружение рендера», «Стоп-правило», «References»); greps
  опираются на них и на пин-язык («по явному запросу», «5 строк», «Без явного»,
  «existing»). Формулировки AC обязаны матчиться (оговорка дизайна) — если Dev
  разойдётся с пин-языком, соответствующий ассерт честно красный до согласования.
- AC-059 реализован в редакции Q-1(a) — форма требования действует как есть
  (ADR-0023 Решение 1; прецедент условных AC — AC-006 link-form-contract).
- Гибриды warden+contract (AC-057, AC-059, AC-062) — решение QA-author в рамках
  правил: green-born warden не красится принудительно (never forced red); красная
  половина каждого гибрида привязана к конкретному несделанному пункту контракта
  дизайна и заявлена в таблице выше.
- Фикстурный `.doc-root.yaml` — модель чужого каталога потребителя (класс
  фикстурных doc-root, прецедент mermaid-adoption), гейтами репозитория не
  валидируется.
- Регистрация suite в `scripts/check-gramax.sh` (--full) — центрально (PM); правка
  общего гейта этим suite не выполнялась (бриф), suite standalone.

## Допущения верхних ролей (остановы и находки — для координатора)

1. **AC-058 vs голая литераль (находка QA-author).** Буквальный grep требования
   зелёный на 9355b69 — «bpmn» упоминают fallback-строки mermaid/drawio
   («Подходит для сложных схем, BPMN, кастомных стилей»), т.е. ключи есть, но
   принадлежат ЧУЖОМУ владельцу. Stub проверяет наличие ключей у владельца
   (description plantuml) и исчезновение BPMN из «подходит»-списков — иначе AC
   принимал бы дерево до реализации по ложной причине. Правку формулировки AC
   оставляю PM.
2. **AC-059/AC-057 — green-born warden'ы по литеральной форме.** Обе литералы
   зелёные сейчас (замер: 0 и 0); принудительное краснение запрещено методологией.
   Обе получили красную контрактную половину из пин-текстов дизайна (fallback-диалог
   mermaid; секция «Стоп-правило» BR-008), поэтому оба stub'а красные на 9355b69 по
   существу, а warden-половины стерегут контракт всегда.
3. **AC-060/AC-061 — частично неисполнимы как написано в shell.** «Повторный вызов
   навыка» и «прогон без подтверждения» — действия агента; исполняемой точки входа
   нет, скрипт-эмулятор запрещён BR-008. Проверяемая в репозитории часть —
   контракт в SKILL.md + фикстуры; смок-прогоны — qa-runner при приёмке. Не решение,
   а отчёт: смягчать/ретировать AC не вправе.
4. **AC-062 — guard против вакуумного зелёного.** До создания навыка гейт не
   запускается (однострочная красная причина); после — литеральная проверка
   `check.sh --fast` rc 0. Прецедент — ac-050 export-skill. Параллельные потоки
   держат дерево транзитно красным: их падения не предмет этого suite'а, приёмка —
   per-stub standalone (бриф).
5. **drawio-правки без собственного AC** (файл-план дизайна: анти-триггер +
   удаление BPMN из fallback) — покрыты folding'ом в AC-058/AC-059; отдельный
   ассерт вне AC не изобретался (бриф).
