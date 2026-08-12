"""Маскирование кода (fenced + inline) для валидаторов Gramax.

Единственный источник правды для анти-ложносрабатывающего примитива маскирования
кода: и `validate_structure.py`, и `validate_render.py` импортируют его из `lib/`
(ADR-0019, Решение 5). Копия в два места дрейфовала бы (дух BR-002).

Статья, документирующая Gramax-синтаксис, может показывать `<note>`, `{{ИМЯ}}`
или `[пример](ссылка.md)` как иллюстрацию, а не как реальную разметку — без маски
баланс-/киллер-/ссылочные проверки давали бы ложные срабатывания. Маскирование
заменяет код пробелами той же длины, сохраняя смещения строк (номера строк
остаются валидными для отчётов).
"""

import re

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")


def _mask_code(text: str) -> str:
    """Заменяет код (fenced-блоки и inline) пробелами той же длины, сохраняя смещения строк.

    Статья, документирующая Gramax-синтаксис, может показывать `[пример](ссылка.md)` или
    `{{ИМЯ}}` как иллюстрацию, а не как реальную ссылку/протёкший плейсхолдер. Без маски
    orphan-/broken-link-/placeholder-проверки давали бы ложные срабатывания на таких примерах.
    """
    out: list[str] = []
    fence_char: str | None = None
    fence_len = 0
    for line in text.split("\n"):
        m = _FENCE_RE.match(line)
        if fence_char is None:
            if m:
                fence_char, fence_len = m.group(1)[0], len(m.group(1))
                out.append(" " * len(line))
            else:
                out.append(line)
            continue
        if m and m.group(1)[0] == fence_char and len(m.group(1)) >= fence_len and not m.group(2).strip():
            fence_char, fence_len = None, 0
        out.append(" " * len(line))
    return _INLINE_CODE_RE.sub(lambda m: " " * len(m.group(0)), "\n".join(out))
