# ADR-0002: Выбор drawio MCP-бэкенда и роль LLM в генерации XML

**Status:** Historical (Informational)
**Date:** 2026-05-08
**Plugin:** gramax

## Context

Spec open question #2: какой из трёх MCP-бэкендов для drawio выбрать?

Кандидаты из Researcher findings:
- **`jgraph/drawio-mcp`** — Apache-2.0, 3.6k★, Node.js, hosted + stdio. Официальный. Сами авторы рекомендуют Mermaid для надёжного AI-рендеринга — прямой сигнал, что генерация drawio XML из описания нестабильна.
- **`drawio-mcp` (PyPI, автор неизвестен)** — MIT, Python 3.11+, 310+ presets, layout-алгоритмы. Высокий AI-fit, но требует Python 3.11, тогда как NFR-003 фиксирует Python 3.10+. Ломает compatibility constraint.
- **`lgazo/drawio-mcp-server`** — MIT, TypeScript v2.1.0, multi-page/layers, активно поддерживается. Node.js. Наиболее зрелый TypeScript-вариант.

Ключевое архитектурное наблюдение: ни один из трёх кандидатов не имеет задокументированного tool для генерации drawio XML из словесного описания. Типичные capabilities MCP drawio-серверов:
- `render_xml` / `convert_xml_to_svg` — рендеринг готового XML в PNG/SVG.
- `validate_xml` — валидация mxfile-структуры.

Генерацию mxfile XML из натурального языка выполняет **LLM** (Claude), а не MCP-сервер. MCP выступает как рендер-backend (XML → SVG), а также как инструмент валидации.

Существующий `drawio_convert.py` (в `plugins/gramax/scripts/`) уже реализует локальный XML → SVG-конвертер с embedded XML (соответствует AC-004). Это Python stdlib, работает без сетевых вызовов, без Node.js.

Таким образом, необходимость drawio MCP в MVP определяется: нужно ли нам что-то сверх того, что уже даёт `drawio_convert.py`?

Ответ: нет. `drawio_convert.py` покрывает весь drawio-путь для MVP.

Spec FR-011 явно предусматривает fallback: «если MCP drawio-бэкенд недоступен, `.drawio` сохраняется, `.svg` — нет». Это подтверждает, что MCP является optional enhancement, а не ключевой зависимостью.

## Decision

**MVP drawio-путь:** LLM генерирует mxfile XML → `drawio_convert.py` конвертирует в SVG с embedded XML. Внешний drawio MCP-бэкенд не является обязательной зависимостью MVP.

В `plugin.json` объявляется опциональная секция `mcpServers` для drawio. Рекомендуемый вариант для пользователей, желающих расширенного рендеринга: **`lgazo/drawio-mcp-server`** (MIT, TypeScript, Node.js).

Критерии выбора `lgazo/drawio-mcp-server` над альтернативами:
- MIT — совместима с нашей лицензией.
- TypeScript — тот же стек, что и `claude-mermaid`; паттерн воспроизводим.
- v2.1.0 — зрелая версия с активным поддержанием.
- Node.js, не Python — не конкурирует с Python-ограничением NFR-003.
- `jgraph/drawio-mcp` отклонён: авторы сами рекомендуют Mermaid, что указывает на слабый AI-fit для XML-генерации.
- `drawio-mcp` (PyPI) отклонён: требует Python 3.11+, нарушает NFR-003.

Финальное подтверждение выбора между `lgazo` и `jgraph` может быть выполнено Dev в рамках PoC (Dev-фаза): запустить оба сервера, вызвать с тестовым mxfile, сравнить качество SVG-вывода.

**PoC критерии:**
1. `<tool_name>(mxfile_xml)` → SVG с валидным viewBox и без artef актов рендеринга.
2. headless, без открытия браузера.
3. stdio transport, совместимый с `mcpServers` Claude Code.

## Consequences

**Положительные:**
- MVP не имеет обязательной внешней зависимости для drawio (только Python 3.10+ stdlib).
- `drawio_convert.py` уже протестирован и работает — ноль дополнительных рисков.
- AC-004 и AC-012 покрыты без MCP.
- FR-011 / AC-009 (fallback при недоступности MCP) — сохраняется как graceful degradation, не как критический путь.

**Отрицательные / trade-offs:**
- Качество SVG-рендера ограничено `drawio_convert.py`: SVG содержит только embedded XML (placeholder геометрию `<g/>`), визуальный рендер требует открытия в diagrams.net.
- Пользователи, ожидающие полного SVG-рендера (с нодами, стрелками), получат «плоский» SVG без визуализации — только embedded XML для round-trip.

**Открытые риски:**
- LLM может генерировать невалидный mxfile XML (AC-012 проверяет валидность через `xml.etree.ElementTree`; при невалидности — error + no file).
- Если потребуется полный визуальный SVG — нужен PoC с drawio MCP в Phase 2.

**Mitigations:**
- Явное предупреждение пользователю в skill-промпте: «SVG содержит embedded-данные для редактирования в diagrams.net; визуальный рендер — в браузере».
- Валидация XML перед вызовом `drawio_convert.py` (Python stdlib `xml.etree.ElementTree.parse`).

## Alternatives Considered

- **`jgraph/drawio-mcp` как обязательная зависимость** — отклонено: авторы рекомендуют Mermaid, высокий риск нестабильного XML-вывода; Apache-2.0 ограничивает некоторые use cases.
- **`drawio-mcp` (PyPI)** — отклонено: Python 3.11+ нарушает NFR-003.
- **`lgazo/drawio-mcp-server` как обязательная зависимость** — отклонено для MVP: Node.js runtime как обязательное требование избыточно при наличии `drawio_convert.py`; переносится в Phase 2.
- **Только LLM, без `drawio_convert.py`** — отклонено: `.drawio` и `.svg` с embedded XML — явное требование spec (FR-009, AC-004); `drawio_convert.py` именно для этого.

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` (open question #2, #4, FR-009, FR-011, AC-004, AC-009, AC-012)
- затрагивает: `plugins/gramax/.claude-plugin/plugin.json` (секция `mcpServers`)
- см. также: ADR-0003 (vendoring strategy), ADR-0005 (save flow)
