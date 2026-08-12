# plugins/gramax/scripts/lib/test_link_resolver.py
"""Unit tests for link_resolver. Run:
   uv run python plugins/gramax/scripts/lib/test_link_resolver.py
"""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.link_resolver import resolve_no_ext, check_hash_anchor, slugify_heading


def test_slugify_basic():
    assert slugify_heading("My Title") == "my-title"
    assert slugify_heading("Hello World") == "hello-world"
    assert slugify_heading("  Extra   Spaces  ") == "extra-spaces"


def test_slugify_special_chars():
    assert slugify_heading("Что-то на русском") == "chto-to-na-russkom"
    assert slugify_heading("C# and .NET") == "c-and-net"


def test_resolve_no_ext_with_md():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "target.md").write_text("content")
        result = resolve_no_ext(root / "target")
        assert result is not None
        assert result.name == "target.md"


def test_resolve_no_ext_with_exact_file():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "target.md").write_text("content")
        result = resolve_no_ext(root / "target.md")
        assert result is not None
        assert result.name == "target.md"


def test_resolve_no_ext_with_index():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "category").mkdir()
        (root / "category" / "index.md").write_text("content")
        result = resolve_no_ext(root / "category")
        assert result is not None
        assert result.name == "index.md"


def test_resolve_no_ext_not_found():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        result = resolve_no_ext(root / "nonexistent")
        assert result is None


def test_check_hash_anchor_found():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        md = root / "doc.md"
        md.write_text("## My Section\n\ncontent\n\n### Sub Section\n\nmore\n")
        assert check_hash_anchor(md, "my-section") is True
        assert check_hash_anchor(md, "sub-section") is True


def test_check_hash_anchor_not_found():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        md = root / "doc.md"
        md.write_text("## Only This\n\ncontent\n")
        assert check_hash_anchor(md, "nonexistent") is False


def test_check_hash_anchor_empty_fragment():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        md = root / "doc.md"
        md.write_text("## Section\n")
        assert check_hash_anchor(md, "") is True


if __name__ == "__main__":
    tests = [
        test_slugify_basic,
        test_slugify_special_chars,
        test_resolve_no_ext_with_md,
        test_resolve_no_ext_with_exact_file,
        test_resolve_no_ext_with_index,
        test_resolve_no_ext_not_found,
        test_check_hash_anchor_found,
        test_check_hash_anchor_not_found,
        test_check_hash_anchor_empty_fragment,
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
