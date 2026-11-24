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
    """Граница префикса `lucide-`, переведённая под ADR-0026 Решение 3 (NFR-084 —
    перевод, не удаление; red on 7553da1 — реестра нет). ADR-0024 Решение 5 и BR-013 —
    superseded в части формы префикса: форм с префиксом `lucide-` движок не знает.

    `xlucide-zap` префиксом НЕ является (не в начале) → кастомный код → W035
    (нет файла .icons/xlucide-zap.svg); `lucide-zap` без файла — тоже W035, с
    подсказкой убрать префикс (stem zap входит в реестр lucide-react)."""

    def test_xlucide_is_custom_lucide_is_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<icon code="xlucide-zap"/>\n\n<icon code="lucide-zap"/>')
            result = run_validator(root)
            self.assertIn("xlucide-zap", result.stdout,
                          "xlucide-zap — кастомный код (префикс не в начале): обязан резолвиться против .icons/")
            self.assertIn("lucide-zap", result.stdout.replace("xlucide-zap", ""),
                          "lucide-zap без файла обязан давать W035: форма префикса движку неизвестна (ADR-0026 Решение 3)")
            lucide_line = next(line for line in result.stdout.splitlines()
                               if "lucide-zap" in line and "xlucide-zap" not in line)
            self.assertIn("префикс", lucide_line,
                          "W035 на lucide-zap обязан нести подсказку убрать префикс (дизайн волны-3 §2.4)")


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
    """Перевод паритетного замка под ADR-0028 Решение 3 (NFR-084 — перевод, не удаление;
    BR-029: контракт меняется через SA-артефакт): диаграммный тег с `path`, записанный
    парным, без самозакрывающего слэша или вовсе без закрывающего `>`, даёт ту же
    находку W031, что самозакрытая форма; атрибут, чьё имя оканчивается на `path`
    (`data-path=`), целью не считается — перед `path` обязан стоять пробельный символ
    (дизайн волны-4 §3.3; интеграционная нога — стаб
    tests/gramax/catalog-validator/ac-167-diagram-tag-without-self-closing.sh).
    Red on 6e2db04: `_diagram_tag_re` требует `/>` — формы без слэша не матчатся,
    ноль находок (слепая зона, закреплённая прежде как намеренная — ADR-0024, следствие
    снято решением 3); `data-path=` сегодня матчится (регэксп допускает любой префикс
    атрибута) и даёт ложный W031."""

    def test_self_closing_with_missing_target_reports_w031(self):
        # Контроль неизменности: прежнее поведение самозакрытой формы сохраняется.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml path="./missing.puml"/>')
            result = run_validator(root)
            self.assertIn("W031", result.stdout, f"фон: {result.stdout}")
            self.assertIn("missing.puml", result.stdout, f"фон: {result.stdout}")

    def test_open_tag_without_slash_reports_w031(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml path="./missing.puml">')
            result = run_validator(root)
            self.assertIn("W031", result.stdout,
                          "открывающий тег с path без самозакрывающего слэша обязан дать W031 "
                          "(ADR-0028 Решение 3; red on 6e2db04 — детектор требует />)")
            self.assertIn("missing.puml", result.stdout,
                          "W031 обязан называть цель из path")

    def test_paired_tag_with_missing_target_reports_w031(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml path="./missing.puml">текст</plant-uml>')
            result = run_validator(root)
            self.assertIn("W031", result.stdout,
                          "парная форма с path и битой целью обязана дать ту же W031, что "
                          "самозакрытая (движок читает атрибуты из открывающего тега — "
                          "tag.pegjs:19-36; red on 6e2db04)")
            self.assertIn("missing.puml", result.stdout, f"фон: {result.stdout}")

    def test_tag_without_closing_gt_reports_w031(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            body = ('<plant-uml path="./missing.puml" width="800px"\n'
                    '\n'
                    'Автор забыл закрыть тег; ближайший `>` дальше по статье — в строке '
                    '<note>совет</note> ниже.')
            build_catalog(root, body)
            result = run_validator(root)
            self.assertIn("W031", result.stdout,
                          "тег с path без закрывающего `>` обязан дать W031 наравне с "
                          "самозакрытой формой (ADR-0028 Решение 3; red on 6e2db04)")
            self.assertIn("missing.puml", result.stdout, f"фон: {result.stdout}")

    def test_paired_tag_with_existing_target_clean(self):
        # Warden (зелёный при рождении): целевая парная форма с существующей целью —
        # ноль находок; фиксирует, что правка детектора не добавляет ложных W031.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml path="./real.puml">текст</plant-uml>')
            (root / "real.puml").write_text("DIAGRAM DSL\n", encoding="utf-8")
            result = run_validator(root)
            self.assertNotIn("W031", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("W034", result.stdout,
                             "plant-uml объявлен в selfClosingTags контракта — W034 молчит")
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")

    def test_data_path_attribute_is_not_a_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, '<plant-uml data-path="./decoy.puml"/>')
            result = run_validator(root)
            self.assertNotIn("decoy.puml", result.stdout,
                             "атрибут, чьё имя оканчивается на path, целью не считается — "
                             "перед path обязан стоять пробельный символ (ADR-0028 Решение 3; "
                             "red on 6e2db04 — старый регэксп матчит data-path)")
            self.assertNotIn("W031", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("W034", result.stdout, f"фон: {result.stdout}")


if __name__ == "__main__":
    unittest.main()
