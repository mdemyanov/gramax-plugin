"""Edge-case tests for validators-parity (ADR-0024, FR-151…FR-157).

Граничные случаи из «Контракт с QA-author» дизайн-документа
(docs/40-architecture/2026-11-18-validators-parity-design.md), которые suite
tests/gramax/catalog-validator/ac-025…ac-036 не покрывает; интеграционный уровень
тот же, что у test_validate_structure.py (ADR-0020 прецедент): вызов валидатора
через `uv run` на минимальном фикстурном каталоге, ассерты по выводу.

Требует `uv` на PATH — валидатор вызывается через `uv run` ради его PEP-723
inline-зависимостей (pyyaml).
"""

import os
import subprocess
import sys
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


class AbsolutePathLeakE037Tests(unittest.TestCase):
    """Правило E037 — целевое значение ADR-0028 Решение 5 с поправкой по ревью без
    автора — раунд r1 (2026-11-25): класс сегмента имени — `\\w` (не-латинские имена
    домашнего каталога), форма WSL `/mnt/<буква>/Users/<имя>/…`, буква диска и буква
    монтирования в сообщении — ФАКТИЧЕСКИЕ (не пришитая `C:`). Имя и сам путь в вывод
    не попадают (FR-072); двойники (`/mnt/…` внутри URL, `$USER`, маскированные формы)
    находки не дают. Интеграционная нога — стаб
    tests/gramax/catalog-validator/ac-181-absolute-path-leak.sh. Имена фиктивные:
    demouser — латиница из [a-z], заповедный — придуманное слово строчной кириллицей
    (не фамилия)."""

    def run_validator_offline(self, target: Path) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["uv", "run", str(SCRIPT), str(target)],
            capture_output=True,
            text=True,
            check=False,
            env={**os.environ, "UV_OFFLINE": "1"},
        )

    def test_wsl_form_reports_with_actual_mount_letter(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, "Отчёт WSL пишется в /mnt/c/Users/demouser/notes/report.md — путь подсистемы.")
            result = self.run_validator_offline(root)
            self.assertIn("E037", result.stdout, f"фон: {result.stdout}")
            self.assertIn("(форма /mnt/c/Users/<имя>/…)", result.stdout,
                          "форма WSL обязана называть фактическую букву монтирования "
                          "(ADR-0028 Решение 5, поправка r1: /mnt/<буква>/Users/<имя>/…)")
            self.assertNotIn("demouser", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("notes/report", result.stdout,
                             "сам путь WSL-формы в вывод не попадает (FR-072)")

    def test_non_ascii_name_in_users_form(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, "Заметки лежат в /Users/заповедный/notes/plan.md и публике им не место.")
            result = self.run_validator_offline(root)
            self.assertIn("E037", result.stdout,
                          "не-ASCII имя домашнего каталога обязано ловиться: класс сегмента "
                          r"\w — буквы и цифры Юникода (ADR-0028 Решение 5, поправка r1)")
            self.assertIn("(форма /Users/<имя>/…)", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("заповедный", result.stdout,
                             "не-ASCII имя не попадает в вывод правила (FR-072)")

    def test_drive_letter_is_actual_in_message(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, r"Локальная копия: D:\Users\demouser\Documents\todo.md — диск D.")
            result = self.run_validator_offline(root)
            self.assertIn("E037", result.stdout, f"фон: {result.stdout}")
            self.assertIn("(форма D:\\Users\\<имя>\\…)", result.stdout,
                          "буква диска в сообщении — фактическая (поправка r1), не пришитая C:")
            self.assertNotIn("(форма C:\\Users", result.stdout,
                             "для диска D форма C: — дефект пришитой буквы (поправка r1)")

    def test_non_ascii_name_in_drive_form(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, r"Локальная копия: X:\Users\заповедный\Documents\todo.md — другая буква диска.")
            result = self.run_validator_offline(root)
            self.assertIn("E037", result.stdout,
                          "не-ASCII имя в форме с буквой диска обязано ловиться (поправка r1)")
            self.assertIn("(форма X:\\Users\\<имя>\\…)", result.stdout, f"фон: {result.stdout}")
            self.assertNotIn("заповедный", result.stdout, f"фон: {result.stdout}")

    def test_line_number_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build_catalog(root, "Заметки лежат в /Users/demouser/notes/plan.md — строка 6 тела файла.")
            result = self.run_validator_offline(root)
            self.assertIn("на строке 6", result.stdout,
                          "фронтматтер 4 строки + пустая — путь на строке 6 файла (дизайн §3.5)")

    def test_clean_lookalikes_stay_quiet(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            body = ("Документация WSL: https://example.com/mnt/c/Users/demouser/notes — путь внутри адреса.\n"
                    "\n"
                    "Домашний каталог в WSL: /mnt/c/Users/$USER/notes — подстановка, не имя.\n"
                    "\n"
                    "Шаблон пути /Users/... — сегмент из одних точек.\n")
            build_catalog(root, body)
            result = self.run_validator_offline(root)
            self.assertNotIn("E037", result.stdout,
                             "WSL-путь внутри URL, $USER и маскированные формы находки не дают "
                             "(ADR-0028 Решение 5, поправка r1; взгляд назад отсекает /mnt/ после домена)")
            self.assertEqual(result.returncode, 0, f"фон: {result.stdout}")


class TolerantScanUtf8Tests(unittest.TestCase):
    """Толерантное чтение в ресурсном парсере (ADR-0028 Решение 1, дизайн волны-4 §3.1):
    `scan_md_resources` на каталоге с файлом-с-битым-UTF-8 возвращает пару
    `(resources, errors)` вместо исключения; файл с битым UTF-8 даёт ровно один
    `MdPageError` (его `source` — этот файл) и ни одного ресурса; обход доводится до
    конца в отсортированном порядке — ресурсы здорового файла, идущего ПОСЛЕ битого,
    на месте (инвариант 1 §3.1). `parse_md_resources` сохраняет совместимость:
    возвращает те же ресурсы.

    Bash-стаб ac-164 этот инвариант доказать не может: оба его ресурса берутся из
    файла, отсортированного ДО битого — `continue`→`break` на его фикстуре невидим.
    Здесь битый файл отсортирован в СЕРЕДИНЕ (a-… < m-… < z-…), поэтому обрыв обхода
    краснит тест. Мутация к красному — `continue`→`break` в scan_md_resources
    (исполнена на scratch-копии plugins/gramax вне дерева, отчёт Dev r2).
    Имена файлов фиктивные (a/m/z + target/img), битые байты синтетические."""

    @classmethod
    def _import_scan(cls):
        """Импорт парсера внутри теста: scripts/ на sys.path относительно файла теста
        (тот же приём, что в lib/test_link_resolver.py) — отсутствие функций даёт
        именованный ассерт-отказ, не ошибку коллекции."""
        if str(Path(__file__).resolve().parent.parent) not in sys.path:
            sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
        try:
            from lib.md_link_parser import parse_md_resources, scan_md_resources
        except ImportError:
            return None, None
        return scan_md_resources, parse_md_resources

    def test_scan_survives_broken_utf8_in_the_middle(self):
        scan_md_resources, parse_md_resources = self._import_scan()
        self.assertIsNotNone(scan_md_resources,
                             "scan_md_resources отсутствует в lib/md_link_parser.py "
                             "(ADR-0028 Решение 1)")
        self.assertIsNotNone(parse_md_resources,
                             "parse_md_resources отсутствует в lib/md_link_parser.py")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "a-healthy.md").write_text(
                "---\norder: 1\ntitle: До\n---\n[цель](./target-a.md)\n", encoding="utf-8"
            )
            # Битый файл: синтетические байты, невалидные как UTF-8, — имя в СЕРЕДИНе
            # сортировки (a-… < m-… < z-…).
            (root / "m-broken.md").write_bytes(
                b"---\norder: 2\ntitle: broken\n---\n\xff\xfe not utf-8\n"
            )
            (root / "z-healthy.md").write_text(
                "---\norder: 3\ntitle: После\n---\n[цель](./target-z.md)\n"
                "![иллюстрация](./img-z.png)\n", encoding="utf-8"
            )
            (root / "target-a.md").write_text("---\norder: 4\ntitle: TA\n---\n\n", encoding="utf-8")
            (root / "target-z.md").write_text("---\norder: 5\ntitle: TZ\n---\n\n", encoding="utf-8")
            (root / "img-z.png").write_bytes(b"\x89PNG\r\n\x1a\n")

            result = scan_md_resources(root)
            self.assertIsInstance(result, tuple,
                                  f"scan_md_resources обязана вернуть пару (resources, errors): "
                                  f"{type(result)}")
            resources, errors = result

            # Ровно одна ошибка чтения — битый файл, и никакой другой.
            self.assertEqual(len(errors), 1,
                             f"файл с битым UTF-8 даёт ровно один MdPageError: {errors}")
            self.assertEqual(errors[0].source.name, "m-broken.md",
                             "source ошибки — файл с битым UTF-8")
            self.assertTrue("a-healthy.md" < errors[0].source.name < "z-healthy.md",
                             "битый файл отсортирован в середине (a- < m- < z-) — "
                             "файл ПОСЛЕ него существует и обязан быть просканирован")
            self.assertEqual(errors[0].error.byte_hex, "ff",
                             "PageReadError несёт первый неверный байт (lib/read_page.py)")

            # Ресурсы ОБОИХ здоровых файлов на месте — особенно файла ПОСЛЕ битого
            # (обход доведён до конца: continue, не break — инвариант 1 §3.1).
            sources = [r.source.name for r in resources]
            self.assertEqual(sources, ["a-healthy.md", "z-healthy.md", "z-healthy.md"],
                             f"порядок обхода отсортированный, ресурсы после битого файла "
                             f"на месте (обрыв обхода здесь краснит): {sources}")
            z_targets = [r.raw_target for r in resources if r.source.name == "z-healthy.md"]
            self.assertEqual(z_targets, ["./target-z.md", "./img-z.png"],
                             "файл ПОСЛЕ битого дал и ссылку, и изображение на существующие цели")

            # Совместимость: parse_md_resources возвращает те же ресурсы.
            self.assertEqual(parse_md_resources(root), resources,
                             "parse_md_resources сохраняет сигнатуру и результат "
                             "(первый элемент пары scan_md_resources, ADR-0028 Решение 1)")


if __name__ == "__main__":
    unittest.main()
