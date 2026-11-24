#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Генерация уникального 5-символьного ID для комментария Gramax."""

import argparse
import random
import string
import sys
from pathlib import Path

ALPHABET = string.ascii_letters + string.digits
MAX_ATTEMPTS = 100


def generate_id() -> str:
    return "".join(random.choices(ALPHABET, k=5))


def load_existing_ids(yaml_path: Path) -> set[str]:
    if not yaml_path.exists():
        return set()
    if not yaml_path.is_file():
        # Граница --check: путь-каталог — именованный отказ вместо traceback
        # IsADirectoryError (ADR-0028 Решение 7, дизайн волны-4 §3.7).
        print(f"not a file: {yaml_path}", file=sys.stderr)
        sys.exit(2)
    try:
        import yaml
    except ImportError:
        print("pyyaml required for --check", file=sys.stderr)
        sys.exit(3)
    # Чтение через общий примитив lib/read_page (ADR-0028 Решение 7): файл с битым
    # UTF-8 — именованный отказ с байтом/позицией/размером вместо traceback
    # UnicodeDecodeError. Импорт ленивый: модуль остаётся импортируемым без lib/ на
    # пути (проба уровня модуля вызывает только generate_id).
    from lib.read_page import read_page, utf8_message

    text, read_err = read_page(yaml_path)
    if read_err is not None or text is None:
        print(f"{yaml_path}: {utf8_message(read_err)}", file=sys.stderr)
        sys.exit(2)
    try:
        data = yaml.safe_load(text)
    except yaml.YAMLError as e:
        print(f"yaml parse error in {yaml_path}: {e}", file=sys.stderr)
        sys.exit(2)
    if not isinstance(data, dict):
        return set()
    return set(data.keys())


def generate_unique_id(existing: set[str]) -> str:
    for _ in range(MAX_ATTEMPTS):
        candidate = generate_id()
        if candidate not in existing:
            return candidate
    print(f"failed to generate unique ID after {MAX_ATTEMPTS} attempts", file=sys.stderr)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Генерация ID комментария Gramax.")
    parser.add_argument("--check", type=Path, help="Путь к .comments.yaml — проверить уникальность.")
    args = parser.parse_args()

    if args.check:
        existing = load_existing_ids(args.check)
        print(generate_unique_id(existing))
    else:
        print(generate_id())


if __name__ == "__main__":
    main()
