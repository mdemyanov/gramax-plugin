# Upstream attribution

Скрипт `validate_render.py` (и правила рендер-киллеров, которые он реализует) — порт
`validate-gramax.py` из плагина `gramax-skills` (sandbox-marketplace, внутренний GitLab
`gitlab-it.nau.im/ai/claude-code/sandbox-marketplace`), автор: Всеволод Шадрин, лицензия: MIT.

В исходнике коллег нет явного copyright-заголовка — атрибуция выводится из provenance
плагина `gramax-skills` (BA факт 6, ADR-0019 Решение 7).

## Список изменений относительно upstream

- **Двойное маскирование кода** (fenced **+ inline**, FR-110): upstream маскирует только
  fenced-блоки, из-за чего `<th>`/`<note>` в inline-коде прозы давали 11 ложных ERROR на
  собственном каталоге. Порт использует общий примитив `lib/md_code_mask.py`
  (`_mask_code`, извлечён из `validate_structure.py`, ADR-0019 Решение 5).
- **Severity-модель ERROR/WARN** (FR-113, ADR-0019 Решение 8): киллеры рендера
  (FR-104…FR-109) — ERROR безусловно, стиль/YAML (FR-111, FR-112) — WARN; флага
  `--strict`, как у структурного валидатора, нет (BR-001: класс киллера не понижается).
- **Exit-контракт 0/1/2** (NFR-001): 0 — ERROR нет (WARN допустимы), 1 — есть ERROR,
  2 — некорректное использование (нет валидного целевого файла/каталога).
- **Демаркация с W034** (`validate_structure.py`, ADR-0019 Решение 3): `<th>` владеет
  рендер-линтер как ERROR; структурный валидатор не дублирует его («одна находка на
  дефект», BR-004). `_KNOWN_TAGS` вычисляется из `gramax-render-rules.json`
  (drawio ∪ killerTags ∪ allowlistedTags).
- **Allowlist «не ошибки»** (FR-115…FR-118): `<colgroup>`/`<col>`, эмодзи в `##`,
  скобки/спецсимволы в XML-атрибутах, многоабзацная ячейка `<td>` не флагаются
  ни ERROR, ни WARN. Реестр — `gramax-render-rules.json` (данные, BR-002/BR-003).
- **Ownership баланса** (ADR-0019 Решение 6): рендер-линтер балансит полный набор
  FR-109 (`note, table, tr, td, th, tabs, tab, color, highlight`);
  `check_tags` дедуплицируется до `pairedTags − balanceTags` (`html, comment`).
- **Контекстные правила в коде** (стековый проход): `<note>` в `<td>`/`<th>`,
  `<note>` в `<note>`, инлайновый `<note>` в одну строку — алгоритмы, не данные
  (ADR-0019 Решение 2).
- **Номер строки для unbalanced-правила** (улучшение над upstream L0, BA «Открытый
  вопрос 5»): сообщение несёт первую строку, где счётчики открыто/закрыто разошлись.

## MIT License (upstream)

```
MIT License

Copyright (c) 2026 Всеволод Шадрин

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

Плагин `gramax` — MIT (см. `plugins/gramax/.claude-plugin/plugin.json`). Порт совместим:
оба MIT, атрибуция сохранена в этом файле и в шапке `validate_render.py`.
