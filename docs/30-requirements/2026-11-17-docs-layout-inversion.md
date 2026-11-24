---
title: Инверсия раскладки документации — `content/` → `docs/` с зачисткой исторических артефактов
order: 13
status: draft
date: 2026-11-17
plugin: marketplace
properties:
  - name: Тип контента
    value: [Требование]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [marketplace]
---

# Инверсия раскладки документации — `content/` → `docs/` с зачисткой исторических артефактов

**Опоры:** `docs/00-project/adr/0021-docs-layout-inversion.md`, `scripts/validate-content.py`,
`tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`, `tests/gramax/orphan-references/run.sh`

**Контур И:** файл целиком уезжает в стор (Фаза 3) — собственной capability у него нет.

## Уезжает в стор (Фаза 3)

Каркас требования (все разделы ниже) целиком уезжает в стор в Фазе 3; собственной capability у документа нет, поэтому пара дрейфа с openspec/ не объявляется.

## JTBD

Когда я сопровождаю репозиторий `gramax-marketplace` и вижу, что документация проекта
размазана по двум корням — `content/` (78 статей, каталог витрины) и `docs/` (15 файлов,
внутренние документы), — 260 файлов дерева пришиты ссылками и гейтами к префиксу
`content/`, исторические артефакты эпохи superpowers дублируют implemented-спеки в
`content/30-requirements/`, а каждая новая работа обязана сверяться с картой раскладки,
«что куда писать», я (сопровождающий репозитория) хочу одного корня документации `docs/`
с инверсной раскладкой `docs/<home>`, формально утверждённым списком удалений и
переписанными ссылками и гейтами, чтобы у дерева была одна точка правды о расположении
документов, а каталог не нёс мёртвый груз дублирующих записей.

## Решения PM (связующие, подтверждены 2026-11-17)

1. **Инверсия намеренная.** Переезд `content/` → `docs/` отменяет три зафиксированные
   позиции: ADR-0014 (внутренний GES рендерит `content/` как каталог), диспозицию
   `docs/doc-paths-disposition.md` (миграция `docs/` → `content/` 2026-08-09 — именно её
   это требование обращает) и карту раскладки в `AGENTS.md` (пары
   `content/<home>` → `<адрес>`). Отмену оформляет новый ADR — его пишет SA следующим
   шагом; это требование фиксирует, ЧТО должно держаться, не само архитектурное решение.
2. **«Лишнее» = исторические артефакты, удаляются** по формализованному списку FR-129.
   Список кандидатов составлен PM и здесь формализуется (не изобретается заново).
3. **Принцип разделения:** историческое = запись о завершённой работе (удаляется);
   design-документы живых suite'ов (`tests/gramax/*/ac-*.sh`) остаются.
4. **GES-конфиг вне этого репозитория.** Репоинтинг регистрации витрины
   (`<управление-GES>`: `repositories/tools-ai/gramax-plugin.yaml`, `workspace.yaml`) —
   внешнее последствие, которое это требование именует (см. «Внешние последствия»), но не
   решает — по прецеденту ADR-0014, раздел «Что нужно вне этого репозитория».

## Факты (верификация 2026-11-17, HEAD 1939ae6)

1. `find content -name "*.md" | wc -l` → **78**; каталогов в `content/` — 12
   (шесть домов `00-project, 10-domain, 30-requirements, 40-architecture,
   60-implementation, 70-operations`, `lessons-learned.md` в корне `content/`).
2. `find docs -type f | wc -l` → **15** (6 каталогов); `docs/.doc-root.yaml` существует —
   `docs/` уже является doc-root (`code: GRAMAX-PLUGIN-DOCS`), второй root —
   `content/.doc-root.yaml` (`code: GRAMAX-PLUGIN`).
3. `grep -rl "content/" --include="*.md" --include="*.py" --include="*.sh"
   --include="*.yaml" --include="*.yml" --include="*.json" --include="*.txt" .`
   (без `.git/`, без `__pycache__`) → **260 файлов**.
4. Гейты заскоплены на `content/`: `.nauta-gates.yaml` (C1–C12, C15, C16; бюджеты
   объёма ADR-018); его комментарии прямо предполагают жизнь проекта без `content/`
   (ключ `documentaryCircuit`). Схема `scripts/validate-content.py` после flip Ф9
   (NA-EPIC-83) берёт дефолтный корень как «первый существующий из пары» — после
   переезда это станет `docs/`.
5. Живой гейт `tests/gramax/doc-paths/` (`allowlist.txt`, 17 записей) пинит
   docs/-упоминания в `content/` дословно; 12 из 17 записей указывают на строки в
   файлах из списка удаления FR-129.
6. `tests/gramax/nauta-integration/ac-003-doc-root-contract.sh` ассертит существование
   `content/.doc-root.yaml` и `content/_index.md` и зелёность `validate-content.py`;
   `ac-004…ac-006` ассертят миграцию adr/requirements/reports в `content/<…>`.
7. Сплит `content/60-implementation/acceptance/` по факту — **9 датированных файлов**:
   3 записи-приёмки 2026-05 (исторические) и 6 at-design-документов 2026-08-11/13.
   Каждый at-design прямо называет живой suite: mermaid-adoption →
   `tests/gramax/mermaid-adoption/` (10 ac-файлов), validation-contract →
   `tests/gramax/catalog-validator/` (24), writer-consumer-rules →
   `tests/gramax/writer-consumer-rules/` (11), cross-catalog-retraction →
   `tests/gramax/cross-catalog-retraction/` (9), link-form-contract-migration →
   `tests/gramax/link-form-migration/` (7), link-form-contract-resolver →
   `tests/gramax/link-form-resolver/` (8). Примечание: кандидат PM формулировал сплит
   как «4 записи / 5 at-design» — фактический сплит 3/6; принцип решения 3 разрешает
   каждый файл однозначно, арифметика кандидата скорректирована (см. Открытые вопросы).
8. `content/60-implementation/test-reports/` — **10 отчётов + `_index.md`**: 5 отчётов
   эпохи superpowers (2026-05-08…2026-08-10) и 5 отчётов живой эпохи at-design
   (2026-08-12/13). Граница эпох — 2026-08-11.
9. Provenance-шапки `tests/gramax/catalog-validator/ac-014…ac-020` и
   `tests/gramax/orphan-references/run.sh` ссылаются на
   `docs/superpowers/specs/2026-08-1x-…-design.md` — файлы из списка удаления;
   указатель после удаления ведёт в пустоту, переписать «на новый путь» нельзя
   (пути-приёмника нет).

## Scope

### In scope

- Полный переезд `content/<X>` → `docs/<X>` (FR-124) и переписывание ссылающихся
  файлов (FR-125), гейтов (FR-126), карты раскладки (FR-127).
- Слияние двух doc-roots в один (FR-128), формальный список удалений (FR-129) и
  фиксация исчезновения предмета suite `doc-paths` (FR-130).

### Out of scope

- Сам ADR об инверсии, порядок коммитов и механика слияния схем — SA.
- Ревизия/ретирмент suite `doc-paths` — решение SA (FR-130 фиксирует только факт).
- Внешний репоинтинг GES-конфига в `<управление-GES>` — отдельный шаг вне репозитория.
- Редактирование содержимого переезжающих статей сверх переписывания путей.

## Функциональные требования

- **FR-124 (полный переезд, тождественная карта):** весь каталог `content/` переезжает в
  `docs/` с сохранением структуры: `content/<X>` → `docs/<X>` для всех шести домов
  (`00-project`, `10-domain`, `30-requirements`, `40-architecture`,
  `60-implementation`, `70-operations`), включая `content/lessons-learned.md` →
  [Lessons Learned — gramax marketplace](../lessons-learned.md) и `_index.md` каждого
  дома. Имя и относительный путь каждого переезжающего файла не меняются — меняется
  только корень. Каталог `content/` после переезда не существует.
- **FR-125 (переписывание ссылающихся файлов):** все 260 файлов, ссылающихся на
  `content/`, переписываются: указатель (POINTER — ссылка, по которой читателя
  приглашают перейти) переписывается на `docs/<X>`; указатель на удаляемый по FR-129
  артефакт не переписывается «на новый путь» (пути-приёмника нет), а снимается или
  переформулируется; запись (RECORD — упоминание пути внутри свидетельства о
  состоявшемся прогоне/решении: процитированная команда, таблица hits с вердиктами,
  список исключений на дату решения) в исторических ADR сохраняется дословно
  (см. NFR-003). Множество включает suite-файлы, пинлящие `content/`:
  `nauta-integration/ac-001…ac-008` (в т.ч. ac-003 переворачивает пин корня на
  `docs/.doc-root.yaml`), provenance-шапки `catalog-validator` и
  `orphan-references/run.sh` (факт 9), `doc-paths/allowlist.txt`.
- **FR-126 (ре-ключ гейтов):** `.nauta-gates.yaml` перепрофилируется с `content/` на
  `docs/`: C1–C12, C15, C16 и ключи бюджетов объёма (ADR-018) действуют на `docs/` как
  на корень документарного контура. Ключ `documentaryCircuit: absent` НЕ
  устанавливается — контур остаётся, меняется адрес корня (проект не живёт «без
  документарного контура», он его переносит).
- **FR-127 (карта раскладки и корневой промт-слой):** карта раскладки в `AGENTS.md`
  перегенерируется повторным прогоном
  `/Users/<имя>/.zcode/cli/plugins/cache/nauta/nauta/2.23.0/bin/init.sh` (канон на
  момент работ; точная командная строка с `--profile classic` и шестью
  `--map-home content/<home>=docs/<home>` — ADR-0021, Поправка B1) так, чтобы
  пары домов читались как `content/<home>` → `docs/<home>` (канон-маркер плагина
  переразрешается на новые адреса); упоминания
  `content/` в `AGENTS.md` и `CLAUDE.md` (в сумме 42 файла-упоминания входят в те же
  260) переписываются на `docs/`; правило «тест-отчёты никогда не пишутся в content/»
  переформулируется на `docs/60-implementation/`.
- **FR-128 (слияние двух doc-roots):** в дереве остаётся ровно один `.doc-root.yaml` —
  `docs/.doc-root.yaml`. Он вбирает модель свойств `content/.doc-root.yaml`
  (enum «Тип контента» как объединение значений обоих корней, enum «Плагин»,
  `filterProperties`); точная редакция YAML — SA/Dev. [Документы](../_index.md) вбирает роль
  `content/_index.md` — становится корневым индексом объединённого каталога (разделы-дома
  от «Проект» до «Эксплуатация» + ссылка на `lessons-learned.md`). `content/.doc-root.yaml`
  и `content/_index.md` удаляются (`git rm`) после переноса их ролей — это поглощение при
  слиянии, не часть исторического списка удалений FR-129.
- **FR-129 (формальный список удаления — 19 файлов):** удаляются только файлы из
  списка ниже (пути — в координатах до переезда; `git rm`, см. NFR-002). Критерий —
  решение PM 3: историческое = запись о завершённой работе; переезжающее дополнение к
  списку запрещено.
  1. `docs/superpowers/` — 10 файлов: `_index.md`;
     `plans/2026-05-08-apply-project-template.md`; `plans/2026-08-07-nauta-integration.md`;
     `plans/2026-08-09-test-harness-taxonomy.md`; `plans/2026-08-12-healthcheck-port-plan.md`;
     `plans/_index.md`; `specs/2026-05-08-apply-project-template-design.md`;
     `specs/2026-08-07-nauta-integration-design.md`;
     `specs/2026-08-12-healthcheck-port-design.md`; `specs/_index.md`.
     Основание: исторические планы+спеки 2026-05…08; implemented-аналоги живут в
     `content/30-requirements/` (для плана 2026-08-09 — требование
     `2026-08-09-test-harness-taxonomy-and-doc-paths.md` + ADR-0011). Три `_index.md` —
     символьная обвязка удаляемого поддерева.
  2. `content/60-implementation/test-reports/` — 5 отчётов:
     `2026-05-08-diagram-on-demand-qa-report.md`;
     `2026-05-11-remove-diagram-skills-qa-report.md`;
     `2026-05-11-routing-mermaid-drawio.md`;
     `2026-05-12-mermaid-file-based-qa-report.md`;
     `2026-08-10-test-harness-taxonomy-qa-report.md`.
     Основание: отчёты эпохи superpowers (до 2026-08-11); парные записи приёмки и планы
     удаляются тем же списком, содержательное зерно — в `content/30-requirements/`.
     **Остаются:** `2026-08-12-wave-4.2.0-qa-report.md`,
     `2026-08-13-cross-catalog-retraction-qa-report.md`,
     `2026-08-13-doc-root-discovery-qa-report.md`,
     `2026-08-13-link-form-contract-qa-report.md`,
     `2026-08-13-render-killer-linter-qa-report.md` и `_index.md` — отчёты живой эпохи,
     парные оставшимся at-design'ам и живым suite'ам.
  3. `content/60-implementation/acceptance/` — 3 записи:
     `2026-05-08-diagram-on-demand-acceptance.md`;
     `2026-05-11-remove-diagram-skills-acceptance.md`;
     `2026-05-11-routing-mermaid-drawio.md`.
     Основание: записи приёмки завершённой работы 2026-05. **Остаются (at-design
     живых suite'ов):** `2026-08-11-mermaid-adoption-at-design.md`;
     `2026-08-11-validation-contract-at-design.md`;
     `2026-08-11-writer-consumer-rules-at-design.md`;
     `2026-08-13-cross-catalog-retraction-at-design.md`;
     `2026-08-13-link-form-contract-migration-at-design.md`;
     `2026-08-13-link-form-contract-resolver-at-design.md`; и `_index.md`.
  4. `docs/doc-paths-disposition.md` — историческая диспозиция миграции 2026-08-09
     `docs/` → `content/` — той самой, которую инвертирует это требование; её таксономия
     POINTER/RECORD переиспользована в FR-125/NFR-003 дословно по смыслу.
- **FR-130 (suite doc-paths теряет предмет):** после переезда предмет suite
  `tests/gramax/doc-paths/` («несвежие указатели `docs/` внутри `content/`»)
  исчезает физически: сканируемого каталога нет. Требование фиксирует только факт
  исчезновения предмета; ревизия suite'а (ретирмент, пере-ключ на охоту за
  `content/`-указателями в `docs/` с allowlist для документов-записей об инверсии,
  любой иной исход) — решение SA, фиксируемое в ADR инверсии.

## Внешние последствия (именуется, не решается)

- Витрина GES читала `content/` по `content/.doc-root.yaml` (ADR-0014); после инверсии корень —
  `docs/`. Регистрация в `<управление-GES>` (`repositories/tools-ai/gramax-plugin.yaml`,
  секция в `workspace.yaml`) и `git push internal main` — внешние шаги, вне этого требования.
- Инвариант «`.doc-root.yaml` в `content/`» (ADR-0014, двойная нагрузка с
  `tests/gramax/nauta-integration/ac-003`) переворачивается: пин корня в ac-003
  переписывается на `docs/.doc-root.yaml` (FR-125), архитектурную сторону держит ADR SA.

## Нефункциональные требования

- **NFR-001 (только `git mv`):** каждый переезд — `git mv`, никаких delete+create:
  история файлов должна читаться через `git log --follow` после переезда.
- **NFR-002 (только `git rm`):** удаления — `git rm`; список — ровно FR-129 плюс
  поглощаемые `content/.doc-root.yaml`, `content/_index.md` (FR-128).
- **NFR-003 (RECORD дословно):** упоминания старых `docs/`-путей внутри исторических
  записей (ADR, surviving-отчёты) не переписываются: замена пути превратила бы запись о
  решении в утверждение о сегодняшней раскладке (та же логика, что allowlist
  `doc-paths`; эталон — `content/00-project/adr/0009-…md:272`).
- **NFR-004 (гейт зелёный на каждом коммите):** `bash scripts/check.sh --fast` зелёный
  после каждого коммита цепочки миграции — дерево не проходит через красные
  промежуточные состояния.
- **NFR-005 (переезд и правка раздельно):** коммит перемещения не смешивается с правками
  содержимого — иначе git не распознаёт переименование (R100) и `--follow`-история рвётся.

## Acceptance Criteria

- [ ] **AC-001 (FR-124, переезд полон):** `test ! -d content && echo OK` → OK;
  `test -f docs/lessons-learned.md && test -f docs/00-project/_index.md &&
  test -f docs/30-requirements/_index.md && test -f docs/60-implementation/_index.md &&
  echo OK` → OK.
- [ ] **AC-002 (FR-124, история сохранена):** `git log --follow --oneline --
  docs/lessons-learned.md | wc -l` → ≥ 2 (переименование распознано, предыстория видна).
- [ ] **AC-003 (FR-125, ссылок на content/ нет):** команда из факта 3 после переезда
  возвращает пусто, КРОМЕ явно перечисленных в ADR исключений — документов-записей об
  инверсии (`docs/30-requirements/2026-11-17-docs-layout-inversion.md`, ADR инверсии);
  полный список исключений фиксирован в ADR.
- [ ] **AC-004 (FR-125/FR-129, указателей на удалённое нет):**
  `grep -rn "doc-paths-disposition\|superpowers/\|2026-05-08-diagram-on-demand-qa-report\|
  2026-08-10-test-harness-taxonomy" --include="*.md" --include="*.sh" docs/ plugins/
  tests/ scripts/ | grep -v "adr/"` → пусто, КРОМЕ построчных RECORD-исключений,
  зафиксированных в `tests/gramax/docs-migration/at-design.md` (напр. выживший отчёт
  wave-4.2.0:258 цитирует удалённый отчёт — RECORD; само требование цитирует FR-129
  дословно — самоссылка); упоминания в исторических ADR — RECORD, допустимы по NFR-003.
- [ ] **AC-005 (FR-126, гейты переехали):** `grep -v '^#' .nauta-gates.yaml |
  grep -n "content/"` → пусто; `grep -n "documentaryCircuit" .nauta-gates.yaml` → пусто;
  `uv run scripts/validate-content.py` → exit 0.
- [ ] **AC-006 (FR-127, карта перегенерирована):** `grep -n "→ content/00-project"
  AGENTS.md` → пусто; `grep -c "docs/00-project/" AGENTS.md` → ≥ 1; все шесть домов в
  карте резолвятся в `docs/`. (Проверка по правой стороне пары: писатель карты
  `bin/init.sh:590` захардкоживает левую `content/<home>/ →`, grep по ней вечно красный,
  а правка managed-блока не переживает следующий прогон — ADR-0021, останов ветки SA.)
- [ ] **AC-007 (FR-128, один doc-root):** `find . -maxdepth 2 -name ".doc-root.yaml"
  -not -path "./.git/*"` → ровно одна строка, `docs/.doc-root.yaml` (ограничение глубины
  обязательно: в дереве 39 отслеживаемых `.doc-root.yaml`, из них 37 — фикстуры сюит
  и payload плагина, кл. 6 ECOSYSTEM — переживают миграцию);
  `grep -c "Требование" docs/.doc-root.yaml` → ≥ 1 (модель свойств вобрана);
  `grep -c "_index.md" docs/_index.md` → ≥ 6 (разделы-дома + журнал).
- [ ] **AC-008 (FR-129, список удаления исполнен):** для каждого из 19 путей FR-129
  `test ! -e <путь>` — все отсутствуют; контроль остающихся:
  `test -f docs/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md &&
  test -f docs/60-implementation/test-reports/2026-08-13-render-killer-linter-qa-report.md &&
  echo OK` → OK.
- [ ] **AC-009 (FR-130, предмет исчез и решён):** `test ! -d content` (AC-001);
  `grep -c "doc-paths" <ADR инверсии>` → ≥ 1 (решение по suite зафиксировано в ADR).
- [ ] **AC-010 (NFR-001/002/005, только R и одобренные D):**
  `git diff --name-status 8b6332d..ad7f1a4 -- content/ docs/` — строки `A` отсутствуют;
  строки `D` — только 19 путей FR-129 + `content/.doc-root.yaml` + `content/_index.md`;
  строки `M` — только на стороне `docs/` (слияние ролей: [Документы](../_index.md),
  `docs/.doc-root.yaml`), на стороне `content/` M запрещены (там только `R`/`D`);
  остальные строки — `R`/`R100`. Окно заморожено на цепочку миграции: `8b6332d` — старт
  Dev-цепочки (после коммита сюиты docs-migration: новые файлы сюиты в диф не попадают),
  `ad7f1a4` — конец цепочки D4. Пост-цепочечные коммиты (фикс `docs/overlays`, регистрация
  отчёта qa-057, ре-ключи ассертов) за окном не аудируются этим AC — их дисциплина
  обеспечивается гейтами их собственных коммитов. (Правка PM 2026-11-18: открытый
  `..HEAD` ронял бы AC-010 на любом легитимном пост-цепочечном коммите, трогающем `docs/`.)
- [ ] **AC-011 (NFR-003, RECORD дословен):** `sed -n '272p'
  docs/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` содержит
  `docs/adr/` дословно.
- [ ] **AC-012 (NFR-004):** `bash scripts/check.sh --fast` → exit 0. (Warden-семантика:
  честного «красного сейчас» нет — NFR-004 требует зелёный на каждом коммите, включая
  текущий; stub краснеет, если любой коммит цепочки сломает быстрый гейт.)

## Инварианты и Safeguards

- **Полнота переезда:** каждый `.md` из `content/` либо переименован (`R`), либо входит в
  список удаления FR-129, либо поглощён корнем (`content/_index.md`) — ничего третьего
  (AC-010).
- **Один корень:** после миграции ровно один `.doc-root.yaml`; второго раунда «двух
  корней» быть не должно (AC-007).
- **Записи неприкосновенны:** RECORD-строки исторических ADR и surviving-отчётов не
  редактируются (NFR-003, AC-011).
- **Секреты/PII:** N/A — требование оперирует путями и процессом; правило маскирования
  внутреннего хоста (ADR-0014) продолжает действовать для новых текстов.

## Открытые вопросы (решение SA)

1. **Судьба suite `doc-paths`** (FR-130): ретирмент или пере-ключ на `content/`-указатели
   в `docs/` с allowlist для документов-записей об инверсии. Требование не предрешает.
2. **Состав enum «Тип контента» после слияния** (FR-128): какие значения обоих корней
   (`Приёмка`, `Тест-отчёт`, `План`, `Спека`, `Гайд`…) переживают удаление 19 файлов;
   допустимы ли пустые значения enum — решает SA/Dev при редакции YAML.
3. **Скорректированный сплит acceptance** (факт 7): кандидат PM — «4 записи / 5
   at-design», верифицировано «3 / 6»; список FR-129 следует верифицированному сплиту по
   принципу решения PM 3. Если PM считает иначе — правка списка до старта Dev.
4. **Нумерация и суперседства ADR инверсии:** какой номер, какие позиции он явно
   отменяет (ADR-0014, диспозиция, карта раскладки) — SA.

## Бриф для SA

**Требование:** `docs/30-requirements/2026-11-17-docs-layout-inversion.md`
**Фаза:** инверсия раскладки `content/` → `docs/`, слияние doc-roots, зачистка
исторических артефактов по FR-129.

**Спроектировать:** ADR инверсии (отмена ADR-0014/диспозиции/карты — решение PM 1);
порядок коммитов (удаление FR-129 до/после `git mv`, NFR-004/005); редакцию
`docs/.doc-root.yaml` (объединение моделей свойств, FR-128); судьбу suite `doc-paths`
(FR-130, открытый вопрос 1); ре-ключ `.nauta-gates.yaml` и `nauta-integration`
(AC-005, FR-125); внешний репоинтинг GES — именовать в Consequences ADR, не решать.
**Бизнес-правила для валидаций:** инвариант полноты переезда; NFR-003.
**Acceptance criteria для проверки архитектуры:** AC-003, AC-005, AC-007, AC-010, AC-011.
