#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Транслит кириллицы в latin-slug для имён файлов/папок Gramax."""

import argparse
import re
import sys

TRANSLIT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd',
    'е': 'e', 'ё': 'yo', 'ж': 'zh', 'з': 'z', 'и': 'i',
    'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
    'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
    'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch',
    'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '',
    'э': 'e', 'ю': 'yu', 'я': 'ya',
}


def slugify(text: str) -> str:
    """Преобразовать заголовок в slug: транслит → lowercase → дефисы → очистка."""
    if not text or not text.strip():
        raise ValueError("empty input: slug requires non-empty string")

    text = text.lower()
    result = []
    for ch in text:
        if ch in TRANSLIT:
            result.append(TRANSLIT[ch])
        elif ch.isalnum():
            result.append(ch)
        else:
            result.append('-')
    s = ''.join(result)
    s = re.sub(r'-+', '-', s)
    s = s.strip('-')
    return s


def main():
    parser = argparse.ArgumentParser(description="Транслит кириллицы в latin-slug.")
    parser.add_argument("text", help="Исходный текст (заголовок страницы/папки).")
    parser.add_argument("--filename", action="store_true", help="Добавить расширение .md.")
    parser.add_argument("--folder", action="store_true", help="Явно без расширения (default).")
    args = parser.parse_args()

    try:
        slug = slugify(args.text)
    except ValueError as e:
        print(str(e), file=sys.stderr)
        sys.exit(2)

    if args.filename:
        slug += ".md"
    print(slug)


if __name__ == "__main__":
    main()
