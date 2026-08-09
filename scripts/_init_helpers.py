#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pyyaml>=6.0,<7.0",
# ]
# ///
"""_init_helpers.py — helper для init.sh: парсинг manifest.yaml, форматирование меню.

Subcommands:
  list-profiles           — JSON-массив профилей {name, description, audience, status}
  menu-max-len            — max длина name из JSON на stdin
  menu-format --max-len N — форматированные строки меню из JSON на stdin
  profile-summary <prof>  — bulleted summary профиля
  init-prompts <prof>     — JSON-массив prompt-объектов
  prompt-field <i> <fld>  — значение поля prompt по индексу (JSON на stdin)
  compat-stacks <prof>    — compatible_stacks через запятую
  slugify <name>          — kebab-case slug; exit 1 если пусто
  detect-plugin-state     — JSON {slug, marketplace, inconsistent}; exit 0 OK, 1 при ошибке чтения
  rename-marketplace <slug> — mutate marketplace.json под slug
  rename-plugin-json <slug> — mutate plugin.json под slug
  rename-settings <slug>    — mutate settings.json под slug

CLI: uv run scripts/_init_helpers.py <subcommand> [args...]
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from pathlib import Path


def load_manifest(profile: str) -> dict:
    """Загрузить manifest.yaml для профиля."""
    import yaml  # noqa: PLC0415
    mf = f"docs/overlays/profiles/{profile}/manifest.yaml"
    try:
        with open(mf, encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        print(f"Warning: cannot read manifest for profile {profile!r}: {e}", file=sys.stderr)
        return {}


def slugify(name: str) -> str:
    """Превратить произвольную строку в kebab-case slug [a-z0-9-]+.

    Правила:
      - lowercase
      - strip accents (NFKD + ascii-encode)
      - non-ASCII символы выкидываются
      - runs of non-alnum → одно '-'
      - leading/trailing '-' trim'аются
    """
    import re  # noqa: PLC0415
    import unicodedata  # noqa: PLC0415

    s = name.lower()
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = s.strip("-")
    return s


def detect_plugin_state(repo_root: Path) -> dict:
    """Прочитать текущее состояние plugin/marketplace из артефактов репо.

    Возвращает {'slug': str, 'marketplace': str, 'inconsistent': bool}.
    'inconsistent' = True если slug в marketplace.json != name в plugin.json.

    Контракт: словарь всегда содержит все 3 ключа. Downstream-код (init.sh)
    проверяет 'inconsistent' явно.
    """
    mf_path = repo_root / ".claude-plugin" / "marketplace.json"
    with open(mf_path, encoding="utf-8") as f:
        mf = json.load(f)

    marketplace_name = mf.get("name", "")
    plugins = mf.get("plugins") or [{}]
    slug_in_marketplace = plugins[0].get("name", "")

    # Найти plugin.json (по slug_in_marketplace или fallback на 'project')
    candidate_dirs = [slug_in_marketplace, "project"]
    plugin_slug = ""
    for d in candidate_dirs:
        if not d:
            continue
        pj = repo_root / ".claude" / "plugins" / d / ".claude-plugin" / "plugin.json"
        if pj.exists():
            with open(pj, encoding="utf-8") as f:
                plugin_slug = json.load(f).get("name", "")
            break

    inconsistent = slug_in_marketplace != plugin_slug
    return {
        "slug": slug_in_marketplace,
        "marketplace": marketplace_name,
        "inconsistent": inconsistent,
    }


def _atomic_write_json(path: Path, data: dict) -> None:
    """Записать JSON атомарно: tmp → rename. 2-space indent, ensure_ascii=False."""
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


def rename_marketplace(repo_root: Path, slug: str) -> None:
    """Mutate .claude-plugin/marketplace.json: name, plugins[0].name, plugins[0].source."""
    mf_path = repo_root / ".claude-plugin" / "marketplace.json"
    with open(mf_path, encoding="utf-8") as f:
        mf = json.load(f)
    mf["name"] = f"{slug}-local"
    if mf.get("plugins"):
        mf["plugins"][0]["name"] = slug
        mf["plugins"][0]["source"] = f"./.claude/plugins/{slug}"
    _atomic_write_json(mf_path, mf)


def rename_plugin_json(repo_root: Path, slug: str) -> None:
    """Mutate .claude/plugins/<slug>/.claude-plugin/plugin.json: поле name."""
    pj_path = repo_root / ".claude" / "plugins" / slug / ".claude-plugin" / "plugin.json"
    with open(pj_path, encoding="utf-8") as f:
        pj = json.load(f)
    pj["name"] = slug
    _atomic_write_json(pj_path, pj)


def find_local_marketplace_key(settings: dict) -> str:
    """Имя локального marketplace'а в settings.json — того, что смотрит на сам репо.

    Ищем по признаку `source.source == "directory"`, а не по литералу имени: имя
    менялось (`pt-local` → `project-template-local`) и будет меняться на каждом /init,
    а признак «directory-источник» — инвариант локального marketplace'а.
    Приоритет у path == "."; при нескольких кандидатах без "." берётся первый.
    Пустая строка = локального marketplace'а в settings нет.
    """
    markets = settings.get("extraKnownMarketplaces") or {}
    fallback = ""
    for name, entry in markets.items():
        src = (entry or {}).get("source") or {}
        if src.get("source") != "directory":
            continue
        if src.get("path") == ".":
            return name
        if not fallback:
            fallback = name
    return fallback


def rename_settings(repo_root: Path, slug: str) -> None:
    """Mutate .claude/settings.json:
       - заменить ключ enabledPlugins["<old-plugin>@<old-market>"] → ["<slug>@<slug>-local"]
       - заменить ключ extraKnownMarketplaces["<old-market>"] → ["<slug>-local"]
       Старые имена определяются по структуре (см. find_local_marketplace_key), а не
       по захардкоженным литералам. Если локального marketplace'а нет или он уже
       переименован — no-op.
    """
    s_path = repo_root / ".claude" / "settings.json"
    with open(s_path, encoding="utf-8") as f:
        s = json.load(f)

    new_plugin_id = f"{slug}@{slug}-local"
    new_marketplace = f"{slug}-local"

    old_marketplace = find_local_marketplace_key(s)
    if not old_marketplace or old_marketplace == new_marketplace:
        _atomic_write_json(s_path, s)
        return

    # enabledPlugins: любой ключ вида "<что-угодно>@<old_marketplace>"
    enabled = s.get("enabledPlugins") or {}
    for key in [k for k in enabled if k.endswith(f"@{old_marketplace}")]:
        enabled[new_plugin_id] = enabled.pop(key)

    # extraKnownMarketplaces
    markets = s.get("extraKnownMarketplaces") or {}
    markets[new_marketplace] = markets.pop(old_marketplace)

    _atomic_write_json(s_path, s)


# ===== Subcommand implementations =====

def cmd_list_profiles(args: argparse.Namespace) -> None:
    """list-profiles: JSON-массив профилей, отсортированных (project first, stable alphabetically)."""
    import yaml  # noqa: PLC0415
    profiles = []
    for mf in glob.glob("docs/overlays/profiles/*/manifest.yaml"):
        try:
            with open(mf, encoding="utf-8") as f:
                m = yaml.safe_load(f) or {}
            profiles.append({
                "name":        m.get("name", os.path.basename(os.path.dirname(mf))),
                "description": m.get("description", ""),
                "audience":    m.get("audience") or "",
                "status":      m.get("status", "stable"),
            })
        except Exception:
            pass  # битый manifest — пропустить без crash

    def sort_key(p: dict) -> tuple:
        if p["name"] == "project":
            return (0, "")
        if p["status"] == "stable":
            return (1, p["name"])
        return (2, p["name"])

    profiles.sort(key=sort_key)
    print(json.dumps(profiles))


def cmd_menu_max_len(args: argparse.Namespace) -> None:
    """menu-max-len: max длина name из JSON на stdin."""
    try:
        ps = json.load(sys.stdin)
        print(max(len(p["name"]) for p in ps) if ps else 7)
    except Exception:
        print(7)


def cmd_menu_format(args: argparse.Namespace) -> None:
    """menu-format --max-len N: форматированные строки меню из JSON на stdin.

    Три исхода различаются (TPL-21): «вот меню» и «профилей нет» — тихо, exit 0;
    «не смог отформатировать» — причина в stderr и exit 1. Прежний `except Exception: pass`
    склеивал их в один — пустой stdout с кодом успеха, из-за чего пользователь `/init`
    видел пустой список и не мог понять, выбирать не из чего или сломался разбор.
    """
    try:
        ps = json.load(sys.stdin)
    except Exception as e:
        print(f"menu-format: не разобрал JSON со списком профилей на stdin: {e}",
              file=sys.stderr)
        sys.exit(1)

    for i, p in enumerate(ps):
        try:
            line = "  {:<{w}} — {}".format(p["name"], p["description"], w=args.max_len)
            if p.get("audience"):
                line += " [для: {}]".format(p["audience"])
        except Exception as e:
            # Частичный вывод особенно опасен: усечённое меню профилей неотличимо от
            # полного, поэтому обрыв на i-м элементе объявляется, а не заминается.
            print(f"menu-format: не отформатировал профиль #{i} ({p!r}): {e}",
                  file=sys.stderr)
            sys.exit(1)
        print(line)


def cmd_profile_summary(args: argparse.Namespace) -> None:
    """profile-summary <profile>: bulleted summary профиля на stdout."""
    profile = args.profile
    m = load_manifest(profile)
    if not m:
        return

    desc = m.get("description", "")
    audience = m.get("audience") or ""
    ops = m.get("operations") or []
    overrides = m.get("agent_overrides") or {}
    subagents = m.get("subagents") or {}
    prompts = m.get("init_prompts") or []

    op_add = sum(1 for o in ops if o.get("op") == "add")
    op_replace = sum(1 for o in ops if o.get("op") == "replace")
    op_resolve = sum(1 for o in ops if o.get("op") == "resolve_agents")
    op_total = len(ops)

    override_names = list(overrides.keys())

    core_count = sum(1 for v in subagents.values() if v == "core")
    optional_count = sum(1 for v in subagents.values() if v == "optional")
    disabled_count = sum(1 for v in subagents.values() if v == "disabled")

    print(f"Profile: {profile} — {desc}")
    print(f"  Description : {desc}")
    if audience:
        print(f"  Audience    : {audience}")
    ops_detail = f"add: {op_add}, replace: {op_replace}"
    if op_resolve:
        ops_detail += f", resolve_agents: {op_resolve}"
    print(f"  Operations  : {op_total} ({ops_detail})")
    if override_names:
        print(f"  Overrides   : {len(override_names)} ({', '.join(override_names)})")
    else:
        print("  Overrides   : 0")
    print(f"  Subagents   : {core_count} core, {optional_count} optional, {disabled_count} disabled")
    print(f"  Init prompts: {len(prompts)}")


def cmd_init_prompts(args: argparse.Namespace) -> None:
    """init-prompts <profile>: JSON-массив prompt-объектов {id, prompt, type, default, choices}."""
    profile = args.profile
    m = load_manifest(profile)
    prompts = m.get("init_prompts") or []
    normalized = []
    for p in prompts:
        normalized.append({
            "id":      p.get("id", ""),
            "prompt":  p.get("prompt", ""),
            "type":    p.get("type", "string"),
            "default": p.get("default", ""),
            "choices": p.get("choices") or [],
        })
    print(json.dumps(normalized))


def cmd_prompt_field(args: argparse.Namespace) -> None:
    """prompt-field <index> <field>: значение поля prompt по индексу из JSON на stdin."""
    try:
        ps = json.load(sys.stdin)
        p = ps[args.index]
        field = args.field
        if field == "choices":
            val = p.get("choices") or []
            print("|".join(val))
        else:
            print(p.get(field, ""))
    except (IndexError, KeyError, json.JSONDecodeError):
        print("")


def cmd_json_count(args: argparse.Namespace) -> None:
    """json-count: длина JSON-массива из stdin (stdlib-only, без PyYAML)."""
    try:
        data = json.load(sys.stdin)
        print(len(data) if isinstance(data, list) else 0)
    except (json.JSONDecodeError, TypeError):
        print(0)


def cmd_compat_stacks(args: argparse.Namespace) -> None:
    """compat-stacks <profile>: compatible_stacks через запятую (или пусто)."""
    profile = args.profile
    m = load_manifest(profile)
    s = m.get("compatible_stacks") or []
    if s and s != ["*"]:
        print(",".join(s))
    else:
        print("")


def cmd_slugify(args: argparse.Namespace) -> None:
    """slugify <name>: kebab-case на stdout; exit 1 если результат пустой."""
    result = slugify(args.name)
    print(result)
    if not result:
        sys.exit(1)


def cmd_detect_plugin_state(args: argparse.Namespace) -> None:
    """detect-plugin-state: JSON {slug, marketplace, inconsistent}.

    Exit codes:
      0 — JSON успешно сформирован (caller проверяет поле 'inconsistent').
      1 — не удалось прочитать/распарсить marketplace.json или plugin.json.
    """
    try:
        state = detect_plugin_state(Path(args.repo_root))
    except FileNotFoundError as e:
        print(f"detect-plugin-state: файл не найден: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"detect-plugin-state: невалидный JSON: {e}", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(state))


def cmd_rename_marketplace(args: argparse.Namespace) -> None:
    rename_marketplace(Path(args.repo_root), args.slug)


def cmd_rename_plugin_json(args: argparse.Namespace) -> None:
    rename_plugin_json(Path(args.repo_root), args.slug)


def cmd_rename_settings(args: argparse.Namespace) -> None:
    rename_settings(Path(args.repo_root), args.slug)


# ===== Argument parsing =====

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="_init_helpers.py — helper subcommands для init.sh",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", metavar="<subcommand>")
    sub.required = True

    # list-profiles
    sub.add_parser("list-profiles", help="JSON-массив профилей")

    # menu-max-len (reads JSON from stdin)
    sub.add_parser("menu-max-len", help="max длина name из JSON на stdin")

    # menu-format (reads JSON from stdin)
    p_mf = sub.add_parser("menu-format", help="форматированные строки меню")
    p_mf.add_argument("--max-len", type=int, default=7, help="ширина колонки name")

    # profile-summary
    p_ps = sub.add_parser("profile-summary", help="bulleted summary профиля")
    p_ps.add_argument("profile", help="имя профиля")

    # init-prompts
    p_ip = sub.add_parser("init-prompts", help="JSON-массив prompt-объектов профиля")
    p_ip.add_argument("profile", help="имя профиля")

    # prompt-field
    p_pf = sub.add_parser("prompt-field", help="поле prompt по индексу (JSON на stdin)")
    p_pf.add_argument("index", type=int, help="индекс prompt'а (0-based)")
    p_pf.add_argument("field", help="имя поля: id, prompt, type, default, choices")

    # json-count (reads JSON array from stdin)
    sub.add_parser("json-count", help="длина JSON-массива из stdin")

    # compat-stacks
    p_cs = sub.add_parser("compat-stacks", help="compatible_stacks через запятую")
    p_cs.add_argument("profile", help="имя профиля")

    # slugify
    p_sl = sub.add_parser("slugify", help="slugify(name) → stdout; exit 1 если пусто")
    p_sl.add_argument("name", help="произвольная строка")

    # detect-plugin-state
    p_dps = sub.add_parser("detect-plugin-state", help="JSON {slug, marketplace, inconsistent}")
    p_dps.add_argument("--repo-root", default=".", help="корень репо (default: .)")

    # rename-marketplace
    p_rm = sub.add_parser("rename-marketplace", help="mutate marketplace.json под slug")
    p_rm.add_argument("slug", help="kebab-case slug")
    p_rm.add_argument("--repo-root", default=".", help="корень репо")

    # rename-plugin-json
    p_rpj = sub.add_parser("rename-plugin-json", help="mutate plugin.json под slug")
    p_rpj.add_argument("slug", help="kebab-case slug")
    p_rpj.add_argument("--repo-root", default=".", help="корень репо")

    # rename-settings
    p_rs = sub.add_parser("rename-settings", help="mutate settings.json под slug")
    p_rs.add_argument("slug", help="kebab-case slug")
    p_rs.add_argument("--repo-root", default=".", help="корень репо")

    return parser


COMMANDS = {
    "list-profiles":       cmd_list_profiles,
    "menu-max-len":        cmd_menu_max_len,
    "menu-format":         cmd_menu_format,
    "profile-summary":     cmd_profile_summary,
    "init-prompts":        cmd_init_prompts,
    "prompt-field":        cmd_prompt_field,
    "json-count":          cmd_json_count,
    "compat-stacks":       cmd_compat_stacks,
    "slugify":             cmd_slugify,
    "detect-plugin-state": cmd_detect_plugin_state,
    "rename-marketplace":  cmd_rename_marketplace,
    "rename-plugin-json":  cmd_rename_plugin_json,
    "rename-settings":     cmd_rename_settings,
}


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    fn = COMMANDS.get(args.command)
    if fn is None:
        parser.print_help()
        sys.exit(1)
    fn(args)


if __name__ == "__main__":
    main()
