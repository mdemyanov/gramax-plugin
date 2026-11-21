#!/usr/bin/env python3
"""lib/stub_portal.py — офлайн-стаб портала для стабов сюиты render-quality.

stdlib http.server на 127.0.0.1 (только loopback); таблица «слаг → код/HTML» читается
из routes-файла (--routes). Живые ответы портала заменяются каноническими кодами и
минимальным HTML — стабы детерминированы и офлайн (дизайн, «Контракт с QA-author»).

Форма пути оракула (RES-009 §4): GET {base}/api/catalogs/{catalog}/articles/{slug}/html —
слаг извлекается из предпоследнего сегмента пути; прочие пути — слаг = последний сегмент
(без хвостового сегмента `html`).

Формат routes-файла (JSON):

    {
      "defaultCode": 200,
      "defaultHtml": "<html><body><p>stub portal</p></body></html>",
      "slugs": {
        "control-clean": {"codes": [200], "html": "<html>...</html>"},
        "killer-th":     {"codes": [500], "html": ""},
        "reindex-flaky": {"codes": [500, 200], "html": "<html>...</html>"}
      }
    }

`codes` — последовательность кодов по порядку запросов данного слага; последний код
повторяется (500, 200 — «решён ретраем»; 500, 500 — устойчивый STABLE_5XX). Состояние
последовательностей живёт в памяти процесса — каждый запуск сервера начинает их заново
(детерминизм стаба).

Запуск:

    python3 lib/stub_portal.py --port 0 --routes FILE

Готовность: строка `STUB_READY port=<N>` в stdout, флаш сразу; дальше stdout молчит
(журнал запросов подавлен). Завершение: SIGTERM/SIGINT — чистый выход 0 (cleanup-трап
вызывающего стаба убивает процесс). Сеть — только 127.0.0.1, никаких внешних обращений.
"""

import argparse
import json
import signal
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote

DEFAULT_HTML = "<html><body><p>stub portal</p></body></html>"
DEFAULT_CODE = 200


def extract_slug(path: str) -> str:
    """Слаг из пути оракула или последнего сегмента пути (RES-009 §4)."""
    segments = [seg for seg in path.split("/") if seg]
    if not segments:
        return ""
    if len(segments) >= 2 and segments[-1] == "html":
        return unquote(segments[-2])
    return unquote(segments[-1])


class PortalState:
    """Таблица «слаг → код/HTML» и счётчики последовательностей (потокобезопасно)."""

    def __init__(self, routes: dict) -> None:
        slugs = routes.get("slugs", {})
        if not isinstance(slugs, dict):
            raise SystemExit("routes: поле 'slugs' обязано быть JSON-объектом")
        self._slugs = slugs
        self._counters: dict = {}
        self._lock = threading.Lock()
        self.default_code = int(routes.get("defaultCode", DEFAULT_CODE))
        self.default_html = str(routes.get("defaultHtml", DEFAULT_HTML))

    def next_response(self, slug: str) -> tuple[int, str]:
        """Следующий (код, html) для слага; последний код последовательности повторяется."""
        with self._lock:
            entry = self._slugs.get(slug)
            if entry is None:
                return self.default_code, self.default_html
            codes = entry.get("codes", [DEFAULT_CODE])
            index = self._counters.get(slug, 0)
            self._counters[slug] = index + 1
            code = codes[index] if index < len(codes) else codes[-1]
            return int(code), str(entry.get("html", self.default_html))


class StubPortalHandler(BaseHTTPRequestHandler):
    state: PortalState

    def do_GET(self) -> None:  # noqa: N802 — имя фиксирует http.server
        slug = extract_slug(self.path)
        code, html = self.state.next_response(slug)
        body = html.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:  # подавление журнала запросов
        pass


def main() -> int:
    parser = argparse.ArgumentParser(description="Офлайн-стаб портала (127.0.0.1, stdlib)")
    parser.add_argument("--port", type=int, default=0,
                        help="порт; 0 — эфемерный (адрес печатается в STUB_READY)")
    parser.add_argument("--routes", required=True, help="routes-JSON: слаг → коды/HTML")
    args = parser.parse_args()

    try:
        routes = json.loads(Path(args.routes).read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        print(f"STUB_ERROR routes unreadable: {exc}", file=sys.stderr)
        return 2
    if not isinstance(routes, dict):
        print("STUB_ERROR routes must be a JSON object", file=sys.stderr)
        return 2

    state = PortalState(routes)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), StubPortalHandler)
    server.daemon_threads = True
    StubPortalHandler.state = state

    def _stop(signum, frame) -> None:
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)

    print(f"STUB_READY port={server.server_address[1]}", flush=True)
    try:
        server.serve_forever()
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
