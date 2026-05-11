# Gramax Plugin Marketplace

Claude Code marketplace с плагинами для работы с документацией [Gramax](https://gramax.io/).

## Что внутри

- **`gramax`** (`./plugins/gramax/`) — основной плагин: создание и редактирование Gramax-документов, работа с комментариями, диаграммами (mermaid, drawio), координация ревью.

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

## Skills (плагин gramax)

- `/gramax:writer` — создание и редактирование Gramax-документов
- `/gramax:comments-read <path>` — показать комментарии
- `/gramax:comments-write <path>` — добавить / ответить / редактировать / удалить
- `/gramax:mermaid` — генерация mermaid-диаграмм inline (без MCP, адаптировано из axtonliu/axton-obsidian-visual-skills, MIT)
- `/gramax:drawio` — drawio-диаграммы через внешний плагин `Agents365-ai/drawio-skill` (двухшаговый workflow)

## Agents (плагин gramax)

- `review-agent` — координация ревью комментариев в каталоге (запуск через Task tool)

## Третьи стороны

- **axton-obsidian-visual-skills** by [Axton Liu](https://github.com/axtonliu) — лицензия MIT, адаптирован в `gramax:mermaid` skill. Upstream: https://github.com/axtonliu/axton-obsidian-visual-skills

## Лицензия

- Код в `plugins/gramax/` — MIT (см. [LICENSE](./LICENSE)).

## Версии

См. [CHANGELOG.md](./CHANGELOG.md) — версия marketplace в целом, и [plugins/gramax/CHANGELOG.md](./plugins/gramax/CHANGELOG.md) — версия gramax-плагина.
