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
    try:
        import yaml
    except ImportError:
        print("pyyaml required for --check", file=sys.stderr)
        sys.exit(3)
    try:
        data = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))
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
