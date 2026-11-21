"""Smoke tests for validate_render.py — severity-калибровка 2026-11-21 (FR-196).

Калибровочный замер валидатора против факта рендера
(docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md):
note-in-cell и note-in-note понижены ERROR → WARN (факт 200 на цели; апстрим-прецедент
04.09.2026 — 42 вхождения на 19 страницах, все 200); многострочный <colgroup> — новый
детектор ERROR (факт «500 до правки, 200 после»); инлайновый <note> остаётся ERROR
(факт 500); однострочная форма <colgroup> легальна (allowlist gramax-render-rules.json).

Интеграционный уровень тот же, что у test_validate_structure.py /
test_validators_parity.py: вызов валидатора через `uv run` на минимальных
фикстурах, ассерты по выводу и коду выхода. Требует `uv` на PATH.
"""

import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "validate_render.py"

NOTE_IN_CELL = (
    "<table>\n"
    "  <tr>\n"
    "    <td>\n"
    "\n"
    '<note type="info">\n'
    "Заметка внутри ячейки таблицы.\n"
    "</note>\n"
    "\n"
    "    </td>\n"
    "  </tr>\n"
    "</table>\n"
)

NOTE_IN_NOTE = (
    '<note type="warn">\n'
    "Внешняя заметка.\n"
    '<note type="info">\n'
    "Вложенная заметка.\n"
    "</note>\n"
    "</note>\n"
)

COLGROUP_MULTILINE = (
    "<table>\n"
    "  <colgroup>\n"
    '    <col style="width: 30%"/>\n'
    '    <col style="width: 70%"/>\n'
    "  </colgroup>\n"
    "  <tr>\n"
    "    <td>Левая колонка</td>\n"
    "    <td>Правая колонка</td>\n"
    "  </tr>\n"
    "</table>\n"
)

COLGROUP_SINGLE_LINE = (
    "<table>\n"
    '  <colgroup><col style="width: 30%"/><col style="width: 70%"/></colgroup>\n'
    "  <tr>\n"
    "    <td>Левая колонка</td>\n"
    "    <td>Правая колонка</td>\n"
    "  </tr>\n"
    "</table>\n"
)

NOTE_INLINE = "текст с <note type=\"info\">инлайновой заметкой</note> в одной строке\n"


def run_validator(tmp: Path, name: str, body: str) -> subprocess.CompletedProcess:
    path = tmp / name
    path.write_text(body, encoding="utf-8")
    return subprocess.run(
        ["uv", "run", str(SCRIPT), str(path)],
        capture_output=True,
        text=True,
        check=False,
    )


class NoteInCellWarnTests(unittest.TestCase):
    """Калибровка 2026-11-21, решение 1: note-in-cell — WARN, не ERROR (факт 200)."""

    def test_note_in_cell_is_warn_not_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_validator(Path(tmp), "note-in-cell.md", NOTE_IN_CELL)
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")
            self.assertNotIn("  ERROR L", result.stdout, f"фон: {result.stdout}")
            self.assertRegex(result.stdout, r"warn  L5", "note-in-cell обязан дать warn на строке открытия <note>")
            self.assertIn("ширины колонок плывут", result.stdout,
                          "текст WARN — семантика апстрима (RES-009 §2), не «сбой рендера»")
            self.assertNotIn("сбой рендера", result.stdout,
                             "слово «сбой рендера» из ERROR-формулировки изъято калибровкой")


class NoteInNoteWarnTests(unittest.TestCase):
    """Калибровка 2026-11-21, решение 1: note-in-note — WARN, не ERROR (факт 200)."""

    def test_note_in_note_is_warn_not_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_validator(Path(tmp), "note-in-note.md", NOTE_IN_NOTE)
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")
            self.assertNotIn("  ERROR L", result.stdout, f"фон: {result.stdout}")
            self.assertRegex(result.stdout, r"warn  L3", "note-in-note обязан дать warn на строке вложенного <note>")
            self.assertIn("вложенные заметки схлопываются", result.stdout,
                          "текст WARN — семантика апстрима (RES-009 §2)")
            self.assertNotIn("сбой рендера", result.stdout)


class ColgroupMultilineErrorTests(unittest.TestCase):
    """Калибровка 2026-11-21, решение 2: многострочный <colgroup> — новый детектор,
    ERROR (факт «500 до правки, 200 после»); механика апстрима — открывающий тег,
    занимающий строку целиком."""

    def test_multiline_colgroup_is_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_validator(Path(tmp), "colgroup-multiline.md", COLGROUP_MULTILINE)
            self.assertEqual(result.returncode, 1, f"фон: {result.stdout}")
            self.assertRegex(result.stdout, r"ERROR L2", "ERROR на строке открывающего <colgroup>")
            self.assertIn("Схлопните в одну строку", result.stdout)


class ColgroupSingleLineLegalTests(unittest.TestCase):
    """Однострочная форма <colgroup> легальна (allowlist colgroup/col в
    gramax-render-rules.json); новый детектор — по форме строки, не по Presence тега."""

    def test_single_line_colgroup_has_no_findings(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_validator(Path(tmp), "control-colgroup-single-line.md", COLGROUP_SINGLE_LINE)
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")
            self.assertNotIn("  ERROR L", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("  warn  L", result.stdout, f"фон: {result.stdout}")
            self.assertTrue(result.stdout.splitlines()[0].startswith("OK"), f"фон: {result.stdout}")


class NoteInlineErrorTests(unittest.TestCase):
    """Контроль калибровки: инлайновый <note>…</note> в одну строку остаётся ERROR
    (факт 500 на цели — не менялся)."""

    def test_inline_note_is_still_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_validator(Path(tmp), "note-inline.md", NOTE_INLINE)
            self.assertEqual(result.returncode, 1, f"фон: {result.stdout}")
            self.assertRegex(result.stdout, r"ERROR L1", "инлайновый <note> обязан дать ERROR")
            self.assertIn("блочный формат", result.stdout)


if __name__ == "__main__":
    unittest.main()
