# plugins/gramax/scripts/lib/link_resolver.py
"""Продвинутый резолв markdown-ссылок и hash-якоря.

Единственный резолвер ссылок плагина (ADR-0028 Решение 4, поправка к ADR-0016
Решение 1) — `resolve_link_target(source_dir, target, *, index_optional=False)`.
Зеркалирует поведение Gramax при рендеринге (linkCreator.ts:99-176 на пине
48592b36) и проверке на ошибки (Healthcheck.ts:192-201, `app/config/const.ts:32-33`):
- Ссылка без расширения [text](other) → other.md или other/_index.md
  (корень раздела движка — `_index.md`);
- Каталог без `_index.md` без флага не резолвится (`None`) — раздел становится
  только при `optionalCategoryIndex: true` (FileStructure.ts:528-531, `:653`);
- При одноимённых файле и каталоге побеждает файл;
- Якорь [text](article#section) → проверка заголовка в целевом файле.
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


def resolve_link_target(source_dir: Path, target: str, *,
                        index_optional: bool = False) -> Path | None:
    """Резолвит `target` ссылки относительно `source_dir` (ADR-0028 Решение 4).

    Порядок кандидатов; возвращается первый подошедший, иначе `None` (дизайн
    волны-4 §3.4):

    1. литерал `(source_dir / target).resolve()` — `is_file()`;
    2. `source_dir / (target + ".md")` — только для цели без `.md` на конце —
       `is_file()` (второго `.md` не появляется, AC-011b);
    3. литерал / `"_index.md"` — `is_file()` (корень раздела движка — `_index.md`,
       `app/config/const.ts:32-33` на пине 48592b36);
    4. литерал — каталог, только при `index_optional=True` — `is_dir()`
       (FileStructure.ts:653).

    Каталог не считается файлом: без `_index.md` и без флага цель не резолвится
    (`None`); при одноимённых файле и каталоге побеждает файл (каталог не проходит
    шаг 1, файл находится на шаге 2). До трёх обращений к файлу и одного к каталогу
    на ссылку (NFR-002)."""
    literal = (source_dir / target).resolve()
    if literal.is_file():
        return literal
    if not target.endswith(".md"):
        with_md = (source_dir / f"{target}.md").resolve()
        if with_md.is_file():
            return with_md
    index_md = literal / "_index.md"
    if index_md.is_file():
        return index_md
    if index_optional and literal.is_dir():
        return literal
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
