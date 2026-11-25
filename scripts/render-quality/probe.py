#!/usr/bin/env python3
"""probe.py — вход прибора рендер-проб (дизайн, Решения 2/5).

CLI, порядок именованных отказов (цель -> импорт playwright -> запуск браузера),
оркестрация тиров tier-0/1/2, агрегат вердикта, rc. rc-семантика: 0 — расхождений
нет; 1 — есть расхождения (отчёт написан); 2 — именованный отказ окружения
(баннер REFUSAL <КОД>: <подсказка> в stderr, stdout пуст, файл отчёта не пишется;
ADR-0029 Решение 5, строка 7).
"""

import argparse
import json
import sys
from pathlib import Path

import config
import report
import tier0_http
import tier1_dom
import tier2_shots

ROOT = Path(__file__).resolve().parents[2]  # scripts/render-quality/probe.py -> корень репо
DEFAULT_FIXTURES = ROOT / "tests" / "gramax" / "render-quality" / "fixtures"
DEFAULT_REPORT = ROOT / "tests" / "gramax" / "render-quality" / "results" / "report.md"

HINT_UNSET = (
    "создай scripts/render-quality/render-target.local.json по образцу "
    "scripts/render-quality/render-target.example.json (хост вне git — FR-195/ADR-0014) "
    "или задай GRAMAX_RENDER_BASE_URL; прогрев окружения: "
    "bash scripts/render-quality/warm.sh"
)
HINT_UNAVAILABLE = (
    "запускай замер через bash scripts/render-quality/live.sh "
    "(uv добавляет --with playwright); прогрев: bash scripts/render-quality/warm.sh"
)
HINT_NO_BROWSER = (
    "прогрей браузер: bash scripts/render-quality/warm.sh "
    "(исполняет playwright install chromium)"
)
HINT_UNREACHABLE = (
    "цель не достигнута ни по одной странице (все факты tier-0 = NETWORK_ERR): "
    "проверь сеть, VPN и baseUrl конфига цели, затем повтори "
    "bash scripts/render-quality/live.sh"
)


def refuse(code: str, hint: str) -> None:
    """Именованный отказ: баннер в stderr, rc=2, отчёт не пишется (дизайн, Решение 2;
    поток stderr — ADR-0029 Решение 5, строка 7: stdout при rc=2 пуст)."""
    sys.stderr.write("REFUSAL %s: %s\n" % (code, hint))
    sys.exit(2)


def _hint_invalid(exc: config.TargetRefusal) -> str:
    return "почини поле '%s' в '%s'; формат — render-target.example.json" % (
        exc.field, exc.source,
    )


def resolve_target(explicit_path: str):
    try:
        return config.resolve(explicit_path)
    except config.TargetRefusal as exc:
        if exc.code == config.RENDER_TARGET_UNSET:
            refuse(config.RENDER_TARGET_UNSET, HINT_UNSET)
        refuse(config.RENDER_TARGET_INVALID, _hint_invalid(exc))


def load_fixtures(fixtures_dir: Path) -> list:
    """Слаги (сортировка — NFR-077) и ожидания; расхождение пары — divergence-строка."""
    entries = []
    for md_path in sorted(fixtures_dir.glob("*.md")):
        slug = md_path.stem
        expect_path = fixtures_dir / (slug + ".expect.json")
        entries.append((slug, _load_expect(expect_path)))
    return entries


def _load_expect(expect_path: Path):
    try:
        data = json.loads(expect_path.read_text(encoding="utf-8"))
        # JSON, валидный, но не объект (`[]`, `null`, `"x"`), — как нечитаемый файл
        # (ADR-0028, поправка r3): None ведёт к именованной строке расхождения
        # «expect.json не читается», а не к AttributeError на .get ниже.
        if not isinstance(data, dict):
            return None
        expect = data.get("expect") or {}
        return {
            "tier0": str(expect.get("tier0", "")),
            "tier1": str(expect.get("tier1", "any")),
            "asserts": list(expect.get("asserts") or []),
        }
    except (OSError, ValueError):
        return None


def tier0_match(fact, expect_tier0: str) -> bool:
    """Матч факт-состояния с ожиданием (дизайн, «Двухслойная семантика»)."""
    if fact.state in (tier0_http.STATE_NOT_FOUND, tier0_http.STATE_HTTP_4XX,
                      tier0_http.STATE_NETWORK_ERR):
        return False  # недоступность страницы — расхождение всегда
    if expect_tier0 == "ok":
        return fact.state == tier0_http.STATE_OK
    if expect_tier0 == "kill":
        return fact.state == tier0_http.STATE_STABLE_5XX
    if expect_tier0 == "either":
        return fact.state in (tier0_http.STATE_OK, tier0_http.STATE_STABLE_5XX)
    return False


def _open_browser(viewport: tuple, headers: dict):
    """Импорт playwright -> запуск chromium (лестница отказов, Решение 2)."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        refuse("PLAYWRIGHT_UNAVAILABLE", HINT_UNAVAILABLE)
    try:
        driver = sync_playwright().start()
        browser = driver.chromium.launch(headless=True)
    except Exception:
        refuse("PLAYWRIGHT_NO_BROWSER", HINT_NO_BROWSER)
    context = browser.new_context(
        viewport={"width": viewport[0], "height": viewport[1]},
        extra_http_headers=headers or None,
    )
    return driver, browser, context


def run_check_env(target) -> int:
    """--check-env: цель -> импорт playwright -> браузер; без тиров и отчёта."""
    driver, browser, _context = _open_browser(target.viewport, target.auth_header())
    browser.close()
    driver.stop()
    print("check-env: OK (цель, импорт playwright, запуск chromium)")
    return 0


def run_probes(target, args) -> int:
    """Полный прогон: tier-0 -> tier-1/tier-2 -> агрегат -> отчёт -> rc."""
    fixtures_dir = Path(args.fixtures)
    entries = load_fixtures(fixtures_dir)
    slugs = [slug for slug, _expect in entries]
    facts = tier0_http.probe_all(target, slugs, args.retry, args.retry_wait, args.jobs)

    # ADR-0027 Решение 2: полная недоступность цели (каждый факт tier-0 = NETWORK_ERR) —
    # именованный отказ до тиров 1-2, rc=2, отчёт не пишется: «не измерено» не подаётся
    # как «измерено и разошлось». Частичная недоступность и NOT_FOUND остаются rc=1
    # с нотами постранично.
    if facts and all(f.state == tier0_http.STATE_NETWORK_ERR for f in facts.values()):
        # Цель из конфига названа в баннере (FR-188 «Гигиена хоста»: цель не хардкодится
        # и видна в выводе — стаб ac-105).
        refuse("RENDER_TARGET_UNREACHABLE",
               "%s (цель из конфига: %s)" % (HINT_UNREACHABLE, target.base_url))

    needs_browser = ("tier1" in target.tiers or "tier2" in target.tiers)
    driver = browser = context = None
    if needs_browser:
        driver, browser, context = _open_browser(target.viewport, target.auth_header())

    rows = []
    match_count = 0
    try:
        for slug, expect in entries:
            row = _probe_row(target, context, slug, expect, facts.get(slug), args)
            if row["verdict"] == "match":
                match_count += 1
            rows.append(row)
    finally:
        if browser is not None:
            browser.close()
            driver.stop()

    divergence_count = len(rows) - match_count
    header = {
        "base_url": target.base_url,
        "catalog": target.catalog,
        "source": target.source,
        "tiers": target.tiers,
        "fixtures_root": str(fixtures_dir),
        "summary": {
            "fixtures": len(rows),
            "match": match_count,
            "divergence": divergence_count,
        },
    }
    text = report.render(header, rows)
    report.write(args.report, text)
    sys.stdout.write(text)
    return 1 if divergence_count else 0


def _probe_row(target, context, slug: str, expect, fact, args) -> dict:
    note = " / ".join(fact.notes) if fact.notes else ""
    # ADR-0029 Решение 5, строка 1: проверка expect is None — первой, до любого
    # чтения expect[...]: нечитаемый expect.json — именованная строка расхождения
    # с нотой «expect.json не читается», не TypeError.
    if expect is None:
        note = " / ".join(part for part in (note, "expect.json не читается") if part)
        expect_tier0 = "?"
        t0_verdict = "divergence"
    else:
        t0_verdict = "match" if tier0_match(fact, expect["tier0"]) else "divergence"
        expect_tier0 = expect["tier0"] or "?"

    row = {
        "slug": slug,
        "verdict": t0_verdict,
        "tier0": {
            "label": fact.label,
            "code": fact.code,
            "expect": expect_tier0,
            "verdict": t0_verdict,
            "note": note,
        },
        "tier1_line": None,
        "tier2_line": None,
    }

    page = None
    tier1_result = None
    tier1_judged = (
        expect is not None
        and fact.is_ok
        and "tier1" in target.tiers
        and expect["tier1"] in ("pass", "fail")
        and expect["asserts"]
    )
    wants_shot = expect is not None and fact.is_ok and "tier2" in target.tiers
    if tier1_judged or wants_shot:
        page = context.new_page()
        try:
            if tier1_judged:
                tier1_result = tier1_dom.evaluate(page, target.page_url(slug), expect["asserts"])
            if wants_shot:
                shot_path = tier2_shots.shots_dir(args.report) / (slug + ".png")
                if tier2_shots.capture(page, shot_path):
                    row["tier2_line"] = "screenshots/%s.png" % slug
                else:
                    row["tier2_line"] = "missing"
        finally:
            page.close()

    if "tier1" in target.tiers:
        if not fact.is_ok:
            row["tier1_line"] = "skip (tier0 %s)" % fact.label
        elif expect is None or expect["tier1"] == "any" or not expect["asserts"]:
            row["tier1_line"] = "any (не судится)"
        else:
            row["tier1_line"] = tier1_dom.verdict_line(tier1_result, expect["tier1"])
            if tier1_result is not None:
                tier1_match = tier1_result["ok"] if expect["tier1"] == "pass" \
                    else not tier1_result["ok"]
                if not tier1_match:
                    row["verdict"] = "divergence"
    if "tier2" in target.tiers and not fact.is_ok:
        row["tier2_line"] = "skip (tier0 %s)" % fact.label
    return row


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Прибор рендер-проб Playwright (tier-0 HTTP, tier-1 DOM, tier-2 скриншоты)",
    )
    parser.add_argument("--config", default="", help="путь конфига цели (шов для тестов)")
    parser.add_argument("--fixtures", default=str(DEFAULT_FIXTURES), help="каталог фикстур")
    parser.add_argument("--report", default=str(DEFAULT_REPORT), help="путь отчёта")
    parser.add_argument("--check-env", action="store_true",
                        help="только проверки окружения (цель, playwright, браузер)")
    parser.add_argument("--retry", type=int, default=2, help="ретраи только по >=500")
    parser.add_argument("--retry-wait", type=float, default=5.0,
                        help="пауза между ретраями, сек (операционная, не окно)")
    parser.add_argument("--jobs", type=int, default=8, help="параллелизм tier-0")
    args = parser.parse_args()

    if not args.check_env and not Path(args.fixtures).is_dir():
        parser.error("--fixtures: каталог не найден: %s" % args.fixtures)

    target = resolve_target(args.config)
    if args.check_env:
        return run_check_env(target)
    return run_probes(target, args)


if __name__ == "__main__":
    sys.exit(main())
