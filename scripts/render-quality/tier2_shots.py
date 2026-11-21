"""tier2_shots.py — скриншоты в фиксированном viewport (дизайн, Решения 4/5).

Артефактный тир: скриншот — материал для человека-разборщика, в агрегат
вердикта не входит (FR-192). Ленивый import playwright. Viewport фиксирован
конфигом контекста (NFR-077); страница уже открыта проходом tier-1.
"""

from pathlib import Path

try:  # ленивый дом зависимости: ImportError судит вызывающий (PLAYWRIGHT_UNAVAILABLE)
    from playwright.sync_api import Error as PlaywrightError
except ImportError:  # pragma: no cover — путь именованного отказа, не ветка тестов
    PlaywrightError = Exception


def shots_dir(report_path) -> Path:
    """Каталог артефактов = каталог отчёта (дом-раскладка results/screenshots/)."""
    return Path(report_path).resolve().parent / "screenshots"


def capture(page, path: Path) -> bool:
    """Снять скриншот страницы в заданный путь; True — артефакт написан."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        page.screenshot(path=str(path), full_page=False)
        return True
    except (PlaywrightError, OSError):
        return False
