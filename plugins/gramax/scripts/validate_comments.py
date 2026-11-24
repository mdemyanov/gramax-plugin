#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Валидация парности позиций комментариев в md и ключей в .comments.yaml.

Позиции комментария в md — три формы: inline-тег `<comment id="ID">…</comment>`,
XML-блочная `<comment id="ID"/> … </comment>` (канон для `syntax: XML`) и скобочная
legacy `[comment:ID] … [/comment]`. Несколько позиций у одного ID — штатная конструкция
движка (BlockMark.getCommentPosition(), FR-210): валидатор показывает их информационной
строкой уровня `info`, на rc и `--strict` она не влияет.

Примеры синтаксиса в code-span и fenced-блоке маскируются `lib/md_code_mask.py`
до извлечения ID (ADR-0026 Решение 8) — иллюстрация не считается разметкой; пробелы
внутри тега ограничены одной строкой, тег, разорванный переносом строки, даёт находку
«тег разорван», а не ложный ID.

Файл с битым UTF-8 даёт ровно одну находку `E036` (ADR-0026 Решение 6), проверки его
текста пропускаются, обход продолжается (чтение — `lib/read_page.py`).
"""

import argparse
import re
import sys
from pathlib import Path

import yaml

from lib.md_code_mask import _mask_code
from lib.read_page import read_page, utf8_message

ID_RE = re.compile(r"^[a-zA-Z0-9]{5}$")
# Пробелы внутри тега — только в пределах одной строки (gramax-4jf.13): \s+ мостил
# через переводы строк и абзацы, порождая ложные ID на разорванных тегах.
INLINE_RE = re.compile(r'<comment[ \t]+id="([^"]+)"[ \t]*>')
XML_BLOCK_RE = re.compile(r'<comment[ \t]+id="([^"]+)"[ \t]*/>')
BLOCK_RE = re.compile(r'\[comment:([a-zA-Z0-9]+)\]')
# Тег, разорванный переносом строки между <comment и id= — разметка не распознаётся.
BROKEN_TAG_RE = re.compile(r'<comment[ \t]*\n[ \t]*id="([^"]*)"')
ISO_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$")

REQUIRED_COMMENT_FIELDS = [
    ("comment", "dateTime"),
    ("comment", "user", "mail"),
    ("comment", "user", "name"),
    ("comment", "content"),
]


class Issue:
    def __init__(self, level: str, path: Path, message: str):
        self.level = level
        self.path = path
        self.message = message

    def __str__(self):
        return f"{self.level.upper()}  {self.path}  {self.message}"


def extract_md_ids(md_text: str) -> list[str]:
    """Вернуть все ID позиций комментариев по порядку (с повторами): inline-тег,
    XML-блочная форма и скобочная legacy."""
    return INLINE_RE.findall(md_text) + XML_BLOCK_RE.findall(md_text) + BLOCK_RE.findall(md_text)


def get_nested(d: dict, *keys):
    cur = d
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur


def validate_md(md_path: Path, issues: list[Issue], strict: bool):
    md_text, read_err = read_page(md_path)
    if read_err is not None:
        issues.append(Issue("error", md_path, f"E036: {utf8_message(read_err)}"))
        return
    masked = _mask_code(md_text)
    md_ids = extract_md_ids(masked)

    # Check ID format
    for mid in md_ids:
        if not ID_RE.match(mid):
            issues.append(Issue("error", md_path, f"invalid comment id format: {mid!r} (must be ^[a-zA-Z0-9]{{5}}$)"))

    # Несколько позиций у одного ID — штатная конструкция движка (FR-210): показываем
    # информационной строкой с номерами строк, уникальность не проверяем.
    positions: dict[str, list[int]] = {}
    for lineno, line in enumerate(masked.split("\n"), 1):
        for mid in extract_md_ids(line):
            positions.setdefault(mid, []).append(lineno)
    for mid, lines in positions.items():
        if len(lines) > 1:
            issues.append(Issue("info", md_path, f"comment id в нескольких позициях md: {mid} (строки {', '.join(map(str, lines))})"))

    # Тег, разорванный переносом строки (gramax-4jf.13): находка вместо ложного ID.
    for broken in BROKEN_TAG_RE.finditer(masked):
        issues.append(Issue("error", md_path, f"тег <comment> разорван переносом строки (id=\"{broken.group(1)}\" не распознан как позиция комментария)"))

    # Check yaml
    yaml_path = md_path.with_suffix(".comments.yaml")
    # special case for _index.md → _index.comments.yaml works via with_suffix
    # but pathlib uses last suffix so _index.md → _index.comments.yaml is correct
    yaml_data: dict = {}
    if yaml_path.exists():
        yaml_text, yaml_err = read_page(yaml_path)
        if yaml_err is not None:
            issues.append(Issue("error", yaml_path, f"E036: {utf8_message(yaml_err)}"))
            return
        try:
            yaml_data = yaml.safe_load(yaml_text) or {}
        except yaml.YAMLError as e:
            issues.append(Issue("error", yaml_path, f"invalid yaml: {e}"))
            return

    yaml_ids = set(yaml_data.keys()) if isinstance(yaml_data, dict) else set()
    md_id_set = set(md_ids)

    # md → yaml
    for mid in md_id_set:
        if ID_RE.match(mid) and mid not in yaml_ids:
            issues.append(Issue("error", yaml_path, f"yaml missing key for md id: {mid}"))

    # yaml → md
    for yid in yaml_ids:
        if yid not in md_id_set:
            issues.append(Issue("error", md_path, f"md missing tag for yaml id: {yid}"))

    # Required fields and datetime format in yaml
    for yid, entry in yaml_data.items() if isinstance(yaml_data, dict) else []:
        if not isinstance(entry, dict):
            issues.append(Issue("error", yaml_path, f"{yid}: entry is not a mapping"))
            continue
        for keys in REQUIRED_COMMENT_FIELDS:
            if get_nested(entry, *keys) is None:
                issues.append(Issue("error", yaml_path, f"{yid}: missing field {'.'.join(keys)}"))
        dt = get_nested(entry, "comment", "dateTime")
        if isinstance(dt, str) and not ISO_RE.match(dt):
            issues.append(Issue("warning", yaml_path, f"{yid}: dateTime not ISO 8601 UTC: {dt}"))

        # Check duplicate answers (warning by default, error in strict)
        answers = entry.get("answers")
        if isinstance(answers, list):
            seen_answers = set()
            for ans in answers:
                if not isinstance(ans, dict):
                    continue
                # У автора ответа движок пишет user.id, равный mail (FR-218)
                user = ans.get("user")
                if not isinstance(user, dict) or user.get("id") is None:
                    issues.append(Issue("warning", yaml_path, f"{yid}: у ответа нет user.id (ожидается id, равный user.mail)"))
                key = (ans.get("content"), ans.get("dateTime"))
                if key in seen_answers:
                    level = "error" if strict else "warning"
                    issues.append(Issue(level, yaml_path, f"{yid}: duplicate answer (content+dateTime)"))
                seen_answers.add(key)
        elif answers is None and strict:
            issues.append(Issue("error", yaml_path, f"{yid}: answers should be [] not missing (strict mode)"))


def main():
    parser = argparse.ArgumentParser(description="Валидация пар <comment> ↔ .comments.yaml.")
    parser.add_argument("path", type=Path, help="Путь к .md файлу или каталогу.")
    parser.add_argument("--strict", action="store_true", help="Warnings → errors.")
    args = parser.parse_args()

    issues: list[Issue] = []

    if args.path.is_file():
        validate_md(args.path, issues, args.strict)
    elif args.path.is_dir():
        for md in args.path.rglob("*.md"):
            if ".gramax" in md.parts:
                continue
            validate_md(md, issues, args.strict)
    else:
        print(f"not a file or directory: {args.path}", file=sys.stderr)
        sys.exit(2)

    for issue in issues:
        print(str(issue))

    # ADR-0028 Решение 11: --strict эскалирует КАЖДОЕ предупреждение (справка
    # «Warnings → errors.» становится истинной); уровень info не эскалируется
    # (AC-129). Метки находок не меняются — меняется только код выхода.
    has_errors = any(i.level == "error" for i in issues)
    has_warnings_strict = args.strict and any(i.level == "warning" for i in issues)
    if has_errors or has_warnings_strict:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
