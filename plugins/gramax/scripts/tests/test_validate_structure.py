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
