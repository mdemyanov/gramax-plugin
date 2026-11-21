#!/usr/bin/env bash
# tests/gramax/render-quality/ac-112-aggregate-red.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-112 (FR-193)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 4
#   («Двухслойная семантика: факт и ожидание», проба AC-112) и «Контракт с QA-author»,
#   строка ac-112.
# Проверка (контракт, офлайн-шов): стаб-слаг с ожиданием ok отдаёт 500 (проба «в контрольную
# фикстуру внесён подтверждённый киллер») -> расхождение -> rc=1, вердикт FAIL, расхождение
# названо по слагу; контрольный прогон «всё совпало» (ожидание kill против 500) -> rc=0,
# вердикт PASS. Красный агрегат красит гейт (--full), зелёный — нет.
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-112.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-112: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-112 (дизайн, Решение 4); сюита красная до реализации Dev"
  exit 1
fi

# Стаб-портал: «отравленный контроль» — стабильно 500
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-poisoned-control": { "codes": [500, 500], "html": "" }
  }
}
JSON
python3 -I "$STUB_PORTAL" --port 0 --routes "$TMP/routes.json" > "$TMP/portal.out" 2> "$TMP/portal.err" &
SERVER_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -s "$TMP/portal.out" ] && grep -q "STUB_READY" "$TMP/portal.out" && break
  sleep 0.2
done
PORT="$(sed -n 's/^STUB_READY port=//p' "$TMP/portal.out" | head -1)"
if [ -z "$PORT" ]; then
  echo "  FAIL: AC-112 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-112: инфраструктура стаба сломана"; exit 1
fi

mkdir -p "$TMP/fixtures-ok" "$TMP/fixtures-kill"
for dir in fixtures-ok fixtures-kill; do
  cat > "$TMP/$dir/stub-poisoned-control.md" <<'EOF'
---
title: "Стаб: отравленный контроль"
order: 1
---

Контрольная фикстура стаба, в которую «внесён киллер» (портал отдаёт 500).
EOF
done
printf '{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }\n' \
  > "$TMP/fixtures-ok/stub-poisoned-control.expect.json"
printf '{ "tableRow": "ERROR-1", "expect": { "tier0": "kill", "tier1": "any", "asserts": [] } }\n' \
  > "$TMP/fixtures-kill/stub-poisoned-control.expect.json"

cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

# Проба 1: факт 5xx против ожидания ok -> расхождение -> rc=1, FAIL, расхождение названо
bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures-ok" \
  --report "$TMP/report-red.md" > "$TMP/out-red.txt" 2>&1
RC_RED=$?
assert_eq "$RC_RED" "1" "AC-112: расхождение факта (5xx) с ожиданием ok — rc=1"
assert_grep "$TMP/report-red.md" "verdict: FAIL" "AC-112: вердикт агрегата FAIL"
assert_grep "$TMP/report-red.md" "stub-poisoned-control: divergence" \
  "AC-112: расхождение названо по слагу"
assert_grep "$TMP/report-red.md" "STABLE_5XX" "AC-112: факт назван (STABLE_5XX)"

# Проба 2: «всё совпало» — ожидание kill против 500 -> rc=0, PASS
bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures-kill" \
  --report "$TMP/report-green.md" > "$TMP/out-green.txt" 2>&1
RC_GREEN=$?
assert_eq "$RC_GREEN" "0" "AC-112: контрольный прогон «всё совпало» — rc=0"
assert_grep "$TMP/report-green.md" "verdict: PASS" "AC-112: вердикт агрегата PASS"
assert_grep "$TMP/report-green.md" "stub-poisoned-control: match" "AC-112: тот же слаг — match"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-112: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-112: расхождение (5xx против ok) даёт rc=1/FAIL с именем слага; совпадение — rc=0/PASS"
