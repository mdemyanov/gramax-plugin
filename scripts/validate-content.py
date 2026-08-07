#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pyyaml>=6.0,<7.0",
# ]
# ///
"""validate-content.py — валидатор структуры Gramax-каталога.

Проверяет content/ на соответствие правилам Gramax (см. CLAUDE.md / spec).
Exit codes: 0 — clean; 1 — есть errors; 2 — pyyaml не установлен или плохой путь.

C9/C10 (ADR-014, TPL-37а) — ссылочная целостность: битые ссылки (error) и статьи-сироты
(warning). Архитектура: ADR-014 (Decision Д1-Д5) и её companion-спека (§1 паттерн-таблица,
§2 алгоритм) — путь не приводится литералом здесь намеренно (docs/adr/ вырезается из
public-снапшота публикацией; литеральный путь в этом keep-файле ловится cross-link
гейтом publish-public.sh — тот же класс осторожности, что у run_gate_if_present в
check.sh).
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _validate_common import (
    Issue, MalformedYamlError, issue_from_yaml_error,
    parse_frontmatter, parse_yaml_file, has_placeholder, PLACEHOLDER_RE, require_yaml,
)


def check_property_names(content_dir: Path, doc_root: dict) -> list[Issue]:
    """C4: имена property в frontmatter объявлены в .doc-root.yaml."""
    declared = {p["name"] for p in doc_root.get("properties", []) if isinstance(p, dict) and "name" in p}
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        if has_placeholder(md_path):
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError as e:
            issues.append(issue_from_yaml_error(e))
            continue
        if not fm or "properties" not in fm or not isinstance(fm["properties"], list):
            continue
        for p in fm["properties"]:
            if not isinstance(p, dict) or "name" not in p:
                continue
            name = p["name"]
            if name not in declared:
                issues.append(Issue("error", str(md_path),
                    f"property \"{name}\" не объявлен в .doc-root.yaml"))
    return issues


def check_property_values(content_dir: Path, doc_root: dict) -> list[Issue]:
    """C5: значения property из frontmatter входят в values: (для type: Enum)."""
    enums = {
        p["name"]: set(p.get("values") or [])
        for p in doc_root.get("properties", [])
        if isinstance(p, dict) and p.get("type") == "Enum" and "name" in p
    }
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        if has_placeholder(md_path):
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError as e:
            issues.append(issue_from_yaml_error(e))
            continue
        if not fm or "properties" not in fm or not isinstance(fm["properties"], list):
            continue
        for p in fm["properties"]:
            if not isinstance(p, dict) or "name" not in p or "value" not in p:
                continue
            name = p["name"]
            if name not in enums:
                continue
            values = p["value"] if isinstance(p["value"], list) else [p["value"]]
            for v in values:
                if v not in enums[name]:
                    allowed = sorted(enums[name])
                    issues.append(Issue("error", str(md_path),
                        f"property \"{name}\" имеет значение \"{v}\", не входящее в enum {allowed}"))
    return issues


def check_filter_coverage(content_dir: Path, doc_root: dict) -> list[Issue]:
    """C6: статья объявляет хотя бы один property из filterProperties (warning)."""
    filter_names = set(doc_root.get("filterProperties") or [])
    if not filter_names:
        return []
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError as e:
            issues.append(issue_from_yaml_error(e))
            continue
        if not fm:
            continue
        props = fm.get("properties") or []
        if not isinstance(props, list):
            continue
        declared = {p["name"] for p in props if isinstance(p, dict) and "name" in p}
        if not (declared & filter_names):
            issues.append(Issue("warning", str(md_path),
                f"не объявляет ни одного property из filterProperties {sorted(filter_names)} — фильтр в Gramax не сработает"))
    return issues


def check_placeholders(content_dir: Path) -> list[Issue]:
    """C7: warning про плейсхолдеры в frontmatter."""
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if has_placeholder(md_path):
            issues.append(Issue("warning", str(md_path),
                "frontmatter содержит плейсхолдер {{...}}; ожидается замена через init.sh"))
    return issues


def check_doc_root_placeholders(content_dir: Path) -> list[Issue]:
    """C7-doc-root: warning, если .doc-root.yaml содержит плейсхолдеры {{...}}."""
    path = content_dir / ".doc-root.yaml"
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8")
    if PLACEHOLDER_RE.search(text):
        return [Issue("warning", str(path),
            "содержит плейсхолдер {{...}}; ожидается замена через init.sh")]
    return []


def check_index_no_properties(content_dir: Path) -> list[Issue]:
    """C2: _index.md не должен содержать properties:."""
    issues = []
    for index_path in content_dir.rglob("_index.md"):
        try:
            fm = parse_frontmatter(index_path)
        except MalformedYamlError as e:
            issues.append(issue_from_yaml_error(e))
            continue
        if fm and "properties" in fm:
            issues.append(Issue(
                level="error",
                path=str(index_path),
                message="_index.md не должен иметь properties (раздел не имеет своего типа/статуса)",
            ))
    return issues


def check_object_notation(content_dir: Path) -> list[Issue]:
    """C3: properties в статьях — список dict-ов с ключами name+value."""
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError as e:
            issues.append(issue_from_yaml_error(e))
            continue
        if not fm or "properties" not in fm:
            continue
        props = fm["properties"]
        if not isinstance(props, list):
            issues.append(Issue("error", str(md_path),
                "properties должен быть списком (получено: " + type(props).__name__ + ")"))
            continue
        for p in props:
            if not isinstance(p, dict):
                issues.append(Issue("error", str(md_path),
                    "элемент properties должен быть dict-ом (получено: " + type(p).__name__ + ")"))
                continue
            keys = set(p.keys())
            if keys != {"name", "value"}:
                # Если ровно один ключ — это плоская нотация.
                if len(keys) == 1:
                    issues.append(Issue("error", str(md_path),
                        f"использует плоскую frontmatter-нотацию ({list(keys)[0]}: ...); требуется object-нотация (- name: X / value: [Y])"))
                else:
                    issues.append(Issue("error", str(md_path),
                        f"элемент properties должен иметь ровно ключи name+value (получено: {sorted(keys)})"))
    return issues


def check_indexes(content_dir: Path) -> list[Issue]:
    """C1: каждая подпапка с .md или вложенными .md содержит _index.md."""
    issues = []
    for d in [content_dir, *sorted(p for p in content_dir.rglob("*") if p.is_dir())]:
        # Пропускаем подпапки без .md (рекурсивно)
        has_md = any(d.rglob("*.md"))
        if not has_md:
            continue
        index_path = d / "_index.md"
        if not index_path.exists():
            issues.append(Issue(
                level="error",
                path=f"{d}/",
                message="missing _index.md (Gramax не покажет раздел в навигации)",
            ))
    return issues


def _strip_frontmatter(text: str) -> str:
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) == 3:
            return parts[2]
    return text


# Модульный уровень, рядом с остальными компилированными паттернами файла (например
# _LINK_PATTERNS). Единственное определение "структурной строки" -- C8 и C11 (§3.4) читают
# ОДНУ константу, не два независимых regex (ADR-010 Д2). Известный дефект (TPL-67 -- слеп к
# блочному Gramax {% table %}, код-fence, юникод-рамкам) НЕ чинится этим ADR -- T_S откалиброван
# RES-026 на этом же regex; правка сдвинула бы run-распределение без данных на замену.
HAS_STRUCTURE_RE = re.compile(r"(?m)^\s*\||<view|<note|^#{2,}\s")


def check_bloat(content_dir: Path, threshold: int = 40) -> list[Issue]:
    """C8 -- логика не меняется, только ссылка на модульную HAS_STRUCTURE_RE вместо
    локальной переменной."""
    issues = []
    for index_path in content_dir.rglob("_index.md"):
        body = _strip_frontmatter(index_path.read_text(encoding="utf-8"))
        has_structure = bool(HAS_STRUCTURE_RE.search(body))
        prose = [ln for ln in body.splitlines()
                 if ln.strip() and not ln.lstrip()[:1] in {"#", "|", "-", "*", ">", "<"}]
        if len(prose) > threshold and not has_structure:
            issues.append(Issue("warning", str(index_path),
                f"_index раздут ({len(prose)} строк прозы) без структуры "
                f"(таблиц/<view>/заголовков); добавьте навигацию или сократите"))
    return issues


# ===== C9/C10: ссылочная целостность (ADR-014, spec §1-§2) ==========================

# Паттерн-таблица §1 — данные, не управляющая логика (новый Gramax-тег = новая строка).
# kind: "path" — резолв относительно source.parent; "snippet_id" — резолв в
# <content_dir>/.gramax/snippets/<raw_target>.md (спец-случай, §2 шаг7).
_LINK_PATTERNS: list[tuple[str, re.Pattern]] = [
    ("path", re.compile(r'!?\[[^\]]*\]\(([^)]+)\)')),          # #1/#2: markdown link/image
    ("path", re.compile(r'<mermaid\s+[^>]*?path="([^"]+)"')),   # #3
    ("path", re.compile(r'<image\s+[^>]*?src="([^"]+)"')),      # #4
    ("path", re.compile(r'<openapi\s+[^>]*?src="([^"]+)"')),    # #5
    ("snippet_id", re.compile(r'<snippet\s+[^>]*?id="([^"]+)"')),  # #6
    ("path", re.compile(r'\[drawio:([^:\]]+):[^\]]*\]')),       # #7 (bracket); #8 legacy — покрыт #1
]

# Внешние цели (http/https/mailto/tel/protocol-relative //) — не сканируются, сети нет
# (ADR-014 Д1/Д5, спека §1).
_EXTERNAL_RE = re.compile(r'^(?:[a-z][a-z0-9+.\-]*:|//)', re.IGNORECASE)


@dataclass
class Reference:
    source: Path        # файл, где найдена ссылка
    raw_target: str     # текст внутри скобок/атрибута, как в файле (до fragment/<>-очистки)
    kind: str           # "path" | "snippet_id"
    resolved: Path | None  # None — не должно случаться (обе ветки §2 шаг6/7 его строят)


def _collect_references(content_dir: Path) -> list[Reference]:
    """§2: единый проход по content_dir.rglob("*.md"), даёт список Reference для C9 и C10.

    Guard Д2: файлы с has_placeholder() == True пропускаются целиком — их исходящие
    ссылки не проверяются вовсе (ни error, ни warning). Файл остаётся видимым в C1-C8 и
    как ЦЕЛЬ входящих ссылок (C10) — guard касается только его СОБСТВЕННЫХ исходящих.
    """
    refs: list[Reference] = []
    for md_path in sorted(content_dir.rglob("*.md")):
        if has_placeholder(md_path):
            continue
        text = md_path.read_text(encoding="utf-8")
        for kind, pattern in _LINK_PATTERNS:
            for m in pattern.finditer(text):
                raw_target = m.group(1)
                # §2 шаг4: сначала #fragment, потом обёртка <...> — в этом порядке.
                target = raw_target.split("#", 1)[0]
                target = target.strip("<>")
                if not target:
                    continue  # самоссылка на якорь — уже отфильтровано
                if _EXTERNAL_RE.match(target):
                    continue
                if kind == "path":
                    resolved = (md_path.parent / target).resolve()
                else:  # "snippet_id" — резолв по raw_target (§2 шаг7), не по target
                    resolved = (content_dir / ".gramax" / "snippets" / f"{raw_target}.md").resolve()
                refs.append(Reference(md_path, raw_target, kind, resolved))
    return refs


def check_broken_links(content_dir: Path) -> list[Issue]:
    """C9: ссылка, не резолвящаяся на диске, — error (факт, не суждение)."""
    issues = []
    for ref in _collect_references(content_dir):
        if ref.resolved is not None and not ref.resolved.exists():
            issues.append(Issue("error", str(ref.source),
                f"битая ссылка на \"{ref.raw_target}\" — {ref.resolved} не существует"))
    return issues


def check_orphans(content_dir: Path) -> list[Issue]:
    """C10: .md-статья (не _index.md) с нулевой входящей степенью — warning.

    In-degree, не BFS от корня (Д3). Self-ссылка не засчитывается как входящая (не
    "отбеливает" орфана), но и не отнимается — инициализация нулём на файл, не декремент.
    Сравнение путей — обе стороны через .resolve() (ловушка прототипа SA, ADR-014 spec §5):
    сравнение resolved-absolute с ключами относительных путей ложно помечало бы всё
    orphan.
    """
    incoming: dict[Path, int] = {}
    display: dict[Path, Path] = {}
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        key = md_path.resolve()
        incoming[key] = 0
        display[key] = md_path

    for ref in _collect_references(content_dir):
        if ref.resolved is None:
            continue
        if ref.resolved == ref.source.resolve():
            continue  # self-ссылка не засчитывается как входящая
        if ref.resolved in incoming:
            incoming[ref.resolved] += 1

    return [
        Issue("warning", str(display[key]),
              "статья без входящих ссылок из каталога — проверьте, что путь к ней "
              "передаётся явно (PM/pm-review), иначе она не будет найдена")
        for key, count in incoming.items() if count == 0
    ]


# ===== C11/C12: детектор объём+структура content/ (ADR-018, PT-EPIC-20) ==============

def _strip_leading_frontmatter(content: str) -> str:
    """Дословная копия check-adr-line-limit.py::_strip_leading_frontmatter (ADR-013 Д3).
    Дублируется здесь (не импортируется): check-adr-line-limit.py НЕ в поставке потомку
    (.publishignore) -- validate-content.py обязан работать независимо от него.
    Используется ТОЛЬКО для T (body_lines, количественный признак) -- RES-025-B/BA-каталог
    калибровали T именно этой функцией, не _strip_frontmatter ниже."""
    if not content.startswith("---\n"):
        return content
    end = content.find("\n---\n", 4)
    if end == -1:
        return content
    return content[end + 5:]


# _strip_frontmatter(text) -- уже существует выше (используется C8). Используется для T_S
# (longest_run_without_structure) -- BA-определение дословно говорит "_strip_frontmatter из
# check_bloat", не _strip_leading_frontmatter. Не заменять один на другой в C11 -- разные
# функции срезают по-разному на файлах с "---" внутри тела (RES-026 калибровала T_S на
# _strip_frontmatter конкретно).


def _longest_run_without_structure(body: str) -> int:
    """RES-026 определение: самый длинный участок ПОДРЯД идущих строк тела, ни одна из
    которых не матчит HAS_STRUCTURE_RE ПОСТРОЧНО (не re.search по всему телу разом --
    иначе один заголовок в конце файла "обелил" бы всё тело, как C8 уже делает для generic
    случая -- этот признак намеренно другой, RES-026/BA-027b)."""
    longest = current = 0
    for line in body.splitlines():
        if HAS_STRUCTURE_RE.search(line):
            current = 0
        else:
            current += 1
            longest = max(longest, current)
    return longest


def _type_content_value(fm: dict | None) -> str | None:
    """Первое значение property "Тип контента" (object-нотация, value: [X] или value: X),
    либо None -- отсутствие frontmatter/properties/самого property/пустого value трактуются
    одинаково. Общий хелпер C11 и C12."""
    if not fm:
        return None
    props = fm.get("properties")
    if not isinstance(props, list):
        return None
    for p in props:
        if isinstance(p, dict) and p.get("name") == "Тип контента":
            v = p.get("value")
            if isinstance(v, list):
                return v[0] if v else None
            return v or None
    return None


def _repo_relative(md_path: Path, content_dir: Path) -> str:
    """Repo-root-relative, "/"-separated путь для сравнения с sizeBudgetGrandfathered ("path:").
    ВНИМАНИЕ (edge case для QA, §9): опирается на то, что content_dir называется буквально
    "content" в реальном дереве; тестовая фикстура вольна называть свой content_dir иначе --
    тогда путь в фикстурном sizeBudgetGrandfathered обязан использовать ТОТ ЖЕ leaf-компонент,
    не литерал "content/..."."""
    return content_dir.name + "/" + str(md_path.relative_to(content_dir)).replace("\\", "/")


def check_size_budget(content_dir: Path, doc_root: dict) -> list[Issue]:
    """C11 (ADR-018): сигнал -- только при совместном срабатывании (BR-004)."""
    entries = {
        b["type"]: b
        for b in (doc_root.get("sizeBudgets") or [])
        if isinstance(b, dict) and b.get("type") and b.get("thresholdLines") is not None
    }
    if not entries:
        return []
    grandfathered = {
        g["path"]: g["ceiling"]
        for g in (doc_root.get("sizeBudgetGrandfathered") or [])
        if isinstance(g, dict) and "path" in g and "ceiling" in g
    }
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        if has_placeholder(md_path):
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError:
            continue  # уже отражено C3 (issue_from_yaml_error) -- не дублируем
        type_value = _type_content_value(fm)
        if type_value not in entries:
            continue
        budget = entries[type_value]
        threshold = budget["thresholdLines"]
        raw = md_path.read_text(encoding="utf-8")
        lines = _strip_leading_frontmatter(raw).count("\n")
        if lines <= threshold:
            continue  # BR-004: количественный не сработал -- тихий проход
        rel = _repo_relative(md_path, content_dir)
        ceiling = grandfathered.get(rel)
        quality = budget.get("quality")
        severity = budget.get("severity", "warn")
        level = "error" if severity == "block" else "warning"

        if quality == "companion-spec":
            if any(content_dir.rglob(f"{md_path.stem}-spec.md")):
                continue  # качественный признак не провален -- тихий проход
            if ceiling is not None:
                if lines <= ceiling:
                    issues.append(Issue("warning", str(md_path),
                        f"грандфазер: {lines} строк тела <= замороженного потолка {ceiling} "
                        f"({rel}, ADR-018 Д5) -- не блокирует"))
                else:
                    issues.append(Issue("error", str(md_path),
                        f"грандфазер-потолок превышен: {lines} строк тела > {ceiling} ({rel}). "
                        f"Верни рост, или подними ceiling явной правкой sizeBudgetGrandfathered "
                        f"в этом же коммите (ADR-018 Д5, прецедент GRANDFATHERED, ADR-013 Д1)."))
                continue
            issues.append(Issue(level, str(md_path),
                f"тело {lines} строк > T={threshold} (Тип контента: {type_value}); "
                f"companion-спека {md_path.stem}-spec.md не найдена. "
                f"P1: расщепи decision/деталь -- вынеси процедурную детализацию в "
                f"{md_path.stem}-spec.md (kind: reference, без лимита строк) -- ADR-013 Д2, ADR-018."))
            continue

        # quality == "longest_run_without_structure"
        run = _longest_run_without_structure(_strip_frontmatter(raw))
        quality_threshold = budget.get("qualityThreshold")
        if quality_threshold is None or run < quality_threshold:
            continue  # тихий проход
        issues.append(Issue(level, str(md_path),
            f"тело {lines} строк > T={threshold} (Тип контента: {type_value}), и самый длинный "
            f"участок без структуры (заголовок/таблица/<view>/<note>) -- {run} строк >= "
            f"T_S={quality_threshold}. P3: сократи содержание (не разметку); "
            f"P4: добавь структуру -- ADR-018."))
    return issues


def check_type_content_declared(content_dir: Path) -> list[Issue]:
    """C12 (ADR-018 Д6, TPL-68): каждая не-_index.md статья обязана нести непустое свойство
    "Тип контента". Ловит класс, невидимый C3-C6: parse_frontmatter -> None для файла без
    ведущего "---" блока вовсе (ADR-007 Д6 -- None не значит "сломан", но и не значит "ОК")."""
    issues = []
    for md_path in content_dir.rglob("*.md"):
        if md_path.name == "_index.md":
            continue
        if has_placeholder(md_path):
            continue
        try:
            fm = parse_frontmatter(md_path)
        except MalformedYamlError:
            continue  # уже отражено C3
        if _type_content_value(fm) is None:
            issues.append(Issue("error", str(md_path),
                'статья не объявляет непустое свойство "Тип контента" '
                '(properties: - name: Тип контента / value: [...]) -- TPL-68, ADR-018 Д6'))
    return issues


def main(argv: list[str]) -> int:
    require_yaml()
    parser = argparse.ArgumentParser(description="Validate Gramax content/ structure")
    parser.add_argument("content_dir", nargs="?", default="content",
                        help="Path to content directory (default: content)")
    args = parser.parse_args(argv)

    content_dir = Path(args.content_dir)
    if not content_dir.is_dir():
        print(f"ERROR: not a directory: {content_dir}", file=sys.stderr)
        return 2

    issues = []
    issues.extend(check_indexes(content_dir))
    issues.extend(check_bloat(content_dir))
    issues.extend(check_broken_links(content_dir))  # C9 (ADR-014)
    issues.extend(check_orphans(content_dir))        # C10 (ADR-014)
    issues.extend(check_index_no_properties(content_dir))
    issues.extend(check_object_notation(content_dir))
    # Три проверки ниже читают декларацию из .doc-root.yaml. Исходы «файла нет» ({} —
    # декларации нет, проверки законно тривиальны) и «файл нечитаем» (error) различаются
    # явно: прежнее `or {}` их схлопывало, и прогон на пустом словаре либо рапортовал
    # «чисто», либо заливал вывод ложными «property не объявлен» (ADR-007 Д5, AC-01-11).
    try:
        doc_root = parse_yaml_file(content_dir / ".doc-root.yaml")
    except MalformedYamlError as e:
        issues.append(issue_from_yaml_error(e))
        doc_root = None
    if doc_root is not None:
        issues.extend(check_property_names(content_dir, doc_root))
        issues.extend(check_property_values(content_dir, doc_root))
        issues.extend(check_filter_coverage(content_dir, doc_root))
        issues.extend(check_size_budget(content_dir, doc_root))       # C11, новое (ADR-018)
    issues.extend(check_placeholders(content_dir))
    issues.extend(check_doc_root_placeholders(content_dir))
    issues.extend(check_type_content_declared(content_dir))          # C12, новое (ADR-018 Д6)

    # Один битый файл видят несколько независимых rglob-проходов. Схлопываем ДО подсчёта:
    # `Errors: N` считается из списка, а не на печати (ADR-007 Д5).
    seen: set[str] = set()
    deduped: list[Issue] = []
    for issue in issues:
        if issue.dedupe_key:
            if issue.dedupe_key in seen:
                continue
            seen.add(issue.dedupe_key)
        deduped.append(issue)
    issues = deduped

    errors = [i for i in issues if i.level == "error"]
    warnings = [i for i in issues if i.level == "warning"]

    for issue in sorted(issues, key=lambda i: (i.path, i.level)):
        print(f"{issue.path}: {issue.message}  [{issue.level}]")

    md_count = sum(1 for _ in content_dir.rglob("*.md"))
    if not issues:
        print(f"{content_dir}/: OK ({md_count} файлов проверены)")

    print(f"\nErrors: {len(errors)} | Warnings: {len(warnings)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
