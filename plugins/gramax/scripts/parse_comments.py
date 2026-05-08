#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Парсинг комментариев Gramax: md-теги + .comments.yaml → отчёт/JSON."""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

INLINE_RE = re.compile(r'<comment\s+id="([^"]+)">(.*?)</comment>', re.DOTALL)
BLOCK_RE = re.compile(r'\[comment:([a-zA-Z0-9]+)\]\s*\n(.*?)\n\s*\[/comment\]', re.DOTALL)


@dataclass
class Comment:
    file: str
    id: str
    anchor: str | None
    comment: dict
    answers: list[dict] = field(default_factory=list)
    status: str = "ok"  # ok | anchor_not_found | yaml_missing


def parse_md_anchors(md_text: str) -> dict[str, str]:
    """Вернуть dict ID → anchor text."""
    anchors = {}
    for m in INLINE_RE.finditer(md_text):
        anchors[m.group(1)] = m.group(2).strip()
    for m in BLOCK_RE.finditer(md_text):
        anchors[m.group(1)] = m.group(2).strip()
    return anchors


def dedupe_answers(answers: list) -> list:
    if not isinstance(answers, list):
        return []
    seen = set()
    result = []
    for ans in answers:
        if not isinstance(ans, dict):
            continue
        key = (ans.get("content"), ans.get("dateTime"))
        if key in seen:
            continue
        seen.add(key)
        result.append(ans)
    return result


def process_md(md_path: Path) -> list[Comment]:
    md_text = md_path.read_text(encoding="utf-8")
    anchors = parse_md_anchors(md_text)
    yaml_path = md_path.with_suffix(".comments.yaml")

    yaml_data: dict = {}
    if yaml_path.exists():
        try:
            yaml_data = yaml.safe_load(yaml_path.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError as e:
            print(f"WARNING: yaml parse error in {yaml_path}: {e}", file=sys.stderr)
            yaml_data = {}

    result: list[Comment] = []
    yaml_ids = set(yaml_data.keys()) if isinstance(yaml_data, dict) else set()

    # IDs in md that have no yaml record
    for mid in anchors:
        if mid not in yaml_ids:
            result.append(Comment(
                file=str(md_path),
                id=mid,
                anchor=anchors[mid],
                comment={},
                answers=[],
                status="yaml_missing",
            ))

    # IDs in yaml
    if isinstance(yaml_data, dict):
        for yid, entry in yaml_data.items():
            if not isinstance(entry, dict):
                continue
            anchor = anchors.get(yid)
            status = "ok" if anchor is not None else "anchor_not_found"
            result.append(Comment(
                file=str(md_path),
                id=yid,
                anchor=anchor,
                comment=entry.get("comment", {}),
                answers=dedupe_answers(entry.get("answers", [])),
                status=status,
            ))

    return result


def collect(path: Path) -> list[Comment]:
    if path.is_file():
        return process_md(path)
    if path.is_dir():
        result = []
        for md in sorted(path.rglob("*.md")):
            if ".gramax" in md.parts:
                continue
            result.extend(process_md(md))
        return result
    raise FileNotFoundError(str(path))


def apply_filters(comments: list[Comment], author: str | None, unanswered: bool, answered: bool) -> list[Comment]:
    result = comments
    if author:
        result = [c for c in result
                  if c.comment.get("user", {}).get("name") == author
                  or any(a.get("user", {}).get("name") == author for a in c.answers)]
    if unanswered:
        result = [c for c in result if not c.answers]
    if answered:
        result = [c for c in result if c.answers]
    return result


def to_dict(c: Comment) -> dict:
    return {
        "file": c.file,
        "id": c.id,
        "anchor": c.anchor,
        "comment": c.comment,
        "answers": c.answers,
        "status": c.status,
    }


def format_report(comments: list[Comment]) -> str:
    lines = []
    current_file = None
    for i, c in enumerate(comments, 1):
        if c.file != current_file:
            lines.append(f"\n## Комментарии к: {c.file}\n")
            current_file = c.file
        author = c.comment.get("user", {}).get("name", "?")
        date = c.comment.get("dateTime", "?")
        content = c.comment.get("content", "")
        lines.append(f"### [{i}] ID: {c.id} | {date} | {author}")
        if c.anchor:
            lines.append(f"**Привязка в тексте:** \"{c.anchor}\"")
        lines.append(f"**Комментарий:** {content}")
        if c.status != "ok":
            lines.append(f"**Статус:** {c.status}")
        if c.answers:
            lines.append("**Ответы:**")
            for j, a in enumerate(c.answers, 1):
                a_author = a.get("user", {}).get("name", "?")
                a_date = a.get("dateTime", "?")
                a_content = a.get("content", "")
                lines.append(f"  {j}. {a_date} | {a_author}: {a_content}")
        lines.append("\n---")
    return "\n".join(lines)


def format_summary(comments: list[Comment]) -> str:
    total = len(comments)
    answered = sum(1 for c in comments if c.answers)
    unanswered = total - answered
    authors: dict[str, int] = {}
    dates = []
    for c in comments:
        name = c.comment.get("user", {}).get("name")
        if name:
            authors[name] = authors.get(name, 0) + 1
        dt = c.comment.get("dateTime")
        if dt:
            dates.append(dt)
    lines = [
        "## Сводка по комментариям",
        f"- Всего комментариев: {total}",
        f"- С ответами: {answered}",
        f"- Без ответов: {unanswered}",
    ]
    if authors:
        lines.append("- Авторы:")
        for name, count in sorted(authors.items(), key=lambda x: -x[1]):
            lines.append(f"  - {name}: {count}")
    if dates:
        lines.append(f"- Период: {min(dates)} — {max(dates)}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Парсинг комментариев Gramax.")
    parser.add_argument("path", type=Path, help="Путь к .md файлу или каталогу.")
    parser.add_argument("--format", choices=["json", "report"], default="report")
    parser.add_argument("--author", help="Фильтр по имени автора.")
    parser.add_argument("--unanswered", action="store_true", help="Только без ответов.")
    parser.add_argument("--answered", action="store_true", help="Только с ответами.")
    parser.add_argument("--summary", action="store_true", help="Краткая сводка.")
    args = parser.parse_args()

    try:
        comments = collect(args.path)
    except FileNotFoundError as e:
        print(f"not found: {e}", file=sys.stderr)
        sys.exit(2)

    comments = apply_filters(comments, args.author, args.unanswered, args.answered)

    if args.summary:
        print(format_summary(comments))
    elif args.format == "json":
        print(json.dumps([to_dict(c) for c in comments], ensure_ascii=False, indent=2))
    else:
        print(format_report(comments))


if __name__ == "__main__":
    main()
