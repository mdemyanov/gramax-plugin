# tests/gramax/plugin-contract/ — живые инварианты поставленного плагина

Suite проверяет текущее (не историческое) состояние `plugins/gramax/` и корневых манифестов.
В отличие от `tests/gramax/archive/**` — трёх suite, приёмку которых он обобщает, — этот suite
редактируется и продолжает запускаться при каждом изменении контракта. Обоснование выделения —
`content/00-project/adr/0011-test-harness-taxonomy.md`.

Семь ассертов вместо 34 в трёх архивных suite: версионные пины и проверки одноразовых миграций
(ретировка/переезд файлов) не перенесены — они истинны только для версии релиза, которую
удостоверяли, и теперь живут в `tests/gramax/archive/`. Сюда попало только то, что остаётся
проверяемым инвариантом на любой будущей версии плагина.

## Таблица соответствия

| Файл | FR | Происхождение | Природа |
|---|---|---|---|
| `ac-001-routing-contract.sh` | FR-006 | обобщает `archive/routing-mermaid-drawio/ac-001…008` + `archive/remove-diagram-skills/ac-014` | regression guard — зелёный на момент создания |
| `ac-002-drawio-tag-format.sh` | FR-007 | `archive/remove-diagram-skills/ac-008` (часть про тег) + `archive/routing-mermaid-drawio/ac-005` | **живой контракт — КРАСНЫЙ на момент создания** |
| `ac-003-writer-drawio-reference.sh` | FR-008 | `archive/remove-diagram-skills/ac-008` (структурная часть) | regression guard — зелёный на момент создания |
| `ac-004-readme-prerequisites-warning.sh` | FR-009 | `archive/remove-diagram-skills/ac-009` | **живой контракт — КРАСНЫЙ на момент создания** |
| `ac-005-mermaid-file-based-contract.sh` | FR-010 | статическая половина `archive/mermaid-file-based` (ac-005b, ac-006, ac-008, ac-011) | regression guard — зелёный на момент создания |
| `ac-006-manifest-coherence.sh` | FR-011 | поглощает шесть версионных пинов трёх архивных suite (remove ac-011/012, routing ac-012/013, mermaid ac-012) | regression guard — зелёный на момент создания |
| `ac-007-retired-skills-field.sh` | FR-012 | сторож ретировки `archive/routing-mermaid-drawio/ac-014` | сторож ретировки — зелёный на момент создания |

## Два известных красных ассерта

`ac-002` и `ac-004` создаются красными сознательно — это два реальных дефекта поставленной
v4.1.0, вскрытые разбором, а не ошибки в тестах:

- **`ac-002`** (негативная часть): живые документы плагина (`README.md`, `skills/writer/SKILL.md`)
  всё ещё учат устаревшему синтаксису тега drawio (`[drawio:...]`, `<Image src=.../>`) вместо
  канонического `<drawio path="..." width="..." height="..."/>`, задокументированного в
  `skills/writer/references/drawio.md`. Недомигрированный тег — дефект v4.1.0.
- **`ac-004`**: `plugins/gramax/README.md` не несёт WARNING о конфликте триггеров с чужим
  `Agents365-ai/mermaid-skill` (ADR-0008, Решение 6). WARNING отсутствует полностью.

Их чинит следующая задача (задача 4 плана `2026-08-09-test-harness-taxonomy`). До тех пор suite
**не подключён** к `scripts/check.sh` ни в одном режиме — подключение красного suite сделало бы
`--full` красным. Ожидаемый результат текущего прогона: `Passed: 5`, `Failed: 2`, `exit=1`.

## Запуск

```bash
bash tests/gramax/plugin-contract/run.sh
```

## `ac-007` — сторож ретировки

`archive/routing-mermaid-drawio/ac-014` требовал поля `skills` в `plugin.json`. Ассерт ретирован
(ADR-0011, Решение 2) — посылка была ложной: skills обнаруживаются автоматически по каталогу
`skills/`, поле манифеста рантаймом не читается. `ac-007` не проверяет продуктовый код — он
проверяет, что ассерт на поле `skills` не вернётся молча в один из `ac-*.sh` этого suite.
