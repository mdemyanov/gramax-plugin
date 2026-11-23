"""Маскирование кода (fenced + inline) для валидаторов Gramax.

Единственный источник правды для анти-ложносрабатывающего примитива маскирования
кода: и `validate_structure.py`, и `validate_render.py` импортируют его из `lib/`
(ADR-0019, Решение 5). Копия в два места дрейфовала бы (дух BR-002).

Статья, документирующая Gramax-синтаксис, может показывать `<note>`, `{{ИМЯ}}`
или `[пример](ссылка.md)` как иллюстрацию, а не как реальную разметку — без маски
баланс-/киллер-/ссылочные проверки давали бы ложные срабатывания. Маскирование
заменяет код пробелами той же длины, сохраняя смещения строк (номера строк
остаются валидными для отчётов).

Тот же приём для блоков сырого HTML `<html>…</html>` (FR-216, ADR-0026 через
`_mask_html_blocks`): движок пропускает их содержимое как есть — внутри легальны
любые HTML-теги, и построчные проверки (W034, W035) и баланс не должны судить их
как разметку страницы. Механика — порт `html_mask()` апстрим-линтера
(провенанс — `LICENSE.upstream.md`, ADR-0019).
"""

import re

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")
# Открывающий тег внешней пары html: допускается форма с атрибутами (парсер тегов
# движка — общий для pairedTags), самозакрытая `<html/>` открывающей не считается —
# та же семантика, что у открывающего регэкспа check_tags (`(?<!/)>`).
_HTML_OPEN_RE = r"<html(?:\s[^>]*)?>"


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


def _mask_html_blocks(text: str) -> str:
    """Заменяет содержимое блоков `<html>…</html>` пробелами той же длины, сохраняя
    смещения строк (FR-216, ADR-0026; механика апстрим-`html_mask()`).

    Применяется ПОСЛЕ `_mask_code` (дизайн волны-3 §6): `<html>` внутри fenced- или
    inline-кода уже замаскирован и маску не переключает. Теги внешней пары остаются
    на месте — `check_tags` продолжает балансировать внешнюю пару html, а баланс
    validate_render видит открывающий/закрывающий теги блока. Соседние блоки
    маскируются каждый своей парой (сопоставление до ближайшего `</html>`, как
    блок заканчивает движок); непарный `<html>` без закрывающего не маскируется —
    баланс внешней пары остаётся находкой.
    """
    pattern = re.compile(_HTML_OPEN_RE + r".*?</html>", re.DOTALL)

    def _blank_body(match: re.Match) -> str:
        block = match.group(0)
        open_len = re.match(_HTML_OPEN_RE, block).end()
        body = block[open_len:-len("</html>")]
        return block[:open_len] + re.sub(r"[^\n]", " ", body) + "</html>"

    return pattern.sub(_blank_body, text)
