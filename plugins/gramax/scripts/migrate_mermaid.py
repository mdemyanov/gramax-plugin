#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Обнаружение и пакетная миграция устаревшего inline-mermaid в file-based формат.

ADR: `content/00-project/adr/0013-mermaid-adoption-and-migration.md` (Решения 1, 3, 4).
Дополняет ADR-0010 (`content/00-project/adr/0010-mermaid-file-based-workflow.md`) —
naming convention (Решение 2), fallback-слаг `existing` (Решение 3), дефолты
`width`/`height` (Решение 5). Требование: `content/30-requirements/
2026-08-11-mermaid-file-based-adoption.md` (FR-054…FR-060, FR-064).

Граница юрисдикции (FR-050, FR-055): для каждого `*.md` ищется ближайший предок
`.doc-root.yaml`; поиск ограничен переданным `path` — вверх по дереву за пределы `path`
не выходит (самодостаточность одного прогона: результат не зависит от того, что лежит
выше в реальной файловой системе). Файл без такого предка в пределах `path` — вне
юрисдикции, пропускается молча в отчёте (никогда не упоминается по имени), учитывается
только суммарным счётчиком «Out-of-jurisdiction». Подробности и обоснование границы —
`plugins/gramax/skills/mermaid/references/jurisdiction-and-validation.md`.

Легаси-паттерны (те же, что в `SKILL.md` § Backward compatibility). Самозакрывающийся
`<mermaid path="…"/>` не совпадает ни с одним по построению — уже корректные вхождения
не задеваются на любом масштабе (BR-003, NFR-051):
  1. Парный тег без `path=`: `<mermaid>...(DSL)...</mermaid>`
  2. Fenced-блок: ```` ```mermaid ... (DSL) ... ``` ````

Режимы:
  (по умолчанию) — только отчёт: `<путь>:<строка>` на каждое вхождение в юрисдикции +
    сводка из трёх счётчиков (FR-064). Ничего не мутирует, сетевого доступа и интерактива
    не требует (NFR-053). Метка первого счётчика зависит от режима, чтобы не утверждать
    свершившееся там, где ничего не изменено: `To-migrate: N` в этом режиме — «найдено и
    подлежит миграции» (кандидаты, ни один файл не тронут); `Migrated: N` — только в
    `--fix --yes`, где файлы реально изменены (найдено дефектом первого прогона:
    отчётный режим печатал `Migrated: N`, хотя ничего не мигрировал — потребитель, читая
    вывод первого, всегда report-режимного, вызова, делал бы ложный вывод, что файлы уже
    изменены). Два других счётчика (`Out-of-jurisdiction`, `Already-compliant`) верны и
    одинаково подписаны в обоих режимах. Завершается ненулевым кодом, если найдены
    вхождения для миграции (`len(occs) > 0`) — полезно для CI-пайплайна как сигнал «есть
    что мигрировать», но учтите при вызове в пайплайне заранее, не по факту красной сборки.
  --fix --yes    — дополнительно мутирует: извлекает DSL побайтово (BR-002) в новый
    `<page-slug>-existing[-N].mermaid` рядом со статьёй-источником (коллизия — следующий
    свободный номер, никогда не перезаписывает — ADR-0013 Решение 4), заменяет исходный
    блок в md-файле тегом с дефолтами `width="800px" height="450px"` (ADR-0010 Решение 5
    — легаси-блоки сегодня без атрибутов размера, второй конвенции не заводится).
    Завершается кодом `0` после успешного применения (мутация — не находка, которую нужно
    сигнализировать как ошибку CI).

NFR-052: только stdlib, без внешних зависимостей и без сетевого доступа.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

DOC_URL = "https://github.com/mdemyanov/gramax-plugin"
EPILOG = (
    "Документация: plugins/gramax/skills/mermaid/references/jurisdiction-and-validation.md, "
    "plugins/gramax/README.md (раздел «Валидация каталога»). "
    "Режим отчёта (без --fix) завершается ненулевым кодом, если найдены вхождения для "
    "миграции — учтите при вызове из CI-пайплайна заранее. "
    f"Репозиторий: {DOC_URL}"
)

# Два легаси-паттерна (ADR-0013 Решение 3). Оба DOTALL: DSL внутри блока — многострочный.
PAIRED_RE = re.compile(r"<mermaid>\n(.*?)\n</mermaid>", re.DOTALL)
FENCED_RE = re.compile(r"```mermaid\n(.*?)\n```", re.DOTALL)
# Уже корректный самозакрывающийся тег — структурно не пересекается ни с одним из двух
# легаси-паттернов выше (BR-003): используется только для счётчика "Already-compliant",
# никогда не заменяется и не переоткрывается как нарушение.
ALREADY_COMPLIANT_RE = re.compile(r'<mermaid\s+path="[^"]+"[^>]*/>')

DEFAULT_WIDTH = "800px"
DEFAULT_HEIGHT = "450px"


class Occurrence:
    """Одно найденное легаси-вхождение mermaid внутри конкретного md-файла."""

    __slots__ = ("md_file", "line", "start", "end", "dsl")

    def __init__(self, md_file: Path, line: int, start: int, end: int, dsl: str):
        self.md_file = md_file
        self.line = line
        self.start = start  # смещение начала совпадения (включая открывающий делимитер)
        self.end = end      # смещение конца совпадения (включая закрывающий делимитер)
        self.dsl = dsl       # DSL побайтово, как он был внутри блока (BR-002)


def nearest_doc_root(md_file: Path, scan_root: Path) -> Path | None:
    """Ближайший предок `.doc-root.yaml` для `md_file`, поиск не выходит за пределы
    `scan_root` (ADR-0013 Решение 1). Возвращает директорию с `.doc-root.yaml` или None,
    если в пределах `scan_root` предка нет — файл вне юрисдикции (FR-050/FR-055)."""
    candidate = md_file.parent.resolve()
    root = scan_root.resolve()
    while True:
        if (candidate / ".doc-root.yaml").exists():
            return candidate
        if candidate == root:
            return None
        if root not in candidate.parents:
            # candidate выпал за пределы поддерева scan_root — не должно случаться для
            # файлов, найденных внутри scan_root, но защищаемся явно, не бесконечным циклом.
            return None
        candidate = candidate.parent


def _line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def find_occurrences(md_file: Path, text: str) -> list[Occurrence]:
    """Оба легаси-паттерна, отсортированные по позиции в файле (для стабильной
    коллизия-нумерации при миграции нескольких блоков в одном файле)."""
    occs: list[Occurrence] = []
    for pattern in (PAIRED_RE, FENCED_RE):
        for m in pattern.finditer(text):
            occs.append(Occurrence(md_file, _line_of(text, m.start()), m.start(), m.end(), m.group(1) + "\n"))
    occs.sort(key=lambda o: o.start)
    return occs


def page_slug(md_file: Path) -> str:
    """`<page-slug>` по ADR-0010 Решение 2: имя файла без расширения; `_index.md` —
    имя родительской директории."""
    if md_file.name == "_index.md":
        return md_file.parent.name
    return md_file.stem


def next_free_mermaid_name(directory: Path, slug: str, taken: set[str]) -> str:
    """`<page-slug>-existing.mermaid`; коллизия — следующий свободный номер
    (`-existing-2.mermaid`, …), никогда не перезаписывает (ADR-0013 Решение 4, fallback-слаг
    `existing` — переиспользован из ADR-0010 Решение 3)."""
    candidate = f"{slug}-existing.mermaid"
    if candidate not in taken and not (directory / candidate).exists():
        taken.add(candidate)
        return candidate
    n = 2
    while True:
        candidate = f"{slug}-existing-{n}.mermaid"
        if candidate not in taken and not (directory / candidate).exists():
            taken.add(candidate)
            return candidate
        n += 1


def migrate_text(md_file: Path, text: str, occs: list[Occurrence]) -> tuple[str, list[tuple[str, str]]]:
    """Строит новый текст статьи (легаси-блоки заменены тегами с дефолтами ADR-0010
    Решение 5) и список (filename, dsl) для записи `.mermaid`-файлов. Не пишет на диск —
    вызывающий код делает это только под `--fix --yes` (FR-058, NFR-053)."""
    slug = page_slug(md_file)
    taken: set[str] = set()
    out: list[str] = []
    created: list[tuple[str, str]] = []
    last_end = 0
    for occ in occs:
        out.append(text[last_end:occ.start])
        filename = next_free_mermaid_name(md_file.parent, slug, taken)
        tag = f'<mermaid path="./{filename}" width="{DEFAULT_WIDTH}" height="{DEFAULT_HEIGHT}"/>'
        out.append(tag)
        created.append((filename, occ.dsl))
        last_end = occ.end
    out.append(text[last_end:])
    return "".join(out), created


def collect_md_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.md") if ".git" not in p.parts and ".gramax" not in p.parts)


def scan(root: Path) -> tuple[list[Occurrence], int, int, dict[Path, str]]:
    """Один проход по дереву: (вхождения-в-юрисдикции, счётчик-вне-юрисдикции,
    счётчик-уже-корректных, кэш прочитанного текста — переиспользуется при `--fix`,
    чтобы не читать файлы дважды и не зависеть от гонки между сканом и мутацией)."""
    in_jurisdiction: list[Occurrence] = []
    out_count = 0
    compliant_count = 0
    text_cache: dict[Path, str] = {}
    for md_file in collect_md_files(root):
        text = md_file.read_text(encoding="utf-8")
        text_cache[md_file] = text
        occs = find_occurrences(md_file, text)
        doc_root = nearest_doc_root(md_file, root)
        if doc_root is None:
            out_count += len(occs)
            continue
        in_jurisdiction.extend(occs)
        compliant_count += len(ALREADY_COMPLIANT_RE.findall(text))
    return in_jurisdiction, out_count, compliant_count, text_cache


def report_line(root: Path, occ: Occurrence) -> str:
    try:
        rel = occ.md_file.relative_to(root)
    except ValueError:
        rel = occ.md_file
    return f"{rel}:{occ.line}"


def main():
    parser = argparse.ArgumentParser(
        description="Обнаружение и пакетная миграция устаревшего inline-mermaid (ADR-0013).",
        epilog=EPILOG,
    )
    parser.add_argument("path", type=Path, help="Путь к каталогу для сканирования (репозиторий или его часть).")
    parser.add_argument("--fix", action="store_true", help="Мигрировать найденные вхождения (требует --yes).")
    parser.add_argument("--yes", action="store_true", help="Подтверждение для --fix.")
    args = parser.parse_args()

    if args.fix and not args.yes:
        print("--fix requires --yes flag for safety", file=sys.stderr)
        sys.exit(2)

    root = args.path.resolve()
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        sys.exit(2)

    occs, out_count, compliant_count, text_cache = scan(root)

    for occ in occs:
        print(report_line(root, occ))

    if args.fix and args.yes:
        by_file: dict[Path, list[Occurrence]] = {}
        for occ in occs:
            by_file.setdefault(occ.md_file, []).append(occ)
        for md_file, file_occs in by_file.items():
            new_text, created = migrate_text(md_file, text_cache[md_file], file_occs)
            for filename, dsl in created:
                (md_file.parent / filename).write_text(dsl, encoding="utf-8")
            md_file.write_text(new_text, encoding="utf-8")

    # Метка первого счётчика зависит от режима (см. докстринг модуля, «Режимы»): report-режим
    # ничего не мутирует и обязан говорить о находке, не о свершившемся факте, иначе первый же
    # (всегда report-режимный) вызов вводит потребителя в заблуждение.
    if args.fix and args.yes:
        print(f"Migrated: {len(occs)}")
    else:
        print(f"To-migrate: {len(occs)}")
    print(f"Out-of-jurisdiction: {out_count}")
    print(f"Already-compliant: {compliant_count}")

    if args.fix and args.yes:
        sys.exit(0)
    sys.exit(0 if len(occs) == 0 else 1)


if __name__ == "__main__":
    main()
