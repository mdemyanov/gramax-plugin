#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Валидация парности <comment id> в md и ключей в .comments.yaml."""

import argparse
import re
import sys
from pathlib import Path

import yaml

ID_RE = re.compile(r"^[a-zA-Z0-9]{5}$")
INLINE_RE = re.compile(r'<comment\s+id="([^"]+)">', re.DOTALL)
BLOCK_RE = re.compile(r'\[comment:([a-zA-Z0-9]+)\]')
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
    """Вернуть все ID из <comment id> и [comment:id] по порядку (с повторами)."""
    return INLINE_RE.findall(md_text) + BLOCK_RE.findall(md_text)


def get_nested(d: dict, *keys):
    cur = d
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur


def validate_md(md_path: Path, issues: list[Issue], strict: bool):
    md_text = md_path.read_text(encoding="utf-8")
    md_ids = extract_md_ids(md_text)

    # Check ID format
    for mid in md_ids:
        if not ID_RE.match(mid):
            issues.append(Issue("error", md_path, f"invalid comment id format: {mid!r} (must be ^[a-zA-Z0-9]{{5}}$)"))

    # Check uniqueness within md
    seen = {}
    for mid in md_ids:
        seen[mid] = seen.get(mid, 0) + 1
    for mid, count in seen.items():
        if count > 1:
            issues.append(Issue("error", md_path, f"duplicate comment id in md: {mid} (appears {count} times)"))

    # Check yaml
    yaml_path = md_path.with_suffix(".comments.yaml")
    # special case for _index.md → _index.comments.yaml works via with_suffix
    # but pathlib uses last suffix so _index.md → _index.comments.yaml is correct
    yaml_data: dict = {}
    if yaml_path.exists():
        try:
            yaml_data = yaml.safe_load(yaml_path.read_text(encoding="utf-8")) or {}
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

    if any(i.level == "error" for i in issues):
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
