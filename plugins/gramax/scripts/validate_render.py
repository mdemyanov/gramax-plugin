#!/usr/bin/env python3
"""
validate_render.py — линтер рендер-киллеров Gramax.

Обнаруживает конструкции markdown, которые роняют рендерер GES (HTTP 500) или ломают
вёрстку: инлайновый `<note>…</note>`, многострочный `<colgroup>`, несколько `![](…)`
в одной строке, несбалансированные парные теги. Стиль/YAML-проблемы (H1 в теле,
frontmatter `title:` без кавычек, `<note>` внутри `<td>`, `<note>` вложенный в
`<note>`) — WARN. `<th>` — WARN с 4.9.0: запись контракта несёт severity warn.

Запись killerTags контракта может нести необязательный атрибут `"severity": "warn"`
(дизайн волны-2, Решение 4): такой киллер даёт WARN вместо ERROR и не подавляет
проверку баланса своего тега; отсутствие атрибута — дефолт «error», поведение
неизменное. Судьба вердикта меняется только замером против факта рендера (BR-021).
Действующая запись `gramax-render-rules.json` несёт `<th>` с `severity: warn`
(с 4.9.0; замер носителя 2026-11-21 — HTTP 200): WARN-находка с подсказкой замены
на `<td>`, шапку задаёт `header="row"` у `<table>`; ERROR-ветка ниже — запасной
текст на случай записи контракта с severity «error», не действующее правило.

Порт правил `validate-gramax.py` плагина `gramax-skills` — © Всеволод Шадрин, MIT.
Полный текст MIT-лицензии, provenance и список изменений относительно upstream —
`LICENSE.upstream.md` рядом со скриптом (ADR-0019, Решение 7, NFR-006).

Файл, не являющийся валидным UTF-8, не обрывает прогон traceback'ом: `check()`
возвращает одну ошибку на строке 0 (`ERROR L0: Файл не является валидным UTF-8 (…)`
— форма апстрим-линтера), остальные файлы каталога проверяются, rc=1
(ADR-0026 Решение 6, FR-212; чтение — общий примитив `lib/read_page.py`).

Контракт киллеров/баланса/allowlist — `gramax-render-rules.json` (корень плагина),
машиночитаемый реестр эмпирических инцидентов (ADR-0019, Решение 2, BR-002/BR-003).
Повреждённый/отсутствующий контракт — явный error, не молчаливый fallback
(ADR-0012, Consequences). Маскирование кода (fenced + inline) и тела блоков сырого
HTML `<html>…</html>` — общий примитив `lib/md_code_mask.py` (ADR-0019, Решение 5;
FR-216): примеры синтаксиса в прозе и легальные HTML-теги внутри html-блока не
считаются разметкой страницы.

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

from lib.md_code_mask import _mask_code, _mask_html_blocks
from lib.read_page import read_page

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

    Все проверки работают по замаскированному тексту (fenced + inline-код и тело
    блоков `<html>…</html>` заменены пробелами той же длины) — кроме
    frontmatter-титла, который кодом не бывает.

    Файл с битым UTF-8 (ADR-0026 Решение 6, FR-212) даёт ровно одну ошибку на
    строке 0 с путём-агностным сообщением — форма апстрим-линтера дословно;
    файл не читается дальше, обход вызывающим кодом продолжается.
    """
    text, read_err = read_page(path)
    errors: list[tuple[int, str]] = []
    warns: list[tuple[int, str]] = []
    if read_err is not None:
        return [(0, f"Файл не является валидным UTF-8 "
                    f"(байт 0x{read_err.byte_hex} на позиции {read_err.start} из {read_err.size})")], warns
    raw_lines = text.split("\n")
    masked = _mask_html_blocks(_mask_code(text))
    masked_lines = masked.split("\n")

    def E(ln: int, msg: str) -> None:
        errors.append((ln, msg))

    def W(ln: int, msg: str) -> None:
        warns.append((ln, msg))

    killer_hint: dict[str, str] = {
        item.get("tag"): item.get("message", "")
        for item in rules.get("killerTags", [])
        if isinstance(item, dict) and item.get("tag")
    }
    # Селективная severity киллера (дизайн волны-2, Решение 4): необязательный атрибут
    # "severity": "warn" у записи killerTags переводит этот киллер в W(); отсутствие
    # атрибута — дефолт "error", поведение байт-в-байт прежнее. Поглощение th-баланса
    # сохраняется только за ERROR-киллером — warn баланс th не подавляет (NFR-083).
    killer_severity: dict[str, str] = {
        item.get("tag"): str(item.get("severity") or "error")
        for item in rules.get("killerTags", [])
        if isinstance(item, dict) and item.get("tag")
    }
    th_severity = killer_severity.get("th", "error")
    balance_tags: list[str] = rules.get("balanceTags", []) or []
    balance_res = {
        tag: (
            re.compile(r"<" + tag + r"(?:\s[^>]*)?(?<!/)>"),
            re.compile(r"</" + tag + r">"),
        )
        for tag in balance_tags
    }

    # --- контекстный проход: инлайновый note → ERROR (FR-105/107); note-in-cell и
    # note-in-note → WARN с 2026-11-21 (калибровка по факту рендера, FR-196:
    # docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md) ---
    stack: list[str] = []  # 'note' | 'td'
    for i, line in enumerate(masked_lines, 1):
        s = line.strip()
        # инлайновый <note ...>...</note> в одну строку
        if re.search(r"<note\b[^>]*>.*</note>", s):
            E(i, "Инлайновый <note>…</note> в одну строку → нужен блочный формат "
                 "(<note …> ⏎ пустая ⏎ текст ⏎ пустая ⏎ </note>)")
        if re.match(r"^<note\b[^>]*>$", s):
            if "td" in stack:
                W(i, "<note> внутри ячейки <td>/<th> — ширины колонок плывут, читается "
                     "плохо. Вынесите в инлайн: **Заголовок.** текст")
            if "note" in stack:
                W(i, "<note> вложен в <note> — вложенные заметки схлопываются. "
                     "Разверните во внешнюю заметку")
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

    # --- построчные проверки (FR-104, FR-108, FR-111; многострочный colgroup —
    # калибровка 2026-11-21, FR-196, см. запись замера по пути из шапки контекстного
    # прохода) ---
    th_error_killer_fired = False
    for i, line in enumerate(masked_lines, 1):
        s = line.strip()
        # многострочный <colgroup>: открывающий тег занимает строку целиком —
        # подтверждённый киллер («500 до правки, 200 после», калибровка FR-196;
        # механика апстрима validate-gramax.py:154-156). Однострочная форма легальна —
        # allowlist colgroup/col в gramax-render-rules.json не меняется.
        if re.match(r"^<colgroup>$", s):
            E(i, "Многострочный <colgroup> → HTTP 500. Схлопните в одну строку")
        # <th> — киллер (FR-104); ERROR-киллер поглощает баланс th в этом файле
        # (ADR-0019 Решение 3); warn-киллер (severity="warn" в контракте) баланс
        # th не подавляет (дизайн волны-2, Решение 4; NFR-083)
        if re.search(r"</?th\b", s):
            hint = killer_hint.get("th", "")
            if th_severity == "warn":
                # WARN-семантика (рекомендация, не констатация сбоя рендера): текст
                # несёт сообщение записи контракта (подсказка замены живёт там же),
                # фолбэк — на случай записи без message (дизайн волны-2, Решение 4;
                # точную формулировку фиксирует цикл понижения)
                msg = hint or ("Тег <th> — потенциальный киллер апстрима, "
                               "не подтверждённый на этой цели.")
                W(i, msg)
            else:
                th_error_killer_fired = True
                # Запасной текст ветки severity «error» (контракт мог быть изменён
                # замером), не действующее правило: действующая запись контракта несёт th
                # с severity warn с 4.9.0 (gramax-render-rules.json)
                msg = ("Тег <th> помечен в контракте ERROR-киллером "
                       "(запасной текст; действующая запись gramax-render-rules.json "
                       "несёт th с severity warn с 4.9.0).")
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

    # --- баланс парных тегов (FR-109); th-баланс подавляется только ERROR-киллером ---
    for tag, (open_re, close_re) in balance_res.items():
        if tag == "th" and th_error_killer_fired:
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
