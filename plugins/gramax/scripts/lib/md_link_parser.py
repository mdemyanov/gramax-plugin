"""Парсинг markdown-ресурсов: ссылки, изображения, drawio-теги.

Извлекает из .md-файлов каталога все ресурсные ссылки в унифицированном виде,
пригодном для downstream-проверок (broken links, images, diagrams).
Код-блоки (fenced + inline) маскируются перед парсингом — документация,
показывающая синтаксис, не даёт ложных срабатываний.
"""

import re
from dataclasses import dataclass
from pathlib import Path

_FENCE_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_INLINE_CODE_RE = re.compile(r"(`+)([^\n]+?)\1")
_MD_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
_DRAWIO_RE = re.compile(r'<drawio\s[^>]*path="([^"]+)"[^>]*/>')
_EXTERNAL_RE = re.compile(r"^(?:[a-z][a-z0-9+.\-]*:|//)", re.IGNORECASE)


@dataclass
class MdResource:
    """Одна ресурсная ссылка в markdown-статье."""
    source: Path          # файл, где найдена ссылка
    raw_target: str        # текст внутри скобок / кавычек, как в файле
    resolved_path: Path     # цель, резолвленная относительно source.parent
    target_type: str        # "link" | "image" | "drawio"
    in_scope: bool          # False — цель за пределами root


def _mask_code(text: str) -> str:
    """Заменяет код (fenced-блоки и inline) пробелами той же длины, сохраняя смещения строк."""
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


def parse_md_resources(root: Path) -> list[MdResource]:
    """Собирает все ресурсные ссылки из markdown-файлов каталога.

    Возвращает унифицированный список MdResource: markdown-ссылки [text](target),
    изображения ![alt](target), и drawio-теги <drawio path="target"/>.
    Внешние ссылки (http/https/mailto) пропускаются. Cross-каталожные ссылки
    помечаются in_scope=False.
    """
    root_resolved = root.resolve()
    resources: list[MdResource] = []

    for md in _collect_md_files(root):
        text = _mask_code(md.read_text(encoding="utf-8"))

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

        # Drawio tags: <drawio path="..."/>
        for m in _DRAWIO_RE.finditer(text):
            raw = m.group(1)
            resolved = (md.parent / raw).resolve()
            in_scope = resolved == root_resolved or root_resolved in resolved.parents
            resources.append(MdResource(md, raw, resolved, "drawio", in_scope))

    return resources
