# plugins/gramax/scripts/lib/test_link_resolver.py
"""Unit tests for link_resolver. Run:
   uv run python plugins/gramax/scripts/lib/test_link_resolver.py

Перевод под ADR-0028 Решение 4 (NFR-084 — перевод, не удаление): единственный резолвер —
`resolve_link_target(source_dir, target, *, index_optional=False)` (дизайн волны-4 §3.4,
четыре шага-кандидата); `resolve_no_ext` удаляется. Интеграционные ноги тех же веток —
стабы tests/gramax/link-form-resolver/ac-168-*, ac-169-*.
Red on 6e2db04: resolve_link_target в lib/link_resolver.py нет — ветки переводятся
с именованным отказом; после правки Dev — зелёные.
"""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.link_resolver import check_hash_anchor, slugify_heading


def _resolve_link_target():
    """Импорт целевого резолвера внутри теста: отсутствие функции — именованный
    ассерт-отказ, а не ошибка коллекции (стаб обязан падать на ассерте, ADR-012 Д5)."""
    try:
        from lib.link_resolver import resolve_link_target
    except ImportError:
        return None
    return resolve_link_target


def test_slugify_basic():
    assert slugify_heading("My Title") == "my-title"
    assert slugify_heading("Hello World") == "hello-world"
    assert slugify_heading("  Extra   Spaces  ") == "extra-spaces"


def test_slugify_special_chars():
    assert slugify_heading("Что-то на русском") == "chto-to-na-russkom"
    assert slugify_heading("C# and .NET") == "c-and-net"


def test_resolve_link_target_literal_file():
    # Шаг 1: цель с .md на конце резолвится буквально.
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "target.md").write_text("content")
        result = resolve(root, "target.md")
        assert result is not None
        assert result.name == "target.md"
        assert result == (root / "target.md").resolve()


def test_resolve_link_target_infers_md():
    # Шаг 2: цель без расширения → target.md (ветка with_suffix поглощена шагом 2).
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "target.md").write_text("content")
        result = resolve(root, "target")
        assert result is not None
        assert result.name == "target.md"


def test_resolve_link_target_no_double_md():
    # Правило 3 §3.4: цель с .md резолвится только буквально — второго .md не появляется.
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "target.md").write_text("content")
        result = resolve(root, "target.md")
        assert result is not None
        assert result.name == "target.md", "цель с .md не должна получить второй .md (AC-011b)"


def test_resolve_link_target_section_index():
    # Шаг 3: литерал / "_index.md" (корень раздела движка — _index.md, const.ts:32-33).
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "category").mkdir()
        (root / "category" / "_index.md").write_text("content")
        result = resolve(root, "category")
        assert result is not None
        assert result.name == "_index.md"


def test_resolve_link_target_dir_only_with_optional_flag():
    # Шаг 4 + правило 1: каталог не считается файлом — без _index.md и без флага None;
    # с index_optional=True — каталог.
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "category").mkdir()
        result = resolve(root, "category")
        assert result is None, "каталог без _index.md без флага не резолвится (правило 1 §3.4)"
        result_flagged = resolve(root, "category", index_optional=True)
        assert result_flagged is not None, "при index_optional=True каталог резолвится (шаг 4 §3.4)"
        assert result_flagged == (root / "category").resolve()


def test_resolve_link_target_file_wins_over_dir():
    # Правило 2 §3.4: при одноимённых файле и каталоге побеждает файл.
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "section.md").write_text("content")
        (root / "section").mkdir()
        result = resolve(root, "section")
        assert result is not None
        assert result.name == "section.md", "побеждает файл (правило 2 §3.4; движок: папка — не файл)"


def test_resolve_link_target_not_found():
    resolve = _resolve_link_target()
    assert resolve is not None, (
        "resolve_link_target отсутствует в lib/link_resolver.py — единственный резолвер "
        "ADR-0028 Решение 4 (дизайн волны-4 §3.4) не заведён; red on 6e2db04"
    )
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        assert resolve(root, "nonexistent") is None


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
        test_resolve_link_target_literal_file,
        test_resolve_link_target_infers_md,
        test_resolve_link_target_no_double_md,
        test_resolve_link_target_section_index,
        test_resolve_link_target_dir_only_with_optional_flag,
        test_resolve_link_target_file_wins_over_dir,
        test_resolve_link_target_not_found,
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
