# Gramax Plugin Marketplace

Claude Code marketplace с плагинами для работы с документацией [Gramax](https://gram.ax/resources/docs).

## Что внутри

- **`gramax`** (`./plugins/gramax/`) — основной плагин: создание и редактирование Gramax-документов, работа с комментариями, диаграммами (mermaid, plantuml/bpmn, drawio), экспорт (DOCX/PDF, статический портал), координация ревью.

## Установка

### Вариант 1: через Claude Code (рекомендуемо)

```
/plugin marketplace add mdemyanov/gramax-plugin
/plugin install gramax@gramax-marketplace
```

### Вариант 2: локальный clone (для разработки плагина)

```bash
git clone https://github.com/mdemyanov/gramax-plugin.git
cd gramax-plugin
# затем в Claude Code:
/plugin marketplace add /absolute/path/to/gramax-plugin
```

## Разработка этого репозитория

Работа над плагином ведётся ролями из marketplace `nauta` (`/nauta:ba`, `/nauta:sa`, `/nauta:dev`, …) — собственных агентов репозиторий не держит. Установка на чистой машине, пререквизиты (`uv`, git-хуки) и проверка — в [docs/onboarding-nauta.md](docs/onboarding-nauta.md).

## Skills (плагин gramax)

- `/gramax:writer` — создание и редактирование Gramax-документов
- `/gramax:comments-read <path>` — показать комментарии
- `/gramax:comments-write <path>` — добавить / ответить / редактировать / удалить
- `/gramax:mermaid` — генерация mermaid-диаграмм: создаёт `.mermaid`-файл рядом со статьёй и вставляет тег-ссылку в md (без MCP, адаптировано из axtonliu/axton-obsidian-visual-skills, MIT)
- `/gramax:plantuml` — генерация PlantUML/BPMN-диаграмм (включая Salt-макеты интерфейсов): создаёт `.puml`/`.bpmn`-файл рядом со статьёй и вставляет тег-ссылку в md; рендер — движок Gramax
- `/gramax:drawio` — drawio-диаграммы через внешний плагин `Agents365-ai/drawio-skill` (двухшаговый workflow)
- `/gramax:export` — экспорт DOCX/PDF (шаблоны, CLI, CI/CD) и сборка статического портала; исполнение — Node.js/`gramax-cli` в окружении пользователя

## Agents (плагин gramax)

- `review-agent` — координация ревью комментариев в каталоге (запуск через Task tool)

## Предусловия skill'а drawio (внешний плагин)

`/gramax:drawio` — делегатор: исполнение живёт во внешнем плагине `drawio-skill` из
marketplace `Agents365-ai/365-skills` (установка: `/plugin marketplace add Agents365-ai/365-skills`,
затем `/plugin install drawio@...`). Предусловия по [ADR-0008](docs/00-project/adr/0008-drop-internal-drawio-skills.md)
и [RES-001](docs/10-domain/research/2026-05-11-drawio-skill-external.md):

- **draw.io desktop (CLI)** — обязателен, версия не фиксирована: macOS — `brew install --cask drawio`;
  Windows — инсталлятор с GitHub Releases; Linux — `.deb`/`.rpm`, **не snap** (AppArmor-sandbox
  блокирует keyring); на headless-сервере дополнительно `sudo apt install xvfb` + `xvfb-run -a`.
- **Python 3** — нужен для `repair_png.py` (починка PNG после экспорта с `-e`); на Windows
  системно не ставится — установи с python.org, иначе шаг экспорта PNG падает.

> **Warning:** не устанавливай `mermaid` из 365-skills параллельно с `gramax:mermaid` — конфликт триггеров:
> оба skill'а описывают «диаграммы/flowchart» семантическим триггером, и выбор между ними
> недетерминирован (ADR-0008 Решение 6). Для drawio ставь только `drawio` из 365-skills;
> mermaid-диаграммы остаются за `gramax:mermaid` и `gramax:plantuml`.

## Третьи стороны

- **axton-obsidian-visual-skills** by [Axton Liu](https://github.com/axtonliu) — лицензия MIT, адаптирован в `gramax:mermaid` skill. Upstream: https://github.com/axtonliu/axton-obsidian-visual-skills

## Лицензия

- Код в `plugins/gramax/` — MIT (см. [LICENSE](./LICENSE)).

## Версии

См. [plugins/gramax/CHANGELOG.md](./plugins/gramax/CHANGELOG.md) — единственный действующий
журнал релизов; версия плагина и metadata.version marketplace.json держатся синхронными.
[CHANGELOG.md](./CHANGELOG.md) в корне — архив записей marketplace 1.0.0–3.0.0, заморожен на
3.0.0 (2026-05-11).
