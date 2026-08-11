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


if __name__ == "__main__":
    unittest.main()
