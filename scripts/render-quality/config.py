"""config.py — разрешение и валидация цели рендера (дизайн, Решение 1).

Порядок разрешения: --config <путь> (флаг-шов) -> дефолтный
render-target.local.json -> env-поля поверх полей файла
(GRAMAX_RENDER_BASE_URL, GRAMAX_RENDER_CATALOG, GRAMAX_API_TOKEN).
Не найден ни файл, ни env -> именованный отказ RENDER_TARGET_UNSET;
конфиг есть, но дефектный -> RENDER_TARGET_INVALID с именем поля.
Проверка цели не требует playwright — идёт до любых обращений к нему.
"""

import json
import os
from pathlib import Path
from urllib.parse import urlsplit, quote

DEFAULT_TIERS = ("tier0", "tier1", "tier2")
KNOWN_TIERS = ("tier0", "tier1", "tier2")
PAGE_REQUIRED_TIERS = ("tier1", "tier2")
DEFAULT_API_TEMPLATE = "{base}/api/catalogs/{catalog}/articles/{slug}/html"
DEFAULT_VIEWPORT = {"width": 1280, "height": 720}

ENV_BASE_URL = "GRAMAX_RENDER_BASE_URL"
ENV_CATALOG = "GRAMAX_RENDER_CATALOG"
ENV_TOKEN = "GRAMAX_API_TOKEN"

RENDER_TARGET_UNSET = "RENDER_TARGET_UNSET"
RENDER_TARGET_INVALID = "RENDER_TARGET_INVALID"


class TargetRefusal(Exception):
    """Именованный отказ цели; code — RENDER_TARGET_*, field — дефектное поле."""

    def __init__(self, code: str, field: str = "", source: str = "") -> None:
        self.code = code
        self.field = field
        self.source = source
        super().__init__(code)


class Target:
    """Валидированная цель рендера. source — метка для отчёта (путь|env)."""

    def __init__(self, data: dict, source: str) -> None:
        self.base_url = data["baseUrl"]
        self.catalog = data["catalog"]
        self.api_template = data.get("apiArticleUrlTemplate") or DEFAULT_API_TEMPLATE
        self.page_template = data.get("pageUrlTemplate") or ""
        self.token = data.get("token") or None
        tiers = data.get("tiers") or list(DEFAULT_TIERS)
        self.tiers = list(tiers)
        viewport = data.get("viewport") or dict(DEFAULT_VIEWPORT)
        self.viewport = (int(viewport["width"]), int(viewport["height"]))
        self.source = source

    def api_url(self, slug: str) -> str:
        return _substitute(self.api_template, self.base_url, self.catalog, slug)

    def page_url(self, slug: str) -> str:
        return _substitute(self.page_template, self.base_url, self.catalog, slug)

    def auth_header(self) -> dict:
        if self.token:
            return {"Authorization": "Bearer " + str(self.token)}
        return {}


def _substitute(template: str, base_url: str, catalog: str, slug: str) -> str:
    return (
        template.replace("{base}", base_url.rstrip("/"))
        .replace("{catalog}", catalog)
        .replace("{slug}", quote(str(slug), safe=""))
    )


def _invalid(field: str, source: str) -> TargetRefusal:
    return TargetRefusal(RENDER_TARGET_INVALID, field=field, source=source)


def _load_json_file(path: Path, source: str) -> dict:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except OSError:
        # Путь задан явно (--config или дефолт), файл не читается — цель не установлена.
        raise TargetRefusal(RENDER_TARGET_UNSET, source=str(path)) from None
    except json.JSONDecodeError:
        raise _invalid("json", source) from None
    if not isinstance(data, dict):
        raise _invalid("json", source)
    return data


def _validate(data: dict, source: str) -> Target:
    base_url = data.get("baseUrl")
    if not isinstance(base_url, str) or not base_url.strip():
        raise _invalid("baseUrl", source)
    parts = urlsplit(base_url.strip())
    if parts.scheme not in ("http", "https") or not parts.netloc:
        raise _invalid("baseUrl", source)
    catalog = data.get("catalog")
    if not isinstance(catalog, str) or not catalog.strip():
        raise _invalid("catalog", source)
    tiers = data.get("tiers")
    if tiers is not None:
        if not isinstance(tiers, list) or not tiers:
            raise _invalid("tiers", source)
        for tier in tiers:
            if tier not in KNOWN_TIERS:
                raise _invalid("tiers", source)
    if any(tier in PAGE_REQUIRED_TIERS for tier in (tiers or DEFAULT_TIERS)):
        page_template = data.get("pageUrlTemplate")
        if not isinstance(page_template, str) or "{slug}" not in page_template:
            raise _invalid("pageUrlTemplate", source)
    token = data.get("token")
    if token is not None and not isinstance(token, str):
        raise _invalid("token", source)
    viewport = data.get("viewport")
    if viewport is not None:
        if not isinstance(viewport, dict):
            raise _invalid("viewport", source)
        for key in ("width", "height"):
            value = viewport.get(key)
            if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
                raise _invalid("viewport", source)
    return Target(data, source)


def resolve(explicit_path: str = "") -> Target:
    """Разрешить цель: --config -> дефолтный файл -> env-поля поверх файла."""
    if explicit_path:
        path = Path(explicit_path)
        if not path.is_file():
            raise TargetRefusal(RENDER_TARGET_UNSET, source=explicit_path)
        data = _load_json_file(path, explicit_path)
        return _validate(data, explicit_path)

    default_path = Path(__file__).resolve().parent / "render-target.local.json"
    if default_path.is_file():
        data = _load_json_file(default_path, str(default_path))
        # env-поля поверх полей файла (дизайн, Решение 1)
        if os.environ.get(ENV_BASE_URL):
            data["baseUrl"] = os.environ[ENV_BASE_URL]
        if os.environ.get(ENV_CATALOG):
            data["catalog"] = os.environ[ENV_CATALOG]
        if os.environ.get(ENV_TOKEN):
            data["token"] = os.environ[ENV_TOKEN]
        return _validate(data, str(default_path))

    base_url = os.environ.get(ENV_BASE_URL)
    if not base_url:
        raise TargetRefusal(RENDER_TARGET_UNSET, source="env")
    data = {"baseUrl": base_url}
    catalog = os.environ.get(ENV_CATALOG)
    if catalog:
        data["catalog"] = catalog
    if os.environ.get(ENV_TOKEN):
        data["token"] = os.environ[ENV_TOKEN]
    return _validate(data, "env")
