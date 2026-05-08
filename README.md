# Gramax Plugin Marketplace

Claude Code marketplace с плагинами для работы с документацией [Gramax](https://gramax.io/).

## Что внутри

- **`gramax`** (`./plugins/gramax/`) — основной плагин: создание и редактирование Gramax-документов, работа с комментариями, диаграммами, координация ревью.
- **`claude-mermaid`** (`./plugins/claude-mermaid/`) — vendored сторонний плагин (см. [veelenga/claude-mermaid](https://github.com/veelenga/claude-mermaid), MIT). Live-preview для mermaid-диаграмм через MCP. Подключён как git submodule.

## Установка

### Вариант 1: через Claude Code (рекомендуемо)

```
/plugin marketplace add mdemyanov/gramax-plugin
/plugin install gramax@gramax-marketplace
/plugin install claude-mermaid@gramax-marketplace
```

### Вариант 2: локальный clone (для разработки плагина)

```bash
git clone --recurse-submodules https://github.com/mdemyanov/gramax-plugin.git
cd gramax-plugin
# затем в Claude Code:
/plugin marketplace add /absolute/path/to/gramax-plugin
```

Если уже клонировал без `--recurse-submodules`:
```bash
git submodule update --init --recursive
```

## Skills (плагин gramax)

- `/gramax:writer` — создание и редактирование Gramax-документов
- `/gramax:comments-read <path>` — показать комментарии
- `/gramax:comments-write <path>` — добавить / ответить / редактировать / удалить
- `/gramax:diagrams` — правила drawio / mermaid в Gramax

## Agents (плагин gramax)

- `review-agent` — координация ревью комментариев в каталоге (запуск через Task tool)

## Третьи стороны

- **claude-mermaid** by [veelenga](https://github.com/veelenga) — лицензия MIT, копия включена через git submodule. Upstream: https://github.com/veelenga/claude-mermaid

## Лицензия

- Код в `plugins/gramax/` — MIT (см. [LICENSE](./LICENSE)).
- `plugins/claude-mermaid/` — лицензия upstream (MIT), см. файл LICENSE внутри подмодуля.

## Версии

См. [CHANGELOG.md](./CHANGELOG.md) — версия marketplace в целом, и [plugins/gramax/CHANGELOG.md](./plugins/gramax/CHANGELOG.md) — версия gramax-плагина.
