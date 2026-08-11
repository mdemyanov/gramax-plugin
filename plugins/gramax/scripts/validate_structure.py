#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml>=6.0"]
# ///
"""Валидация структуры каталога Gramax (pre-publish staging-check).

Контракт тегов и правил каталога — не хардкод здесь, а два JSON-файла рядом со скриптом
(`plugins/gramax/gramax-tags.json`, `plugins/gramax/gramax-catalog-rules.json`), единственный
источник правды (ADR-0012 «Контракт валидации Gramax-каталога», Решение 3, BR-002). Повреждённый
или отсутствующий контракт — error, не молчаливый fallback (ADR-0012, Consequences).
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

DOC_URL = "https://github.com/mdemyanov/gramax-plugin"
EPILOG = (
    "Документация: plugins/gramax/README.md (раздел «Валидация каталога»), "
    f"plugins/gramax/skills/writer/SKILL.md. Репозиторий: {DOC_URL}"
)


class Issue:
    __slots__ = ("level", "path", "message")

    def __init__(self, level: str, path: Path, message: str):
        self.level = level  # "error" or "warning"
        self.path = path
        self.message = message

    def __str__(self):
        return f"{self.level.upper()}  {self.path}  {self.message}"


# ===== Машиночитаемый контракт (ADR-0012, Решение 3) =================================

def load_json_contract(path: Path, issues: list[Issue]) -> dict | None:
    """Читает JSON-контракт; None + error-Issue при отсутствии/повреждении файла.

    Не проглатывает молча (ADR-0012, Consequences): вызывающий код обязан трактовать
    None как «контракт недоступен», а не как «пустой контракт по умолчанию» — downstream
    проверки, зависящие от контракта, останутся no-op, но факт отказа уже зафиксирован
    error-уровня Issue выше по списку.
    """
    if not path.exists():
        issues.append(Issue("error", path, "contract file not found"))
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        issues.append(Issue("error", path, f"invalid contract JSON: {e}"))
        return None
    if not isinstance(data, dict):
        issues.append(Issue("error", path, "contract JSON top-level must be an object"))
        return None
    return data


def check_doc_root(root: Path, issues: list[Issue], required_fields: list[str]) -> bool:
    yaml_file = root / ".doc-root.yaml"
    if not yaml_file.exists():
        issues.append(Issue("error", root, ".doc-root.yaml not found"))
        return False
    try:
        data = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        issues.append(Issue("error", yaml_file, f"invalid yaml: {e}"))
        return False
    for field in required_fields:
        if not isinstance(data, dict) or field not in data:
            issues.append(Issue("error", yaml_file, f"missing field: {field}"))
    return True


def load_property_schema(root: Path) -> dict[str, dict] | None:
    """Возвращает {property_name: {type, values}} из .doc-root.yaml.

    None — если schema нечитабельна или содержит экспериментальный type: select.
    """
    yaml_file = root / ".doc-root.yaml"
    try:
        data = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
    except yaml.YAMLError:
        return None
    if not isinstance(data, dict):
        return None
    props = data.get("properties", [])
    if not isinstance(props, list):
        return None
    schema: dict[str, dict] = {}
    for p in props:
        if not isinstance(p, dict) or not p.get("name"):
            continue
        # detect experimental type: select with values: [{name: X}]
        values = p.get("values", [])
        if any(isinstance(v, dict) for v in values):
            return None
        schema[p["name"]] = {
            "type": p.get("type", "String"),
            "values": [str(v) for v in values],
        }
    return schema


def check_subfolders_have_index(root: Path, issues: list[Issue]):
    """Каждая подпапка с .md или вложенными папками обязана иметь _index.md
    (`indexPolicy.subfolder: required`, gramax-catalog-rules.json). Корень каталога в этот
    обход не входит (`subdir == root` исключён) — там `_index.md` `optional`
    (ADR-0012 Решение 1, ADR-0015)."""
    for subdir in root.rglob("*"):
        if not subdir.is_dir():
            continue
        if ".gramax" in subdir.parts:
            continue
        if subdir == root:
            continue
        # has any .md file or any subdirectory inside
        has_content = any(
            child.is_dir() or (child.is_file() and child.suffix == ".md")
            for child in subdir.iterdir()
            if child.name != "_index.md"
        )
        if not has_content:
            continue
        if not (subdir / "_index.md").exists():
            issues.append(Issue("error", subdir, "missing _index.md (Gramax не покажет раздел в навигации)"))


def extract_frontmatter(text: str) -> dict | None:
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    try:
        return yaml.safe_load(text[3:end])
    except yaml.YAMLError:
        return None


def check_frontmatter(md_file: Path, issues: list[Issue], schema: dict | None, required_fields: list[str]):
    text = md_file.read_text(encoding="utf-8")
    fm = extract_frontmatter(text)
    if fm is None:
        issues.append(Issue("error", md_file, "missing or invalid frontmatter"))
        return
    for field in required_fields:
        if field not in fm:
            issues.append(Issue("error", md_file, f"frontmatter missing field: {field}"))
    if md_file.name == "_index.md" and fm.get("properties"):
        issues.append(Issue("error", md_file, "_index.md не должен содержать properties:"))

    # V3: плоская нотация — предупреждение
    if md_file.name != "_index.md" and "properties" in fm:
        props = fm["properties"]
        if isinstance(props, list):
            for entry in props:
                if isinstance(entry, dict) and "name" not in entry:
                    issues.append(
                        Issue("warning", md_file,
                              "устаревшая плоская нотация properties; см. SKILL.md → Frontmatter")
                    )
                    break

    # V4, V5: properties соответствуют schema
    if md_file.name != "_index.md" and schema is not None and "properties" in fm:
        props = fm["properties"]
        if isinstance(props, list):
            for entry in props:
                if not isinstance(entry, dict) or "name" not in entry:
                    continue  # plain notation already reported by V3
                pname = entry["name"]
                if pname not in schema:
                    issues.append(
                        Issue("error", md_file,
                              f'property "{pname}" не объявлен в .doc-root.yaml')
                    )
                    continue
                schema_def = schema[pname]
                if schema_def["type"] != "Enum":
                    continue
                allowed = schema_def["values"]
                values = entry.get("value", [])
                if not isinstance(values, list):
                    values = [values]
                for v in values:
                    if str(v) not in allowed:
                        issues.append(
                            Issue("error", md_file,
                                  f'property "{pname}" имеет значение "{v}", '
                                  f'не входит в [{", ".join(allowed)}]')
                        )


def check_tags(md_file: Path, issues: list[Issue], paired_tags: list[str]):
    text = md_file.read_text(encoding="utf-8")
    # Маскируем код (fenced-блоки И inline `код`) через _mask_code — статья, упоминающая
    # Gramax-тег словами в прозе (например, `` `<note>` `` как имя тега, не как разметку),
    # не должна давать ложный unpaired (найдено догфудингом на ADR-0012 и требовании
    # 2026-08-11-writer-consumer-rules.md — inline-код там не вырезался прежней ad-hoc
    # регуляркой, которая знала только про ``` fences).
    cleaned = _mask_code(text)
    for tag in paired_tags:
        opens = len(re.findall(rf"<{tag}(\s[^>]*)?(?<!/)>", cleaned))
        closes = len(re.findall(rf"</{tag}>", cleaned))
        if opens != closes:
            issues.append(Issue("error", md_file, f"unpaired <{tag}>: {opens} open, {closes} close"))
    # Block comment [comment:id]...[/comment]
    bc_open = len(re.findall(r"\[comment:[a-zA-Z0-9]{5}\]", cleaned))
    bc_close = len(re.findall(r"\[/comment\]", cleaned))
    if bc_open != bc_close:
        issues.append(Issue("error", md_file, f"unpaired [comment:id]: {bc_open} open, {bc_close} close"))


def check_garbage(root: Path, issues: list[Issue], strict: bool, fix: bool, yes: bool, garbage_files: set[str]) -> list[Path]:
    removed = []
    for path in root.rglob("*"):
        if path.name in garbage_files:
            level = "error" if strict else "warning"
            issues.append(Issue(level, path, f"garbage file: {path.name}"))
            if fix and yes:
                path.unlink()
                removed.append(path)
    return removed


def check_no_drawio(root: Path, issues: list[Issue], strict: bool):
    for path in root.rglob("*.drawio"):
        level = "error" if strict else "warning"
        issues.append(Issue(level, path, ".drawio file should be converted to .svg"))


# ===== Плейсхолдеры / сироты / битые ссылки (FR-046…FR-048, ADR-0012 Решение 2) =======

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")
_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
_EXTERNAL_RE = re.compile(r"^(?:[a-z][a-z0-9+.\-]*:|//)", re.IGNORECASE)
_PLACEHOLDER_RE = re.compile(r"\{\{[^{}\n]+\}\}")


def _mask_code(text: str) -> str:
    """Заменяет код (fenced-блоки и inline) пробелами той же длины, сохраняя смещения строк.

    Статья, документирующая Gramax-синтаксис, может показывать `[пример](ссылка.md)` или
    `{{ИМЯ}}` как иллюстрацию, а не как реальную ссылку/протёкший плейсхолдер. Без маски
    orphan-/broken-link-/placeholder-проверки давали бы ложные срабатывания на таких примерах.
    """
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


@dataclass
class LinkRef:
    source: Path      # файл, где найдена ссылка
    raw_target: str    # текст внутри скобок, как в файле (до fragment/<>-очистки)
    resolved: Path      # цель, резолвленная относительно source.parent
    in_scope: bool      # False — цель за пределами root (cross-каталожная), FR-047 граница


def _collect_links(root: Path) -> list[LinkRef]:
    """Собирает markdown-ссылки/изображения (`[текст](цель)`, `![alt](цель)`) из всех .md
    каталога.

    Границы (FR-047, разделяемые orphan- и broken-link-проверками):
    - внешние (http/https/mailto/tel/protocol-relative) и якорные (`#foo`) цели не
      резолвятся вовсе — не .md-путь внутри каталога;
    - цель, резолвящаяся ЗА пределами `root` (cross-каталожная ссылка на соседний
      `.doc-root.yaml`-каталог), помечается `in_scope=False`: ни orphan-, ни
      broken-link-проверка её не использует — не резолвится, не создаёт ложных находок
      (AC-014).
    """
    root_resolved = root.resolve()
    refs: list[LinkRef] = []
    for md in _collect_md_files(root):
        text = _mask_code(md.read_text(encoding="utf-8"))
        for m in _MD_LINK_RE.finditer(text):
            raw = m.group(1)
            target = raw.split("#", 1)[0].strip()
            target = target.strip("<>")
            if not target:
                continue  # якорь на текущую страницу — не файловая ссылка
            if _EXTERNAL_RE.match(target):
                continue  # http/https/mailto/tel/protocol-relative — офлайн-инструмент их не резолвит
            resolved = (md.parent / target).resolve()
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            refs.append(LinkRef(md, raw, resolved, in_scope))
    return refs


def check_placeholders(root: Path, issues: list[Issue]):
    """FR-046: плейсхолдер шаблона `{{ИМЯ}}`, доехавший до наполненного каталога — error
    безусловно (ADR-0012 Решение 2). Сканирует `.doc-root.yaml` целиком и текст каждой
    статьи (код-блоки замаскированы — пример синтаксиса в документации не считается
    протёкшим плейсхолдером)."""
    yaml_file = root / ".doc-root.yaml"
    if yaml_file.exists():
        for m in _PLACEHOLDER_RE.finditer(yaml_file.read_text(encoding="utf-8")):
            issues.append(Issue("error", yaml_file,
                                 f"плейсхолдер шаблона {m.group(0)} не заменён (placeholder)"))
    for md in _collect_md_files(root):
        masked = _mask_code(md.read_text(encoding="utf-8"))
        for m in _PLACEHOLDER_RE.finditer(masked):
            issues.append(Issue("error", md,
                                 f"плейсхолдер шаблона {m.group(0)} не заменён (placeholder)"))


def check_broken_links(root: Path, issues: list[Issue]):
    """FR-048: markdown-ссылка на несуществующий файл внутри того же `.doc-root.yaml`-
    каталога — error безусловно (ADR-0012 Решение 2). Cross-каталожные ссылки не
    резолвятся вовсе (`in_scope=False`) — граница общая с check_orphans (FR-047)."""
    for ref in _collect_links(root):
        if not ref.in_scope:
            continue
        if not ref.resolved.exists():
            issues.append(Issue(
                "error", ref.source,
                f'битая ссылка (broken link) на "{ref.raw_target}" — файл не найден: {ref.resolved}',
            ))


def check_orphans(root: Path, issues: list[Issue], strict: bool):
    """FR-047: статья без входящих markdown-ссылок внутри каталога — warning по умолчанию,
    error под `--strict` (ADR-0012 Решение 2, тот же переключатель, что check_garbage/
    check_no_drawio).

    Семантика — эквивалент C10 (`scripts/validate-content.py::check_orphans`, территория
    nauta, не трогаем, только читаем как образец): каждая `.md`, кроме `_index.md`, с
    нулевой входящей степенью — сирота, без исключений по числу соседей в директории.
    `_index.md` никогда не считается сиротой — титул раздела, не самостоятельная статья
    (та же оговорка, что в C10). Self-ссылка не засчитывается как входящая, но и не
    отнимается — инициализация нулём на файл, не декремент (симметрично C10).

    Cross-каталожные ссылки (FR-047 граница, `_collect_links` → `in_scope=False`) не
    засчитываются как входящие — AC-014.
    """
    level = "error" if strict else "warning"
    incoming: dict[Path, int] = {}
    display: dict[Path, Path] = {}
    for md in _collect_md_files(root):
        if md.name == "_index.md":
            continue
        key = md.resolve()
        incoming[key] = 0
        display[key] = md

    for ref in _collect_links(root):
        if not ref.in_scope:
            continue
        if ref.resolved == ref.source.resolve():
            continue  # самоссылка не считается входящей
        if ref.resolved in incoming:
            incoming[ref.resolved] += 1

    for key, count in incoming.items():
        if count == 0:
            issues.append(Issue(
                level, display[key],
                "статья-сирота: нет входящих markdown-ссылок внутри каталога (FR-047)",
            ))


def validate(root: Path, strict: bool, fix: bool, yes: bool) -> list[Issue]:
    issues: list[Issue] = []

    plugin_root = Path(__file__).resolve().parent.parent
    tags_contract = load_json_contract(plugin_root / "gramax-tags.json", issues)
    rules_contract = load_json_contract(plugin_root / "gramax-catalog-rules.json", issues)
    paired_tags = (tags_contract or {}).get("pairedTags", [])
    garbage_files = set((rules_contract or {}).get("garbageFiles", []))
    doc_root_required = (rules_contract or {}).get("docRootRequiredFields", [])
    frontmatter_required = (rules_contract or {}).get("frontmatterRequiredFields", [])

    if not root.is_dir():
        issues.append(Issue("error", root, "not a directory"))
        return issues
    if not check_doc_root(root, issues, doc_root_required):
        return issues
    check_subfolders_have_index(root, issues)
    schema = load_property_schema(root)
    if schema is None:
        issues.append(Issue("warning", root / ".doc-root.yaml",
                            "schema использует экспериментальный формат values; V4/V5 пропущены"))
    for md in root.rglob("*.md"):
        if ".gramax" in md.parts:
            continue
        check_frontmatter(md, issues, schema, frontmatter_required)
        check_tags(md, issues, paired_tags)
    check_garbage(root, issues, strict, fix, yes, garbage_files)
    check_no_drawio(root, issues, strict)
    check_placeholders(root, issues)
    check_broken_links(root, issues)
    check_orphans(root, issues, strict)
    return issues


def main():
    parser = argparse.ArgumentParser(
        description="Валидация структуры каталога Gramax.",
        epilog=EPILOG,
    )
    parser.add_argument("path", type=Path, help="Путь к корню каталога Gramax.")
    parser.add_argument("--strict", action="store_true", help="Warnings → errors.")
    parser.add_argument("--fix", action="store_true", help="Удалить мусорные файлы (требует --yes).")
    parser.add_argument("--yes", action="store_true", help="Подтверждение для --fix.")
    args = parser.parse_args()

    if args.fix and not args.yes:
        print("--fix requires --yes flag for safety", file=sys.stderr)
        sys.exit(2)

    issues = validate(args.path, args.strict, args.fix, args.yes)

    has_errors = any(i.level == "error" for i in issues)
    has_warnings_strict = args.strict and any(i.level == "warning" for i in issues)

    for issue in issues:
        print(str(issue))

    if has_errors or has_warnings_strict:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
