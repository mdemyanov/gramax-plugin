"""Unit tests for md_link_parser. Run from repo root:
   uv run python plugins/gramax/scripts/lib/test_md_link_parser.py
"""
import sys
import tempfile
from pathlib import Path

# Ensure lib/ is importable when run directly
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.md_link_parser import parse_md_resources, MdResource


def test_parse_markdown_link():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".doc-root.yaml").write_text("code: test\ntitle: Test\nlanguage: ru\nsyntax: XML\n")
        (root / "article.md").write_text(
            "---\norder: 1\ntitle: Test\n---\n[ссылка](./other.md)\n"
        )
        (root / "other.md").write_text(
            "---\norder: 2\ntitle: Other\n---\ncontent\n"
        )
        resources = parse_md_resources(root)
        links = [r for r in resources if r.target_type == "link"]
        assert len(links) == 1, f"Expected 1 link, got {len(links)}"
        assert links[0].raw_target == "./other.md"
        assert links[0].in_scope is True


def test_parse_image():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".doc-root.yaml").write_text("code: test\ntitle: Test\nlanguage: ru\nsyntax: XML\n")
        (root / "article.md").write_text(
            "---\norder: 1\ntitle: Test\n---\n![alt](./img.png)\n"
        )
        resources = parse_md_resources(root)
        images = [r for r in resources if r.target_type == "image"]
        assert len(images) == 1, f"Expected 1 image, got {len(images)}"
        assert images[0].raw_target == "./img.png"


def test_parse_drawio():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".doc-root.yaml").write_text("code: test\ntitle: Test\nlanguage: ru\nsyntax: XML\n")
        (root / "article.md").write_text(
            '---\norder: 1\ntitle: Test\n---\n<drawio path="./diagram.drawio"/>\n'
        )
        resources = parse_md_resources(root)
        drawios = [r for r in resources if r.target_type == "drawio"]
        assert len(drawios) == 1, f"Expected 1 drawio, got {len(drawios)}"
        assert drawios[0].raw_target == "./diagram.drawio"


def test_external_links_skipped():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".doc-root.yaml").write_text("code: test\ntitle: Test\nlanguage: ru\nsyntax: XML\n")
        (root / "article.md").write_text(
            "---\norder: 1\ntitle: Test\n---\n[external](https://example.com)\n[mail](mailto:a@b.com)\n"
        )
        resources = parse_md_resources(root)
        assert len(resources) == 0, f"External links should be skipped, got {len(resources)}"


def test_code_masked():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".doc-root.yaml").write_text("code: test\ntitle: Test\nlanguage: ru\nsyntax: XML\n")
        (root / "article.md").write_text(
            "---\norder: 1\ntitle: Test\n---\n```\n![code](./not-real.png)\n```\n"
            "`[inline](./also-not-real.md)`\n"
            'real [link](./real.md)\n'
        )
        (root / "real.md").write_text("---\norder: 2\ntitle: Real\n---\ncontent\n")
        resources = parse_md_resources(root)
        links = [r for r in resources if r.target_type == "link"]
        assert len(links) == 1, f"Only real link outside code, got {len(links)}"
        assert links[0].raw_target == "./real.md"


if __name__ == "__main__":
    tests = [
        test_parse_markdown_link,
        test_parse_image,
        test_parse_drawio,
        test_external_links_skipped,
        test_code_masked,
    ]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  PASS  {t.__name__}")
        except AssertionError as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
    sys.exit(failed)
