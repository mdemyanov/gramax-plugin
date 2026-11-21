#!/usr/bin/env bash
# tests/gramax/render-quality/ac-126-live-form-config.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-126 (FR-205)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 1
#   (живая форма pageUrlTemplate {base}/{catalog}/{slug} без сегмента /page/ — ДАННЫЕ
#   gitignore-конфига; config.py НЕ меняется; отказ — существующий RENDER_TARGET_INVALID
#   по полю pageUrlTemplate до любого обращения к playwright; tiers=tier0 — поле
#   опционально; render-target.local.json вне git).
# Проверка (контракт, офлайн: config.py и probe.py — чисто stdlib, playwright
# импортируется лениво, сети и браузера нет):
#   1) живая форма разрешается; page_url без /page/; подстановка {slug} не искажает адрес;
#   2) pageUrlTemplate без {slug} -> RENDER_TARGET_INVALID с полем pageUrlTemplate;
#   3) tiers=["tier0"] без pageUrlTemplate -> разрешается (поле опционально, не читается);
#   4) баннер отказа через вход probe.py: REFUSAL RENDER_TARGET_INVALID + подсказка с
#      именем поля (лестница: отказ конфига раньше playwright);
#   5) git check-ignore подтверждает: render-target.local.json вне git.
#   Живые ноги AC-126 (check-env зелёный на боевой цели, отчёт называет цель) —
#   сессионные, владелец исполнитель/BA (Решение 1, «Где живут живые значения»); стаб
#   живые значения конфига не читает (секреты, NFR-081).
# Цвет при создании: ЗЕЛЁНЫЙ — варден контракта волны-2 («схема конфига не расширяется,
#   config.py не меняется» — Решение 1): контракт уже в дереве, замер 2026-11-21 это
#   подтвердил (живая форма разрешается, отказ по полю). Красный = триаж: кто-то сломал
#   приём живой формы или игнор-строку — дефект регрессии, не плановая краснота
#   (прецедент зелёных с рождения варденов ac-104/ac-118 волны-1).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE_PY="$ROOT/scripts/render-quality/probe.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-126.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

# --- 1)-3) разрешение и отказ конфига (уровень config.py, без playwright) ---
PY_OUT="$(python3 -I - "$ROOT" "$TMP" <<'PYEOF'
import json, os, sys
sys.path.insert(0, sys.argv[1] + "/scripts/render-quality")
import config

_cfg_seq = [0]

def write_cfg(data):
    _cfg_seq[0] += 1
    path = os.path.join(sys.argv[2], "cfg-%d.json" % _cfg_seq[0])
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle)
    return path

# 1) живая форма {base}/{catalog}/{slug} разрешается, /page/ нет
p = write_cfg({"baseUrl": "https://render-target.example.invalid",
               "catalog": "catalog-slug",
               "pageUrlTemplate": "{base}/{catalog}/{slug}",
               "tiers": ["tier0", "tier1"]})
target = config.resolve(p)
url = target.page_url("probe-slug")
print("LIVE_URL_OK=%s" % ("true" if url == "https://render-target.example.invalid/catalog-slug/probe-slug" else "false:%s" % url))
print("LIVE_NO_PAGE_SEGMENT=%s" % ("true" if "/page/" not in url else "false"))
os.unlink(p)

# 2) malformed (нет {slug}) -> RENDER_TARGET_INVALID по полю pageUrlTemplate
p = write_cfg({"baseUrl": "https://render-target.example.invalid",
               "catalog": "catalog-slug",
               "pageUrlTemplate": "{base}/view/{slug2}",
               "tiers": ["tier0", "tier1"]})
try:
    config.resolve(p)
    print("MALFORMED_REFUSAL=absent")
except config.TargetRefusal as exc:
    print("MALFORMED_REFUSAL=%s" % exc.code)
    print("MALFORMED_FIELD=%s" % exc.field)
os.unlink(p)

# 3) tiers=tier0: поле опционально, не читается
p = write_cfg({"baseUrl": "https://render-target.example.invalid",
               "catalog": "catalog-slug", "tiers": ["tier0"]})
try:
    config.resolve(p)
    print("TIER0_ONLY=ok")
except config.TargetRefusal as exc:
    print("TIER0_ONLY=refusal:%s:%s" % (exc.code, exc.field))
os.unlink(p)
PYEOF
)"
if printf '%s\n' "$PY_OUT" | grep -qF "LIVE_URL_OK=false"; then
  echo "  FAIL: AC-126 — живая форма {base}/{catalog}/{slug} обязана разрешаться в base/catalog/slug без искажений (Решение 1):" >&2
  printf '%s\n' "$PY_OUT" | grep -E "LIVE_URL_OK=" >&2
  FAIL=$((FAIL + 1))
fi
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'LIVE_NO_PAGE_SEGMENT=true' || true)" "1" "AC-126: живая форма без сегмента /page/ (отличие от примера схемы волны-1, факт 5)"
if printf '%s\n' "$PY_OUT" | grep -qF "MALFORMED_REFUSAL=absent"; then
  echo "  FAIL: AC-126 — pageUrlTemplate без {slug} обязан отказывать RENDER_TARGET_INVALID (Решение 1, «malformed» и «missing» неразличимы)" >&2
  FAIL=$((FAIL + 1))
else
  assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'MALFORMED_FIELD=pageUrlTemplate' || true)" "1" "AC-126: отказ называет поле pageUrlTemplate"
fi
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'TIER0_ONLY=ok' || true)" "1" "AC-126: tiers=tier0 — pageUrlTemplate опционален и не читается"

# --- 4) баннер отказа через вход probe.py (лестница: конфиг раньше playwright) ---
BAD_CFG="$TMP/bad-pageurl.json"
cat > "$BAD_CFG" <<'JSON'
{"baseUrl": "https://render-target.example.invalid", "catalog": "catalog-slug",
 "pageUrlTemplate": "{base}/view/{slug2}", "tiers": ["tier0", "tier1"]}
JSON
if OUT="$(python3 "$PROBE_PY" --check-env --config "$BAD_CFG" 2>&1)"; then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "2" "AC-126: именованный отказ конфига через вход прибора — rc=2"
assert_eq "$(printf '%s\n' "$OUT" | grep -cF 'REFUSAL RENDER_TARGET_INVALID' || true)" "1" "AC-126: баннер «REFUSAL RENDER_TARGET_INVALID: …» (набор кодов не расширяется, Решение 1)"
assert_eq "$(printf '%s\n' "$OUT" | grep -cF 'pageUrlTemplate' || true)" "1" "AC-126: подсказка называет поле pageUrlTemplate"
assert_eq "$(printf '%s\n' "$OUT" | grep -ciF 'playwright' || true)" "0" "AC-126: отказ конфига раньше любого обращения к playwright (лестница Решения 2 волны-1)"

# --- 5) render-target.local.json вне git ---
if git -C "$ROOT" check-ignore -q scripts/render-quality/render-target.local.json; then
  : # игнор-строка на месте
else
  echo "  FAIL: AC-126 — git check-ignore не подтверждает: render-target.local.json обязан быть вне git (.gitignore, Решение 1)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-126: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-126: живая форма {base}/{catalog}/{slug} разрешается, отказ по pageUrlTemplate именован и раньше playwright, конфиг вне git"
