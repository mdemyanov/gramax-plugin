#!/usr/bin/env bash
# tests/gramax/render-quality/ac-111-screenshots.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-111 (FR-192)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решения 4/5
#   (tier-2 артефактный, вне агрегата; каталог results/; screenshots/<slug>.png) и
#   «Контракт с QA-author», строка ac-111.
# Проверка (контракт, офлайн-шов): прогон стаба с tier-2 в скоупе; в каталоге результатов
# (каталог отчёта --report) лежит НЕПУСТОЙ screenshots/<slug>.png на каждую открытую
# фикстуру; у skip-страницы (tier0 NOT_FOUND) — именованный skip в отчёте и файла нет;
# артефакты вне git (результаты стаба — во временном каталоге).
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-111.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-111: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-111 (дизайн, Решение 5); сюита красная до реализации Dev"
  exit 1
fi

cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-shot-a": { "codes": [200], "html": "<html><body><p>страница А стаба</p></body></html>" },
    "stub-shot-b": { "codes": [200], "html": "<html><body><p>страница Б стаба</p></body></html>" },
    "stub-shot-gone": { "codes": [404], "html": "" }
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
  echo "  FAIL: AC-111 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-111: инфраструктура стаба сломана"; exit 1
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
write_fixture stub-shot-a ok
write_fixture stub-shot-b ok
write_fixture stub-shot-gone ok

cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "pageUrlTemplate": "{base}/api/catalogs/{catalog}/articles/{slug}/html",
  "tiers": ["tier0", "tier1", "tier2"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

# Каталог результатов = каталог отчёта (дом-раскладка дизайна: results/report.md + results/screenshots/)
mkdir -p "$TMP/results"
bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" \
  --report "$TMP/results/report.md" >/dev/null 2>&1
RC=$?

# stub-shot-gone: NOT_FOUND — расхождение всегда -> rc=1 (скриншот тут не вердикт)
assert_eq "$RC" "1" "AC-111: расхождение NOT_FOUND красит агрегат; скриншоты в агрегат не входят"
for slug in stub-shot-a stub-shot-b; do
  shot="$TMP/results/screenshots/$slug.png"
  assert_file_exists "$shot" "AC-111: скриншот открытой фикстуры $slug"
  if [ -f "$shot" ] && [ ! -s "$shot" ]; then
    echo "  FAIL: AC-111 — скриншот $slug пуст (нужен непустой PNG-артефакт)" >&2
    FAIL=$((FAIL + 1))
  fi
  assert_grep "$TMP/results/report.md" "screenshots/$slug.png" \
    "AC-111: отчёт называет артефакт скриншота $slug"
done
assert_file_not_exists "$TMP/results/screenshots/stub-shot-gone.png" \
  "AC-111: неоткрытой странице (NOT_FOUND) скриншот не снимается"
assert_grep "$TMP/results/report.md" "tier2: skip" \
  "AC-111: skip-страница названа в отчёте именованным skip"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-111: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-111: непустые скриншоты открытых фикстур, skip назван по имени, артефакты вне git"
