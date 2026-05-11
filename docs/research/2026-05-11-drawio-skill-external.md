# RES-001: Agents365-ai/drawio-skill

Дата: 2026-05-11
Автор: researcher-agent
Источники:
- https://github.com/Agents365-ai/drawio-skill (v1.5.2)
- https://github.com/Agents365-ai/365-skills (marketplace)

## Лицензия

**MIT** — оба репозитория (`Agents365-ai/drawio-skill` v1.5.2 и контейнирующий marketplace `Agents365-ai/365-skills`). Совместимо с MIT нашего плагина; нет ограничений на распространение и ссылки.

## Prerequisites (точный список)

- **draw.io desktop app (CLI)** — обязательно; версия не фиксирована.
  - macOS: `brew install --cask drawio` (рекомендован) или dmg с github.com/jgraph/drawio-desktop/releases
  - Windows: инсталлятор с того же GitHub Releases; может потребоваться добавить в PATH вручную
  - Linux: `.deb`/`.rpm` — **не snap** (AppArmor-sandbox блокирует keyring, краш)
  - Linux headless/server: дополнительно `sudo apt install xvfb` + `xvfb-run -a` перед каждым вызовом CLI
- **Python 3** — нужен для `scripts/repair_png.py` (починка IEND-чанка после экспорта PNG с `-e`).
- **Vision-enabled модель** (Claude Sonnet/Opus) — для self-check; без неё шаг пропускается.
- Никаких env-переменных, Node/npm, MCP-серверов.

## Триггеры

SKILL.md description:

> "Use when user requests diagrams, flowcharts, architecture charts, or visualizations. Also use proactively when explaining systems with 3+ components, complex data flows, or relationships that benefit from visual representation."

Нет дискретного списка `triggers:`. Триггер семантический через `description`. **Конфликт с нашим `mermaid` skill** реален — оба описывают «диаграммы/flowcharts».

## Контракт ввода/вывода

**Input:** Natural-language описание. Опционально reference `.drawio` или изображение для захвата стиля. **Нет** именованных параметров (`engine`, `target_page`).

**Output:**
- `.drawio` XML-файл на диск
- Финальные экспорты в форматах (PNG, SVG, PDF, JPG) с `-e` (embedded XML); PNG чинится `repair_png.py`
- Файлы в **CWD** или в явно указанном пути (`./artifacts/`). `mkdir -p` сам.
- Имена: `<name>.drawio` + `<name>.drawio.png`. Без версий — перезаписывает.

**Markdown:** skill **не вставляет ссылку в md**. Сообщает только пути к файлам.

## Совместимость с Gramax

| Аспект | Поддержка |
|--------|-----------|
| `.doc-root.yaml` (`syntax: XML/Markdown`) | **Нет** |
| Кириллица → latin slug | **Нет** (пользователь сам именует) |
| Gramax-теги `<Image src="..." />` / `[drawio:...:WxH]` | **Нет** |
| Авто-вставка в `target_page.md` | **Нет** |
| Сохранение рядом с `.md`-страницей | Только если пользователь явно укажет путь |

## Совместимость с writer-skill

Прямой интеграции нет. Workflow становится двухшаговым:

1. Пользователь вызывает drawio-skill → получает `.drawio` + экспорт.
2. Пользователь вручную вставляет тег `[drawio:...]` или `<Image>` в md-страницу (writer-skill подскажет формат).

Текущий `writer/references/drawio.md` описывает workflow через `scripts/drawio_convert.py`. **При удалении скрипта эту часть нужно переписать**, иначе writer-skill будет советовать несуществующий путь.

## MCP / внешние сервисы

Никаких MCP. Только CLI draw.io + Python.

## Риски

1. **Сужение функциональности**: наш `diagram-on-demand` делал автовставку в md с учётом `.doc-root.yaml`. Внешний skill этого не умеет → ручной шаг вставки.
2. **Усложнение onboarding'а**: пользователь ставит draw.io desktop + Python 3 + marketplace + plugin вместо одного `/plugin install gramax`.
3. **Конфликт триггеров** с нашим `mermaid` skill — Claude может выбрать не тот skill при «нарисуй flowchart».
4. **Linux-нюансы**: snap-версия драки.io не работает; headless нужен xvfb. Документация нужна.
5. **Python 3 dependency**: на Linux/macOS обычно есть, на Windows — нет. Нужно явно прописать.

## Рекомендации BA/SA

1. **BA:** Зафиксировать в spec сужение UX — НЕ заявлять функциональный паритет. Acceptance Criteria должны это явно учитывать.
2. **BA:** Onboarding раздел в README должен покрывать: draw.io desktop (с платформенными деталями), Python 3, marketplace add, plugin install.
3. **SA:** Обязательно переписать `writer/references/drawio.md` — описать новый двухшаговый workflow, убрать ссылки на `drawio_convert.py`.
4. **SA:** Решить, нужно ли дополнить `mermaid` SKILL.md trigger-description для уменьшения конфликта с drawio-skill (явно ограничить triggers только mermaid-кейсами).
5. **SA:** В ADR-0008 — обозначить политику «сторонние диаграммные плагины»: рекомендуем drawio-skill из 365-skills; mermaid остаётся в нашем плагине; 365-skills/mermaid НЕ устанавливать одновременно (конфликт).

## Открытые вопросы для BA

- Хочет ли пользователь сохранить `[drawio:...]` Gramax-тег как канонический формат вставки drawio? Если да — нужна инструкция «после генерации вставь тег вручную / попроси writer-skill».
- Что делать на Windows без Python 3 — описывать установку или предупреждать?
