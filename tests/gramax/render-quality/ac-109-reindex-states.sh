#!/usr/bin/env bash
# tests/gramax/render-quality/ac-109-reindex-states.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-109 (FR-190)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 6
#   (переиндексация: именованные состояния + bounded retry без константы окна) и
#   «Контракт с QA-author», строка ac-109.
# Проверка (контракт, офлайн-шов): стаб-портал отдаёт три слага — устойчивый 500,
# 500->200 (решается ретраем), 404; отчёт называет все три состояния по имени:
# STABLE_5XX с нотой кандидата на переиндексацию; OK с нотой «решён ретраем»;
# NOT_FOUND с нотой «404 сразу после пуша». Код прибора не содержит sleep-констант
# (NFR-080: окно переиндексации не кодируется).
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-109.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-109: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-109 (дизайн, Решение 6); сюита красная до реализации Dev"
  exit 1
fi

# Стаб-портал: устойчивый 500; 500->200 (ретрай решает); 404
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-stable-kill":    { "codes": [500, 500], "html": "" },
    "stub-reindex-flaky":  { "codes": [500, 200], "html": "<html><body><p>переиндексировалось</p></body></html>" },
    "stub-gone":           { "codes": [404], "html": "" }
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
  echo "  FAIL: AC-109 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-109: инфраструктура стаба сломана"; exit 1
fi

mkdir -p "$TMP/fixtures"
write_fixture() { # слаг, tier0-ожидание
  cat > "$TMP/fixtures/$1.md" <<EOF
---
title: "Стаб: $1"
order: 1
---

Тело фикстуры стаба $1.
EOF
  printf '{ "tableRow": "control", "expect": { "tier0": "%s", "tier1": "any", "asserts": [] } }\n' \
    "$2" > "$TMP/fixtures/$1.expect.json"
}
write_fixture stub-stable-kill kill
write_fixture stub-reindex-flaky ok
write_fixture stub-gone ok

cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" --report "$TMP/report.md" >/dev/null 2>&1
RC=$?

# stub-gone: NOT_FOUND — расхождение всегда (страницу нечего судить) -> rc=1
assert_eq "$RC" "1" "AC-109: NOT_FOUND — расхождение всегда, отчёт написан, rc=1"
assert_grep "$TMP/report.md" "STABLE_5XX" "AC-109: устойчивый 500 после ретрая — финальный факт STABLE_5XX"
assert_grep "$TMP/report.md" "кандидат на переиндексацию" \
  "AC-109: STABLE_5XX несёт ноту кандидата на переиндексацию (не окончательный приговор сразу)"
assert_grep "$TMP/report.md" "решён ретраем" "AC-109: 500->200 — факт OK с нотой «решён ретраем»"
assert_grep "$TMP/report.md" "NOT_FOUND" "AC-109: 404 — финальный факт NOT_FOUND"
assert_grep "$TMP/report.md" "404 сразу после пуша" \
  "AC-109: NOT_FOUND несёт ноту «404 сразу после пуша — обычно переиндексация»"
assert_grep "$TMP/report.md" "verdict: FAIL" "AC-109: расхождение (gone) красит агрегат"

# NFR-080: окно переиндексации не кодируется — в модуле прибора нет sleep-констант
if grep -nE 'sleep\(' "$ROOT"/scripts/render-quality/*.py > /dev/null 2>&1; then
  echo "  FAIL: AC-109/NFR-080 — sleep-константа в коде прибора (окно переиндексации не кодируется):" >&2
  grep -nE 'sleep\(' "$ROOT"/scripts/render-quality/*.py | head -5 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-109: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-109: три состояния названы (STABLE_5XX + кандидат, OK + решён ретраем, NOT_FOUND + нота), sleep-констант нет"
