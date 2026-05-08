#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Валидация структуры каталога Gramax (pre-publish staging-check)."""

import argparse
import re
import sys
from pathlib import Path

import yaml

GARBAGE_FILES = {".DS_Store", "Thumbs.db", "CLAUDE.md"}
PAIRED_TAGS = ["note", "tabs", "tab", "html", "comment", "color", "highlight"]
SELF_CLOSING = ["view", "snippet", "openapi", "mermaid", "video", "icon", "image"]


class Issue:
    __slots__ = ("level", "path", "message")

    def __init__(self, level: str, path: Path, message: str):
        self.level = level  # "error" or "warning"
        self.path = path
        self.message = message

    def __str__(self):
        return f"{self.level.upper()}  {self.path}  {self.message}"


def check_doc_root(root: Path, issues: list[Issue]) -> bool:
    yaml_file = root / ".doc-root.yaml"
    if not yaml_file.exists():
        issues.append(Issue("error", root, ".doc-root.yaml not found"))
        return False
    try:
        data = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        issues.append(Issue("error", yaml_file, f"invalid yaml: {e}"))
        return False
    for field in ("title", "language", "syntax"):
        if not isinstance(data, dict) or field not in data:
            issues.append(Issue("error", yaml_file, f"missing field: {field}"))
    return True


def load_property_schema(root: Path) -> dict[str, dict] | None:
    """Возвращает {property_name: {type, values}} из .doc-root.yaml.

    None — если schema нечитабельна или содержит экспериментальный type: select.
    """
    yaml_file = root / ".doc-root.yaml"
    try:
        data = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
    except yaml.YAMLError:
        return None
    if not isinstance(data, dict):
        return None
    props = data.get("properties", [])
    if not isinstance(props, list):
        return None
    schema: dict[str, dict] = {}
    for p in props:
        if not isinstance(p, dict) or not p.get("name"):
            continue
        # detect experimental type: select with values: [{name: X}]
        values = p.get("values", [])
        if any(isinstance(v, dict) for v in values):
            return None
        schema[p["name"]] = {
            "type": p.get("type", "String"),
            "values": [str(v) for v in values],
        }
    return schema


def check_no_index_in_root(root: Path, issues: list[Issue]):
    if (root / "_index.md").exists():
        issues.append(Issue("error", root / "_index.md", "_index.md not allowed in catalog root (next to .doc-root.yaml)"))


def check_subfolders_have_index(root: Path, issues: list[Issue]):
    """V1: каждая подпапка с .md или вложенными папками обязана иметь _index.md."""
    for subdir in root.rglob("*"):
        if not subdir.is_dir():
            continue
        if ".gramax" in subdir.parts:
            continue
        if subdir == root:
            continue
        # has any .md file or any subdirectory inside
        has_content = any(
            child.is_dir() or (child.is_file() and child.suffix == ".md")
            for child in subdir.iterdir()
            if child.name != "_index.md"
        )
        if not has_content:
            continue
        if not (subdir / "_index.md").exists():
            issues.append(Issue("error", subdir, "missing _index.md (Gramax не покажет раздел в навигации)"))


def extract_frontmatter(text: str) -> dict | None:
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    try:
        return yaml.safe_load(text[3:end])
    except yaml.YAMLError:
        return None


def check_frontmatter(md_file: Path, issues: list[Issue], schema: dict | None = None):
    text = md_file.read_text(encoding="utf-8")
    fm = extract_frontmatter(text)
    if fm is None:
        issues.append(Issue("error", md_file, "missing or invalid frontmatter"))
        return
    for field in ("order", "title"):
        if field not in fm:
            issues.append(Issue("error", md_file, f"frontmatter missing field: {field}"))
    if md_file.name == "_index.md" and fm.get("properties"):
        issues.append(Issue("error", md_file, "_index.md не должен содержать properties:"))

    # V3: плоская нотация — предупреждение
    if md_file.name != "_index.md" and "properties" in fm:
        props = fm["properties"]
        if isinstance(props, list):
            for entry in props:
                if isinstance(entry, dict) and "name" not in entry:
                    issues.append(
                        Issue("warning", md_file,
                              "устаревшая плоская нотация properties; см. SKILL.md → Frontmatter")
                    )
                    break

    # V4, V5: properties соответствуют schema
    if md_file.name != "_index.md" and schema is not None and "properties" in fm:
        props = fm["properties"]
        if isinstance(props, list):
            for entry in props:
                if not isinstance(entry, dict) or "name" not in entry:
                    continue  # plain notation already reported by V3
                pname = entry["name"]
                if pname not in schema:
                    issues.append(
                        Issue("error", md_file,
                              f'property "{pname}" не объявлен в .doc-root.yaml')
                    )
                    continue
                schema_def = schema[pname]
                if schema_def["type"] != "Enum":
                    continue
                allowed = schema_def["values"]
                values = entry.get("value", [])
                if not isinstance(values, list):
                    values = [values]
                for v in values:
                    if str(v) not in allowed:
                        issues.append(
                            Issue("error", md_file,
                                  f'property "{pname}" имеет значение "{v}", '
                                  f'не входит в [{", ".join(allowed)}]')
                        )


def check_tags(md_file: Path, issues: list[Issue]):
    text = md_file.read_text(encoding="utf-8")
    # Strip code fences
    cleaned = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
    for tag in PAIRED_TAGS:
        opens = len(re.findall(rf"<{tag}(\s[^>]*)?(?<!/)>", cleaned))
        closes = len(re.findall(rf"</{tag}>", cleaned))
        if opens != closes:
            issues.append(Issue("error", md_file, f"unpaired <{tag}>: {opens} open, {closes} close"))
    # Block comment [comment:id]...[/comment]
    bc_open = len(re.findall(r"\[comment:[a-zA-Z0-9]{5}\]", cleaned))
    bc_close = len(re.findall(r"\[/comment\]", cleaned))
    if bc_open != bc_close:
        issues.append(Issue("error", md_file, f"unpaired [comment:id]: {bc_open} open, {bc_close} close"))


def check_garbage(root: Path, issues: list[Issue], strict: bool, fix: bool, yes: bool) -> list[Path]:
    removed = []
    for path in root.rglob("*"):
        if path.name in GARBAGE_FILES:
            level = "error" if strict else "warning"
            issues.append(Issue(level, path, f"garbage file: {path.name}"))
            if fix and yes:
                path.unlink()
                removed.append(path)
    return removed


def check_no_drawio(root: Path, issues: list[Issue], strict: bool):
    for path in root.rglob("*.drawio"):
        level = "error" if strict else "warning"
        issues.append(Issue(level, path, ".drawio file should be converted to .svg"))


def validate(root: Path, strict: bool, fix: bool, yes: bool) -> list[Issue]:
    issues: list[Issue] = []
    if not root.is_dir():
        issues.append(Issue("error", root, "not a directory"))
        return issues
    if not check_doc_root(root, issues):
        return issues
    check_no_index_in_root(root, issues)
    check_subfolders_have_index(root, issues)
    schema = load_property_schema(root)
    if schema is None:
        issues.append(Issue("warning", root / ".doc-root.yaml",
                            "schema использует экспериментальный формат values; V4/V5 пропущены"))
    for md in root.rglob("*.md"):
        if ".gramax" in md.parts:
            continue
        check_frontmatter(md, issues, schema)
        check_tags(md, issues)
    check_garbage(root, issues, strict, fix, yes)
    check_no_drawio(root, issues, strict)
    return issues


def main():
    parser = argparse.ArgumentParser(description="Валидация структуры каталога Gramax.")
    parser.add_argument("path", type=Path, help="Путь к корню каталога Gramax.")
    parser.add_argument("--strict", action="store_true", help="Warnings → errors.")
    parser.add_argument("--fix", action="store_true", help="Удалить мусорные файлы (требует --yes).")
    parser.add_argument("--yes", action="store_true", help="Подтверждение для --fix.")
    args = parser.parse_args()

    if args.fix and not args.yes:
        print("--fix requires --yes flag for safety", file=sys.stderr)
        sys.exit(2)

    issues = validate(args.path, args.strict, args.fix, args.yes)

    has_errors = any(i.level == "error" for i in issues)
    has_warnings_strict = args.strict and any(i.level == "warning" for i in issues)

    for issue in issues:
        print(str(issue))

    if has_errors or has_warnings_strict:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
