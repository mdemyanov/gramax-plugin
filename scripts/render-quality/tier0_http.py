"""tier0_http.py — HTTP-пробы цели, ретрай по >=500, факт-состояния (дизайн, Решение 6).

Чистый stdlib, браузера не требует. Ретрай только по >=500 — семантика
апстрим-оракула (RES-009 §4); 404/4xx и сетевые ошибки не ретраятся.
Параметры ретрая операционные (--retry N, --retry-wait SEC, --jobs N),
окно переиндексации числом не кодируется (NFR-080); ожидание между
попытками — threading.Event, без констант окна.

Факт-состояния: OK -> «OK 2xx»; устойчивый 5xx -> «STABLE_5XX»;
404 -> «NOT_FOUND 404»; прочие 4xx -> «HTTP_4XX»; сетевая ошибка -> «NETWORK_ERR».
"""

import concurrent.futures
import threading
import urllib.error
import urllib.request
from urllib.parse import urlsplit

STATE_OK = "OK"
STATE_STABLE_5XX = "STABLE_5XX"
STATE_NOT_FOUND = "NOT_FOUND"
STATE_HTTP_4XX = "HTTP_4XX"
STATE_NETWORK_ERR = "NETWORK_ERR"

# Отображение состояния в форму отчёта (дизайн, «Отчёт»; at-design: имена дословно)
STATE_LABELS = {
    STATE_OK: "OK 2xx",
    STATE_STABLE_5XX: "STABLE_5XX",
    STATE_NOT_FOUND: "NOT_FOUND 404",
    STATE_HTTP_4XX: "HTTP_4XX",
    STATE_NETWORK_ERR: "NETWORK_ERR",
}

NOTE_REINDEX_CANDIDATE = (
    "кандидат на переиндексацию после пуша; окно gram.ax не установлено (RES-009 §6, NFR-080)"
)
NOTE_RETRY_RESOLVED = "решён ретраем"
NOTE_404 = (
    "404 сразу после пуша — обычно переиндексация (RES-009 §4); проверь пуш фикстур в каталог цели"
)
NOTE_TOKEN = "401/403 — проверь токен цели (NFR-081)"
NOTE_NETWORK = "сетевая ошибка — проверь доступ к внутреннему хосту цели"

REQUEST_TIMEOUT_SEC = 60  # прецедент апстрим-оракула (RES-009 §4)


class Fact:
    """Факт tier-0 по одной фикстуре: состояние, последний код, ноты."""

    def __init__(self, state: str, code: int = 0, notes: tuple = ()) -> None:
        self.state = state
        self.code = code
        self.notes = tuple(notes)

    @property
    def label(self) -> str:
        return STATE_LABELS[self.state]

    @property
    def is_ok(self) -> bool:
        return self.state == STATE_OK


def _wait(seconds: float) -> None:
    # Ожидание без цикла-занятости; окно переиндексации не кодируется (NFR-080).
    threading.Event().wait(seconds)


def _fetch(url: str, headers: dict) -> int:
    request = urllib.request.Request(url, headers=headers, method="GET")
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SEC) as response:
        return int(response.status)


def probe_one(url: str, headers: dict, retry: int, retry_wait: float) -> Fact:
    """Одна проба: GET, bounded retry только по >=500, именованный факт."""
    code = 0
    saw_5xx = False
    attempts = retry + 1
    for attempt in range(attempts):
        try:
            code = _fetch(url, headers)
        except urllib.error.HTTPError as exc:
            code = int(exc.code)
        except Exception:  # сетевой класс: URLError, timeouts, сокеты — не ретраится
            return Fact(STATE_NETWORK_ERR, code=0, notes=(NOTE_NETWORK,))
        if code < 500:
            break
        saw_5xx = True
        if attempt + 1 < attempts:
            _wait(retry_wait)
    if code >= 500:
        return Fact(STATE_STABLE_5XX, code=code, notes=(NOTE_REINDEX_CANDIDATE,))
    notes = []
    if saw_5xx:
        notes.append(NOTE_RETRY_RESOLVED)
    if code == 404:
        notes.append(NOTE_404)
        return Fact(STATE_NOT_FOUND, code=code, notes=tuple(notes))
    if 400 <= code < 500:
        if code in (401, 403):
            notes.append(NOTE_TOKEN)
        return Fact(STATE_HTTP_4XX, code=code, notes=tuple(notes))
    return Fact(STATE_OK, code=code, notes=tuple(notes))


def probe_all(target, slugs, retry: int, retry_wait: float, jobs: int) -> dict:
    """Пробы по всем слагам (api_url), параллельно; результат slug -> Fact."""
    headers = {"User-Agent": "render-quality-probe"}
    headers.update(target.auth_header())

    def work(slug: str) -> tuple:
        return slug, probe_one(target.api_url(slug), headers, retry, retry_wait)

    results = {}
    if jobs <= 1 or len(slugs) <= 1:
        for slug in slugs:
            results[slug] = probe_one(target.api_url(slug), headers, retry, retry_wait)
        return results
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(work, slug) for slug in slugs]
        for future in concurrent.futures.as_completed(futures):
            slug, fact = future.result()
            results[slug] = fact
    return results


def assert_target_scheme(target) -> None:
    """Защитная проверка схемы цели перед запросами (http/https)."""
    parts = urlsplit(target.base_url)
    if parts.scheme not in ("http", "https"):
        raise ValueError("target scheme must be http or https")
