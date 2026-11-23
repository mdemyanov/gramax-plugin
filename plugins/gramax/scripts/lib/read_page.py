"""Чтение страницы каталога с диагностикой битого UTF-8 (ADR-0026, Решение 6).

Единый примитив чтения текстовых файлов каталога (`.md`, `.comments.yaml`,
`.doc-root.yaml`) для валидаторов. Прямое `path.read_text(encoding="utf-8")` роняет
скрипт UnicodeDecodeError'ом: traceback, обрыв обхода, путь файла не назван.
`read_page` декодирует строго и на неудачу возвращает диагностику первого неверного
байта вместо исключения:

    from lib.read_page import read_page, utf8_message

    text, err = read_page(path)
    if err is None:
        ...  # обычная обработка text
    else:
        # err.byte_hex — два шестнадцатеричных разряда первого неверного байта ('d0')
        # err.start    — позиция первого неверного байта с нуля (UnicodeDecodeError.start)
        # err.size     — размер файла в байтах
        # utf8_message(err) — общий фрагмент формулировки:
        #   'файл не является валидным UTF-8 (байт 0xd0 на позиции 121 из 123)'

Формулировки находок по уровням — дословно дизайн волны-3 §2.4, за вызывающей стороной:

    validate_render.py                        → `ERROR L0: Файл не является валидным UTF-8 (…)`
    validate_structure.py, validate_comments.py → `E036: файл не является валидным UTF-8 (…)`
    parse_comments.py (stderr)                → `WARNING: {path}: файл не является валидным UTF-8 (…) — файл пропущен`

На файл с битым UTF-8 — ровно одна находка, проверки текста этого файла пропускаются,
обход продолжается (BR-004). Пустой файл — не ошибка (возвращается пустая строка).

Провенанс механики — `read_page()` апстрим-линтера `validate-gramax.py` плагина
`gramax-skills` (© Всеволод Шадрин, MIT), MIT-порт по ADR-0019; полный текст лицензии
и список изменений — `LICENSE.upstream.md` рядом со скриптами.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class PageReadError:
    """Диагностика первого неверного байта файла с битым UTF-8."""

    byte_hex: str  # два шестнадцатеричных разряда со строчными буквами, без префикса ('d0')
    start: int     # позиция первого неверного байта с нуля (UnicodeDecodeError.start)
    size: int      # размер файла в байтах


def utf8_message(err: PageReadError) -> str:
    """Общий фрагмент формулировки про битый UTF-8 (дословно — дизайн §2.4)."""
    return f"файл не является валидным UTF-8 (байт 0x{err.byte_hex} на позиции {err.start} из {err.size})"


def read_page(path: Path) -> tuple[str | None, PageReadError | None]:
    """Прочитать файл как текст UTF-8: `(text, None)` или `(None, PageReadError)`.

    Декодирование строгое (`errors="strict"`); исключение UnicodeDecodeError
    преобразуется в `PageReadError` с байтом, позицией и размером файла.
    """
    data = Path(path).read_bytes()
    try:
        return data.decode("utf-8"), None
    except UnicodeDecodeError as e:
        byte = data[e.start] if e.start < len(data) else data[-1]
        return None, PageReadError(byte_hex=f"{byte:02x}", start=e.start, size=len(data))
