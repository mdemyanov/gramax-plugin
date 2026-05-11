# Upstream attribution

Skill `gramax:mermaid` адаптирован из проекта [axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills/tree/main/mermaid-visualizer), автор: Axton Liu, лицензия: MIT.

## Список изменений относительно upstream

- `SKILL.md` — перевод на русский, удалены Obsidian-специфичные секции, добавлены:
  - Учёт `.doc-root.yaml` (XML vs Markdown синтаксис) для Gramax-каталога.
  - Список 8 поддерживаемых типов в Gramax и явный stop-list (`gitGraph`, `journey`, `requirementDiagram`, `C4Context`).
  - Workflow с открытием `.doc-root.yaml` и вставкой блока в md-страницу.
  - Frontmatter `name: mermaid` (вместо `mermaid-visualizer`).
- `references/syntax-rules.md` — перевод на русский, добавлен раздел «Особенности Gramax» с поддерживаемыми типами и `.doc-root.yaml`-конвенциями; платформозависимые заметки об Obsidian/GitHub удалены.
- Удалена зависимость от MCP `claude-mermaid` — skill полностью inline, генерирует DSL и вставляет в md без внешних серверов.

## MIT License (upstream)

```
MIT License

Copyright (c) 2025 Axton Liu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Совместимость с лицензией gramax-marketplace

Плагин `gramax` — MIT (см. `plugins/gramax/.claude-plugin/plugin.json`). Адаптация совместима: оба MIT, attribution сохранена в этом файле.
