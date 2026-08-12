# plugins/gramax/scripts/lib/link_resolver.py
"""Продвинутый резолв markdown-ссылок: no-ext и hash-якоря.

Зеркалирует поведение Gramax при рендеринге:
- Ссылка без расширения [text](other) → other.md или other/index.md
- Якорь [text](article#section) → проверка заголовка в целевом файле
"""

import re
import unicodedata
from pathlib import Path

# Транслит кириллицы → latin (тот же набор, что в plugins/gramax/scripts/slugify.py).
# Gramax slugify транслитерирует кириллицу, а не вырезает её.
_TRANSLIT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd',
    'е': 'e', 'ё': 'yo', 'ж': 'zh', 'з': 'z', 'и': 'i',
    'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
    'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
    'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch',
    'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '',
    'э': 'e', 'ю': 'yu', 'я': 'ya',
}


def _find_headings(md_path: Path) -> list[str]:
    """Извлекает текст заголовков (## Title) из markdown-файла.
    Маскирует код-блоки чтобы заголовки внутри примеров не считались настоящими.
    """
    if not md_path.exists():
        return []
    text = md_path.read_text(encoding="utf-8")
    # Маскируем fenced code blocks
    lines = text.split("\n")
    in_fence = False
    headings: list[str] = []
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = re.match(r"^#{1,6}\s+(.+?)(?:\s*\{[^}]*\})?\s*$", line)
        if m:
            headings.append(m.group(1).strip())
    return headings


def slugify_heading(text: str) -> str:
    """Преобразует заголовок в slug для сравнения с hash-якорем.

    Правила (совместимо с Gramax рендерингом):
    - lowercase
    - кириллица → транслит (как в slugify.py)
    - убрать диакритику (NFKD → ascii)
    - пробелы → дефисы
    - оставить только [a-z0-9-]
    - схлопнуть повторяющиеся дефисы
    """
    text = unicodedata.normalize("NFKD", text)
    text = text.lower()
    result = []
    for ch in text:
        if ch in _TRANSLIT:
            result.append(_TRANSLIT[ch])
        elif ch.isalnum():
            result.append(ch)
        else:
            result.append("-")
    text = "".join(result)
    # Убираем диакритику (NFKD-распад латиницы) и оставшиеся не-ASCII
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-{2,}", "-", text)
    return text.strip("-")


def resolve_no_ext(candidate: Path) -> Path | None:
    """Резолвит markdown-ссылку без расширения.

    Пробует:
    1. candidate как есть (может быть папкой с index.md)
    2. candidate.md
    3. candidate/index.md (для ссылок на категории)

    Возвращает Path существующего файла или None.
    """
    # 1. Точное совпадение (может быть директория)
    if candidate.is_dir():
        index_md = candidate / "index.md"
        if index_md.exists():
            return index_md
        return None
    if candidate.is_file():
        return candidate
    # 2. candidate.md
    with_ext = candidate.with_suffix(".md")
    if with_ext.exists():
        return with_ext
    # 3. candidate/index.md
    index_md = candidate / "index.md"
    if index_md.exists():
        return index_md
    return None


def check_hash_anchor(target_md: Path, fragment: str) -> bool:
    """Проверяет существование hash-якоря в целевом markdown-файле.

    fragment — часть после #, например "my-section".
    Возвращает True если заголовок с таким slug существует.
    """
    if not fragment:
        return True  # нет якоря — OK
    headings = _find_headings(target_md)
    target_slug = slugify_heading(fragment)
    for h in headings:
        if slugify_heading(h) == target_slug:
            return True
    return False
