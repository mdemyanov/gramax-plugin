"""tier1_dom.py — DOM-ассерты по ожиданиям фикстуры (дизайн, Решения 4/5).

Ленивый import playwright — модуль импортируется без браузера, отказы
RENDER_TARGET_* работают и без прогретого окружения. Примитив ассерта один:
{"name", "selector", "count"} — фактический счётчик селектора на отрисованной
человекочитаемой странице (pageUrlTemplate) сверяется с ожиданием.
"""

try:  # ленивый дом зависимости: ImportError судит вызывающий (PLAYWRIGHT_UNAVAILABLE)
    from playwright.sync_api import Error as PlaywrightError
except ImportError:  # pragma: no cover — путь именованного отказа, не ветка тестов
    PlaywrightError = Exception


def evaluate(page, url: str, asserts: list) -> dict:
    """Открыть страницу и сверить ассерты.

    Возвращает {"passed": int, "ok": bool, "failed": str | None}:
    failed — имя первого не сошедшего ассерта (вердикт тира назван, FR-191).
    """
    page.goto(url, wait_until="load")
    passed = 0
    failed = None
    for entry in asserts:
        name = str(entry.get("name", ""))
        selector = str(entry.get("selector", ""))
        expected = int(entry.get("count", 0))
        try:
            actual = page.locator(selector).count()
        except PlaywrightError:
            actual = -1
        if actual == expected:
            passed += 1
        elif failed is None:
            failed = name or selector
    return {"passed": passed, "ok": failed is None, "failed": failed}


def verdict_line(result, expect_tier1: str) -> str:
    """Строка тира-1 отчёта: pass (N asserts) | fail (assert <имя>) | any (не судится)."""
    if expect_tier1 == "any":
        return "any (не судится)"
    if result is None:
        return "any (не судится)"
    if result["ok"]:
        return "pass (%d asserts)" % result["passed"]
    return "fail (assert %s)" % result["failed"]
