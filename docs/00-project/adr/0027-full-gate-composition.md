---
title: "ADR-0027: Полный гейт `--full` релиза 4.10.0 — живая нога вне гейта, именованные отказы, догфудинг валидаторов, статус сюит и удаление overlay-тулинга"
order: 27
status: accepted
date: 2026-11-23
properties:
  - name: Тип контента
    value: [ADR]
  - name: Статус
    value: [Accepted]
  - name: Плагин
    value: [gramax, marketplace]
---

# ADR-0027: Полный гейт `--full` релиза 4.10.0 — живая нога вне гейта, именованные отказы, догфудинг валидаторов, статус сюит и удаление overlay-тулинга

**Status:** Accepted — ратифицировано PM 2026-11-23 по санкции владельца «автономно до push включительно»
(волна-3, решение D6): решения 1–6 приняты как написаны. Поправки при ратификации: (а) в состав `--full`
добавлена 17-я сюита `tests/gramax/gate-composition/` — сторожа состава гейта и текстов репозитория
(стабы AC-143…AC-147, AC-149, AC-150), последним шагом; (б) по OI: OI-1 — задача `gramax-o0q.45` вне волны;
OI-2 — принята карта Решения 5, отдельного AC сюите не заводится; OI-3 — решено в ADR-0026 Решением 8;
OI-4 — пункт 6 задачи `gramax-o0q.40` (правится в nauta); OI-5 — `--strict` в шагах догфудинга в волне-3
не включается, вопрос возвращается при нуле предупреждений.
**Date:** 2026-11-23
**Plugin:** gramax / marketplace
**Опоры:** `docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`,
`docs/00-project/epics/2026-11-23-wave3-contracts-gates-genesis-tree.md`, `scripts/check-gramax.sh`,
`scripts/render-quality/probe.sh`, `tests/gramax/render-quality/run.sh`,
`docs/70-operations/2026-11-21-render-quality-runbook.md`, `tests/gramax/orphan-references/sunset-registry.txt`

## Context

Требование [волны-3](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md) и его D5:
живая нога прибора рендер-проб выносится из `--full` (NFR-085). Замеры 2026-11-23 на HEAD 7553da1:
`bash scripts/render-quality/probe.sh` даёт `fixtures=21 match=0 divergence=21`, rc=1 — пробные страницы убраны
с публикующего инстанса после волны-2, и шаг 18 `scripts/check-gramax.sh` красный всегда, вне сессии замеров.
В сети без pypi.org `uv run --with playwright==1.65.2` падает rc=2 безымянной ошибкой при тёплом кэше, `UV_OFFLINE=1` лечит.
Заголовок `scripts/check-gramax.sh` называет 13 сюит, тело `--full` исполняет 14; `validate_structure.py` и
`validate_comments.py` по `docs/` гейт не зовёт; `cross-catalog-retraction` и `docs-migration` вне гейта без статуса.
Контракты валидаторов — ADR-0026; здесь — состав гейта (`gramax-o0q.1`, `.5`, `.6`, `.9`, `gramax-4jf.13`).

## Решение 1 — живая нога выходит из `--full` в именованный шаг (FR-219, AC-141)

`tests/gramax/render-quality/run.sh` по умолчанию исполняет только офлайн-стабы `ac-*.sh` и остаётся шагом
`--full`-блока; вызов `probe.sh` с дефолтными путями из агрегатора уходит. Живой прогон — именованный скрипт
`scripts/render-quality/live.sh` (обёртка: `probe.sh` с дефолтными путями); гейт не зовёт его ни в одном режиме.
**Почему:** агрегатор возвращается к контракту раннера (ADR-0011 Решение 5), а имя шага адресует сетевую ногу в
ритуале — флаг `--live` на агрегаторе оставил бы два поведения у одного входа. **Ритуал релиза** (отдельного
документа в дереве нет; носитель — новый раздел runbook): (1) `bash scripts/check.sh --full` зелёный на чистом
дереве; (2) шаг замера `bash scripts/render-quality/live.sh` — когда владелец выдал токен и санкцию на публикацию
проб, иначе в релизной заметке «не исполнен», а не зелёный; (3) уборка проб. **Superseded в части** (старые
документы не правятся): ADR-0025 Решение 3 — «`--full` становится сетевым шагом» и следствие «`--full` требует
сети» (Решения 1–2 действуют); Решение 7 дизайна волны-1 — пункт 2 состава `run.sh`; D8 волны-2 — наследование
ADR-0025 как финального: стационарно красная нога — поведение именованного шага, не гейта.

## Решение 2 — именованный отказ с рычагом (FR-219, AC-142)

Класс rc=2 (баннер `REFUSAL <КОД>: <подсказка>`, отчёт не пишется) получает два кода. `PLAYWRIGHT_PIN_UNRESOLVED` —
uv не разрешил `playwright==<пин>` (rc≠0, сигнатура `Failed to fetch` в stderr): обёртка `uv_named_refusal` в
`probe.sh` печатает баннер, rc=2. `RENDER_TARGET_UNREACHABLE` — все факты tier-0 равны `NETWORK_ERR`: `probe.py` отказывает
до тиров 1–2 (сегодня rc=1 постранично — «не измерено» подавалось как «измерено и разошлось»); частичная
недоступность остаётся rc=1 с нотами, как и «цель доступна, проб нет» (`NOT_FOUND`). Подсказки несут рычаг:
«при тёплом кэше повтори с `UV_OFFLINE=1`, иначе прогрей окружение: `bash scripts/render-quality/warm.sh`» и
«проверь сеть, VPN и `baseUrl` конфига цели, затем повтори `bash scripts/render-quality/live.sh`». **Почему без
автофолбэка:** AC-142 требует отказа с рычагом, смена режима разрешения пакета не может быть тихой (ADR-0025
Решение 2). В пути гейта `run.sh` экспортирует `UV_OFFLINE=1` для стабов (офлайн по построению — стаб-портал на
`127.0.0.1`): сеть не запрашивается, промах кэша ловит сигнатура ADR-159; дрейф текста uv — fail-open по имени:
шаг красный, не зелёный.

## Решение 3 — явный статус двух сюит (FR-220(а), AC-143)

`tests/gramax/cross-catalog-retraction` входит в `--full` последним шагом: замер PM 2026-11-23 — 9/9, exit=0, офлайн;
два вложенных прогона `check.sh --fast` стоят около 16 с — принятая цена; условие её README «подключать, когда все
красные позеленеют» исполнено, README и шапка `run.sh` правятся. `tests/gramax/docs-migration` переезжает `git mv` без
правки байтов в `tests/gramax/archive/docs-migration/` со строкой в `tests/gramax/archive/README.md` (свидетельство
инверсии ADR-0021, окно `8b6332d..ad7f1a4`, релиз 4.6.0): её AC-010 судит дифф `base..HEAD` замороженного окна и вне
его красна структурно; цвет на HEAD — `N/A — запуск сюит в этой задаче не разрешён`. **Отступление от ADR-0011 Решение 1**
(живые ассерты выделяются до переезда): AC-003…AC-007 живой природы (один корень `.doc-root.yaml`, нет указателей на
`content/`) не выделены — защита не меняется, сюита не в одном гейте; выделение — OI-1.

## Решение 4 — догфудинг своих валидаторов в `--full` (FR-220(б), AC-144)

Два шага первыми внутри `--full`-блока, до shellcheck — подряд с быстрыми валидаторами `docs/` (шаги 2.5–2.6,
остаются в `--fast`): `uv run plugins/gramax/scripts/validate_structure.py docs` и
`uv run plugins/gramax/scripts/validate_comments.py docs`. Порог 0 ERROR — rc-контракт валидатора без `--strict`:
rc≠0 даёт FAIL. Предупреждения печатаются полностью и гейт не красят, флаги подавления не вводятся; каждое
закрывается правкой либо принимается записью в журнале приёмки волны с числом. Замер 2026-11-23 (HEAD 7553da1,
обе команды): `validate_structure` — rc=0, 0 ERROR и 3 WARNING W034 (плейсхолдеры `<home>`, `<file>`, `<raw>`;
AC-148) с этим файлом в дереве, до него 1 ERROR — битая ссылка ADR-0026 на ADR-0027; `validate_comments` — rc=1,
4 ERROR, 0 WARNING — ложные `invalid comment id format` на примерах синтаксиса в code-span, маски кода нет.
**Зависимость:** порог AC-144 достижим только после gramax-4jf.13 (маска `_mask_code` в `validate_comments.py` и
`parse_comments.py`, ADR-0026); шаг подключается после правки, ожидание 0 ERROR — замер той же командой. В `--fast` не переносится.

## Решение 5 — новая сюита `tests/gramax/comments/` (FR-220, gramax-o0q.33)

Дом контракта скриптов комментариев `validate_comments.py`, `parse_comments.py`, `gen_comment_id.py`, `slugify.py` —
до волны их не покрывала ни одна сюита (`plugins/gramax/scripts/tests/` — только render и structure). Формат — ADR-0011
Решение 5: плоский каталог, `ac-*.sh`, `run.sh` по glob. Волна сажает стабы AC-129, AC-130, AC-139, comments-ногу AC-132
и регрессию маски кода `ac-144` (gramax-4jf.13; замок Решения 4 — пример в code-span даёт 0 находок); стабы
`gen_comment_id.py`, `slugify.py` — хвост gramax-o0q.33. AC-131, AC-133 (контракт `validate_structure.py`) живут в
`tests/gramax/catalog-validator/`, рендер-нога AC-132 — в `tests/gramax/render-linter/`. Уровни: unit (разбор фикстур),
integration (CLI на фикстуре каталога: rc и текст). Место в `--full` — сразу после `catalog-validator`, метка `==> comments`.

## Решение 6 — мёртвый overlay-тулинг удаляется (FR-220(в), AC-145)

Пять файлов: `scripts/apply-overlay.sh`, `scripts/_init_helpers.py`, `scripts/_resolve_agents.py`, `scripts/_apply_profile.py`,
`scripts/_apply_yaml_patch.py` (единственный вызывающий последнего — `apply-overlay.sh:144`, `:159`); ни один не входит
в payload nauta (25 файлов), ни один живой файл их не зовёт. Переключение на `templates/overlays/` отклонено: профилей
нет (только `.gitkeep`), а `scripts/init.sh` не существовал (`git log --all --oneline -- scripts/init.sh` — пусто).
Записи реестра — по форме ADR-0011 Решение 3 (путь или вызов, не голое слово):

```
scripts/apply-overlay\.sh
scripts/_init_helpers\.py|(from|import) _init_helpers([^a-zA-Z0-9_]|$)
scripts/_resolve_agents\.py|(from|import) _resolve_agents([^a-zA-Z0-9_]|$)
scripts/_apply_profile\.py|(from|import) _apply_profile([^a-zA-Z0-9_]|$)
scripts/_apply_yaml_patch\.py|(from|import) _apply_yaml_patch([^a-zA-Z0-9_]|$)
```

Замер по методике `tests/gramax/orphan-references/run.sh` на HEAD 7553da1: попадания — только внутри пяти файлов и
два в `tests/gramax/docs-migration/` (`at-design.md:232`, `ac-003-no-content-pointers.sh:107`), payload не задет.
**Порядок обязателен:** архивирование `docs-migration` (Решение 3) — первым коммитом либо тем же, что и записи
реестра; «сначала реестр» даёт красный `--full` (прецедент — ADR-0011 Решение 3).

## Целевой состав `--full`

Ниже — блок `--full` проектного гейта `scripts/check-gramax.sh` по порядку (метки `==>` шагов); nauta-часть
`bash scripts/check.sh --full` и путь `--fast` (шаги 1, 2, 2.5, 2.6) не меняются:

```
validate-structure · validate-comments · shellcheck · submodule status · orphan-references · nauta-integration ·
plugin-contract · catalog-validator · comments · mermaid-adoption · writer-consumer-rules · link-form-resolver ·
link-form-migration · export-skill · plantuml-bpmn · writer-sync-470 · writer-tail-480 · render-linter ·
render-quality · cross-catalog-retraction · gate-composition
```

Новые — два валидатора, `comments`, `cross-catalog-retraction`, `gate-composition` (сторожа состава гейта
и текстов репозитория — поправка ратификации); каждая сюита — `bash tests/gramax/<имя-сюиты>/run.sh`,
`render-quality` — только офлайн-стабы. Итог: 2 валидатора, shellcheck, submodule status и 17 сюит; заголовок скрипта
перечисляет все 17 (AC-147). Варден `tests/gramax/render-quality/ac-118-fast-isolation.sh` переводится, не удаляется
(NFR-084): комментарий заголовка с `render-quality` не «вне `--full`», исполняемая строка вне блока краснит. Стационарное
состояние: чистое дерево, прогретые кэш uv и chromium (`bash scripts/render-quality/warm.sh`), без опубликованных проб и без сети.

## Consequences

- **Положительные:** `--full` зелёный в стационарном состоянии; именованный отказ на каждом уровне; свои валидаторы судят свой каталог; ни одна живая сюита не вне гейта.
- **Совместимость:** живой замер зовётся явно — `bash scripts/render-quality/live.sh`; полная недоступность цели даёт rc=2 вместо rc=1; `--full` длиннее на четыре шага и около 16 с.
- **Trade-offs:** `--full` зависит от прогретой машины; `docs-migration` не ловит регрессию `content/` (OI-1); пример на удалённый скрипт остаётся в прозе payload (OI-4).
- **NFR-мэппинг:** NFR-085 — Решения 1–4 (в `--full` нет сети, проб и токена); NFR-084 — перевод `ac-118` и подключение `cross-catalog-retraction` без правки ассертов; NFR-079 — `--full` только пополняется офлайн-шагами.

- **OI-1** (PM, вне волны): живые ассерты AC-003…AC-007 архивной `docs-migration` выделить в живую сюиту копированием — архив не редактируется.
- **OI-2** (BA/PM): у сюиты `comments` нет своего AC «существует и зелёная в `--full`» (стабы — под номерами других AC); завести AC либо принять карту Решения 5.
- **OI-3** (владелец ADR-0026): в ADR-0026 нет строки `Contract:` для маски кода — дополнить там; здесь только зависимость.
- **OI-4** (PM): payload-файл `.claude/skills/subagent-delegation-brief/SKILL.md` (стр. 38–39) приводит удалённый `scripts/apply-overlay.sh`; хэш-пинован, правится в nauta.
- **OI-5** (SA/PM, при 0 предупреждений): включать ли `--strict` в шагах догфудинга.

## Alternatives Considered

- Живая нога в `--full` при сессии замеров в каждом релизе; красный `--full` по умолчанию — отклонены владельцем (D5).
- Автофолбэк `--offline` в обёртке — отклонён: тихая смена режима (Решение 2); `docs-migration` архивировать частично сейчас — отклонено: цвет на HEAD не измерен, риск для AC-141.
- Править четыре места в `docs/` вместо маски кода — отклонено: RECORD-документы, класс повторится; `--strict` сразу — 3 W034 закроют гейт.

## Связанные артефакты

- генезис-деревья: [волна-3](../epics/2026-11-23-wave3-contracts-gates-genesis-tree.md) (D5), [волна-2](../epics/2026-11-21-render-quality-wave2-genesis-tree.md) (D8); дизайн: [Render-quality Playwright](../../40-architecture/2026-11-21-playwright-render-quality-design.md)
- контракты валидаторов: [ADR-0026](0026-validator-contracts-engine-pin.md); поправляет в части (Решение 1): [ADR-0025](0025-playwright-dev-loop-dependency.md); применяет: [ADR-0011](0011-test-harness-taxonomy.md) (Решения 1, 3, 5), [ADR-0021](0021-docs-layout-inversion.md)
- затрагивает (файлы Dev): `scripts/check-gramax.sh`; `scripts/render-quality/` (`live.sh` — новый, `probe.sh`, `probe.py`); `tests/gramax/render-quality/` (`run.sh`, `README.md`, `ac-118-fast-isolation.sh`); `tests/gramax/comments/` (стабы QA-author, позеленение); `tests/gramax/cross-catalog-retraction/` (`README.md`, `run.sh`)
- `tests/gramax/docs-migration/` → `tests/gramax/archive/docs-migration/`; `tests/gramax/archive/README.md`; пять файлов Решения 6 — `git rm`; `tests/gramax/orphan-references/sunset-registry.txt`
- `plugins/gramax/scripts/validate_comments.py`, `plugins/gramax/scripts/parse_comments.py` (gramax-4jf.13); `docs/60-implementation/test-reports/2026-11-19-night-review-report.md` (пометка); runbook (раздел ритуала, два кода) — путь в «Опорах»
