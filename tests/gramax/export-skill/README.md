# Suite `export-skill` — AC-041…AC-050 (failing stubs, QA-author)

Предмет: guidance-навык `plugins/gramax/skills/export/` плагина gramax (экспорт
DOCX/PDF: шаблоны, placement на портале, рецепты CLI/CI/UI/статический портал,
граница исполнения).

- Требование: `docs/30-requirements/2026-11-18-export-skill-requirement.md` (AC-041…AC-050)
- Дизайн: `docs/40-architecture/2026-11-18-export-skill-design.md` (§«Контракт с QA-author» —
  уровни и хуки; §«План компонентов и файлов» — предмет проверки)
- Таксономия: ADR-0011 (suite в `tests/gramax/<домен>/`, файлы `ac-NNN-<тема>.sh`, агрегатор `run.sh`)

## Статус: красный по дизайну

Stub'ы написаны ДО реализации (TDD-цепочка qa-author → dev). Красная причина у всех —
одна: `plugins/gramax/skills/export/` не существует (коммит базы stub'ов — `9355b69`).
Зеленит suite реализация Dev по плану файлов дизайна: `SKILL.md` + `references/templates.md`
+ `references/recipes.md` + одна строка кросс-ссылки в `writer/SKILL.md`. Пока предмета нет,
каждый stub падает на гейте существования с одной строкой-причиной, а не россыпью
«паттерн не найден» — причина красноты читается из вывода без разбора.

## Уровни (по дизайну)

Unit неприменим — исполняемого кода в навыке нет. AC-041…AC-049 — integration (проверки
артефактов: файлы, frontmatter, контент-грейпы). AC-050 — e2e (композитный гейт
`bash scripts/check.sh --fast` по коду возврата).

## Таблица AC → файл

| AC | Файл | Уровень | Предмет |
|---|---|---|---|
| AC-041 | `ac-041-skill-surface-and-triggers.sh` | integration | `SKILL.md` существует; frontmatter `name: export`; триггеры «экспорт/docx/pdf» (литерала AC) + все шесть слов FR-131 в `description` (хук дизайна); негативная демаркация (description export ∌ авторинг-триггеров writer; description writer ∌ экспортных слов); кросс-ссылка `gramax:export` в writer ровно одной строкой; структурный кейс FR-132 (`references/` существуют и названы в SKILL.md) |
| AC-042 | `ac-042-pdf-template-facts.sh` | integration | факты PDF-шаблона: `.page`, `title-page`, колонтитулы (`колонтитул\|header\|footer`) |
| AC-043 | `ac-043-docx-template-facts.sh` | integration | факты DOCX-шаблона: `dotx`, `word` |
| AC-044 | `ac-044-portal-template-placement.sh` | integration | placement на портале: `assets/pdf`, `assets/word` |
| AC-045 | `ac-045-cli-export-recipe.sh` | integration | CLI-рецепт: `gramax-cli export`; флаг `-f docx\|pdf` либо запасная форма `-f pdf` |
| AC-046 | `ac-046-ci-stage-recipe.sh` | integration | CI-стадия: `gitlab-ci`, `EXPORT_FILE_PATH` |
| AC-047 | `ac-047-static-portal-recipe.sh` | integration | статический портал: `статическ\|static` + `gramax-cli` |
| AC-048 | `ac-048-ui-export-scope.sh` | integration | UI-экспорт: `приложени`, `раздел`, `каталог` |
| AC-049 | `ac-049-execution-boundary.sh` | integration | граница исполнения: `node` + альтернация `не исполняет\|не запускает\|инструктир\|границ` (канонические формулировки дизайна матчятся) |
| AC-050 | `ac-050-composite-gate.sh` | e2e | `bash scripts/check.sh --fast` → exit 0 (C10-orphan warning допустим, Errors = 0) |

## Прогон

```bash
bash tests/gramax/export-skill/run.sh                     # весь suite
bash tests/gramax/export-skill/ac-042-pdf-template-facts.sh   # один AC, из любого cwd
```

## Регистрация (НЕ выполнена — изоляция параллельной работы)

Механика обнаружения: suite'ы `tests/gramax/` НЕ обнаруживаются автоматически.
Цепочка: `scripts/check.sh --fast/--full` → projectGates (`.nauta-gates.yaml`) →
`scripts/gate-gramax-fast.sh`/`gate-gramax-full.sh` → `scripts/check-gramax.sh`;
в `--full` ветке `check-gramax.sh` каждый suite вызван явно
(`bash tests/gramax/<suite>/run.sh`). Регистрация этого suite = новый блок в
`scripts/check-gramax.sh` по образцу блока render-linter + строка в шапке файла.
Файл общий, поток параллелится — блок добавляет PM централизованно (та же логика,
что в открытом вопросе 3 дизайна: регистрация статей suite'а в `_index.md` — PM).

## Границы покрытия (что осознанно НЕ грепается)

- **NFR-056 / BR-007 (факт-гигиена, запрет изобретений)** — процессная ревью-проверка
  по источникам, отмеченным в тексте навыка; грепом не выражается (дизайн, §«Контракт
  с QA-author», последний пункт).
- **Релизная поверхность** (версии `plugin.json`/`marketplace.json`/CHANGELOG 4.7.0) —
  покрывается существующим `tests/gramax/plugin-contract/ac-006-manifest-coherence.sh`
  (синхронность манифестов, инвариант ADR-0006); конкретный номер здесь не пинится —
  bump делает Tech-writer в release-flow, номер не зарезервирован жёстко (дизайн,
  §«Релизная поверхность»).
- **Негативная демаркация триггеров** — греп ловит только компаунд-фразу
  «создаёт/редактирует статьи»; семантика роутинга в целом — ревью.
