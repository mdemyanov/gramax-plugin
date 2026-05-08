#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Конвертация .drawio (raw mxfile XML) в SVG с embedded drawio-данными.

Алгоритм:
  input mxfile → извлечь diagram/mxGraphModel → URL-encode → deflate → base64
  → обернуть в <mxfile><diagram>...</diagram></mxfile> → html.escape
  → поместить в content="..." тега <svg>.

Это обеспечивает ASCII-only content (кириллица не ломается Latin-1 парсингом).
"""

import argparse
import base64
import html
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path


def compress_diagram(xml_content: str) -> str:
    """URL-encode → raw deflate → base64."""
    url_encoded = urllib.parse.quote(xml_content, safe="")
    # raw deflate: zlib-сжатие без zlib-header (2 байта) и без Adler32 (4 байта в конце)
    compressed = zlib.compress(url_encoded.encode("utf-8"))[2:-4]
    return base64.b64encode(compressed).decode("ascii")


def decompress_diagram(b64: str) -> str:
    """base64 → raw inflate → URL-decode."""
    decoded = base64.b64decode(b64)
    decompressed = zlib.decompress(decoded, -15)
    return urllib.parse.unquote(decompressed.decode("utf-8"))


def extract_mxgraph_model(drawio_xml: str) -> tuple[str, int | None, int | None]:
    """Извлечь mxGraphModel из .drawio. Вернуть (xml, width, height) где width/height из pageWidth/pageHeight."""
    try:
        root = ET.fromstring(drawio_xml)
    except ET.ParseError as e:
        raise ValueError(f"drawio parse error: {e}") from e

    diagram = root.find("diagram") if root.tag == "mxfile" else None
    if diagram is None:
        raise ValueError("no <diagram> element in mxfile")

    mxgraph = diagram.find("mxGraphModel")
    if mxgraph is None:
        # Возможно, diagram содержит уже сжатые данные — не обрабатываем
        raise ValueError("diagram has no <mxGraphModel> (already compressed?)")

    width = mxgraph.get("pageWidth")
    height = mxgraph.get("pageHeight")
    return (
        ET.tostring(mxgraph, encoding="unicode"),
        int(width) if width else None,
        int(height) if height else None,
    )


def build_svg(compressed_b64: str, width: int, height: int) -> str:
    mxfile_tag = (
        f'<mxfile host="app.diagrams.net" version="24.3.1" type="embed">'
        f'<diagram id="d1" name="Page-1">{compressed_b64}</diagram></mxfile>'
    )
    escaped = html.escape(mxfile_tag, quote=True)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'version="1.1" width="{width}px" height="{height}px" '
        f'viewBox="-0.5 -0.5 {width} {height}" '
        f'content="{escaped}"><defs/><g/></svg>'
    )


def convert(input_path: Path, output_path: Path, width: int | None, height: int | None) -> None:
    drawio_xml = input_path.read_text(encoding="utf-8")
    mxgraph_xml, default_w, default_h = extract_mxgraph_model(drawio_xml)
    w = width or default_w or 800
    h = height or default_h or 600
    compressed = compress_diagram(mxgraph_xml)
    svg = build_svg(compressed, w, h)
    output_path.write_text(svg, encoding="utf-8")


def extract_content_from_svg(svg_xml: str) -> str:
    root = ET.fromstring(svg_xml)
    content = root.get("content")
    if not content:
        raise ValueError("svg has no content attribute")
    return content


def decompress_from_svg(svg_path: Path) -> str:
    svg = svg_path.read_text(encoding="utf-8")
    content = extract_content_from_svg(svg)
    mxfile_xml = content  # html.escape обратим автоматически xml.etree при parsing — но здесь уже распарсено
    # извлечь содержимое <diagram>
    root = ET.fromstring(mxfile_xml)
    diagram = root.find("diagram") if root.tag == "mxfile" else None
    if diagram is None or diagram.text is None:
        raise ValueError("no diagram in svg content")
    return decompress_diagram(diagram.text)


def main():
    parser = argparse.ArgumentParser(description="Конвертация .drawio → SVG с embedded drawio-данными.")
    parser.add_argument("input", type=Path, nargs="?", help="Входной .drawio файл.")
    parser.add_argument("output", type=Path, nargs="?", help="Выходной .svg файл.")
    parser.add_argument("--width", type=int, help="Ширина SVG (иначе pageWidth).")
    parser.add_argument("--height", type=int, help="Высота SVG (иначе pageHeight).")
    parser.add_argument("--decompress", type=Path, help="SVG-файл для декомпрессии (вывод mxGraphModel в stdout).")
    args = parser.parse_args()

    try:
        if args.decompress:
            print(decompress_from_svg(args.decompress))
            return
        if not args.input or not args.output:
            parser.error("input and output required (or use --decompress)")
        convert(args.input, args.output, args.width, args.height)
    except (ValueError, ET.ParseError, OSError) as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
