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
import datetime
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

from lib.md_code_mask import _mask_code
from lib.md_link_parser import parse_md_resources
from lib.link_resolver import resolve_no_ext, check_hash_anchor

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


def check_doc_root(root: Path, issues: list[Issue], required_fields: list[str]) -> set[str]:
    """Проверяет `.doc-root.yaml` каталога: наличие, парсинг, типы обязательных полей
    (FR-121…FR-123, ADR-0020).

    Возвращает множество токенов-плейсхолдеров `{{...}}`, чьи placeholder-находки поглощены
    parse-error-находкой с подсказкой FR-123 (BR-004: одна находка на дефект).

    FR-122: ошибка парсинга существующего файла прогон не прекращает — вызывающий код
    продолжает остальные проверки (минимум `check_placeholders`); отсутствие файла сигналит
    error, трактуемое вызывающим кодом как «каталога нет» (прежнее поведение).
    """
    yaml_file = root / ".doc-root.yaml"
    if not yaml_file.exists():
        issues.append(Issue("error", root, ".doc-root.yaml not found"))
        return set()
    raw = yaml_file.read_text(encoding="utf-8")
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as e:
        return _report_doc_root_yaml_error(yaml_file, issues, raw, e)
    if not isinstance(data, dict):
        issues.append(Issue("error", yaml_file, "invalid yaml: top-level structure must be a mapping"))
        return set()
    value_lines = _value_line_map(raw)
    lines = raw.splitlines()
    for field in required_fields:
        if field not in data:
            issues.append(Issue("error", yaml_file, f"missing field: {field}"))
            continue
        value = data[field]
        if isinstance(value, str) and value.strip():
            continue
        # FR-121: непустая строка — единственный валидный тип значения обязательного поля;
        # сообщение несёт фактический тип и исходную строку (номер строки + raw-текст).
        loc = ""
        line_no = value_lines.get(field)
        if line_no is not None and line_no - 1 < len(lines):
            loc = f" (строка {line_no}: {lines[line_no - 1].strip()})"
        issues.append(Issue(
            "error", yaml_file,
            f'invalid type for field "{field}": expected non-empty string, '
            f"got {_value_type_name(value)}{loc}",
        ))
    return set()


def _value_line_map(raw: str) -> dict[str, int]:
    """{top-level field: 1-based номер строки его значения} из `yaml.compose` (FR-121)."""
    result: dict[str, int] = {}
    try:
        node = yaml.compose(raw)
    except yaml.YAMLError:
        return result
    if not isinstance(node, yaml.MappingNode):
        return result
    for key_node, value_node in node.value:
        if isinstance(key_node, yaml.ScalarNode):
            result[key_node.value] = value_node.start_mark.line + 1
    return result


def _value_type_name(value) -> str:
    """Человекочитаемое имя типа значения поля `.doc-root.yaml` (FR-121)."""
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, str):
        return "empty string" if not value.strip() else "string"
    if isinstance(value, dict):
        return "dict"
    if isinstance(value, list):
        return "list"
    if isinstance(value, (int, float)):
        return type(value).__name__
    if isinstance(value, datetime.datetime):
        return "datetime"
    if isinstance(value, datetime.date):
        return "date"
    return type(value).__name__


_PLACEHOLDER_AT_VALUE_RE = re.compile(r"^(\w[\w-]*)\s*:\s*(\{\{[^{}\n]+\}\})(.*)$")


def _placeholder_quote_hint(raw: str) -> tuple[str, str] | None:
    """FR-123: если парсинг упал из-за незакавыченного `{{...}}` на позиции значения поля
    (эвристика по raw-строке) — возвращает (токен, текст подсказки с закавычиванием)."""
    for line in raw.splitlines():
        m = _PLACEHOLDER_AT_VALUE_RE.match(line)
        if not m:
            continue
        field, token, rest = m.group(1), m.group(2), m.group(3).strip()
        value_str = token + (f" {rest}" if rest else "")
        hint = (f"незакавыченный плейсхолдер {token} на позиции значения поля; "
                f"закавычьте значение: {field}: \"{value_str}\" "
                f'(пример: title: "{{{{PROJECT_NAME}}}}")')
        return token, hint
    return None


def _report_doc_root_yaml_error(yaml_file: Path, issues: list[Issue], raw: str, e: yaml.YAMLError) -> set[str]:
    """FR-122/FR-123: сообщение об ошибке парсинга `.doc-root.yaml` с номером строки/колонки
    из `problem_mark` pyyaml (fallback `str(e)` при отсутствии mark); возвращает множество
    поглощённых placeholder-токенов (одна находка на дефект, BR-004)."""
    mark = getattr(e, "problem_mark", None)
    if mark is not None and getattr(mark, "line", None) is not None:
        msg = f"invalid yaml: синтаксическая ошибка на строке {mark.line + 1}, колонке {mark.column + 1}"
    else:
        msg = f"invalid yaml: {e}"
    hint = _placeholder_quote_hint(raw)
    if hint is not None:
        token, hint_text = hint
        issues.append(Issue("error", yaml_file, f"{msg}; {hint_text}"))
        return {token}
    issues.append(Issue("error", yaml_file, msg))
    return set()


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


# ===== Рекурсивное обнаружение catalog root и границы ownership (ADR-0020, FR-120) =====
# Исключения обхода — явный список (Решение 1 и 6): по имени каталога на любой глубине и
# по относительному пути от переданного корня (фикстурные пути догфудинга AC-040).
_EXCLUDED_DIR_NAMES = {".git", ".gramax", "node_modules"}


def _is_excluded_walk_path(root: Path, path: Path) -> bool:
    """True — `path` (файл/каталог) лежит в поддереве, исключённом из обхода (FR-120).

    Сам переданный корень не исключается никогда: `relative_to(root)` даёт `.` без частей."""
    try:
        rel = path.relative_to(root)
    except ValueError:
        return False
    if any(part in _EXCLUDED_DIR_NAMES for part in rel.parts):
        return True
    if rel.parts and rel.parts[0] == "tests":
        return True
    if str(rel).startswith("plugins/gramax/scripts/tests/fixtures"):
        return True
    return False


def _iter_doc_root_yaml(root: Path):
    """Все вложенные `.doc-root.yaml` под `root` (кроме первичного и исключённых путей)."""
    for candidate in root.rglob(".doc-root.yaml"):
        d = candidate.parent
        if d == root:
            continue
        if _is_excluded_walk_path(root, d):
            continue
        yield d


def _nested_doc_root_dirs(root: Path) -> set[Path]:
    """Resolved-директории вложенных `.doc-root.yaml` — их поддеревья вне структурной
    области `root` (FR-120 граница ownership, переиспользует дух `in_scope=False`, FR-047)."""
    return {d.resolve() for d in _iter_doc_root_yaml(root)}


def _discover_nested_doc_roots(root: Path) -> list[Path]:
    """Отсортированный список вложенных catalog root для валидации (FR-120, NFR-002)."""
    return sorted(_iter_doc_root_yaml(root))


def _in_nested_subtree(path: Path, nested: set[Path]) -> bool:
    """True — `path` лежит внутри одного из вложенных catalog root (ownership boundary)."""
    r = path.resolve()
    return any(r == n or n in r.parents for n in nested)


def _parse_resources(root: Path, nested: set[Path]):
    """Ресурсные ссылки (`parse_md_resources`) только из структурной области `root`:
    источники из поддеревьев вложенных root / исключённых путей отбрасываются (FR-120)."""
    return [
        r for r in parse_md_resources(root)
        if not _in_nested_subtree(r.source, nested)
        and not _is_excluded_walk_path(root, r.source)
    ]


def check_subfolders_have_index(root: Path, issues: list[Issue], nested: set[Path] | None = None):
    """Каждая подпапка с .md или вложенными папками обязана иметь _index.md
    (`indexPolicy.subfolder: required`, gramax-catalog-rules.json). Корень каталога в этот
    обход не входит (`subdir == root` исключён) — там `_index.md` `optional`
    (ADR-0012 Решение 1, ADR-0015).

    Поддеревья вложенных `.doc-root.yaml` и исключённые пути обхода (FR-120) пропускаются:
    их политика индекса — зона вложенного root, валидируется там, не дублем от ancestor."""
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for subdir in root.rglob("*"):
        if not subdir.is_dir():
            continue
        if ".gramax" in subdir.parts:
            continue
        if subdir == root:
            continue
        if _is_excluded_walk_path(root, subdir):
            continue
        if _in_nested_subtree(subdir, nested):
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


def check_garbage(root: Path, issues: list[Issue], strict: bool, fix: bool, yes: bool,
                  garbage_files: set[str], nested: set[Path] | None = None) -> list[Path]:
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    removed = []
    for path in root.rglob("*"):
        if path.name in garbage_files:
            if _is_excluded_walk_path(root, path) or _in_nested_subtree(path, nested):
                continue
            level = "error" if strict else "warning"
            issues.append(Issue(level, path, f"garbage file: {path.name}"))
            if fix and yes:
                path.unlink()
                removed.append(path)
    return removed


def check_no_drawio(root: Path, issues: list[Issue], strict: bool, nested: set[Path] | None = None):
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for path in root.rglob("*.drawio"):
        if _is_excluded_walk_path(root, path) or _in_nested_subtree(path, nested):
            continue
        level = "error" if strict else "warning"
        issues.append(Issue(level, path, ".drawio file should be converted to .svg"))


# ===== Плейсхолдеры / сироты / битые ссылки (FR-046…FR-048, ADR-0012 Решение 2) =======
# _mask_code (fenced + inline) — общий примитив lib/md_code_mask.py (ADR-0019 Решение 5)

_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
_EXTERNAL_RE = re.compile(r"^(?:[a-z][a-z0-9+.\-]*:|//)", re.IGNORECASE)
_PLACEHOLDER_RE = re.compile(r"\{\{[^{}\n]+\}\}")


def _collect_md_files(root: Path, nested: set[Path] | None = None) -> list[Path]:
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    return sorted(
        p for p in root.rglob("*.md")
        if ".gramax" not in p.parts
        and not _is_excluded_walk_path(root, p)
        and not _in_nested_subtree(p, nested)
    )


@dataclass
class LinkRef:
    source: Path      # файл, где найдена ссылка
    raw_target: str    # текст внутри скобок, как в файле (до fragment/<>-очистки)
    resolved: Path      # цель, резолвленная относительно source.parent
    in_scope: bool      # False — цель за пределами root (cross-каталожная), FR-047 граница


# Апстрим-дефект nauta C9 (нет инференса .md/_index.md) — issue tools-ai/nauta, номер уточнит PM
def _resolve_link_target(source_dir: Path, target: str) -> Path:
    """Резолвит `target` ссылки относительно `source_dir` (FR-082, ADR-0016 Решение 1).

    Если `target` уже оканчивается на `.md` — инференс не применяется, возвращается
    буквальный `resolve()` (не пытается получить `цель.md.md`, AC-011b). Иначе пробует по
    порядку: литерал `target` → `target + ".md"` → `target + "/_index.md"`, возвращает
    первый существующий (`Path.exists()`) путь. Если ни один вариант не существует — тоже
    возвращается буквальный `resolve()` (нужен и для текста ошибки, и для `in_scope`,
    NFR-001: генуинно битая ссылка не должна «починиться»)."""
    literal = (source_dir / target).resolve()
    if target.endswith(".md"):
        return literal
    for candidate in (literal, (source_dir / f"{target}.md").resolve(), (source_dir / f"{target}/_index.md").resolve()):
        if candidate.exists():
            return candidate
    return literal


def _collect_links(root: Path, nested: set[Path] | None = None) -> list[LinkRef]:
    """Собирает markdown-ссылки/изображения (`[текст](цель)`, `![alt](цель)`) из всех .md
    каталога.

    Границы (FR-047, разделяемые orphan- и broken-link-проверками):
    - внешние (http/https/mailto/tel/protocol-relative) и якорные (`#foo`) цели не
      резолвятся вовсе — не .md-путь внутри каталога;
    - цель, резолвящаяся ЗА пределами `root` (cross-каталожная ссылка на соседний
      `.doc-root.yaml`-каталог), помечается `in_scope=False`: ни orphan-, ни
      broken-link-проверка её не использует — не резолвится, не создаёт ложных находок
      (AC-014);
    - статьи из поддеревьев вложенных `.doc-root.yaml` не собираются вовсе (FR-120
      ownership boundary): их ссылки резолвятся в границах своего root (AC-039).
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    root_resolved = root.resolve()
    refs: list[LinkRef] = []
    for md in _collect_md_files(root, nested):
        text = _mask_code(md.read_text(encoding="utf-8"))
        for m in _MD_LINK_RE.finditer(text):
            raw = m.group(1)
            target = raw.split("#", 1)[0].strip()
            target = target.strip("<>")
            if not target:
                continue  # якорь на текущую страницу — не файловая ссылка
            if _EXTERNAL_RE.match(target):
                continue  # http/https/mailto/tel/protocol-relative — офлайн-инструмент их не резолвит
            resolved = _resolve_link_target(md.parent, target)
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            refs.append(LinkRef(md, raw, resolved, in_scope))
    return refs


def check_placeholders(root: Path, issues: list[Issue], suppressed_tokens: set[str] | None = None,
                       nested: set[Path] | None = None):
    """FR-046: плейсхолдер шаблона `{{ИМЯ}}`, доехавший до наполненного каталога — error
    безусловно (ADR-0012 Решение 2). Сканирует `.doc-root.yaml` целиком и текст каждой
    статьи (код-блоки замаскированы — пример синтаксиса в документации не считается
    протёкшим плейсхолдером).

    FR-123 (BR-004): токен незакавыченного `{{...}}`, по которому уже выдана
    parse-error-находка с подсказкой (`suppressed_tokens`), placeholder-находку не даёт;
    прочие токены того же файла продолжают давать собственные находки."""
    suppressed = suppressed_tokens or set()
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    yaml_file = root / ".doc-root.yaml"
    if yaml_file.exists():
        for m in _PLACEHOLDER_RE.finditer(yaml_file.read_text(encoding="utf-8")):
            if m.group(0) in suppressed:
                continue
            issues.append(Issue("error", yaml_file,
                                 f"плейсхолдер шаблона {m.group(0)} не заменён (placeholder)"))
    for md in _collect_md_files(root, nested):
        masked = _mask_code(md.read_text(encoding="utf-8"))
        for m in _PLACEHOLDER_RE.finditer(masked):
            issues.append(Issue("error", md,
                                 f"плейсхолдер шаблона {m.group(0)} не заменён (placeholder)"))


def check_broken_links(root: Path, issues: list[Issue], nested: set[Path] | None = None):
    """FR-048: markdown-ссылка на несуществующий файл внутри того же `.doc-root.yaml`-
    каталога — error безусловно (ADR-0012 Решение 2).

    Расширено healthcheck-портом:
    - W032: no-ext resolution — если target не найден, но target.md существует → OK;
      если ни target, ни target.md не найдены → предупреждение (до повышения до error
      в будущем релизе).
    - W033: hash anchor — если #fragment не соответствует ни одному заголовку → warning.
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for res in _parse_resources(root, nested):
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
                    f'W033: hash-якорь "#{fragment}" не найден в {resolved.relative_to(root.resolve())} '
                    f'(ссылка из {res.source.name})',
                ))


def check_orphans(root: Path, issues: list[Issue], strict: bool, nested: set[Path] | None = None):
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
    засчитываются как входящие — AC-014. Статьи из поддеревьев вложенных `.doc-root.yaml`
    в учёт не входят вовсе (FR-120 ownership boundary) — их orphan-статус — зона
    вложенного root, AC-039.
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    level = "error" if strict else "warning"
    incoming: dict[Path, int] = {}
    display: dict[Path, Path] = {}
    for md in _collect_md_files(root, nested):
        if md.name == "_index.md":
            continue
        key = md.resolve()
        incoming[key] = 0
        display[key] = md

    for ref in _collect_links(root, nested):
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

    # Демаркация с рендер-линтером (ADR-0019 Решение 3 и 6):
    #   known = {"drawio"} ∪ killerTags ∪ allowlistedTags — W034 молчит по <th>/<colgroup>/<col>,
    #   чтобы дефект давал ровно одну находку по гейту (BR-004);
    #   check_tags балансит только pairedTags − balanceTags — unbalanced note/tabs/tab/color/
    #   highlight репортит validate_render.py (FR-109), html/comment остаются за check_tags.
    # Отсутствующий/повреждённый gramax-render-rules.json — error через load_json_contract
    # (ADR-0012, Consequences); known_tags тогда сводится к {"drawio"}.
    render_contract = load_json_contract(plugin_root / "gramax-render-rules.json", issues)
    balance_tags = set((render_contract or {}).get("balanceTags", []))
    known_tags = {"drawio"}
    if render_contract is not None:
        known_tags |= {
            item.get("tag") for item in render_contract.get("killerTags", [])
            if isinstance(item, dict) and item.get("tag")
        }
        known_tags |= set(render_contract.get("allowlistedTags", []))
    effective_paired_tags = [t for t in paired_tags if t not in balance_tags]

    if not root.is_dir():
        issues.append(Issue("error", root, "not a directory"))
        return issues
    # FR-122: отсутствие `.doc-root.yaml` на переданном корне — error + прекращение
    # (прежнее поведение): директория без catalog root не является каталогом, структурным
    # проверкам не к чему привязаться. Это НЕ про ошибку парсинга — та прогон не глушит.
    if not (root / ".doc-root.yaml").exists():
        issues.append(Issue("error", root, ".doc-root.yaml not found"))
        return issues
    # FR-120: обход всего дерева переданного пути, каждый найденный `.doc-root.yaml`
    # валидируется как отдельный catalog root полным структурным suite'ом. Первичный
    # root — всегда первым, вложенные — в отсортированном порядке (NFR-002).
    for catalog_root in [root, *_discover_nested_doc_roots(root)]:
        _validate_catalog_root(catalog_root, issues, strict, fix, yes, garbage_files,
                               doc_root_required, frontmatter_required,
                               effective_paired_tags, known_tags)
    return issues


def _validate_catalog_root(root: Path, issues: list[Issue], strict: bool, fix: bool, yes: bool,
                           garbage_files: set[str], doc_root_required: list[str],
                           frontmatter_required: list[str], effective_paired_tags: list[str],
                           known_tags: set[str]):
    """Полный структурный suite для одного catalog root (FR-120: каждый найденный
    `.doc-root.yaml` валидируется как отдельный root). Ошибка парсинга `.doc-root.yaml`
    прогон не прекращает (FR-122) — все проверки, включая `check_placeholders`, выполняются."""
    nested = _nested_doc_root_dirs(root)
    suppressed = check_doc_root(root, issues, doc_root_required)
    check_subfolders_have_index(root, issues, nested)
    schema = load_property_schema(root)
    if schema is None:
        issues.append(Issue("warning", root / ".doc-root.yaml",
                            "schema использует экспериментальный формат values; V4/V5 пропущены"))
    for md in _collect_md_files(root, nested):
        check_frontmatter(md, issues, schema, frontmatter_required)
        check_tags(md, issues, effective_paired_tags)
    check_garbage(root, issues, strict, fix, yes, garbage_files, nested)
    check_no_drawio(root, issues, strict, nested)
    check_placeholders(root, issues, suppressed, nested)
    check_broken_links(root, issues, nested)
    check_orphans(root, issues, strict, nested)
    check_unsupported_markup(root, issues, known_tags, nested)
    check_images(root, issues, nested)
    check_diagrams(root, issues, nested)


def check_images(root: Path, issues: list[Issue], nested: set[Path] | None = None):
    """Проверяет существование файлов изображений, на которые ссылаются markdown-статьи.

    ![alt](path) → path должен существовать на диске. WARNING-уровень (W030).
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for res in _parse_resources(root, nested):
        if res.target_type != "image":
            continue
        if not res.in_scope:
            continue  # cross-каталожная ссылка — не резолвим (FR-047)
        if not res.resolved_path.exists():
            issues.append(Issue(
                "warning", res.source,
                f'W030: файл изображения не найден: "{res.raw_target}" → {res.resolved_path}',
            ))


def check_diagrams(root: Path, issues: list[Issue], nested: set[Path] | None = None):
    """Проверяет существование .drawio-файлов, на которые ссылаются статьи.

    <drawio path="..."/> → path должен существовать на диске. WARNING-уровень (W031).
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for res in _parse_resources(root, nested):
        if res.target_type != "drawio":
            continue
        if not res.in_scope:
            continue
        if not res.resolved_path.exists():
            issues.append(Issue(
                "warning", res.source,
                f'W031: файл диаграммы не найден: "{res.raw_target}" → {res.resolved_path}',
            ))


# Whitelist тегов, которые Gramax НЕ считает unsupported.
# <th> (killer) и <colgroup>/<col> (allowlist) владеет validate_render.py — W034 по ним
# молчит, чтобы дефект давал ровно одну находку по гейту (ADR-0019 Решение 3, BR-004).
# Набор вычисляется из контракта gramax-render-rules.json в validate() — не литерал:
# новый киллер добавляется строкой в killerTags, демаркация обновляется сама.

_UNSUPPORTED_HTML_RE = re.compile(r"<(?!\/)([a-z][a-z0-9]*)(?:\s[^>]*)?>", re.IGNORECASE)


def check_unsupported_markup(root: Path, issues: list[Issue], known_tags: set[str],
                             nested: set[Path] | None = None):
    """Проверяет наличие HTML-тегов и нестандартной разметки в markdown-статьях.

    Gramax не поддерживает произвольный HTML. Исключение: <drawio path="..."/> и
    теги из gramax-render-rules.json (killerTags + allowlistedTags).
    WARNING-уровень (W034) — некоторые HTML-теги могут быть валидны в markdown.
    """
    if nested is None:
        nested = _nested_doc_root_dirs(root)
    for md in _collect_md_files(root, nested):
        text = _mask_code(md.read_text(encoding="utf-8"))
        seen_tags: set[str] = set()
        for m in _UNSUPPORTED_HTML_RE.finditer(text):
            tag = m.group(1).lower()
            if tag not in known_tags and tag not in seen_tags:
                seen_tags.add(tag)
                issues.append(Issue(
                    "warning", md,
                    f'W034: неподдерживаемая разметка: <{m.group(1)}> '
                    f'(Gramax может не отобразить этот элемент)',
                ))


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


if __name__ == "__main__":
    main()
