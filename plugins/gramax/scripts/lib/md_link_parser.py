"""Парсинг markdown-ресурсов: ссылки, изображения, диаграммные теги.

Извлекает из .md-файлов каталога все ресурсные ссылки в унифицированном виде,
пригодном для downstream-проверок (broken links, images, diagrams).
Код-блоки (fenced + inline) маскируются перед парсингом — документация,
показывающая синтаксис, не даёт ложных срабатываний. Маска одна — общий примитив
`lib/md_code_mask.py`, собственной копии у парсера нет (ADR-0028 Решение 1).

Чтение страниц — только через `lib/read_page.py` (ADR-0028 Решение 1, круг читателей
ADR-0026 Решение 6): файл, не являющийся валидным UTF-8, не роняет скан исключением —
он даёт один `MdPageError` и ни одного ресурса, остальные файлы сканируются в
отсортированном порядке. `scan_md_resources` возвращает пару
`(resources, errors)`; `parse_md_resources` сохраняет прежнюю сигнатуру и тип
результата (первый элемент пары) как обратная совместимость.
"""

import re
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

from lib.md_code_mask import _mask_code
from lib.read_page import PageReadError, read_page

_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
_EXTERNAL_RE = re.compile(r"^(?:[a-z][a-z0-9+.\-]*:|//)", re.IGNORECASE)

# Деградационный fallback для standalone-вызова без контракта (ADR-0012, Consequences):
# повреждённый контракт уже дал error через load_json_contract, молчаливый ноль
# диаграммных проверок не добавляется.
_DEFAULT_DIAGRAM_TAGS: tuple[str, ...] = ("drawio",)


def _diagram_tag_re(diagram_tags: tuple[str, ...]) -> re.Pattern[str]:
    """Матчер диаграммных тегов с file-based целью: ``<tag path="..."/>``.

    Строится из списка тегов контракта `gramax-tags.json` (ключ `diagramTags`,
    ADR-0024 Решение 3): новый диаграммный тег = строка JSON, ноль правок кода.
    Самозакрытие не требуется (ADR-0028 Решение 3: движок читает атрибуты из
    открывающего тега в обеих формах — tag.pegjs:19-36 на пине 48592b36): парная
    форма (`<plant-uml path="…">…</plant-uml>`) и форма без закрывающего `>` дают
    ту же находку, что самозакрытая. Атрибут, чьё имя оканчивается на `path`
    (`data-path=`), целью не считается — перед `path` обязан стоять пробельный
    символ. Группа 1 — имя тега, группа 2 — цель."""
    names = "|".join(re.escape(t) for t in diagram_tags)
    return re.compile(rf"<({names})(?:\s[^>]*?)?\s+path=\"([^\"]+)\"[^>]*>")


@dataclass
class MdResource:
    """Одна ресурсная ссылка в markdown-статье."""
    source: Path          # файл, где найдена ссылка
    raw_target: str        # текст внутри скобок / кавычек, как в файле
    resolved_path: Path     # цель, резолвленная относительно source.parent
    target_type: str        # "link" | "image" | имя диаграммного тега ("drawio" | "mermaid" | "plant-uml" | "bpmn")
    in_scope: bool          # False — цель за пределами root


@dataclass(frozen=True)
class MdPageError:
    """Файл каталога, который не прочитался (ADR-0028 Решение 1).

    Файл, не являющийся валидным UTF-8, даёт ровно один `MdPageError` и ни одного
    ресурса; формулировка для находки — `utf8_message(err.error)` из `lib.read_page`."""
    source: Path            # файл, который не прочитался
    error: PageReadError    # первый неверный байт, позиция, размер — lib/read_page.py


def _collect_md_files(root: Path, exclude: Callable[[Path], bool] | None = None) -> list[Path]:
    """Отсортированный список .md-файлов под `root` вне `.gramax` и вне `exclude`.

    `exclude` — предикат вызывающей стороны (например, границы ownership валидатора,
    FR-120), добавляется к встроенному исключению `.gramax` (ADR-0028 Решение 1)."""

    def _excluded(p: Path) -> bool:
        return ".gramax" in p.parts or (exclude is not None and exclude(p))

    return sorted(p for p in root.rglob("*.md") if not _excluded(p))


def scan_md_resources(root: Path,
                      diagram_tags: tuple[str, ...] = _DEFAULT_DIAGRAM_TAGS,
                      *,
                      exclude: Callable[[Path], bool] | None = None,
                      ) -> tuple[list[MdResource], list[MdPageError]]:
    """Собирает ресурсные ссылки из markdown-файлов каталога без падения на битом UTF-8.

    Возвращает пару: унифицированный список MdResource (markdown-ссылки [text](target),
    изображения ![alt](target), диаграммные теги <tag path="target"/> — список тегов
    задаёт `diagram_tags` (контракт `gramax-tags.json`, ключ `diagramTags`);
    `target_type` ресурса — имя тега) и список MdPageError (по одному на файл,
    который не прочитался). Внешние ссылки (http/https/mailto) пропускаются.
    Cross-каталожные ссылки помечаются in_scope=False. Файлы сканируются в
    отсортированном порядке; файл с битым UTF-8 обрыв скана не составляет (ADR-0028
    Решение 1, инвариант 1)."""
    root_resolved = root.resolve()
    resources: list[MdResource] = []
    errors: list[MdPageError] = []
    diagram_re = _diagram_tag_re(diagram_tags)

    for md in _collect_md_files(root, exclude):
        text, read_err = read_page(md)
        if read_err is not None or text is None:
            errors.append(MdPageError(md, read_err))
            continue
        text = _mask_code(text)

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

        # Diagram tags: <tag path="..."/> (и парная форма / без закрывающего `>` —
        # ADR-0028 Решение 3) — drawio/mermaid/plant-uml/bpmn (контракт)
        for m in diagram_re.finditer(text):
            raw = m.group(2)
            resolved = (md.parent / raw).resolve()
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            resources.append(MdResource(md, raw, resolved, m.group(1), in_scope))

    return resources, errors


def parse_md_resources(root: Path,
                       diagram_tags: tuple[str, ...] = _DEFAULT_DIAGRAM_TAGS,
                       *,
                       exclude: Callable[[Path], bool] | None = None) -> list[MdResource]:
    """Собирает все ресурсные ссылки из markdown-файлов каталога (совместимость).

    Сохраняет прежнюю сигнатуру и тип результата: возвращает первый элемент пары
    `scan_md_resources` (ADR-0028 Решение 1). Ошибки чтения (битый UTF-8) в этом
    результате не видны — для них используйте `scan_md_resources` напрямую."""
    resources, _errors = scan_md_resources(root, diagram_tags, exclude=exclude)
    return resources
