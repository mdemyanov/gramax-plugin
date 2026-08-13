"""Smoke tests for validate_structure.py.

Requires `uv` on PATH — the test invokes the validator via `uv run` to
honor its PEP-723 inline dependencies (pyyaml). Install with
`pip install uv` or `brew install uv`.
"""

import subprocess
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "validate_structure.py"
FIXTURES = Path(__file__).parent / "fixtures"

# ADR-0020 (FR-120…FR-123, AC-036…AC-040): новые кейсы валидируют ТЕ ЖЕ фикстуры, что и
# acceptance-suite tests/gramax/catalog-validator/ac-021…ac-024.sh — один набор фикстур на
# два прогона, без дублирования. parents[4] — корень репозитория (tests/scripts/gramax/plugins).
AC_FIXTURES = Path(__file__).resolve().parents[4] / "tests" / "gramax" / "catalog-validator" / "fixtures"


def run_validator(target: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["uv", "run", str(SCRIPT), str(target), *args],
        capture_output=True,
        text=True,
        check=False,
    )


class GoodCatalogTests(unittest.TestCase):
    def test_good_catalog_passes(self):
        result = run_validator(FIXTURES / "good")
        self.assertEqual(result.returncode, 0, f"stdout: {result.stdout}\nstderr: {result.stderr}")
        self.assertEqual(result.stdout.strip(), "", "Good catalog should produce no messages")


class RootIndexTests(unittest.TestCase):
    """AC-009 (content/30-requirements/2026-08-11-validation-contract.md); проверяемое
    требование зафиксировано в content/00-project/adr/0015-root-index-inert.md, Решение 5.

    `fixtures/good/` не несёт корневой `_index.md` и уже проходит чисто
    (`GoodCatalogTests.test_good_catalog_passes`) — негативный контроль «отсутствие»
    уже покрыт, отдельная фикстура для него не заводится (ADR-0015, Решение 5).

    Природа: живой контракт — КРАСНЫЙ на момент создания. `check_no_index_in_root`
    (`validate_structure.py:78-80`) всё ещё вызывается из `validate()` и сегодня
    флагует `_index.md` в корне как error — удаление этой проверки закрывает DEV-001
    (ADR-0012 Решение 1 / ADR-0015 Решение 1). Тест проверяет только код возврата и
    отсутствие issue — не рендер: у Python-валидатора нет доступа к движку Gramax,
    сам факт «контент не отображается» вне его периметра (ADR-0015, Решение 5).
    """

    def test_root_index_present_passes(self):
        result = run_validator(FIXTURES / "root-index")
        self.assertEqual(result.returncode, 0, f"stdout: {result.stdout}")
        self.assertEqual(result.stdout.strip(), "")


class TagMaskingRegressionTests(unittest.TestCase):
    """Регрессия на дефект `check_tags`, найденный догфудингом (ADR-0012 Решение 5): тег,
    упомянутый в прозе как inline-код (`` `<note>` ``), не парная разметка — не должен
    давать ложный `unpaired`. `check_tags` раньше вырезал только ``` fenced-блоки
    собственной ad-hoc регуляркой, не inline-код; почин — переиспользовать `_mask_code`
    (уже используется `check_placeholders`/`check_broken_links`/`check_orphans`).

    Фикстура держит и ложный кандидат (inline-упоминание `<note>`/`<tabs>` без реальной
    разметки), и настоящую сбалансированную пару `<note>...</note>` — вторая часть
    гарантирует, что маскирование не выключило детектирование реальных непарных тегов.
    """

    def test_inline_tag_mention_does_not_trigger_unpaired(self):
        result = run_validator(FIXTURES / "inline-tag-mention")
        self.assertEqual(result.returncode, 0, f"stdout: {result.stdout}\nstderr: {result.stderr}")
        self.assertNotIn("unpaired", result.stdout)


class BadCatalogTests(unittest.TestCase):
    def setUp(self):
        self.result = run_validator(FIXTURES / "bad")

    def test_exits_nonzero(self):
        self.assertNotEqual(self.result.returncode, 0)

    def test_v1_orphan_section(self):
        self.assertIn("orphan-section", self.result.stdout)
        self.assertIn("missing _index.md", self.result.stdout)

    def test_v3_flat_notation(self):
        self.assertIn("flat-notation.md", self.result.stdout)
        self.assertIn("плоская нотация", self.result.stdout)

    def test_v4_invalid_property(self):
        self.assertIn("invalid-property.md", self.result.stdout)
        self.assertIn("не объявлен", self.result.stdout)

    def test_v5_invalid_value(self):
        self.assertIn("invalid-value.md", self.result.stdout)
        self.assertIn("не входит", self.result.stdout)

    def test_v2_index_with_properties(self):
        self.assertIn("index-with-properties/_index.md", self.result.stdout)
        self.assertIn("не должен содержать properties", self.result.stdout)


class NestedDocRootDiscoveryTests(unittest.TestCase):
    """ADR-0020 / FR-120 (AC-036): рекурсивное обнаружение вложенных .doc-root.yaml.
    Регресс-якорь инцидента 2026-08-13 — до FR-120 фикстура даёт exit 0."""

    def test_nested_doc_root_discovered(self):
        result = run_validator(AC_FIXTURES / "nested-doc-root-discovery")
        self.assertNotEqual(result.returncode, 0, f"stdout: {result.stdout}\nstderr: {result.stderr}")
        self.assertIn("examples/project-example/content/.doc-root.yaml", result.stdout)


class NestedDocRootDemarcationTests(unittest.TestCase):
    """ADR-0020 / FR-120 граница ownership (AC-039): вложенный root валидируется как
    отдельный root, его статьи не orphan-ы внешнего, дефект — ровно одна находка."""

    def test_nested_root_validated_and_single_finding(self):
        result = run_validator(AC_FIXTURES / "nested-doc-root-demarcation")
        self.assertNotEqual(result.returncode, 0, f"stdout: {result.stdout}\nstderr: {result.stderr}")
        self.assertEqual(result.stdout.count('invalid type for field "title"'), 1,
                         "дефект вложенного .doc-root.yaml обязан давать ровно одну находку (BR-004)")

    def test_nested_articles_not_orphans_of_outer(self):
        result = run_validator(AC_FIXTURES / "nested-doc-root-demarcation")
        # inner.md связана ссылкой внутри вложенного root — не сирота внешнего
        self.assertIn("outer-orphan.md", result.stdout, "orphan-проверка внешнего каталога обязана работать")
        self.assertNotIn("inner.md", result.stdout,
                         "статья вложенного root не должна считаться сиротой внешнего каталога")


class DocRootTitleTypeTests(unittest.TestCase):
    """ADR-0020 / FR-121 (AC-037): значение обязательного поля обязано быть непустой строкой;
    dict/list/bool/int/float/date/null/пустая строка → error с фактическим типом."""

    CASES = {
        "float": "got float",
        "bool": "got bool",
        "null": "got null",
        "dict": "got dict",
    }

    def test_non_string_title_errors_with_type(self):
        for name, expected_type in self.CASES.items():
            with self.subTest(name=name):
                result = run_validator(AC_FIXTURES / "doc-root-title-type" / name)
                self.assertNotEqual(result.returncode, 0, f"stdout: {result.stdout}")
                self.assertIn(expected_type, result.stdout,
                              f"title в фикстуре {name} обязан давать error с фактическим типом")

    def test_quoted_title_passes(self):
        result = run_validator(AC_FIXTURES / "doc-root-title-type" / "quoted")
        self.assertEqual(result.returncode, 0, f"stdout: {result.stdout}\nstderr: {result.stderr}")
        self.assertEqual(result.stdout.strip(), "", "закавыченный title: \"4.21\" должен проходить чисто")


class DocRootParseErrorTests(unittest.TestCase):
    """ADR-0020 / FR-122 + FR-123 (AC-038): невалидный YAML не глушит диагностику;
    сообщение несёт номер строки, слово о плейсхолдере и подсказку закавычивания."""

    def test_unquoted_placeholder_diagnostics(self):
        result = run_validator(AC_FIXTURES / "doc-root-parse-error")
        self.assertNotEqual(result.returncode, 0, f"stdout: {result.stdout}")
        self.assertRegex(result.stdout, r"строк[а-я]* \d+",
                         "сообщение обязано содержать номер строки (FR-122)")
        self.assertRegex(result.stdout, r"плейсхолдер|placeholder",
                         "сообщение обязано упоминать плейсхолдер как причину (FR-123)")
        self.assertIn('title: "{{PROJECT_NAME}}"', result.stdout,
                      "сообщение обязано предлагать закавычивание (FR-123)")
        self.assertNotIn("плейсхолдер шаблона {{PROJECT_NAME}} не заменён", result.stdout,
                         "parse-error-находка с подсказкой поглощает placeholder того же токена (BR-004)")


if __name__ == "__main__":
    unittest.main()
