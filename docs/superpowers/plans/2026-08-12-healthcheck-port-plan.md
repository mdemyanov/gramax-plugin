# Healthcheck Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Портировать 4 категории healthcheck-проверок из Gramax-поставщика в `validate_structure.py` и расширить тестовые фикстуры.

**Architecture:** Новые модули `lib/md_link_parser.py` (парсинг ссылок/изображений/диаграмм) и `lib/link_resolver.py` (no-ext + hash-резолв). Новые проверки W030-W034 добавляются функциями в `validate_structure.py`. Флаг `--groups` — опциональный grouped-вывод. Тестовые фикстуры в `tests/gramax/catalog-validator/fixtures/gramax-fixtures/` следуют шаблону `ac-NNN.sh`.

**Tech Stack:** Python 3.10+, pyyaml, bash (тесты)

## Global Constraints

- Все новые проверки — WARNING, не ERROR (не ломают exit code без `--strict`)
- Существующие коды ошибок (C1-C10, W010-W029) не меняются
- Без `--groups` вывод идентичен текущему формату (обратная совместимость)
- Тестовые фикстуры в `tests/gramax/catalog-validator/fixtures/gramax-fixtures/`
- Новые Python-модули в `plugins/gramax/scripts/lib/`
- AC-тесты следуют нумерации: ac-014 (W030 images), ac-015 (W031 diagrams), ac-016 (W032 no-ext), ac-017 (W033 hash), ac-018 (W034 unsupported), ac-019 (W030-W034 regression), ac-020 (--groups)

---

### Task 1: lib/md_link_parser.py — парсинг markdown-ресурсов

**Files:**
- Create: `plugins/gramax/scripts/lib/__init__.py`
- Create: `plugins/gramax/scripts/lib/md_link_parser.py`
- Modify: `plugins/gramax/scripts/validate_structure.py` (импорт и использование вместо inline-регексов)

**Interfaces:**
- Produces: `MdLinkParser` dataclass с полями `source`, `raw_target`, `target_type` ("link"|"image"|"drawio"), `resolved_path`
- Produces: `parse_md_resources(root: Path) -> list[MdLinkParser]` — собирает все ссылки/изображения/drawio-теги из каталога
- Produces: `MdResource` dataclass с полями `source`, `raw_path`, `target_type`, `resolved_path`

**Why:** Сейчас парсинг ссылок в `validate_structure.py` размазан между `_MD_LINK_RE`, `_collect_links()` и захардкожен в `LinkRef`. Для новых проверок (images, diagrams, drawio) нужен единый сборщик всех ресурсных ссылок.

- [ ] **Step 1: Create `lib/__init__.py`**

```bash
mkdir -p plugins/gramax/scripts/lib
```

```python
# plugins/gramax/scripts/lib/__init__.py
"""Shared utilities for Gramax catalog validation."""
```

- [ ] **Step 2: Write `lib/md_link_parser.py`**

```python
# plugins/gramax/scripts/lib/md_link_parser.py
"""Парсинг markdown-ресурсов: ссылки, изображения, drawio-теги.

Извлекает из .md-файлов каталога все ресурсные ссылки в унифицированном виде,
пригодном для downstream-проверок (broken links, images, diagrams).
Код-блоки (fenced + inline) маскируются перед парсингом — документация,
показывающая синтаксис, не даёт ложных срабатываний.
"""

import re
from dataclasses import dataclass
from pathlib import Path

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")
_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
_DRAWIO_RE = re.compile(r'<drawio\s[^>]*path="([^"]+)"[^>]*/>')
_EXTERNAL_RE = re.compile(r"^(?:[a-z][a-z0-9+.\-]*:|//)", re.IGNORECASE)


@dataclass
class MdResource:
    """Одна ресурсная ссылка в markdown-статье."""
    source: Path          # файл, где найдена ссылка
    raw_target: str        # текст внутри скобок / кавычек, как в файле
    resolved_path: Path     # цель, резолвленная относительно source.parent
    target_type: str        # "link" | "image" | "drawio"
    in_scope: bool          # False — цель за пределами root


def _mask_code(text: str) -> str:
    """Заменяет код (fenced-блоки и inline) пробелами той же длины, сохраняя смещения строк."""
    out: list[str] = []
    fence_char: str | None = None
    fence_len = 0
    for line in text.split("\n"):
        m = _FENCE_RE.match(line)
        if fence_char is None:
            if m:
                fence_char, fence_len = m.group(1)[0], len(m.group(1))
                out.append(" " * len(line))
            else:
                out.append(line)
            continue
        if m and m.group(1)[0] == fence_char and len(m.group(1)) >= fence_len and not m.group(2).strip():
            fence_char, fence_len = None, 0
        out.append(" " * len(line))
    return _INLINE_CODE_RE.sub(lambda m: " " * len(m.group(0)), "\n".join(out))


def _collect_md_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.md") if ".gramax" not in p.parts)


def parse_md_resources(root: Path) -> list[MdResource]:
    """Собирает все ресурсные ссылки из markdown-файлов каталога.

    Возвращает унифицированный список MdResource: markdown-ссылки [text](target),
    изображения ![alt](target), и drawio-теги <drawio path="target"/>.
    Внешние ссылки (http/https/mailto) пропускаются. Cross-каталожные ссылки
    помечаются in_scope=False.
    """
    root_resolved = root.resolve()
    resources: list[MdResource] = []

    for md in _collect_md_files(root):
        text = _mask_code(md.read_text(encoding="utf-8"))

        # Markdown links and images: [text](target), ![alt](target)
        for m in _MD_LINK_RE.finditer(text):
            full_match = m.group(0)
            raw = m.group(1)
            target = raw.split("#", 1)[0].strip()
            target = target.strip("<>")
            if not target:
                continue
            if _EXTERNAL_RE.match(target):
                continue
            resolved = (md.parent / target).resolve()
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            ttype = "image" if full_match.startswith("!") else "link"
            resources.append(MdResource(md, raw, resolved, ttype, in_scope))

        # Drawio tags: <drawio path="..."/>
        for m in _DRAWIO_RE.finditer(text):
            raw = m.group(1)
            resolved = (md.parent / raw).resolve()
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            resources.append(MdResource(md, raw, resolved, "drawio", in_scope))

    return resources
```

- [ ] **Step 3: Unit test — `lib/test_md_link_parser.py`**

```python
# plugins/gramax/scripts/lib/test_md_link_parser.py
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
```

- [ ] **Step 4: Run unit tests to verify they pass**

Run: `cd /Users/mdemyanov/Devel/gramax && uv run python plugins/gramax/scripts/lib/test_md_link_parser.py`
Expected: PASS for all 5 tests

- [ ] **Step 5: Commit**

```bash
git add plugins/gramax/scripts/lib/__init__.py plugins/gramax/scripts/lib/md_link_parser.py plugins/gramax/scripts/lib/test_md_link_parser.py
git commit -m "feat(validate): lib/md_link_parser — унифицированный парсинг markdown-ресурсов

Извлекает ссылки, изображения и drawio-теги в MdResource. Код-блоки маскируются.
5 unit tests.

Part of: healthcheck-port (W030-W034).
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: lib/link_resolver.py — продвинутый резолв ссылок

**Files:**
- Create: `plugins/gramax/scripts/lib/link_resolver.py`
- Create: `plugins/gramax/scripts/lib/test_link_resolver.py`

**Interfaces:**
- Produces: `resolve_no_ext(candidate: Path) -> Path | None` — пробует `target`, `target.md`, `target/index.md`
- Produces: `check_hash_anchor(target_md: Path, fragment: str) -> bool` — проверяет существование заголовка с slugify
- Produces: `slugify_heading(text: str) -> str` — lowercase, пробелы→дефисы, спецсимволы удалены

- [ ] **Step 1: Write `lib/link_resolver.py`**

```python
# plugins/gramax/scripts/lib/link_resolver.py
"""Продвинутый резолв markdown-ссылок: no-ext и hash-якоря.

Зеркалирует поведение Gramax при рендеринге:
- Ссылка без расширения [text](other) → other.md или other/index.md
- Якорь [text](article#section) → проверка заголовка в целевом файле
"""

import re
import unicodedata
from pathlib import Path


def _find_headings(md_path: Path) -> list[str]:
    """Извлекает текст заголовков (## Title) из markdown-файла.
    Маскирует код-блоки чтобы заголовки внутри примеров не считались настоящими.
    """
    if not md_path.exists():
        return []
    text = md_path.read_text(encoding="utf-8")
    # Маскируем fenced code blocks
    lines = text.split("\n")
    in_fence = False
    headings: list[str] = []
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = re.match(r"^#{1,6}\s+(.+?)(?:\s*\{[^}]*\})?\s*$", line)
        if m:
            headings.append(m.group(1).strip())
    return headings


def slugify_heading(text: str) -> str:
    """Преобразует заголовок в slug для сравнения с hash-якорем.

    Правила (совместимо с Gramax рендерингом):
    - lowercase
    - пробелы → дефисы
    - удалить диакритику (NFKD)
    - оставить только [a-z0-9-]
    - схлопнуть повторяющиеся дефисы
    """
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-{2,}", "-", text)
    return text.strip("-")


def resolve_no_ext(candidate: Path) -> Path | None:
    """Резолвит markdown-ссылку без расширения.

    Пробует:
    1. candidate как есть (может быть папкой с index.md)
    2. candidate.md
    3. candidate/index.md (для ссылок на категории)

    Возвращает Path существующего файла или None.
    """
    # 1. Точное совпадение (может быть директория)
    if candidate.is_dir():
        index_md = candidate / "index.md"
        if index_md.exists():
            return index_md
        return None
    if candidate.is_file():
        return candidate
    # 2. candidate.md
    with_ext = candidate.with_suffix(".md")
    if with_ext.exists():
        return with_ext
    # 3. candidate/index.md
    index_md = candidate / "index.md"
    if index_md.exists():
        return index_md
    return None


def check_hash_anchor(target_md: Path, fragment: str) -> bool:
    """Проверяет существование hash-якоря в целевом markdown-файле.

    fragment — часть после #, например "my-section".
    Возвращает True если заголовок с таким slug существует.
    """
    if not fragment:
        return True  # нет якоря — OK
    headings = _find_headings(target_md)
    target_slug = slugify_heading(fragment)
    for h in headings:
        if slugify_heading(h) == target_slug:
            return True
    return False
```

- [ ] **Step 2: Write `lib/test_link_resolver.py`**

```python
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
```

- [ ] **Step 3: Run unit tests to verify they pass**

Run: `cd /Users/mdemyanov/Devel/gramax && uv run python plugins/gramax/scripts/lib/test_link_resolver.py`
Expected: PASS for all 9 tests

- [ ] **Step 4: Commit**

```bash
git add plugins/gramax/scripts/lib/link_resolver.py plugins/gramax/scripts/lib/test_link_resolver.py
git commit -m "feat(validate): lib/link_resolver — продвинутый резолв ссылок

no-ext resolution (target → target.md → target/index.md) и hash-anchor
проверка со slugify-сравнением. 9 unit tests.

Part of: healthcheck-port (W032, W033).
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Image + Diagram checks (W030, W031)

**Files:**
- Modify: `plugins/gramax/scripts/validate_structure.py` (добавить `check_images` и `check_diagrams`)

**Interfaces:**
- Consumes: `parse_md_resources` from `lib.md_link_parser`
- Produces: `check_images(root, issues)` — W030 для ненайденных изображений
- Produces: `check_diagrams(root, issues)` — W031 для ненайденных drawio-файлов

- [ ] **Step 1: Add imports to `validate_structure.py`**

Insert after line 21 (`from pathlib import Path`):

```python
from lib.md_link_parser import parse_md_resources
```

- [ ] **Step 2: Add `check_images` function**

Insert before `def main():` (before line 422):

```python
def check_images(root: Path, issues: list[Issue]):
    """Проверяет существование файлов изображений, на которые ссылаются markdown-статьи.

    ![alt](path) → path должен существовать на диске. WARNING-уровень (W030).
    """
    for res in parse_md_resources(root):
        if res.target_type != "image":
            continue
        if not res.in_scope:
            continue  # cross-каталожная ссылка — не резолвим (FR-047)
        if not res.resolved_path.exists():
            issues.append(Issue(
                "warning", res.source,
                f'W030: файл изображения не найден: "{res.raw_target}" → {res.resolved_path}',
            ))


def check_diagrams(root: Path, issues: list[Issue]):
    """Проверяет существование .drawio-файлов, на которые ссылаются статьи.

    <drawio path="..."/> → path должен существовать на диске. WARNING-уровень (W031).
    """
    for res in parse_md_resources(root):
        if res.target_type != "drawio":
            continue
        if not res.in_scope:
            continue
        if not res.resolved_path.exists():
            issues.append(Issue(
                "warning", res.source,
                f'W031: файл диаграммы не найден: "{res.raw_target}" → {res.resolved_path}',
            ))
```

- [ ] **Step 3: Wire into `validate()`**

Insert after line 418 (`check_orphans(root, issues, strict)`):

```python
    check_images(root, issues)
    check_diagrams(root, issues)
```

- [ ] **Step 4: Verify existing tests still pass**

Run: `cd /Users/mdemyanov/Devel/gramax && bash tests/gramax/catalog-validator/run.sh`
Expected: existing tests still pass (W030/W031 — warnings, не ломают exit code)

- [ ] **Step 5: Dogfood — run on real content**

Run: `cd /Users/mdemyanov/Devel/gramax && uv run plugins/gramax/scripts/validate_structure.py content/`
Expected: clean exit (0) или только новые WARNING

- [ ] **Step 6: Commit**

```bash
git add plugins/gramax/scripts/validate_structure.py
git commit -m "feat(validate): проверка изображений и диаграмм (W030, W031)

check_images — существование файлов для ![alt](path)
check_diagrams — существование файлов для <drawio path=\"...\"/>
Использует lib/md_link_parser для сбора ресурсов.

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Advanced link checks (W032, W033)

**Files:**
- Modify: `plugins/gramax/scripts/validate_structure.py` (доработать `check_broken_links`)

**Interfaces:**
- Consumes: `resolve_no_ext`, `check_hash_anchor` from `lib.link_resolver`
- Consumes: `parse_md_resources` from `lib.md_link_parser`
- Produces: enhanced `check_broken_links` — W032 (no-ext fail), W033 (hash not found)

- [ ] **Step 1: Add link_resolver import to `validate_structure.py`**

Insert after the `lib.md_link_parser` import (added in Task 3):

```python
from lib.link_resolver import resolve_no_ext, check_hash_anchor
```

- [ ] **Step 2: Enhance `check_broken_links`**

Replace the existing `check_broken_links` function (lines 333-344) with:

```python
def check_broken_links(root: Path, issues: list[Issue]):
    """FR-048: markdown-ссылка на несуществующий файл внутри того же `.doc-root.yaml`-
    каталога — error безусловно (ADR-0012 Решение 2).

    Расширено healthcheck-портом:
    - W032: no-ext resolution — если target не найден, но target.md существует → OK;
      если ни target, ни target.md не найдены → предупреждение (до повышения до error
      в будущем релизе).
    - W033: hash anchor — если #fragment не соответствует ни одному заголовку → warning.
    """
    for res in parse_md_resources(root):
        if res.target_type != "link":
            continue
        if not res.in_scope:
            continue

        raw = res.raw_target
        fragment = raw.split("#", 1)[1] if "#" in raw else ""
        target_no_fragment = raw.split("#", 1)[0].strip().strip("<>")

        # Пробуем найти целевой файл с no-ext резолвом
        resolved = res.resolved_path
        if not resolved.exists():
            # no-ext fallback
            alt = resolve_no_ext(resolved)
            if alt is not None:
                resolved = alt
            else:
                issues.append(Issue(
                    "error", res.source,
                    f'битая ссылка (broken link) на "{raw}" — файл не найден: {resolved}',
                ))
                continue

        # Проверяем hash-якорь только если файл найден
        if fragment and resolved.suffix == ".md":
            if not check_hash_anchor(resolved, fragment):
                issues.append(Issue(
                    "warning", res.source,
                    f'W033: hash-якорь "#{fragment}" не найден в {resolved.relative_to(root)} '
                    f'(ссылка из {res.source.name})',
                ))
```

- [ ] **Step 3: Verify existing tests still pass**

Run: `cd /Users/mdemyanov/Devel/gramax && bash tests/gramax/catalog-validator/run.sh`
Expected: existing tests pass (ac-005 broken-link still detected; no-ext резолв не отменяет error для настоящих битых ссылок)

- [ ] **Step 4: Dogfood — run on real content**

Run: `cd /Users/mdemyanov/Devel/gramax && uv run plugins/gramax/scripts/validate_structure.py content/`
Expected: clean exit (0) или только новые WARNING

- [ ] **Step 5: Commit**

```bash
git add plugins/gramax/scripts/validate_structure.py
git commit -m "feat(validate): продвинутый резолв ссылок — no-ext (W032) и hash-якоря (W033)

check_broken_links теперь использует resolve_no_ext (пробует target.md если target
не найден) и check_hash_anchor (проверяет #fragment по заголовкам целевого файла).
W033 — warning, не ломает exit code.

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Unsupported markup (W034) + `--groups` taxonomy

**Files:**
- Modify: `plugins/gramax/scripts/validate_structure.py` (добавить `check_unsupported_markup` и `--groups` вывод)

**Interfaces:**
- Produces: `check_unsupported_markup(root, issues)` — W034 для HTML-тегов/нестандартной разметки
- Produces: `print_groups(issues)` — группированный вывод по `CatalogErrorGroups`
- Produces: `--groups` CLI-флаг

- [ ] **Step 1: Add `check_unsupported_markup` function**

Insert before `def main():`:

```python
# Whitelist тегов, которые Gramax НЕ считает unsupported
_KNOWN_TAGS = {"drawio"}

_UNSUPPORTED_HTML_RE = re.compile(r"<(?!\/)([a-z][a-z0-9]*)(?:\s[^>]*)?>", re.IGNORECASE)


def check_unsupported_markup(root: Path, issues: list[Issue]):
    """Проверяет наличие HTML-тегов и нестандартной разметки в markdown-статьях.

    Gramax не поддерживает произвольный HTML. Исключение: <drawio path="..."/>
    WARNING-уровень (W034) — некоторые HTML-теги могут быть валидны в markdown.
    """
    for md in _collect_md_files(root):
        text = _mask_code(md.read_text(encoding="utf-8"))
        seen_tags: set[str] = set()
        for m in _UNSUPPORTED_HTML_RE.finditer(text):
            tag = m.group(1).lower()
            if tag not in _KNOWN_TAGS and tag not in seen_tags:
                seen_tags.add(tag)
                issues.append(Issue(
                    "warning", md,
                    f'W034: неподдерживаемая разметка: <{m.group(1)}> '
                    f'(Gramax может не отобразить этот элемент)',
                ))
```

- [ ] **Step 2: Add `--groups` taxonomy output**

Replace the `main()` body (lines 422-451) to add `--groups` flag:

```python
def main():
    parser = argparse.ArgumentParser(
        description="Валидация структуры каталога Gramax.",
        epilog=EPILOG,
    )
    parser.add_argument("path", type=Path, help="Путь к корню каталога Gramax.")
    parser.add_argument("--strict", action="store_true", help="Warnings → errors.")
    parser.add_argument("--fix", action="store_true", help="Удалить мусорные файлы (требует --yes).")
    parser.add_argument("--yes", action="store_true", help="Подтверждение для --fix.")
    parser.add_argument("--groups", action="store_true",
                        help="Группировать ошибки по таксономии CatalogErrorGroups (Gramax-совместимый вывод).")
    args = parser.parse_args()

    if args.fix and not args.yes:
        print("--fix requires --yes flag for safety", file=sys.stderr)
        sys.exit(2)

    issues = validate(args.path, args.strict, args.fix, args.yes)

    has_errors = any(i.level == "error" for i in issues)
    has_warnings_strict = args.strict and any(i.level == "warning" for i in issues)

    if args.groups:
        _print_groups(issues)
    else:
        for issue in issues:
            print(str(issue))

    if has_errors or has_warnings_strict:
        sys.exit(1)
    sys.exit(0)
```

Insert before `main()` — the `_print_groups` helper and group taxonomy:

```python
# Таксономия CatalogErrorGroups (Gramax-совместимо)
# Не все группы применимы к нам (icons, comments отсутствуют)
_ERROR_GROUPS = {
    "content":       {"title": "incorrects-content",      "pattern": r"^(?:ERROR|WARNING)\s+.*\s+(?:missing|invalid|плейсхолдер|placeholder|фронтматтер|frontmatter)"},
    "links":         {"title": "incorrects-paths",         "pattern": r"битая ссылка|broken link|hash-якорь|W032|W033"},
    "images":        {"title": "incorrects-paths",         "pattern": r"W030|изображени"},
    "diagrams":      {"title": "incorrects-paths",         "pattern": r"W031|диаграмм"},
    "unsupported":   {"title": "incorrects-unsupported",   "pattern": r"W034|неподдержива"},
}

_UNGROUPED = {"title": "other", "pattern": None}


def _classify_issue(issue: Issue) -> str:
    """Классифицирует Issue в группу CatalogErrorGroups."""
    text = str(issue)
    for group, meta in _ERROR_GROUPS.items():
        if re.search(meta["pattern"], text, re.IGNORECASE):
            return group
    return "other"


def _print_groups(issues: list[Issue]):
    """Группированный вывод по CatalogErrorGroups."""
    if not issues:
        print("No issues found.")
        return
    from collections import defaultdict
    grouped: dict[str, list[Issue]] = defaultdict(list)
    for i in issues:
        grouped[_classify_issue(i)].append(i)

    for group in ["content", "links", "images", "diagrams", "unsupported", "other"]:
        items = grouped.get(group, [])
        if not items:
            continue
        meta = _ERROR_GROUPS.get(group, _UNGROUPED)
        print(f"\n[{group}] {meta['title']} ({len(items)}):")
        for i in items:
            print(f"  {i}")
```

- [ ] **Step 3: Wire `check_unsupported_markup` into `validate()`**

Insert before `check_images` call (added in Task 3):

```python
    check_unsupported_markup(root, issues)
```

- [ ] **Step 4: Verify existing tests still pass**

Run: `cd /Users/mdemyanov/Devel/gramax && bash tests/gramax/catalog-validator/run.sh`
Expected: existing tests pass

- [ ] **Step 5: Verify `--groups` output format**

Run: `cd /Users/mdemyanov/Devel/gramax && uv run plugins/gramax/scripts/validate_structure.py tests/gramax/catalog-validator/fixtures/broken-link --groups`
Expected: grouped output with `[links] incorrects-paths (1):` section

- [ ] **Step 6: Commit**

```bash
git add plugins/gramax/scripts/validate_structure.py
git commit -m "feat(validate): unsupported markup (W034) + --groups taxonomy

check_unsupported_markup — обнаружение HTML-тегов в markdown.
--groups флаг — группировка ошибок по CatalogErrorGroups (Gramax-совместимо).
Обратная совместимость без --groups сохранена.

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 6: Test fixtures — gramax-fixtures

**Files:**
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-image/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-image/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-diagram/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-diagram/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-ok/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-ok/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-ok/other.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-broken/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-broken/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-broken/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-broken/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-broken/target.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-ok/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-ok/article.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-ok/target.md`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/unsupported-html/.doc-root.yaml`
- Create: `tests/gramax/catalog-validator/fixtures/gramax-fixtures/unsupported-html/article.md`

- [ ] **Step 1: Create fixture — broken-image**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-image
```

`.doc-root.yaml`:
```yaml
code: broken-image-test
title: Broken image fixture
description: Фикстура для W030 — markdown-изображение на несуществующий файл.
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с битым изображением"
---

![скриншот](./screenshot.png)
```

- [ ] **Step 2: Create fixture — broken-diagram**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/broken-diagram
```

`.doc-root.yaml`:
```yaml
code: broken-diagram-test
title: Broken diagram fixture
description: Фикстура для W031 — drawio-тег на несуществующий файл.
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с битой диаграммой"
---

См. диаграмму:

<drawio path="./architecture.drawio"/>
```

- [ ] **Step 3: Create fixture — link-no-ext-ok (no-ext резолв успешен)**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-ok
```

`.doc-root.yaml`:
```yaml
code: link-no-ext-ok
title: Link no-ext OK fixture
description: Ссылка без .md на существующий файл — no-ext резолв должен сработать.
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья со ссылкой без расширения"
---

См. [другую статью](./other) — other.md существует, no-ext резолв должен найти его.
```

`other.md`:
```markdown
---
order: 2
title: "Другая статья"
---

Контент.
```

- [ ] **Step 4: Create fixture — link-no-ext-broken (no-ext резолв провален)**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-no-ext-broken
```

`.doc-root.yaml`:
```yaml
code: link-no-ext-broken
title: Link no-ext broken fixture
description: Ссылка без .md на несуществующий файл — битая ссылка (error).
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с битой ссылкой без расширения"
---

См. [несуществующую статью](./nonexistent) — ни nonexistent, ни nonexistent.md не существует.
```

- [ ] **Step 5: Create fixture — link-hash-broken (hash-якорь не найден)**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-broken
```

`.doc-root.yaml`:
```yaml
code: link-hash-broken
title: Link hash broken fixture
description: Фикстура для W033 — hash-якорь на несуществующий заголовок.
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с битым якорем"
---

См. [раздел](./target.md#nonexistent-section) — такого заголовка нет в target.md.
```

`target.md`:
```markdown
---
order: 2
title: "Целевая статья"
---

## Existing Section

Контент.
```

- [ ] **Step 6: Create fixture — link-hash-ok (hash-якорь найден)**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/link-hash-ok
```

`.doc-root.yaml`:
```yaml
code: link-hash-ok
title: Link hash OK fixture
description: Фикстура — hash-якорь на существующий заголовок (должен быть OK).
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с рабочим якорем"
---

См. [раздел](./target.md#existing-section) — такой заголовок есть.
```

`target.md`:
```markdown
---
order: 2
title: "Целевая статья"

## Existing Section

Контент.
```

- [ ] **Step 7: Create fixture — unsupported-html**

```bash
mkdir -p tests/gramax/catalog-validator/fixtures/gramax-fixtures/unsupported-html
```

`.doc-root.yaml`:
```yaml
code: unsupported-html-test
title: Unsupported HTML fixture
description: Фикстура для W034 — HTML-теги в markdown.
language: ru
syntax: XML
```

`article.md`:
```markdown
---
order: 1
title: "Статья с HTML"
---

<div class="warning">
Этот блок использует HTML-тег div, который Gramax может не отобразить.
</div>

<iframe src="https://example.com"></iframe>
```

- [ ] **Step 8: Commit**

```bash
git add tests/gramax/catalog-validator/fixtures/gramax-fixtures/
git commit -m "test(validate): gramax-fixtures — 7 тестовых каталогов для healthcheck-проверок

broken-image (W030), broken-diagram (W031), link-no-ext-ok/broken (W032),
link-hash-broken/ok (W033), unsupported-html (W034).

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: AC test scripts (ac-014 — ac-020)

**Files:**
- Create: `tests/gramax/catalog-validator/ac-014-image-broken.sh`
- Create: `tests/gramax/catalog-validator/ac-015-diagram-broken.sh`
- Create: `tests/gramax/catalog-validator/ac-016-link-no-ext.sh`
- Create: `tests/gramax/catalog-validator/ac-017-link-hash.sh`
- Create: `tests/gramax/catalog-validator/ac-018-unsupported-markup.sh`
- Create: `tests/gramax/catalog-validator/ac-019-healthcheck-regression.sh`
- Create: `tests/gramax/catalog-validator/ac-020-groups-output.sh`

- [ ] **Step 1: Write ac-014 — broken image detected (W030)**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-014-image-broken.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — W030
# Проверка: битое изображение ![alt](./missing.png) → W030 warning

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/broken-image"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qiE 'W030|изображени|image'; then
  echo "  FAIL: W030 — вывод должен содержать 'W030' или 'изображени' или 'image'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-014: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-014: битое изображение обнаруживается (W030)"
```

- [ ] **Step 2: Write ac-015 — broken diagram detected (W031)**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-015-diagram-broken.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — W031
# Проверка: битая диаграмма <drawio path="./missing.drawio"/> → W031 warning

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/broken-diagram"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qiE 'W031|диаграмм|diagram'; then
  echo "  FAIL: W031 — вывод должен содержать 'W031' или 'диаграмм' или 'diagram'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-015: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-015: битая диаграмма обнаруживается (W031)"
```

- [ ] **Step 3: Write ac-016 — no-ext link resolution**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-016-link-no-ext.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — no-ext resolution
# Проверка: [link](./other) где other.md существует → OK (no error)
#           [link](./nonexistent) где ничего нет → битая ссылка (error)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# no-ext OK: ссылка без .md на существующий файл
FIXTURE_OK="$SCRIPT_DIR/fixtures/gramax-fixtures/link-no-ext-ok"
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_OK" 2>&1); then
  EXIT_OK=0
else
  EXIT_OK=$?
fi
if [ "$EXIT_OK" -ne 0 ]; then
  echo "  FAIL: no-ext OK — ссылка [other](./other) где other.md существует не должна давать ошибку (exit=$EXIT_OK)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# no-ext broken: ссылка на несуществующий файл
FIXTURE_BROKEN="$SCRIPT_DIR/fixtures/gramax-fixtures/link-no-ext-broken"
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_BROKEN" 2>&1); then
  EXIT_BROKEN=0
else
  EXIT_BROKEN=$?
fi
if [ "$EXIT_BROKEN" -eq 0 ]; then
  echo "  FAIL: no-ext broken — ссылка на несуществующий файл должна давать ошибку" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-016: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-016: no-ext link resolution работает корректно"
```

- [ ] **Step 4: Write ac-017 — hash anchor check (W033)**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-017-link-hash.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — W033
# Проверка: [link](./target.md#nonexistent-section) → W033 warning
#           [link](./target.md#existing-section) → OK (no warning)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# hash broken: несуществующий заголовок
FIXTURE_BROKEN="$SCRIPT_DIR/fixtures/gramax-fixtures/link-hash-broken"
OUT_BROKEN=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_BROKEN" 2>&1) || true

if ! echo "$OUT_BROKEN" | grep -qiE 'W033|hash-якор|hash.*anchor'; then
  echo "  FAIL: W033 — вывод должен содержать 'W033' или 'hash-якорь'" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT_BROKEN" >&2
  FAIL=$((FAIL + 1))
fi

# hash OK: существующий заголовок — не должно быть W033
FIXTURE_OK="$SCRIPT_DIR/fixtures/gramax-fixtures/link-hash-ok"
OUT_OK=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_OK" 2>&1) || true

if echo "$OUT_OK" | grep -qi 'W033'; then
  echo "  FAIL: hash OK — ссылка на существующий заголовок не должна давать W033" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT_OK" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-017: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-017: hash-якоря проверяются корректно (W033)"
```

- [ ] **Step 5: Write ac-018 — unsupported markup detected (W034)**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-018-unsupported-markup.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — W034
# Проверка: <div>, <iframe> в markdown → W034 warning

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/unsupported-html"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qiE 'W034|неподдержива|unsupported'; then
  echo "  FAIL: W034 — вывод должен содержать 'W034' или 'неподдержива' или 'unsupported'" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-018: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-018: неподдерживаемая разметка обнаруживается (W034)"
```

- [ ] **Step 6: Write ac-019 — healthcheck regression (all W030-W034 on dogfood)**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-019-healthcheck-regression.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md
# Проверка: прогон ВСЕХ gramax-fixtures через validate_structure.py,
#           каждый должен выдать ожидаемый код (W030-W034).
# Это регрессионный тест: ловит случай, когда новая правка отключает проверку.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
GFX="$SCRIPT_DIR/fixtures/gramax-fixtures"

declare -A EXPECTED_PATTERNS=(
  ["broken-image"]="W030"
  ["broken-diagram"]="W031"
  ["link-no-ext-broken"]="битая ссылка"
  ["link-hash-broken"]="W033"
  ["unsupported-html"]="W034"
)

for fixture in "${!EXPECTED_PATTERNS[@]}"; do
  pattern="${EXPECTED_PATTERNS[$fixture]}"
  OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$GFX/$fixture" 2>&1) || true
  if ! echo "$OUT" | grep -qiE "$pattern"; then
    echo "  FAIL: fixture '$fixture' — expected pattern '$pattern' not found in output" >&2
    echo "  --- вывод ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
done

# link-no-ext-ok и link-hash-ok должны быть чистыми
for fixture in "link-no-ext-ok" "link-hash-ok"; do
  if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$GFX/$fixture" 2>&1); then
    EXIT=0
  else
    EXIT=$?
  fi
  if [ "$EXIT" -ne 0 ]; then
    echo "  FAIL: fixture '$fixture' должна давать чистый проход (exit 0), получили exit=$EXIT" >&2
    echo "  --- вывод ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-019: $FAIL regression(s) failed"; exit 1; fi
pass_msg "ac-019: все gramax-fixtures выдают ожидаемые коды (W030-W034)"
```

- [ ] **Step 7: Write ac-020 — --groups output format**

```bash
#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-020-groups-output.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — --groups
# Проверка: флаг --groups выводит группированный вывод с заголовками групп

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/broken-image"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" --groups 2>&1) || true

if ! echo "$OUT" | grep -qE '\[images\]'; then
  echo "  FAIL: --groups вывод должен содержать '[images]' заголовок группы" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qE 'incorrects-paths'; then
  echo "  FAIL: --groups вывод должен содержать 'incorrects-paths' (название группы из CatalogErrorGroups)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# Без --groups вывод НЕ должен содержать [images] (плоский формат)
OUT_FLAT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true
if echo "$OUT_FLAT" | grep -qE '^\[images\]'; then
  echo "  FAIL: без --groups вывод не должен содержать '[images]' заголовок (плоский формат по умолчанию)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-020: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-020: --groups вывод работает корректно"
```

- [ ] **Step 8: Make scripts executable**

```bash
chmod +x tests/gramax/catalog-validator/ac-01[4-9]-*.sh tests/gramax/catalog-validator/ac-020-*.sh
```

- [ ] **Step 9: Run all new AC tests**

Run: `cd /Users/mdemyanov/Devel/gramax && bash tests/gramax/catalog-validator/run.sh`
Expected: all 20 AC tests pass (ac-001 through ac-020)

- [ ] **Step 10: Commit**

```bash
git add tests/gramax/catalog-validator/ac-014-*.sh tests/gramax/catalog-validator/ac-015-*.sh tests/gramax/catalog-validator/ac-016-*.sh tests/gramax/catalog-validator/ac-017-*.sh tests/gramax/catalog-validator/ac-018-*.sh tests/gramax/catalog-validator/ac-019-*.sh tests/gramax/catalog-validator/ac-020-*.sh
git commit -m "test(validate): AC-014–AC-020 — тесты healthcheck-проверок

ac-014: W030 broken image
ac-015: W031 broken diagram
ac-016: no-ext link resolution
ac-017: W033 hash anchor
ac-018: W034 unsupported markup
ac-019: regression all gramax-fixtures
ac-020: --groups output format

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: QA — полный прогон + регистрация в CI

**Files:**
- Modify: `scripts/check.sh` (добавить gramax-fixtures suite в `--full`, если ещё нет)
- Modify: `tests/gramax/catalog-validator/README.md` (актуализировать таблицу AC-тестов)

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/mdemyanov/Devel/gramax && bash scripts/check.sh --full
```

Expected: все suite'ы зелёные. Если есть красные — зафиксировать какие, но не чинить (не зона этой задачи).

- [ ] **Step 2: Verify catalog-validator/run.sh picks up new AC tests**

Run: `cd /Users/mdemyanov/Devel/gramax && bash tests/gramax/catalog-validator/run.sh`
Expected: reports "Running 20 AC tests" (было 13, добавили 7)

- [ ] **Step 3: Dogfood — проверить content/ на реальном каталоге**

```bash
cd /Users/mdemyanov/Devel/gramax && uv run plugins/gramax/scripts/validate_structure.py content/
```

Expected: exit 0. Если есть новые WARNING от W030-W034 — зафиксировать, но не править (это реальные находки, требующие отдельных задач).

- [ ] **Step 4: Update catalog-validator README**

Read current README and add rows for ac-014 through ac-020 in the test table.

- [ ] **Step 5: Commit**

```bash
git add tests/gramax/catalog-validator/README.md
git commit -m "docs(validate): актуализация README — новые AC-014–AC-020

Part of: healthcheck-port.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Dependency Graph

```
Task 1 (md_link_parser) ──┬── Task 3 (images/diagrams W030-W031)
                          │
                          ├── Task 4 (advanced links W032-W033)
                          │       └── depends on Task 2 (link_resolver)
                          │
                          └── Task 5 (unsupported W034 + --groups)

Task 6 (fixtures) ── зависит от Tasks 3-5 (нужны рабочие проверки)

Task 7 (AC tests) ── зависит от Tasks 6 (нужны фикстуры)

Task 8 (QA run) ── зависит от Tasks 7 (нужны AC тесты)
```

**Параллельно можно делать:**
- Task 1 + Task 2 (независимые lib-модули)
- Task 3 + Task 4 + Task 5 (после Task 1, независимы друг от друга)

**Последовательно:**
- Task 6 → Task 7 → Task 8
