#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Классификация и миграция навигационных код-спанов (`` `content/<путь>.md` ``) в
markdown-ссылки.

Требование: `content/30-requirements/2026-08-13-link-form-contract.md` (FR-077…081, FR-091,
FR-092). ADR: `content/00-project/adr/0016-link-form-contract.md` (Решения 2, 3, 5).
Архитектура: `content/40-architecture/2026-08-13-link-form-contract-design.md`, «Бриф для Dev»
пп. 5–7. Прецедент структуры: `plugins/gramax/scripts/migrate_mermaid.py` (PEP 723, только
stdlib, dry-run по умолчанию, `--fix --yes` — мутация).

Классификация код-спана с путём (FR-077…FR-079), в порядке приоритета:
  1. **SELF** (FR-078) — цель код-спана совпадает с путём документа-источника. Приоритет над
     остальными тестами; никогда не мигрируется и не удаляется (BR-001).
  2. Иначе три теста FR-077 по порядку — все три обязаны быть истинны для класса **NAV**:
     a. **directionality** — маркер направления («см.», «зафиксировано в», «обоснование в»,
        «дополняет», «supersedes», «применяет» и аналогичные, включая шаблонные шапки
        `**ADR:**`/`**Spec:**`/`**Требование:**`, когда цель — НЕ сам документ) непосредственно
        перед код-спаном (окно от начала абзаца или от конца предыдущего кандидата).
     b. **existence** — цель физически существует на момент запуска.
     c. **scope** — цель резолвится внутри переданного `.doc-root.yaml`-каталога И абзац не
        называет цель принадлежащей другому репозиторию/проекту (лексические маркеры вида «в
        другом репозитории», «не в этом» — регрессионная защита FR-077 теста 3 от гомонима
        пути, прецедент RES-005 3.4).
  3. Иначе — **SUBJECT** (не мигрируется, не репортится построчно — только счётчиком).

Маскирование код-спанов/fenced-блоков (`_mask_code`, `_FENCE_RE`, `_INLINE_CODE_RE`) —
побайтовая копия алгоритма `plugins/gramax/scripts/validate_structure.py::_mask_code` (НЕ
импорт — прецедент RES-005 «побайтовая копия, не эквивалентная»), используется здесь для
поиска маркеров направления в окрестности код-спана без ложных срабатываний на словах внутри
ДРУГИХ код-спанов/fenced-примеров того же абзаца. Обнаружение самих код-спанов-кандидатов
(нужно СОХРАНИТЬ содержимое, не замаскировать) идёт по отдельному, только-fence-маскированию
(`_mask_fences_only`) — тот же построчный алгоритм fence-детекции, что и в `_mask_code`, без
финального шага маскирования inline-кода.

Форма результата NAV (FR-080, FR-081, ADR-0016 Решение 2 — временный протокол): markdown-ссылка
`[title цели](относительный-путь.md)` — текст механически берётся из `title` frontmatter цели
(не из заголовка `#`, не из имени файла), href — относительный путь (`os.path.relpath`-стиля) С
ЯВНЫМ `.md`-суффиксом (не канонический FR-080 «без расширения» — расхождение специфично только
этому репозиторию, пока апстрим nauta не инферит расширение, ADR-0016 Решение 2). Путь никогда
не начинается с имени doc-root-каталога (антипаттерн FR-081) — гарантировано конструктивно:
и источник, и цель код-спана всегда лежат внутри одного и того же `path`-аргумента.

Режимы:
  (по умолчанию) — только отчёт: `<путь>:<строка> NAV -> <относительный путь цели>` для каждого
    NAV-кандидата + сводка (`To-migrate`/`SELF`/`SUBJECT`). Ничего не мутирует.
  --fix --yes    — мутирует: каждый NAV-код-спан заменяется markdown-ссылкой. Требует
    `--expect-count=N`, совпадающий с пересчитанным числом NAV-кандидатов НА МОМЕНТ ЗАПУСКА
    (дефолт 103 — снимок реального корпуса, RES-005, ADR-0016 Решение 5); расхождение —
    hard guard: abort БЕЗ мутаций, ненулевой exit. Guard применяется только к `--fix --yes` —
    report-mode всегда просто печатает пересчитанный отчёт, не сверяясь с ожиданием (иначе
    первый же разведывательный прогон без `--expect-count` был бы бесполезен для получения
    актуального числа).

`path`-аргумент — сам `.doc-root.yaml`-каталог (`uv run migrate_nav_codespans.py content`), по
конвенции `validate_structure.py` — не произвольный scan-root с поиском вложенных доc-root'ов.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

DOC_URL = "https://github.com/mdemyanov/gramax-plugin"
EPILOG = (
    "Документация: content/40-architecture/2026-08-13-link-form-contract-design.md "
    "(«Бриф для Dev»), content/00-project/adr/0016-link-form-contract.md (Решения 2, 3, 5). "
    f"Репозиторий: {DOC_URL}"
)

DEFAULT_EXPECT_COUNT = 103  # снимок реального корпуса на момент RES-005 (ADR-0016 Решение 5).

# ===== Побайтовая копия validate_structure.py::_mask_code (см. докстринг модуля) ============

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")

# Markdown-ссылка — независимая копия по прецеденту `validate_structure.py::_MD_LINK_RE`,
# нужна ТОЛЬКО для отслеживания границы окна маркеров (см. `_boundary_ends` ниже), не для
# резолва/orphan-проверки (это территория validate_structure.py, не трогается этим скриптом).
_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")


def _mask_code(text: str) -> str:
    """Байт-в-байт копия `validate_structure.py::_mask_code` — маскирует и fenced-блоки, и
    inline-код пробелами той же длины, сохраняя смещения строк. НЕ импортируется (прецедент
    RES-005 «побайтовая копия, не эквивалентная»)."""
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


def _mask_fences_only(text: str) -> str:
    """Тот же построчный fence-алгоритм, что первая половина `_mask_code` — БЕЗ финального шага
    маскирования inline-кода, чтобы содержимое код-спанов-кандидатов осталось читаемым.
    Используется только для поиска код-спанов (не для поиска маркеров направления — там нужен
    полный `_mask_code`, см. докстринг модуля)."""
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
    return "\n".join(out)


# ===== Классификация (FR-077…FR-079) =========================================================

# FR-077 test 1 — маркеры направления. Список из требования плюс шаблонные шапки
# **ADR:**/**Spec:**/**Требование:**/**Тест-отчёт:** (RES-005 «Задача 1», intro) — эти же шапки
# оборачивают и SELF-случаи, но SELF-приоритет (FR-078) проверяется раньше directionality, так
# что конфликта нет.
_DIRECTIONALITY_RE = re.compile(
    r"(?i)"
    r"\bсм\.\s"
    r"|\bсмотр\w*"
    r"|зафиксир\w*\s+в\b"
    r"|обоснован\w*\s+в\b"
    r"|дополня\w*"
    r"|supersedes"
    r"|примен\w*"
    r"|прецедент\w*"
    r"|\*\*(?:ADR|Spec|Требование|Тест-отчёт|Архитектура)\s*:\*\*"
    r"|\b(?:ADR|Spec|Требование|Тест-отчёт|Архитектура|Разведка|Research|research)\s*\(?\s*$"
)

# Структурный маркер: пункт списка вида `- <label>: `путь1`, `путь2`, ...` (или нумерованный
# `N. **Label** — `путь`, `путь`, ...`) в разделе «## Связанные артефакты»/перечислении
# источников (найдено повсеместно реальным корпусом при калибровке против RES-005 — «spec:»,
# «требование:», «research:», «дополняет:», «применяет semver-policy:», «**История и решения**
# —» и т. п. — структура пункта списка надёжнее, чем перечисление каждого возможного
# слова-метки). Метка проверяется у НАЧАЛА пункта списка — код-спан может быть вторым/третьим в
# comma-separated перечислении целей одного и того же пункта, не только первым сразу после
# метки.
_BULLET_START_RE = re.compile(r"(?:^|\n)(?:-|\d+\.)[ \t]+")
_BULLET_LABEL_PREFIX_RE = re.compile(r"\A[^\n`]{1,80}?(?::|—)")


def _has_bullet_label_marker(marker_source: str, paragraph_start: int, span_start: int) -> bool:
    search_region = marker_source[paragraph_start:span_start]
    last_bullet_end = None
    for bm in _BULLET_START_RE.finditer(search_region):
        last_bullet_end = paragraph_start + bm.end()
    if last_bullet_end is None:
        return False
    prefix = marker_source[last_bullet_end:span_start]
    return bool(_BULLET_LABEL_PREFIX_RE.match(prefix))


def _current_bullet_bounds(source: str, paragraph_start: int, paragraph_end: int, pos: int) -> tuple[int, int]:
    """Границы ТЕКУЩЕГО пункта списка (от последнего маркера `- `/`N. ` до pos, до следующего
    такого маркера после pos) — используется, чтобы cross-repo-проверка (FR-077 test 3) не
    "протекала" на СОСЕДНИЕ пункты одного нумерованного/маркированного списка (реальный корпус:
    numbered-list с несколькими самостоятельными пунктами внутри одного blank-line-абзаца).
    Вне списка (нет маркера) — деградирует до границ всего абзаца, как раньше."""
    head = source[paragraph_start:pos]
    last_start = None
    for bm in _BULLET_START_RE.finditer(head):
        last_start = paragraph_start + bm.start()
    if last_start is None:
        return paragraph_start, paragraph_end
    tail = source[pos:paragraph_end]
    nm = _BULLET_START_RE.search(tail)
    end = pos + nm.start() if nm else paragraph_end
    return last_start, end


def _closest_link_end_before(link_ends: list[int], pos: int) -> int:
    """Наибольший конец markdown-ссылки, не превышающий `pos` (0, если ни одна не подходит).

    Нужно для ИДЕМПОТЕНТНОСТИ окна маркеров направления (`window_start`): без этой поправки
    повторный прогон ПОСЛЕ `--fix --yes` находит ложные NAV-кандидаты — предыдущий код-спан
    того же предложения/списка, уже смигрированный в markdown-ссылку на первом прогоне, больше
    не совпадает с `_INLINE_CODE_RE` (это уже не код-спан), поэтому перестаёт ограничивать
    окно поиска маркера у СЛЕДУЮЩЕГО код-спана — маркер из-ЗА только что созданной ссылки
    (например, «прецедент —» перед первой ссылкой инлайн-перечисления) «протекает» на второй,
    третий и т. д. элементы того же перечисления, которые сами по себе марkера не несут.
    Отслеживание конца markdown-ссылки как ТАКОЙ ЖЕ границы, какой была граница код-спана,
    делает повторный прогон детерминированно тем же, что и первый (найдено обнаружено при
    контроле реальной миграции против RES-005 — см. заметку реализации)."""
    best = 0
    for end in link_ends:
        if end <= pos and end > best:
            best = end
        elif end > pos:
            break
    return best


# FR-077 test 3 — граница scope: гомоним пути из ДРУГОГО репозитория (RES-005 3.4, AC-004).
# Существование+буквальный резолв внутри root уже механичны — этот маркер снимает ложный NAV на
# синтаксически совпадающем, но семантически чужом пути. Последняя альтернатива —
# «репозиторий `name`» (именование конкретного стороннего репозитория рядом с кодом-спаном,
# найдено калибровкой против RES-005 — вендорский корпус `gramax-user-docs` и т. п.) — ищется
# в `fenced_masked` (fenced-блоки вырезаны, inline-код виден), не в полностью замаскированном
# `_mask_code`, потому что бэктики самого имени репозитория нужны для совпадения.
_CROSS_REPO_RE = re.compile(
    r"(?i)"
    r"не\s+в\s+этом\b"
    r"|друг(?:ом|ого|ой|ая)\s+(?:репозитори\w*|проект\w*)"
    r"|чуж(?:ом|ого|ой|ая)\s+(?:репозитори\w*|проект\w*)"
    r"|соседн\w*.{0,40}?(?:репозитори\w*|проект\w*)"
)
_CROSS_REPO_NAMED_RE = re.compile(r"(?i)репозитори\w*\s*`")

_BLANK_LINE_RE = re.compile(r"\n[ \t]*\n")

_FRONTMATTER_TITLE_RE = re.compile(r"^title:\s*(.+)$", re.MULTILINE)


class Occurrence:
    """Один найденный код-спан-кандидат (содержимое соответствует `<root.name>/…\\.md`)."""

    __slots__ = ("md_file", "line", "start", "end", "raw", "cls", "target")

    def __init__(self, md_file: Path, line: int, start: int, end: int, raw: str, cls: str, target: Path):
        self.md_file = md_file
        self.line = line
        self.start = start  # начало полного совпадения (открывающие бэктики)
        self.end = end      # конец полного совпадения (закрывающие бэктики)
        self.raw = raw       # содержимое код-спана как есть, напр. "content/nav-target.md"
        self.cls = cls        # "SELF" | "NAV" | "SUBJECT"
        self.target = target  # резолвленный путь цели


def _line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def _paragraph_bounds(text: str, pos: int) -> tuple[int, int]:
    """Границы абзаца (blank-line-delimited блока), содержащего позицию `pos`."""
    start = 0
    for bm in _BLANK_LINE_RE.finditer(text, 0, pos):
        start = bm.end()
    end_match = _BLANK_LINE_RE.search(text, pos)
    end = end_match.start() if end_match else len(text)
    return start, end


def _extract_title(text: str) -> str | None:
    """Значение `title` frontmatter (без кавычек) — механический дефолт текста ссылки
    (ADR-0016 Решение 5). Только stdlib — regex, не полноценный YAML-парсер (PEP 723 этого
    скрипта не тянет `pyyaml`, в отличие от `validate_structure.py`)."""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    m = _FRONTMATTER_TITLE_RE.search(text[3:end])
    if not m:
        return None
    raw = m.group(1).strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in ("'", '"'):
        raw = raw[1:-1]
    return raw or None


def _collect_md_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.md") if ".gramax" not in p.parts)


def classify_file(root: Path, md_file: Path, text: str, content_path_re: re.Pattern) -> list[Occurrence]:
    """Все код-спаны-кандидаты (`<root.name>/…\\.md`) файла, классифицированные SELF/NAV/SUBJECT
    по FR-077…FR-079, отсортированные по позиции."""
    fenced_masked = _mask_fences_only(text)  # inline-код цел, fenced-содержимое обнулено
    marker_source = _mask_code(text)         # и fenced, и inline обнулены — для поиска маркеров
    root_resolved = root.resolve()
    md_resolved = md_file.resolve()
    # Уже существующие (или ранее в этом же прогоне созданные — не актуально, файл читается
    # один раз до мутации) markdown-ссылки — граница окна маркеров наравне с код-спанами
    # (см. `_closest_link_end_before`), для идемпотентности повторного прогона после `--fix`.
    link_ends = sorted(lm.end() for lm in _MD_LINK_RE.finditer(fenced_masked))

    occs: list[Occurrence] = []
    prev_end = 0
    for m in _INLINE_CODE_RE.finditer(fenced_masked):
        raw = m.group(2)
        if not content_path_re.fullmatch(raw):
            continue
        span_start, span_end = m.start(), m.end()
        rel_after_root = raw[len(root.name) + 1 :]
        target = (root / rel_after_root).resolve()

        if target == md_resolved:
            occs.append(Occurrence(md_file, _line_of(text, span_start), span_start, span_end, raw, "SELF", target))
            prev_end = span_end
            continue

        paragraph_start, paragraph_end = _paragraph_bounds(text, span_start)
        window_start = max(paragraph_start, prev_end, _closest_link_end_before(link_ends, span_start))
        window = marker_source[window_start:m.start(1)]
        has_marker = bool(_DIRECTIONALITY_RE.search(window)) or _has_bullet_label_marker(
            marker_source, paragraph_start, m.start(1)
        )

        exists = target.exists()
        in_root = target == root_resolved or root_resolved in target.parents
        # Cross-repo-проверка ограничена ТЕКУЩИМ пунктом списка (если код-спан внутри
        # списка) — иначе гомоним чужого репозитория в ОДНОМ пункте numbered-list ложно
        # глушил бы NAV-кандидатов в СОСЕДНИХ, содержательно не связанных пунктах того же
        # blank-line-абзаца (см. докстринг `_current_bullet_bounds`).
        bullet_start, bullet_end = _current_bullet_bounds(marker_source, paragraph_start, paragraph_end, span_start)
        cross_repo_text = marker_source[bullet_start:bullet_end]
        cross_repo_text_fenced = fenced_masked[bullet_start:bullet_end]
        cross_repo = bool(_CROSS_REPO_RE.search(cross_repo_text)) or bool(
            _CROSS_REPO_NAMED_RE.search(cross_repo_text_fenced)
        )
        in_scope = in_root and not cross_repo

        cls = "NAV" if (has_marker and exists and in_scope) else "SUBJECT"
        occs.append(Occurrence(md_file, _line_of(text, span_start), span_start, span_end, raw, cls, target))
        prev_end = span_end

    return occs


def scan(root: Path) -> tuple[list[Occurrence], dict[Path, str]]:
    content_path_re = re.compile(rf"^{re.escape(root.name)}/[^\s`]+\.md$")
    text_cache: dict[Path, str] = {}
    all_occs: list[Occurrence] = []
    for md_file in _collect_md_files(root):
        text = md_file.read_text(encoding="utf-8")
        text_cache[md_file] = text
        all_occs.extend(classify_file(root, md_file, text, content_path_re))
    return all_occs, text_cache


def report_rel(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return str(path)


def _link_text_and_href(root: Path, occ: Occurrence, title_cache: dict[Path, str]) -> tuple[str, str]:
    if occ.target not in title_cache:
        target_text = occ.target.read_text(encoding="utf-8") if occ.target.exists() else ""
        title_cache[occ.target] = _extract_title(target_text) or occ.target.stem
    title = title_cache[occ.target]
    rel = os.path.relpath(occ.target, start=occ.md_file.parent)
    href = Path(rel).as_posix()
    # Конструктивная гарантия FR-081: источник и цель всегда внутри одного root, relpath между
    # двумя путями внутри общего предка никогда не начинается с имени этого предка — assert как
    # документация инварианта, не runtime-defense «на всякий случай».
    assert not href.startswith(f"{root.name}/"), f"antipattern FR-081 leaked into href: {href}"
    return title, href


def migrate_file(root: Path, md_file: Path, text: str, occs: list[Occurrence], title_cache: dict[Path, str]) -> str:
    out: list[str] = []
    last_end = 0
    for occ in occs:
        if occ.cls != "NAV":
            continue
        out.append(text[last_end:occ.start])
        title, href = _link_text_and_href(root, occ, title_cache)
        out.append(f"[{title}]({href})")
        last_end = occ.end
    out.append(text[last_end:])
    return "".join(out)


def main():
    parser = argparse.ArgumentParser(
        description="Классификация и миграция NAV-код-спанов в markdown-ссылки (ADR-0016).",
        epilog=EPILOG,
    )
    parser.add_argument("path", type=Path, help="Путь к .doc-root.yaml-каталогу для сканирования.")
    parser.add_argument("--fix", action="store_true", help="Мигрировать найденные NAV-код-спаны (требует --yes).")
    parser.add_argument("--yes", action="store_true", help="Подтверждение для --fix.")
    parser.add_argument(
        "--expect-count",
        type=int,
        default=DEFAULT_EXPECT_COUNT,
        dest="expect_count",
        help=f"Ожидаемое число NAV-кандидатов — hard guard для --fix (дефолт {DEFAULT_EXPECT_COUNT}, RES-005).",
    )
    args = parser.parse_args()

    if args.fix and not args.yes:
        print("--fix requires --yes flag for safety", file=sys.stderr)
        sys.exit(2)

    root = args.path.resolve()
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        sys.exit(2)

    occs, text_cache = scan(root)
    nav = [o for o in occs if o.cls == "NAV"]
    self_count = sum(1 for o in occs if o.cls == "SELF")
    subject_count = sum(1 for o in occs if o.cls == "SUBJECT")

    if args.fix and args.yes:
        if len(nav) != args.expect_count:
            print(
                f"error: expected {args.expect_count} NAV candidates, found {len(nav)} — "
                "aborting without mutations (ADR-0016 Решение 5 hard guard)",
                file=sys.stderr,
            )
            sys.exit(1)

    for occ in sorted(nav, key=lambda o: (str(o.md_file), o.start)):
        title_cache: dict[Path, str] = {}
        _, href = _link_text_and_href(root, occ, title_cache)
        print(f"{report_rel(root, occ.md_file)}:{occ.line} NAV -> {href}")

    if args.fix and args.yes:
        by_file: dict[Path, list[Occurrence]] = {}
        for occ in nav:
            by_file.setdefault(occ.md_file, []).append(occ)
        title_cache: dict[Path, str] = {}
        for md_file, file_occs in by_file.items():
            file_occs_sorted = sorted(file_occs, key=lambda o: o.start)
            new_text = migrate_file(root, md_file, text_cache[md_file], file_occs_sorted, title_cache)
            md_file.write_text(new_text, encoding="utf-8")
        print(f"Migrated: {len(nav)}")
    else:
        print(f"To-migrate: {len(nav)}")
    print(f"SELF: {self_count}")
    print(f"SUBJECT: {subject_count}")

    if args.fix and args.yes:
        sys.exit(0)
    sys.exit(0 if len(nav) == 0 else 1)


if __name__ == "__main__":
    main()
