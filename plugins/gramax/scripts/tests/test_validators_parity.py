"""Edge-case tests for validators-parity (ADR-0024, FR-151…FR-157).

Граничные случаи из «Контракт с QA-author» дизайн-документа
(docs/40-architecture/2026-11-18-validators-parity-design.md), которые suite
tests/gramax/catalog-validator/ac-025…ac-036 не покрывает; интеграционный уровень
тот же, что у test_validate_structure.py (ADR-0020 прецедент): вызов валидатора
через `uv run` на минимальном фикстурном каталоге, ассерты по выводу.

Требует `uv` на PATH — валидатор вызывается через `uv run` ради его PEP-723
inline-зависимостей (pyyaml).
"""

import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "validate_structure.py"

DOC_ROOT_YAML = (
    "code: edge\n"
    'title: "Граничный случай"\n'
    'description: "Фикстура edge-case"\n'
    "language: ru\n"
    "syntax: XML\n"
)


def build_catalog(root: Path, article_body: str, name: str = "article"):
    """Мини-каталог по паттерну дизайн-документа: .doc-root.yaml (непустые строки),
    _index.md со входящей ссылкой (гасит шум сироты), статья с тегом под тестом."""
    root.mkdir(parents=True, exist_ok=True)
    (root / ".doc-root.yaml").write_text(DOC_ROOT_YAML, encoding="utf-8")
    (root / "_index.md").write_text(
        "---\norder: 1\ntitle: Индекс\n---\n\n[статья](article.md)\n", encoding="utf-8"
    )
    (root / f"{name}.md").write_text(
        f"---\norder: 1\ntitle: Статья\n---\n\n{article_body}\n", encoding="utf-8"
    )


def run_validator(target: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["uv", "run", str(SCRIPT), str(target), *args],
        capture_output=True,
        text=True,
        check=False,
    )


class NestedDocRootOwnIconsTests(unittest.TestCase):
    """ADR-0020: иконка статьи вложенного doc-root резолвится против `.icons/`
    СВОЕГО root, не внешнего (дизайн FR-153; edge case «вложенный doc-root со своим
    .icons/»). Различение: `.icons/` есть ТОЛЬКО у вложенного root; коды иконок
    живут ТОЛЬКО в статье вложенного root. Присутствующий код находки не даёт
    (резолв против своего root; и против внешнего тоже не должен — статьи вложенного
    root вообще вне обхода внешнего, FR-120), отсутствующий — даёт W035."""

    def test_inner_icon_resolves_against_inner_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            outer = Path(tmp)
            build_catalog(outer, "Внешняя статья без иконок.")
            inner = outer / "inner"
            build_catalog(inner, '<icon code="inner-present"/>\n\n<icon code="inner-missing"/>')
            icons = inner / ".icons"
            icons.mkdir()
            (icons / "inner-present.svg").write_text(
                '<svg xmlns="http://www.w3.org/2000/svg"/>', encoding="utf-8"
            )
            result = run_validator(outer)
            self.assertIn("inner-missing", result.stdout,
                          "отсутствующая иконка внутреннего root обязана дать W035")
            self.assertNotIn("inner-present", result.stdout,
                             "иконка резолвится против .icons/ СВОЕГО root — находки быть не должно")
            self.assertNotIn("W030", result.stdout, f"фон: {result.stdout}")


class XlucidePrefixBoundaryTests(unittest.TestCase):
    """Граница префикса `lucide-` (BR-013, Решение 5 ADR-0024): `xlucide-zap` префиксом
    НЕ является (не в начале) → кастомный код → резолв против .icons/xlucide-zap.svg;
    `lucide-zap` — библиотечный, против .icons/ не резолвится."""

    def test_xlucide_is_custom_lucide_is_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<icon code="xlucide-zap"/>\n\n<icon code="lucide-zap"/>')
            result = run_validator(root)
            self.assertIn("xlucide-zap", result.stdout,
                          "xlucide-zap — кастомный код (префикс не в начале): обязан резолвиться против .icons/")
            self.assertNotIn("lucide-zap\n", result.stdout.replace("xlucide-zap", ""),
                             "lucide-zap не резолвится против .icons/ — упоминаний быть не должно")


class BareSelfClosingW034Tests(unittest.TestCase):
    """Расширение матчера (FR-157, проба SA): голая self-closing-форма без атрибутов
    вида <br/> — прежде невидимая слепая зона — теперь генуинно неподдерживаемая
    разметка, W034 warning (расширение, не регрессия)."""

    def test_bare_self_closing_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, "текст с переносом <br/> внутри")
            result = run_validator(root)
            self.assertRegex(result.stdout, r"W034.*<br>",
                             "голый self-closing <br/> обязан получать W034 (расширение матчера /?-веткой)")


class DiagramPathWithoutSelfClosingTests(unittest.TestCase):
    """Унаследованная слепая зона (документирована дизайн-документом, паритет семантики
    drawio, не дефект этого изменения): диаграммный тег с `path`, записанный БЕЗ
    self-closing слэша, не матчится парсером (нет W031) и не репортится W034
    (тег известен контракту) — ноль находок."""

    def test_no_findings_for_path_without_slash(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml path="./missing.puml">')
            result = run_validator(root)
            self.assertNotIn("missing.puml", result.stdout,
                             "тег с path без /> — парсер не матчится: ноль находок (унаследованная слепая зона)")
            self.assertNotIn("W031", result.stdout)
            self.assertNotIn("W034", result.stdout,
                             "plant-uml объявлен в selfClosingTags контракта — W034 молчит")
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")


if __name__ == "__main__":
    unittest.main()
