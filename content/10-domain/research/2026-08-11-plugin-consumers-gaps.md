---
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax]
---

# RES-002: Где потребителям не хватило инструкций плагина

Дата: 2026-08-11
Автор: PM + 6 разведчиков (Explore, Sonnet)
Тип: экспресс-исследование, вход для BA/SA и формирования бэклога

## Метод и охват

Найдены локальные проекты с `gramax@gramax-marketplace: true` в `.claude/settings*.json` — около 30 репозиториев.
Разобраны шестью параллельными агентами по кластерам; искали расхождение между тем, что предписывает
плагин (`writer`, `mermaid`, `drawio`, `comments-*`, `review-agent`), и тем, что потребители сделали в реальности.

| Кластер | Репозитории | Роль |
|---|---|---|
| Референсный потребитель | `Devel/mango-cti-rest` | 9 локальных скиллов, включая `gramax-catalog` |
| Процессный | `ecosystem/process_design` (+3 отставшие рабочие копии одного репо) | гейты C11/C12, скилл `plugin-ops` |
| Докъ-репозитории | `knowlage/{gramax-user-docs,moex,commerical-knowlage,json-rpc-docs,tsn-assistant}` | чистые потребители `writer`/`mermaid` |
| Шаблоны | `knowlage/project_template`, `knowlage/project-template`, `Devel/project-template`, `Devel/dm_template` | концентрат обходных решений |
| Продуктовые репо | `Devel/{cockpit,smb-sales,calendar-booking,showcase-config,ai-em-classify,pg_vector_service,nsmp-json-rpc,naumen-smp-mcp}`, `Devel/clients365/foodplex` | Gramax вторичен к коду |
| Хвост и окружение | `knowlage/sd-ai-assistant`, `knowlage/sales-assistant`, `CursorProjects/Gramax`, `gramax-sync`, `nau-gramax-manager`, `gramax_docportal_mcp`, `Devel/nsmp-plugin` | предыстория и соседние инструменты |

Оговорка о шуме: `grep` по всему дереву репозитория ловит `docs/`, `docs/superpowers/*`, `.claude/plugins/*` —
это не Gramax-контент. Счётчики диаграмм ниже — только по `content/` (там, где лежит `.doc-root.yaml`).

## Находки

### G1. Валидатор каталога переизобретён ~20 раз — при том что он есть в плагине

Каждый кластер независимо написал `scripts/validate-content.py` с кодами C1–C14: обязательность `_index.md`,
`_index.md` без `properties:`, property не объявлен в `.doc-root.yaml`, плейсхолдеры `{{...}}`, bloat,
битые ссылки (C9), статьи-сироты (C10), бюджеты объёма (C11–C14). При этом плагин **уже поставляет**
`scripts/validate_structure.py` с частью тех же проверок (`check_doc_root`, `check_no_index_in_root`,
`check_subfolders_have_index`, `check_frontmatter`, `check_tags`, `check_no_drawio`).

- Доказательство: `plugins/gramax/scripts/validate_structure.py:32-198` против
  `knowlage/project_template/scripts/validate-content.py:250-265`,
  `knowlage/gramax-user-docs/scripts/validate-content.py:26-200`,
  `Devel/mango-cti-rest/scripts/validate-content.py:246-262`,
  `ecosystem/process_design/scripts/validate-content.py:250-258`.
- Плагинный валидатор упомянут только внутри `skills/writer/SKILL.md:293` и `README.md:69` — ни один
  из разобранных проектов на него не ссылается.
- Область: каталог/валидация, discoverability. Уверенность: высокая.

### G2. Список Gramax-тегов задублирован вручную у каждого потребителя

Валидаторы потребителей несут собственную regex-таблицу тегов (`<mermaid path>`, `<image src>`,
`<openapi src>`, `<snippet id>`, legacy `[drawio:...]`) с комментарием-контрактом
«новый Gramax-тег = новая строка». Плагин не отдаёт машиночитаемого списка поддерживаемых тегов,
поэтому каждый апдейт плагина требует ручной синхронизации у всех потребителей.

- Доказательство: `knowlage/project_template/scripts/validate-content.py:250`;
  та же таблица в `mango-cti-rest`, `process_design`, продуктовом кластере.
- Область: writer / mermaid / drawio, контракт API. Уверенность: высокая.

### G3. Cross-каталожные ссылки: правило продублировано минимум в пяти проектах

Gramax не резолвит markdown-ссылку между двумя `.doc-root.yaml`-каталогами. Потребители пришли к правилу
«межкаталожные ссылки — только inline code, не markdown-ссылка» и записали его как красную линию.

> **Уточнение (BA, 2026-08-11):** формулировка «плагин об этом молчит» неверна — правило есть в
> `plugins/gramax/skills/writer/SKILL.md:205-207` с первого коммита плагина. Часть проектов написала его
> раньше появления плагина (`sd-ai-assistant`, 2026-04-16), часть продублировала локально, потому что
> плагин не даёт автоматической проверки соблюдения и не показывает рабочего примера через поле `code`
> в `.doc-root.yaml`. Реальный пробел — enforcement и пример, а не отсутствие правила.

- Доказательство: `Devel/mango-cti-rest/.claude/skills/gramax-catalog/SKILL.md:33-35`
  (скилл прямо объявляет себя приоритетным над `gramax:writer`), `CLAUDE.md:325`;
  `ecosystem/process_design/CLAUDE.md:179,264`;
  `knowlage/project_template/CLAUDE.md:72`;
  `Devel/dm_template/docs/overlays/naumen-smp/claude-md-patch.md:22`;
  `knowlage/sd-ai-assistant/CLAUDE.md:54`.
- Побочный эффект: «ловушка C9» — процитированная в обратных кавычках чужая битая ссылка всё равно
  красит статью, потому что валидаторы потребителей смотрят на сырой текст (`process_design/CLAUDE.md:264`).
- Область: writer. Уверенность: высокая.

### G4. Прямой конфликт: file-based mermaid v4.0.0 против валидаторов потребителей

`smb-sales` явно **запретил** отдельный `.mermaid`-файл и предписал инлайновый ```mermaid — потому что
локальный C9-гейт обходит только `*.md` (`ALLOWED_SUFFIXES = {".md"}`) и содержимое вынесенного файла
для него невидимо: «дыра, а не разрешение». Это осознанный отказ от правила плагина, а не дрейф.

- Доказательство: `Devel/smb-sales/CLAUDE.md:222-225`;
  механизм — `Devel/smb-sales/scripts/validate-content.py:26-32`.
- Тот же валидатор унаследован ещё в 7 репозиториях кластера, то есть конфликт латентно присутствует везде.
- Область: mermaid ↔ каталог/валидация. Уверенность: высокая.

### G5. Миграция на file-based mermaid не доехала: старый формат живёт в `content/`

Инлайновые фенсы остались в настоящих Gramax-статьях. Инструмента миграции плагин не даёт.

- `knowlage/moex`: `content/00-project/adr/007-dr-cluster-topology.md:64`,
  `content/00-project/adr/008-pii-masking-integration-log.md:159,243` (3 инлайна, 0 тегов).
- `Devel/mango-cti-rest`: `content/00-project/plans/deploy-1-stand-smoke.md:180`,
  `content/70-operations/network-prerequisites.md:30` — при том что соседние статьи уже на `<mermaid path>`.
- `Devel/naumen-smp-mcp`: 156 корректных тегов и 2 файла в `content/00-project/handoffs/` со старым форматом.
- Область: mermaid. Уверенность: высокая (для moex и mango-cti-rest), средняя (природа дрейфа).

### G6. Знание плагина копируется в локальные скиллы и там расходится

Три поколения одной и той же проблемы: потребителю нужен цитируемый локально свод Gramax-соглашений.

- `Devel/mango-cti-rest/.claude/skills/gramax-catalog/SKILL.md` — «дополняет `gramax:writer`, при расхождении
  побеждают правила отсюда». Плюс собственный маппинг статусов ADR (`Accepted→Approved`, `Proposed→Review`),
  которого в плагине нет (`SKILL.md:44-52`).
- `Devel/naumen-smp-mcp/.claude/plugins/project/skills/gramax-authoring/SKILL.md:92-96,153,163` — переизложение
  правил плагина, местами строже официального скилла.
- `knowlage/sd-ai-assistant/.claude/plugins/sdaa/skills/gramax-authoring/` — исторический предок (создан
  2026-04-16, удалён 2026-04-20 с переходом на плагин). После появления плагина `sales-assistant` локальных
  скиллов уже не заводил — то есть плагин закрыл исходную потребность, но потом снова начал отставать.
- Область: writer, дистрибуция знания. Уверенность: высокая.

### G7. Правило плагина «в корне каталога нет `_index.md`» нарушено повсеместно — включая этот репозиторий

`skills/writer/SKILL.md:63` запрещает `_index.md` рядом с `.doc-root.yaml`. Практика ровно обратная:
`content/_index.md` есть во всех пяти докъ-репозиториях, во всех четырёх шаблонах и в самом
`Devel/gramax`. Валидаторы потребителей (C1) наоборот требуют `_index.md` в каждой папке.

- Доказательство: `plugins/gramax/skills/writer/SKILL.md:63` против
  `knowlage/{gramax-user-docs,moex,commerical-knowlage,json-rpc-docs,tsn-assistant}/content/_index.md`
  и `content/_index.md` в этом репозитории.
- Проверено прогоном: `uv run plugins/gramax/scripts/validate_structure.py content` на собственном репозитории
  даёт `ERROR content/_index.md _index.md not allowed in catalog root`, плюс отсутствие `language`/`syntax`
  в `.doc-root.yaml` и отсутствие `title`/`order` в большинстве статей. **Репозиторий плагина не проходит
  собственный валидатор.**
- Область: writer, догфудинг. Уверенность: высокая.

### G8. «enabled ≠ installed»: включённый плагин не значит доступные скиллы

Дважды независимо: `gramax:writer` не резолвился, хотя `gramax@gramax-marketplace: true` стоял в настройках —
плагин был установлен со `scope=project` для чужого каталога. Диагностики плагин не даёт, ловушку описали
в собственных скиллах эксплуатации.

- Доказательство: `Devel/mango-cti-rest/docs/lessons-learned.md:29` (2026-07-21) и
  `.claude/skills/plugin-maintenance/SKILL.md:24-28` (правило «проверять замером, а не чтением конфига»);
  `ecosystem/process_design/.claude/skills/plugin-ops/SKILL.md:9-16`.
- Смежное: коллизия имён между 17 включёнными маркетплейсами уводила `/project:pm` в чужой промпт —
  потребовался постоянный override в настройках (`plugin-maintenance/SKILL.md:9-11,49`).
- Область: установка/дистрибуция. Уверенность: высокая (для gramax — по mango-cti-rest; в process_design
  тот же механизм разобран на примере nauta).

### G9. Нет фиксации версии плагина — потребитель сам городит пиннинг

Подключение маркетплейса тянет актуальную версию; дрейф поведения между прогонами потребители закрывают сами.

- Доказательство: `knowlage/project_template/scripts/tests/test_central_plugin_pinned_checkout.py`,
  `scripts/test-central-plugin-checkout.sh`.
- Область: установка/дистрибуция. Уверенность: средняя.

### G10. Инфраструктура плагина отстаёт от соседнего `nsmp-plugin` того же автора

- Нет git-хуков: у соседа `install-hooks.sh` + `.githooks/pre-commit` гоняет `check.sh --fast`
  (`Devel/nsmp-plugin/scripts/install-hooks.sh:1-22`).
- Нет разведения «опубликованный marketplace» / «локальный dogfooding» — у соседа пара
  `marketplace.json` + `marketplace-local.json` с разными id, чтобы догфудинг не проверял молча
  уже опубликованную версию (`Devel/nsmp-plugin/.claude-plugin/marketplace-local.json:3`).
- Тесты: у плагина один `test_validate_structure.py`; `validate_comments.py`, `parse_comments.py`,
  `gen_comment_id.py`, `slugify.py` не покрыты. У соседа — 6 `test-*.sh` под единым `check.sh`.
- CI нет ни у того, ни у другого — это не отличие.
- Область: установка/дистрибуция, качество. Уверенность: высокая.

### G11. Комментарии: механизм используют не по назначению и без валидации на стороне потребителя

- `knowlage/gramax-user-docs` перенёс содержательный блок статей («Инварианты и Safeguards») в `.comments.yaml`
  как в сайдкар-хранилище — миграция 28 файлов под собственный ADR-004 Amendment 2 (коммит `f54518f`).
- Там же после ручных правок понадобился «срочный триаж»: 24 ошибки валидатора и **дубли якорей комментариев**
  (коммит `9a80e91`) — плагин поставляет `validate_comments.py`, но в рабочий цикл потребителя он не встроен.
- Область: comments. Уверенность: средняя.

### G12. Функциональные пробелы, закрытые отдельными продуктами

Существование этих инструментов = функциональность, которой в плагине нет:

- `Devel/gramax_docportal_mcp` — поиск и чтение статей **живого** портала (`gramax_search`, `gramax_get_article`);
  плагин работает только с локально склонированным каталогом (`README.md:1-11`).
- `Devel/nau-gramax-manager` — управление workspace Gramax Enterprise Server: `editors.yaml`, `groups.yaml`,
  доступы к каталогам (`README.md:23-30`).
- `CursorProjects/gramax-sync` — массовые git-операции по набору репозиториев через `workspace.yaml` (`README.md:1-5`).
- Область: интеграция/синхронизация. Уверенность: высокая.

### G13. Мелкие, но повторяющиеся

- **Плейсхолдеры шаблона доехали до продакшена**: `knowlage/tsn-assistant/content/.doc-root.yaml:1-3` и
  `content/_index.md:2,5,9-10` держат `{{TSN_CODE}}`, `{{EDITOR_EMAIL}}` при уже наполненном каталоге.
  Проверка C7 у потребителей есть, у плагина — нет.
- **Схема `.doc-root.yaml` шире, чем описано**: у `knowlage/moex` два независимых `.doc-root.yaml`
  (вложенный `content/gramax-internal-docs/`) и property «Сценарий», добавленное внешним overlay'ем.
  Плагин сценарий вложенных каталогов и внешних расширений схемы не описывает.
- **XML-блоки не считаются структурой**: `process_design` пришлось писать свой детектор структурности,
  явно исключающий `<tabs>` и `<snippet>`, иначе Gramax-нативная статья получает заниженную оценку
  (`CLAUDE.md:209`).
- **Утечка абсолютных путей**: `/Users/<user>/...` от внешнего контрибьютора уезжают в публичный Gramax —
  ручной `grep -rn '/Users/' content/` как обязательный шаг ревью (`sd-ai-assistant/CLAUDE.md:55`).
- **Дисциплина объёма**: гейты C11–C14 (строки статьи, кода, суммарный CLAUDE.md+AGENTS.md) с реестром
  замороженного долга `.nauta-gates.yaml` — изобретены в `process_design` (`CLAUDE.md:203-217`) и
  `nsmp-json-rpc` (`CLAUDE.md:38`).

## Что не подтвердилось или уже закрыто

- **Противоречие drawio-тега внутри плагина** (`writer/SKILL.md` учил `[drawio:...]`, а CHANGELOG требовал
  `<drawio path=...>`) — зафиксировано потребителем в `knowlage/gramax-user-docs/docs/research/e5-gramax-plugin.md:53,85,153`,
  но исправлено в плагине 4.1.1 (2026-08-10). Осадок: расхождение обнаружил и задокументировал потребитель,
  а не сам плагин; их research-отчёт до сих пор описывает это как открытый вопрос.
- **drawio не используется нигде**: ноль вхождений `[drawio:`, `<drawio path`, `<Image src` во всех
  разобранных продуктовых и докъ-репозиториях. Скилл поставляется, но практикой не подтверждён.
- **`review-agent`** — ни одного следа использования или обхода ни в одном проекте.
- **Терминологическая коллизия**: `CursorProjects/Gramax` — это Groovy-модуль Naumen SD, а не документация;
  сбивает поиск по экосистеме.

## Кандидаты в бэклог (сгруппировано, без решений)

1. Валидация каталога как публичный контракт плагина: G1, G2, G7, G13 (плейсхолдеры).
2. Устранить конфликт file-based mermaid ↔ валидаторы потребителей и дать миграцию: G4, G5.
3. Собрать в плагин то, что потребители изобрели независимо: cross-каталожные ссылки, статусы ADR,
   вложенные `.doc-root.yaml`, структурность XML-блоков: G3, G6, G13.
4. Дистрибуция и диагностика установки: G8, G9, G10.
5. Комментарии — встроить `validate_comments.py` в цикл потребителя: G11.
6. Решить судьбу неиспользуемых поверхностей (`drawio`, `review-agent`) и границу с внешними
   инструментами (MCP-портал, sync, workspace-менеджер): G12 и раздел «не подтвердилось».
7. Догфудинг: привести собственный `content/` в соответствие с `validate_structure.py` — G7.
