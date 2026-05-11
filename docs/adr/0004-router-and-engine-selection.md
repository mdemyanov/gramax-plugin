# ADR-0004: Механизм выбора движка (router и engine selection)

**Status:** Accepted
**Date:** 2026-05-08
**Plugin:** gramax

## Context

Spec open question #1 (часть) и #3 (неявно): где живёт логика диспетчеризации между mermaid- и drawio-путём?

Пользователь явно указывает движок в запросе («нарисуй mermaid...» / «сделай drawio...»). Никакого auto-detect. Вопрос: как архитектурно оформить распознавание триггера и переключение пути.

Кандидаты:

**Вариант A — отдельный router-skill:**
- Skill `diagram-router` активируется на любой запрос о диаграммах.
- Парсит `engine` из запроса и делегирует в `diagram-mermaid` skill или `diagram-drawio` skill.
- Два backend-skill живут в `plugins/gramax/skills/diagram-mermaid/` и `plugins/gramax/skills/diagram-drawio/`.
- Плюс: чёткое разделение ответственности. Минус: три SKILL.md вместо одного; суммарный токен-бюджет выше; Claude активирует router, затем backend — двойной hop.

**Вариант B — один skill `diagram-on-demand` с двумя путями внутри:**
- Один SKILL.md с `description`, покрывающим триггеры обоих движков.
- Skill сам извлекает `engine` параметр (из ключевых слов «mermaid» / «drawio» в запросе).
- Если `engine` не определён — переспрашивает.
- Плюс: один артефакт, одна точка входа, уложиться в ≤2000 токенов (NFR-002) реально. Минус: skill содержит логику двух движков.

**Вариант C — slash-команды `/diagram mermaid|drawio ...`:**
- Пользователь вызывает явно: `/gramax:diagram mermaid flowchart авторизации`.
- Плюс: явный вызов, нет неопределённости. Минус: команды требуют явного `/`, что меняет UX — spec описывает natural language триггеры, не slash. Команды не авто-активируются.

Дополнительный контекст: spec open question #3 о сигнатуре `mermaid_save`:
- `claude-mermaid` MCP предоставляет tool `mermaid_save`. Судя по названию и паттерну (аналог `mermaid_preview`), tool принимает DSL-контент и путь сохранения.
- Если `mermaid_save` принимает `(path, content)` — skill вызывает его напрямую.
- Если `mermaid_save` поддерживает только preview (без пути) — skill записывает DSL в файл самостоятельно через shell.
- Решение: skill-промпт описывает оба сценария; Dev проверяет сигнатуру в PoC и реализует соответствующую ветку. Файл сохраняется в любом случае (FR-010, AC-001, AC-008).

Spec open question #6 (позиция вставки ссылки в md): skill вставляет ссылку в конец файла по умолчанию. Угадывание позиции не входит в MVP (см. ADR-0007). Если пользователь указал конкретную позицию — skill принимает это как параметр. Это не требует router-логики.

## Decision

**Вариант B: один skill `diagram-on-demand` с внутренней диспетчеризацией по параметру `engine`.**

Структура файлов:
```
plugins/gramax/skills/diagram-on-demand/
  SKILL.md                        # основной промпт, ≤2000 токенов
  references/
    mermaid-path.md               # детали mermaid-пути (типы, MCP-сигнатура)
    drawio-path.md                # детали drawio-пути (XML-генерация, convert.py)
```

Логика в SKILL.md:
1. Из запроса извлекается `engine` (ключевые слова «mermaid» / «drawio»).
2. Если `engine` не найден — skill переспрашивает: «Уточни движок: mermaid или drawio?»
3. В зависимости от `engine` — выполняется соответствующий путь.

Сигнатура `mermaid_save`: Dev должен проверить в PoC. Skill описывает оба варианта:
- Если tool принимает `(path, dsl_content)` — вызвать напрямую.
- Если tool — только preview — записать DSL через `python3 -c "..."` или bash heredoc, затем вызвать `mermaid_preview` для проверки.

Вставка ссылки в md: по умолчанию в конец файла. Если пользователь указал позицию («после раздела H2 "Архитектура"») — skill принимает это как instruction и выполняет целевую вставку.

## Consequences

**Положительные:**
- Один SKILL.md — один артефакт для Dev, один для QA, один для Tech-writer.
- Нет двойного hop (router → backend): Claude активирует один skill, выполняет всю логику.
- Уложиться в ≤2000 токенов (NFR-002) реально при использовании references/.
- Slash-команды не нужны — natural language триггеры из spec сохранены.

**Отрицательные / trade-offs:**
- При добавлении третьего движка skill начнёт разрастаться; будет повод для рефакторинга.
- Единственный skill-файл — единая точка отказа; ошибка в промпте затрагивает оба движка.

**Открытые риски:**
- Если `mermaid_save` не принимает path — нужен дополнительный shell-шаг записи файла; Dev должен протестировать в PoC.

**Mitigations:**
- References разбиты по движкам: изменение одного пути не затрагивает другой.
- Smoke-тесты для каждого AC независимы: тест mermaid-пути и тест drawio-пути не зависят от общей точки входа.

## Alternatives Considered

- **Отдельный router-skill + два backend-skill** — отклонено: три SKILL.md, двойной LLM-hop, суммарный токен-бюджет выше NFR-002.
- **Slash-команды `/gramax:diagram`** — отклонено: spec описывает natural language UX; slash-команды требуют явного вызова пользователем и не авто-активируются.
- **Auto-detect движка по описанию** — явно out-of-scope в spec (Out of Scope, пункт первый).

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` (open question #1, #3, #6; FR-010, AC-001, AC-008, AC-011)
- предшествует: ADR-0001 (один плагин без split)
- затрагивает: `plugins/gramax/skills/diagram-on-demand/SKILL.md`
