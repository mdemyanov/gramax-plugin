#!/usr/bin/env python3
"""
validate_render.py — линтер рендер-киллеров Gramax.

Обнаруживает конструкции markdown, которые роняют рендерер GES (HTTP 500) или ломают
вёрстку: `<th>`, инлайновый `<note>…</note>`, `<note>` внутри `<td>`/`<th>`, `<note>`
вложенный в `<note>`, несколько `![](…)` в одной строке, несбалансированные парные
теги. Стиль/YAML-проблемы (H1 в теле, frontmatter `title:` без кавычек) — WARN.

Порт правил `validate-gramax.py` плагина `gramax-skills` — © Всеволод Шадрин, MIT.
Полный текст MIT-лицензии, provenance и список изменений относительно upstream —
`LICENSE.upstream.md` рядом со скриптом (ADR-0019, Решение 7, NFR-006).

Контракт киллеров/баланса/allowlist — `gramax-render-rules.json` (корень плагина),
машиночитаемый реестр эмпирических инцидентов (ADR-0019, Решение 2, BR-002/BR-003).
Повреждённый/отсутствующий контракт — явный error, не молчаливый fallback
(ADR-0012, Consequences). Маскирование кода (fenced + inline) — общий примитив
`lib/md_code_mask.py` (ADR-0019, Решение 5): примеры синтаксиса в прозе не считаются
разметкой (FR-110, устраняет 11 ложных ERROR исходника на нашем же каталоге).

Использование:
    uv run plugins/gramax/scripts/validate_render.py <файл.md | каталог> [...]

Коды выхода (NFR-001, ADR-0019 Решение 8):
    0 — ERROR нет (WARN допустимы); 1 — есть хотя бы один ERROR;
    2 — некорректное использование (нет валидного целевого файла/каталога).
"""

import argparse
import json
import re
import sys
from pathlib import Path

from lib.md_code_mask import _mask_code

DOC_URL = "https://github.com/mdemyanov/gramax-plugin"
EPILOG = (
    "Документация: plugins/gramax/README.md (раздел «Валидация каталога»), "
    f"plugins/gramax/skills/writer/SKILL.md. Репозиторий: {DOC_URL}"
)

# ===== Машиночитаемый контракт (ADR-0019 Решение 2) =================================

def load_render_rules() -> dict:
    """Читает gramax-render-rules.json; повреждённый/отсутствующий контракт — error.

    Не молчим (ADR-0012, Consequences): оба валидатора поставляются в одной версии
    плагина, отсутствие контракта — дефект упаковки, не допустимый fallback.
    """
    path = Path(__file__).resolve().parent.parent / "gramax-render-rules.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        raise SystemExit(f"ERROR: контракт рендер-правил нечитаем ({path}): {e}")
    if not isinstance(data, dict):
        raise SystemExit(f"ERROR: контракт рендер-правил — не JSON-объект ({path})")
    return data


# ===== Проверки одного файла ========================================================

def check(path: Path, rules: dict) -> tuple[list, list]:
    """Возвращает (errors, warns) как списки (lineno, message).

    Все проверки работают по замаскированному тексту (fenced + inline-код заменён
    пробелами той же длины) — кроме frontmatter-титла, который кодом не бывает.
    """
    text = path.read_text(encoding="utf-8")
    raw_lines = text.split("\n")
    masked = _mask_code(text)
    masked_lines = masked.split("\n")
    errors: list[tuple[int, str]] = []
    warns: list[tuple[int, str]] = []

    def E(ln: int, msg: str) -> None:
        errors.append((ln, msg))

    def W(ln: int, msg: str) -> None:
        warns.append((ln, msg))

    killer_hint: dict[str, str] = {
        item.get("tag"): item.get("message", "")
        for item in rules.get("killerTags", [])
        if isinstance(item, dict) and item.get("tag")
    }
    balance_tags: list[str] = rules.get("balanceTags", []) or []
    balance_res = {
        tag: (
            re.compile(r"<" + tag + r"(?:\s[^>]*)?(?<!/)>"),
            re.compile(r"</" + tag + r">"),
        )
        for tag in balance_tags
    }

    # --- контекстный проход: note-in-cell, note-in-note, инлайновый note (FR-105..107) ---
    stack: list[str] = []  # 'note' | 'td'
    for i, line in enumerate(masked_lines, 1):
        s = line.strip()
        # инлайновый <note ...>...</note> в одну строку
        if re.search(r"<note\b[^>]*>.*</note>", s):
            E(i, "Инлайновый <note>…</note> в одну строку → нужен блочный формат "
                 "(<note …> ⏎ пустая ⏎ текст ⏎ пустая ⏎ </note>)")
        if re.match(r"^<note\b[^>]*>$", s):
            if "td" in stack:
                E(i, "<note> внутри ячейки <td>/<th> → сбой рендера. "
                     "Вынесите в инлайн: **Заголовок.** текст")
            if "note" in stack:
                E(i, "<note> вложен в другой <note> → сбой рендера. "
                     "Разверните во внешнюю заметку (**Заголовок:** + содержимое)")
            stack.append("note")
        elif s == "</note>":
            for k in range(len(stack) - 1, -1, -1):
                if stack[k] == "note":
                    del stack[k]
                    break
        elif re.match(r"^<t[dh]\b[^>]*>$", s):
            stack.append("td")
        elif re.match(r"^</t[dh]>$", s):
            for k in range(len(stack) - 1, -1, -1):
                if stack[k] == "td":
                    del stack[k]
                    break

    # --- построчные проверки (FR-104, FR-108, FR-111) ---
    th_killer_fired = False
    for i, line in enumerate(masked_lines, 1):
        s = line.strip()
        # <th> — киллер (FR-104); поглощает баланс th в этом файле (ADR-0019 Решение 3)
        if re.search(r"</?th\b", s):
            th_killer_fired = True
            hint = killer_hint.get("th", "")
            msg = "Тег <th> не поддерживается Gramax → HTTP 500."
            if hint:
                msg += f" {hint}"
            E(i, msg)
        # несколько картинок в одной строке (FR-108)
        if s.count("![](") > 1:
            E(i, "Несколько ![](…) в одной строке не рендерятся. "
                "Каждое изображение — на отдельной строке")
        # H1 в теле — стиль (FR-111), не краш рендера
        if re.match(r"^#\s", s):
            W(i, "H1 (# …) в теле: заголовок страницы берётся из frontmatter title. "
                "Используйте ## и ниже")

    # --- баланс парных тегов (FR-109); th-баланс подавляется, если киллер уже зафлагован ---
    for tag, (open_re, close_re) in balance_res.items():
        if tag == "th" and th_killer_fired:
            continue
        opens = closes = 0
        first_bad = 0
        for i, line in enumerate(masked_lines, 1):
            opens += len(open_re.findall(line))
            closes += len(close_re.findall(line))
            if opens != closes and first_bad == 0:
                first_bad = i
        if opens != closes:
            E(first_bad, f"Несбалансированный <{tag}>: открыто {opens}, закрыто {closes}")

    # --- frontmatter: title с ': ' без кавычек (FR-112) ---
    if raw_lines and raw_lines[0].strip() == "---":
        for idx, l in enumerate(raw_lines[1:], 2):
            if l.strip() == "---":
                break
            m = re.match(r"^title:\s*(.+)$", l)
            if m:
                val = m.group(1).strip()
                if ": " in val and not (val.startswith('"') or val.startswith("'")):
                    W(idx, "frontmatter title содержит ': ' без кавычек → ломает YAML, "
                          "страница пустая. Закавычьте")

    return errors, warns


# ===== CLI ===========================================================================

def collect_targets(paths: list[Path]) -> list[Path]:
    """Разворачивает аргументы в детерминированный (отсортированный) список .md-файлов."""
    targets: set[Path] = set()
    for p in paths:
        if p.is_dir():
            targets.update(q for q in p.rglob("*.md") if ".gramax" not in q.parts)
        else:
            targets.add(p)
    return sorted(targets)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Линтер рендер-киллеров Gramax (порт validate-gramax.py, MIT).",
        epilog=EPILOG,
    )
    parser.add_argument("paths", nargs="+", type=Path,
                        help="Файлы .md и/или каталоги Gramax.")
    parser.add_argument("--errors-only", action="store_true",
                        help="Показывать только ERROR (WARN подавляются; exit-контракт не меняется).")
    args = parser.parse_args()

    rules = load_render_rules()

    for p in args.paths:
        if not p.exists():
            print(f"validate_render: целевой путь не существует: {p}", file=sys.stderr)
            print("usage: validate_render.py <файл.md | каталог> [...]", file=sys.stderr)
            return 2

    targets = collect_targets(args.paths)
    if not targets:
        print("usage: validate_render.py <файл.md | каталог> [...]", file=sys.stderr)
        return 2

    total_err = 0
    for path in targets:
        errors, warns = check(path, rules)
        total_err += len(errors)
        if not errors and not warns:
            print(f"OK   {path}")
            continue
        if errors:
            print(f"FAIL {path}")
            for ln, msg in errors:
                print(f"  ERROR L{ln}: {msg}")
            if not args.errors_only:
                for ln, msg in warns:
                    print(f"  warn  L{ln}: {msg}")
        elif not args.errors_only:
            # Файл только с WARN: печатаем, только если WARN не подавлены.
            print(f"WARN {path}")
            for ln, msg in warns:
                print(f"  warn  L{ln}: {msg}")

    print(f"\nИтого: файлов={len(targets)}, ERROR={total_err}")
    return 1 if total_err else 0


if __name__ == "__main__":
    sys.exit(main())
