#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""check-subprocess-encoding.py — born-red гейт класса «детерминированное декодирование
субпроцессов» (NA-EPIC-150 срез 1, BA-118; capability subprocess-utf8-determinism;
gitsd issue #1).

Предмет: места вызова subprocess в текстовом режиме (`text=True`) в `scripts/` и `hooks/`
этого дерева без явного `encoding=`. Класс (issue #1): без `encoding=` вывод ребёнка
декодируется ANSI-страницей платформы (cp1251 на Windows) — кириллический UTF-8 байт роняет
reader-thread исключением UnicodeDecodeError, `stdout` остаётся `None`, следующая строка
падает AttributeError; на POSIX дефект невидим в CI. Норма FR-2 спеки: вызов `text=True`
без `encoding=` — красная находка fast-гейта; находка называет файл и строку (форма
`file:line`) — голый счётчик находкой не считается.

Гранулярность — МЕСТО ВЫЗОВА, не сырые строки (FR-3): разбор AST (`ast.Call` с keyword
`text=True`), поэтому (а) совместимый многострочный вызов с `encoding=` на соседней строке —
не находка, (б) нарушитель, отформатированный в несколько строк, всё равно найден,
(в) упоминание литерала `text=True` в комментарии или докстринге — не находка (класс живого
упоминания — `scripts/role-preflight.sh:241`).

Opt-out нет (FR-4): маркеры-подавители (`# noqa`, `# nauta-suppress: …`), комментарии-
исключения и реестры исключений находку не глушат — они не код и не аргумент вызова; hooks/
судится тем же правилом, что scripts/ (исключений по типу файла или каталогу нет).

Python-код внутри `.sh` читается из heredoc-тел (`<<'МЕТКА'` … МЕТКА): тело разбирается AST
с пересчётом строк в адреса файла; тело, не разбирающееся как Python, предметом не является
(файл печатается отдельной `[INFO]`-строкой — «не смог разобрать» громок, не тих). Файлы
`.py` разбираются целиком (битый синтаксис — та же `[INFO]`-строка, продолжаем по остальным).
`universal_newlines` в дереве отсутствует (замер BA-118) и классом не считается; допуск
`encoding=` без `errors=` нормой FR-1 не покрывается — находка судится по `encoding=`,
`errors="replace"` добавляется волной и держится ревью (спека FR-1).

Коды возврата (ADR-102 Д2): 0 — находок нет, чистый прогон печатает именованный нулевой
счётчик (норма спеки «passes green with a reported count»); 1 — есть находки, каждая
напечатана формой `file:line`; 2 — использование (argparse).

Ступень `--fast` (AC-002c: перенос в `--full`-only — нарушение нормы); окно collect
ADR-123 — хвостовой вызов батча, пин стартов интерпретаторов не двигает. Гейт доставляется
потребителю (класс A ADR-085 Д1: предмет — `scripts/` и `hooks/` самого дерева-потребителя;
«детектор обязан работать на потребительском дереве», BA-118) и зовётся ростером
`scripts/check.sh`. Замки: tests/test_qa197_utf8_subprocess_born_red.py (ac1a…ac4b).
"""
from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

#: Начало heredoc: `<<'МЕТКА'`, `<<"МЕТКА"`, `<<-МЕТКА`, `<< МЕТКА`; `<<<` (here-string)
#: исключён просмотром назад. МЕТКА — слово в конце строки.
HEREDOC_START_RE = re.compile(r"(?<![<])<<-?\s*[\"']?([A-Za-z_][A-Za-z0-9_]*)[\"']?\s*$")


def _heredoc_python_blocks(text: str) -> list[tuple[int, str]]:
    """Тела heredoc'ов .sh-файла как (строка-начала-тела, код). Блоки, не разбирающиеся
    как Python, отбираются ЗДЕСЬ по try-parse на месте вызова, не здесь."""
    lines = text.splitlines()
    blocks: list[tuple[int, str]] = []
    i = 0
    while i < len(lines):
        m = HEREDOC_START_RE.search(lines[i])
        if not m:
            i += 1
            continue
        delim = m.group(1)
        body: list[str] = []
        j = i + 1
        while j < len(lines) and lines[j].strip() != delim:
            body.append(lines[j])
            j += 1
        # Незакрытый heredoc (нет терминатора) — тело до конца файла; парсинг решит.
        if body:
            blocks.append((i + 2, "\n".join(body) + "\n"))
        i = j + 1
    return blocks


def _call_findings(tree: ast.AST, offset: int) -> list[int]:
    """Строки вызовов с keyword `text=True` и без `encoding=`; offset — пересчёт в адрес
    файла (для heredoc-тел). Гранулярность — узел вызова (FR-3); строка — начало вызова
    (для многострочного нарушителя допустимая форма адреса, at-design qa197)."""
    out: list[int] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        has_text = any(
            kw.arg == "text"
            and isinstance(kw.value, ast.Constant)
            and kw.value.value is True
            for kw in node.keywords
        )
        # Маркеры-подавители и реестры исключений не читаются принципиально (FR-4):
        # суждение — только по аргументам самого вызова.
        has_encoding = any(kw.arg == "encoding" for kw in node.keywords)
        if has_text and not has_encoding:
            out.append(node.lineno + offset)
    return out


def _iter_source_files(root: Path, sub: str) -> list[Path]:
    base = root / sub
    if not base.is_dir():
        return []
    files = [
        p
        for p in sorted(base.rglob("*"))
        if p.is_file()
        and p.suffix in {".py", ".sh"}
        and "__pycache__" not in p.parts
    ]
    return files


def collect(root: Path) -> tuple[list[tuple[str, int]], list[str]]:
    """Находки (relpath, line) и имена неразобранных файлов; сортировка детерминирована."""
    findings: list[tuple[str, int]] = []
    unparseable: list[str] = []
    for sub in ("hooks", "scripts"):
        for path in _iter_source_files(root, sub):
            rel = path.relative_to(root).as_posix()
            raw = path.read_bytes().decode("utf-8", errors="replace")
            if path.suffix == ".py":
                try:
                    tree = ast.parse(raw, filename=rel)
                except (SyntaxError, ValueError, RecursionError):
                    unparseable.append(rel)
                    continue
                findings.extend((rel, ln) for ln in _call_findings(tree, 0))
            else:
                for start_line, code in _heredoc_python_blocks(raw):
                    try:
                        tree = ast.parse(code, filename=f"{rel}@{start_line}")
                    except (SyntaxError, ValueError, RecursionError):
                        continue  # heredoc не Python (шаблон, текст) — не предмет
                    findings.extend((rel, ln) for ln in _call_findings(tree, start_line - 1))
    findings.sort()
    unparseable.sort()
    return findings, unparseable


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Born-red гейт: вызовы text=True без encoding= в scripts/ и hooks/ "
        "(BA-118, capability subprocess-utf8-determinism).",
    )
    parser.add_argument(
        "--root",
        default=None,
        help="корень дерева (по умолчанию — каталог над scripts/ этого файла)",
    )
    args = parser.parse_args(argv)
    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parents[1]
    if not (root / "scripts").is_dir() and not (root / "hooks").is_dir():
        print(
            f"ERROR: check-subprocess-encoding: ни scripts/, ни hooks/ не найдены под "
            f"{root} — предмет гейта структурно отсутствует, судить нечего (ADR-007 Д1).",
            file=sys.stderr,
        )
        return 3
    findings, unparseable = collect(root)
    for rel, line in findings:
        print(f"{rel}:{line}: text=True без encoding= — детерминированного декодирования нет "
              f"(BA-118, AC-002a; добавь encoding=\"utf-8\" и errors=\"replace\")")
    if unparseable:
        print(f"[INFO] check-subprocess-encoding: файлы, не разобранные как Python "
              f"(предмет этой проверки на них не завершён — не тихо): "
              f"{', '.join(unparseable)}")
    total = len(findings)
    print(f"subprocess-utf8-determinism: {total} findings — мест вызова text=True без "
          f"encoding= в scripts/ и hooks/ (норма FR-1/FR-2; ноль — норма чистого дерева)")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
