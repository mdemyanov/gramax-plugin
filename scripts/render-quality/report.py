"""report.py — детерминированный отчёт прибора (дизайн, «Отчёт»; NFR-077).

Форма фиксирована дизайном: обход фикстур по алфавиту слага, без таймингов,
меток времени и идентификаторов прогона; два прогона подряд на неизменном
состоянии цели дают побайтно идентичный файл (AC-117). stdout зеркалит отчёт —
зеркалит probe.py, модуль только рендерит и пишет файл.
"""

from pathlib import Path


def _tier0_line(row: dict) -> str:
    fact = row["tier0"]
    head = "  tier0: %s (http %s) — expect %s → %s" % (
        fact["label"],
        fact["code"] if fact["code"] else "-",
        fact["expect"],
        fact["verdict"],
    )
    if fact.get("note"):
        head += "; note: %s" % fact["note"]
    return head


def render(header: dict, rows: list) -> str:
    """Собрать текст отчёта. rows уже отсортированы вызывающим (probe.py)."""
    lines = [
        "# render-quality report",
        "target: %s  catalog: %s  config: %s" % (
            header["base_url"], header["catalog"], header["source"],
        ),
        "tiers: %s  fixtures-root: %s" % (
            ",".join(header["tiers"]), header["fixtures_root"],
        ),
    ]
    for row in rows:
        lines.append("")
        lines.append("%s: %s" % (row["slug"], row["verdict"]))
        lines.append(_tier0_line(row))
        if row.get("tier1_line"):
            lines.append("  tier1: %s" % row["tier1_line"])
        if row.get("tier2_line"):
            lines.append("  tier2: %s" % row["tier2_line"])
    summary = header["summary"]
    lines.append("")
    lines.append(
        "summary: fixtures=%d match=%d divergence=%d" % (
            summary["fixtures"], summary["match"], summary["divergence"],
        )
    )
    lines.append("verdict: %s" % ("FAIL" if summary["divergence"] else "PASS"))
    return "\n".join(lines) + "\n"


def write(path: str, text: str) -> None:
    """Записать отчёт; каталог создаётся (шов --report стабов может быть в новом каталоге)."""
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
