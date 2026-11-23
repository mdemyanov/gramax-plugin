# tests/gramax/gate-composition/ — гейт `--full` и хвосты гигиены волны-3

Failing-stub suite (QA-author, до правок Dev) по требованию
`docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`
(AC-143…AC-147, AC-149, AC-150 — гейт, тексты и реестр идентификаторов) и решению
`docs/00-project/adr/0027-full-gate-composition.md` (состав `--full`, именованные отказы
живой ноги, статусы сюит, удаление overlay-тулинга). Запись at-design —
`docs/60-implementation/acceptance/2026-11-23-wave3-gates-at-design.md`.
Стабы AC-141 и AC-142 живут в `tests/gramax/render-quality/` (дом носителя — прибор и его
агрегатор); здесь — всё, что судит сам гейт, корневые тексты, CHANGELOG и реестр.

## Статус и подключение

Все стабы красные на 7553da1 — красный прогон `run.sh` есть ожидаемое состояние TDD-цикла
до правок Dev. Регистрация в `scripts/check-gramax.sh` `--full` — задача Dev **последним
шагом блока** (поправка PM к списку ADR-0027: 17 сюит с настоящей); до регистрации сюита
существует standalone и в `--fast` не участвует.

## AC → файл → что проверяет

| AC | Файл | Что проверяет | Красные ноги на 7553da1 |
|----|------|---------------|--------------------------|
| AC-143 | `ac-143-suite-statuses.sh` | cross-catalog-retraction подключена к `--full` (шаг тела + строка заголовка); docs-migration лежит в `tests/gramax/archive/docs-migration/` со строкой в `archive/README.md`, старого каталога нет; настоящая сюита — последний шаг `--full` | шага cross-catalog-retraction нет; docs-migration не переехала; сюита не зарегистрирована |
| AC-144 | `ac-144-dogfood-validators.sh` | `--full` вызывает `validate_structure.py docs` и `validate_comments.py docs` с rc-гейтингом (без хвоста-подавления); оба на `docs/` дают rc=0 | шагов в гейте нет; `validate_comments` даёт 4 ложных ERROR (gramax-4jf.13) |
| AC-145 | `ac-145-overlay-sunset.sh` | пять файлов overlay-тулинга (ADR-0027 Решение 6) отсутствуют; `sunset-registry.txt` несёт все пять якорных шаблонов дословно | все пять файлов на месте; записей реестра нет |
| AC-146 | `ac-146-root-texts.sh` | CLAUDE.md: состав плагина = 7 навыков + агент, без `v0.3.1`, описание `--full` = оба валидатора + 17 сюит; порог C14 (550 строк CLAUDE.md+AGENTS.md) цел; README: якоря предусловий ADR-0008/RES-001 и предупреждение о конфликте триггеров | состава plantuml/export нет; `v0.3.1` на месте; `--full` описан двумя сюитами; README без якорей |
| AC-147 | `ac-147-texts-and-header.sh` | README render-quality без «не подключён ни к одному гейту» и «10 красных / 2 зелёных»; README plantuml-bpmn актуален; множества сюит заголовка и тела `--full` равны; варден ac-118 держит изоляцию | обе фразы в README; фраза «ещё не создана» в plantuml README; заголовок 13 сюит против 14 тела |
| AC-149 | `ac-149-changelog-calibration.sh` | CHANGELOG несёт запись калибровки волны-1 (note-in-cell, note-in-note → WARN; colgroup-multiline → ERROR); маркер `**Опоры:**` в шапке записи замера (первые 30 строк, до первого `## `); `check-content-actuality.py` не даёт SIGNAL по записи | в 4.9.0 только th; маркер в конце файла (строка 90) — SIGNAL гейта |
| AC-150 | `ac-150-identifier-registry.sh` | варден: каждый `**AC-NNN`/`**NFR-NNN`/`**BR-NNN` глобальной эры (AC ≥ 036, NFR ≥ 050, BR ≥ 006) определён ровно в одном файле `docs/30-requirements/*.md`; реестр диапазонов с владельцем каждой строки; паритет не определяет AC-061…AC-072 и BR-011; карта catalog-validator указывает AC-152…AC-163, имена стабов `ac-025`…`ac-036` не менялись | коллизия AC-061/AC-062/BR-011; паритет не перенумерован; карта README указывает на старый диапазон |

## Запуск

```bash
bash tests/gramax/gate-composition/run.sh; echo "exit=$?"
# поштучно:
bash tests/gramax/gate-composition/ac-150-identifier-registry.sh; echo "exit=$?"
```

Каждый стаб standalone из корня репо (`git rev-parse --show-toplevel`). Тяжёлые ноги —
только локальные: валидаторы на `docs/` (AC-144) и гейт актуальности (AC-149) — офлайн,
сеть не запрашивается.

## Границы

- Порог C14 в стабе AC-146 — константа 550 из `.nauta-gates.yaml` (promptLayerSizeBudget);
  при смене порога в конфиге стаб правится тем же коммитом (литерал, а не чтение конфига —
  чтобы стаб не зависел от чтения YAML).
- Скан AC-150 ограничен `docs/30-requirements/*.md` (эра локальных номеров до 13.08.2026
  выведена порогами AC ≥ 036, NFR ≥ 050, BR ≥ 006); жирные цитирования вне директории
  требований — вне контракта AC-150.
- Ноги, не автоматизируемые стабом, с владельцами — в at-design (запись ночного отчёта
  AC-145 — PM; настоящий зелёный `--full` на чистом дереве AC-141 — доказательство
  координатора, не стаб).
