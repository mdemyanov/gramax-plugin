# Онбординг: роли nauta на чистой машине

Этот документ — для контрибьютора **этого репозитория** (`gramax-marketplace`), не для
потребителя плагина `gramax`. Если вы просто хотите установить `gramax` в свой Claude
Code — вам в раздел [«Установка» в README.md](../README.md#установка), сюда идти не нужно.

Если вы работаете над самим репозиторием — правите `plugins/gramax/`, пишете ADR,
требования или тесты в `content/` — читайте дальше: без шагов ниже команды `/nauta:*`
не появятся, а `scripts/check.sh --fast` откажется работать.

## Зачем нужен nauta

Роли `/nauta:pm`, `/nauta:ba`, `/nauta:sa`, `/nauta:dev`, `/nauta:qa`, `/nauta:tech-writer` и
остальные из карты команд в [CLAUDE.md](../CLAUDE.md) — не часть этого репозитория.
Они приходят из отдельного marketplace `nauta`: набора агентных промптов, который
подключается через Claude Code, а не хранится в `plugins/`. Собственных агентов
`gramax-marketplace` не держит — это единственный способ вести цикл
Researcher → BA → SA → Dev → QA → Tech-writer в этом репозитории.

Отдельно от ролей `nauta` доставляет ещё один артефакт — Python-валидаторы в `scripts/`
(например `scripts/validate-content.py`). Они попадают в репозиторий не через marketplace,
а командой `/nauta:sync-scripts` и версионируются файлом `.nauta-scripts-basis.yaml`. Роли
и валидаторы — два независимых канала доставки, которые здесь по факту закреплены на одном
релизе nauta (`v0.3.1`), но обновляются разными шагами. Этот документ — только про роли
(marketplace). Обновление валидаторов — отдельная задача через `/nauta:sync-scripts`.

## Пререквизиты

- Claude Code с поддержкой plugin marketplace.
- git.
- [`uv`](https://docs.astral.sh/uv/) — жёсткий пререквизит, не опция. `scripts/check.sh --fast`
  запускает `content/`-валидатор через `uv run scripts/validate-content.py`. Если `uv` не
  установлен, гейт **падает** (`FAIL: uv not installed`), а не выдаёт предупреждение —
  закоммитить без `uv` в системе не получится через штатный pre-commit hook.

## Шаг 1. Зарегистрировать marketplace `nauta`

Добавьте запись в `~/.claude/settings.json` (или через `/plugin marketplace add` в Claude
Code — команда сделает то же самое). Форма записи:

```json
{
  "extraKnownMarketplaces": {
    "nauta": {
      "source": {
        "source": "git",
        "url": "https://<внутренний-хост>/tools-ai/nauta.git",
        "ref": "v0.3.1"
      }
    }
  }
}
```

Путь репозитория — `tools-ai/nauta` (он уже упоминается в `content/lessons-learned.md` и
в спеках интеграции). Хост — внутренний, в публичном marketplace не публикуется; уточните
его у команды, которая ведёт этот репозиторий.

**Почему `ref` закреплён, а не плавает.** `nauta` уже давал повод: валидатор
`validate-content.py` версии 0.2.1 ложно считал примеры Gramax-тегов внутри код-блоков
битыми ссылками (31 ложный error на реальном корпусе) — дефект поймали, завели апстрим и
осознанно переехали на исправленную версию, а не подхватили её автоматически (детали —
[`content/lessons-learned.md`](../content/lessons-learned.md)). Роли `/nauta:*` управляют
тем же принципом: если marketplace плавает на последний релиз, поведение `/nauta:dev` или
`/nauta:qa` может незаметно поменяться между двумя PR одного контрибьютора — это ломает
воспроизводимость ревью. Закреплённый `ref` даёт всем одну и ту же версию ролей, пока
кто-то осознанно не поднимет `ref` явным коммитом.

## Шаг 2. Включить плагины локально

Marketplace зарегистрирован — но ещё не включён. Набор включённых плагинов зависит от
конкретной машины (у кого-то стоит `superpowers`, у кого-то ещё десяток посторонних),
поэтому он не входит в общий `~/.claude/settings.json`, а живёт в
`.claude/settings.local.json` внутри репозитория. Этот файл — per-machine и в
`.gitignore` (см. `.gitignore` в корне): распространять чужой набор плагинов всем
контрибьюторам не нужно.

Скопируйте пример и включите нужные плагины:

```bash
cp .claude/settings.local.json.example .claude/settings.local.json
```

Пример включает `nauta` и `superpowers` — минимум для работы над этим репозиторием.
Отредактируйте `.claude/settings.local.json` под себя, если нужны другие плагины из
других marketplace — сам файл в git не попадёт.

## Шаг 3. Активировать git-хуки (опционально, но рекомендуется)

По умолчанию хук pre-commit **не установлен** — свежий `git clone` не запускает
`scripts/check.sh` автоматически. Активируйте его явно:

```bash
bash scripts/install-hooks.sh
```

Команда идемпотентна (повторный запуск не ломает) и переключает `core.hooksPath` на
`.githooks/`, где лежит `pre-commit`, вызывающий `scripts/check.sh --fast`. Отключить:
`git config --unset core.hooksPath`. Обойти разово: `git commit --no-verify` (в этом
репозитории — только с явного разрешения, см. красные линии в `CLAUDE.md`).

## Проверка установки

Основная проверка — `scripts/check.sh --fast`, тот же гейт, что срабатывает в
pre-commit hook:

```bash
bash scripts/check.sh --fast
```

Ожидаемый вывод (число проверенных файлов в `content/` растёт по мере пополнения
каталога — важны не цифры, а отсутствие `FAIL` и финальная строка):

```
==> mode: --fast
==> whitespace
OK: no whitespace issues
==> json
OK: JSON validated
==> content
content/: OK (N файлов проверены)

Errors: 0 | Warnings: 0
OK: content validated
==> RESULT: PASS
```

Если вместо `OK: content validated` видите `FAIL: uv not installed` — вернитесь к
пререквизитам, `uv` не установлен или не в `PATH`.

Полный прогон — `bash scripts/check.sh --full`. Он включает `--fast` целиком, плюс
`shellcheck` (если установлен), проверку статуса submodule и четыре suite:
`tests/gramax/orphan-references`, `tests/gramax/nauta-integration`,
`tests/gramax/plugin-contract`, `tests/gramax/doc-paths`. В здоровом состоянии вывод
содержит заголовок каждого из четырёх suite и завершается `==> RESULT: PASS`. Дословный
вывод здесь не приводится намеренно — состав репозитория и найденные `shellcheck`-замечания
меняются со временем, и застывший в документе вывод быстро разойдётся с реальностью;
сверяйтесь с актуальным прогоном, а не с этим текстом.

Последняя проверка — что роли действительно доступны. В сессии Claude Code внутри
этого репозитория выполните:

```
/nauta:pm status
```

Если marketplace зарегистрирован и плагин включён (шаги 1–2 выполнены), команда
отвечает как PM-роль. Если Claude Code сообщает, что команда не найдена — проверьте
`extraKnownMarketplaces` в `~/.claude/settings.json` (шаг 1) и `enabledPlugins` в
`.claude/settings.local.json` (шаг 2).

## Второй remote: внутренняя витрина в GES

Если `git remote -v` в этом репозитории показывает не только `origin`, а ещё и `internal` —
это не забытая настройка и не ошибка. У репозитория есть вторая точка публикации: внутренняя
read-only витрина в корпоративном Gramax Enterprise Server (GES), которая рендерит тот же
`content/`, что вы видите здесь. Полное обоснование, альтернативы и trade-offs — в
[ADR-0014](../content/00-project/adr/0014-dual-publication-targets.md); здесь — только то, что
нужно контрибьютору на практике.

**Два таргета, две роли.** `origin` (GitHub, `mdemyanov/gramax-plugin`) — источник правды и
канал distribution: сюда уходит обычный `git push`, отсюда пользователи ставят плагин через
`/plugin marketplace add`. `internal` (внутренний GitLab, `tools-ai/gramax-plugin`) — read-only
витрина: из неё GES тянет `content/` и рендерит каталог для внутренних читателей.

**Обновление витрины — вручную, автоматизации нет.** После значимых изменений в `content/`
кто-то явно выполняет:

```bash
git push internal main
```

Если этого не сделать сразу, витрина отстаёт от `origin`. Это ожидаемое и допустимое
состояние, а не поломка — мониторинга рассинхрона нет, и так решили сознательно.

**Не переключайте upstream локальной `main` на `internal`.** Он намеренно указывает на
`origin/main`, поэтому обычные `git push` и `git pull` не задевают внутренний контур. Если
сделать `internal` upstream'ом или единственным push-target (например, через `git remote
set-url`), рутинный `git push` без параметров начнёт неявно уезжать во внутренний GitLab.

**Витрина не принимает редактирование.** `internal` read-only по договорённости, не из-за
технического ограничения GitLab. Все правки контента делаются только в этом репозитории — в
витрину они попадают через `git push internal main`, уже после того как окажутся в `origin`.

**Не переносите `content/.doc-root.yaml` в корень репозитория.** От того, что этот файл лежит
внутри `content/`, зависит не только контракт `check.sh --fast`
(`tests/gramax/nauta-integration/ac-003-doc-root-contract.sh`), но и сама способность GES
отрендерить витрину.

**Если после push витрина не появилась.** Синхронизированный `internal` — не то же самое, что
видимый в GES репозиторий. Отдельный шаг вне этого репозитория — регистрация в GES: PR в
`nau-gramax-manager` (файл `repositories/tools-ai/gramax-plugin.yaml` + запись в
`workspace.yaml`). Пока этот PR не смёржен, `internal` синхронизирован, но GES его не видит.
Если контент не отрендерился — причина здесь, а не в `git push`.

**Воспроизвести на чистой машине.** При обычном `git clone` remote `internal` не появляется —
добавьте его вручную:

```bash
git remote add internal https://<внутренний-хост>/tools-ai/gramax-plugin.git
```

Хост тот же внутренний, что используется для marketplace `nauta` в шаге 1 — уточните его у
команды, которая ведёт этот репозиторий.
