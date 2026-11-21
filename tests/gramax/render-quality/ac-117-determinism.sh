#!/usr/bin/env bash
# tests/gramax/render-quality/ac-117-determinism.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-117 (NFR-077)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 5
#   («Отчёт»: сортировка по слагу, без таймингов; два прогона — побайтно идентичный файл)
#   и «Контракт с QA-author», строка ac-117.
# Проверка (контракт, офлайн-шов): два прогона прибора по неизменному стаб-порталу на
# неизменном мини-наборе фикстур дают побайтно идентичные отчёты (diff пуст) и одинаковые rc.
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-117.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-117: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-117 (дизайн, Решение 5); сюита красная до реализации Dev"
  exit 1
fi

# Неизменный стаб: три слага вперемешку (порядок обхода обязан нормализоваться сортировкой)
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "zeta-page":  { "codes": [200], "html": "<html><body><p>zeta</p></body></html>" },
    "alpha-page": { "codes": [200], "html": "<html><body><p>alpha</p></body></html>" },
    "mid-page":   { "codes": [500, 500], "html": "" }
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
  echo "  FAIL: AC-117 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-117: инфраструктура стаба сломана"; exit 1
fi

mkdir -p "$TMP/fixtures"
for slug in zeta-page alpha-page mid-page; do
  cat > "$TMP/fixtures/$slug.md" <<EOF
---
title: "Стаб: $slug"
order: 1
---

Тело фикстуры стаба $slug.
EOF
done
printf '{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }\n' \
  > "$TMP/fixtures/zeta-page.expect.json"
printf '{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }\n' \
  > "$TMP/fixtures/alpha-page.expect.json"
printf '{ "tableRow": "ERROR-1", "expect": { "tier0": "kill", "tier1": "any", "asserts": [] } }\n' \
  > "$TMP/fixtures/mid-page.expect.json"

cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" \
  --report "$TMP/report-1.md" > "$TMP/out-1.txt" 2>&1
RC1=$?
bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" \
  --report "$TMP/report-2.md" > "$TMP/out-2.txt" 2>&1
RC2=$?

assert_eq "$RC1" "$RC2" "AC-117: rc двух прогонов идентичны"
assert_file_exists "$TMP/report-1.md" "AC-117: отчёт первого прогона написан"
assert_file_exists "$TMP/report-2.md" "AC-117: отчёт второго прогона написан"
if ! diff -u "$TMP/report-1.md" "$TMP/report-2.md" > "$TMP/report.diff" 2>&1; then
  echo "  FAIL: AC-117/NFR-077 — отчёты двух прогонов подряд на неизменном состоянии цели различаются:" >&2
  head -20 "$TMP/report.diff" >&2
  FAIL=$((FAIL + 1))
fi
# stdout зеркалит отчёт — детерминизм распространяется и на вывод (NFR-077)
if ! diff -u "$TMP/out-1.txt" "$TMP/out-2.txt" > "$TMP/out.diff" 2>&1; then
  echo "  FAIL: AC-117/NFR-077 — stdout двух прогонов различается:" >&2
  head -20 "$TMP/out.diff" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-117: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-117: два прогона подряд — идентичные rc, побайтно идентичные отчёт и stdout (diff пуст)"
