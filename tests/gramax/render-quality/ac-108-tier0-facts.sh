#!/usr/bin/env bash
# tests/gramax/render-quality/ac-108-tier0-facts.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-108 (FR-190)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решения 1/4/6
#   и «Контракт с QA-author», строка ac-108.
# Проверка (контракт, офлайн-шов): стаб-портал lib/stub_portal.py на 127.0.0.1 отдаёт
# контроль-слагу 200, киллер-слагу 500; временный конфиг через --config (baseUrl = адрес
# стаба); tier-0 выдаёт реальный HTTP-факт по каждой фикстуре: контроль — «OK 2xx»,
# киллер — «STABLE_5XX»; ожидания (ok/kill) совпали -> rc=0 (вередикт PASS).
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-108.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-108: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-108 (дизайн, Решения 4/5); сюита красная до реализации Dev"
  exit 1
fi

# Стаб-портал: контроль 200, киллер 500 (канонические коды, детерминированно)
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-control": { "codes": [200], "html": "<html><body><p>чистая страница стаба</p></body></html>" },
    "stub-killer":  { "codes": [500], "html": "" }
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
  echo "  FAIL: AC-108 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-108: инфраструктура стаба сломана"; exit 1
fi

# Мини-набор фикстур стаба (шов --fixtures): свои слаги, свои ожидания
mkdir -p "$TMP/fixtures"
cat > "$TMP/fixtures/stub-control.md" <<'EOF'
---
title: "Стаб: контроль"
order: 1
---

Чистая страница стаба.
EOF
cat > "$TMP/fixtures/stub-control.expect.json" <<'EOF'
{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }
EOF
cat > "$TMP/fixtures/stub-killer.md" <<'EOF'
---
title: "Стаб: киллер"
order: 2
---

Фикстура стаба с подтверждённым киллером (ожидание kill).
EOF
cat > "$TMP/fixtures/stub-killer.expect.json" <<'EOF'
{ "tableRow": "ERROR-1", "expect": { "tier0": "kill", "tier1": "any", "asserts": [] } }
EOF

# Конфиг-шов: baseUrl = адрес стаб-портала (127.0.0.1), только tier-0
cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

OUT="$(bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" --report "$TMP/report.md" 2>&1)"
RC=$?

assert_eq "$RC" "0" "AC-108: ожидания ok/kill совпали с фактами — rc=0, verdict PASS"
assert_grep "$TMP/report.md" "OK 2xx" "AC-108: контроль-слаг — факт OK 2xx (http 200)"
assert_grep "$TMP/report.md" "STABLE_5XX" "AC-108: киллер-слаг — факт STABLE_5XX (http 500)"
assert_grep "$TMP/report.md" "stub-control: match" "AC-108: контроль — match"
assert_grep "$TMP/report.md" "stub-killer: match" "AC-108: киллер — match (ожидание kill + 5xx = согласие, не красность)"
assert_grep "$TMP/report.md" "verdict: PASS" "AC-108: агрегат PASS"
if printf '%s\n' "$OUT" | grep -qF "REFUSAL"; then
  echo "  FAIL: AC-108 — именованный отказ не ожидается: цель (стаб) сконфигурирована" >&2
  printf '%s\n' "$OUT" | head -10 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-108: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-108: tier-0 выдал факты OK 2xx (контроль, 200) и STABLE_5XX (киллер, 500), ожидания совпали, rc=0"
