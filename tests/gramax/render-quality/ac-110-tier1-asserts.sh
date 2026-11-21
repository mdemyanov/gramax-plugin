#!/usr/bin/env bash
# tests/gramax/render-quality/ac-110-tier1-asserts.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-110 (FR-191)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решения 4/5
#   (двухслойная семантика, примитив ассерта {name, selector, count}) и «Контракт с
#   QA-author», строка ac-110.
# Проверка (контракт, офлайн-шов): стаб-портал отдаёт HTML с маркером
# ([data-testid=note-block]) и без; обе фикстуры ожидают tier1-ассерт присутствия маркера;
# вердикт тира по каждой фикстуре булев и назван в отчёте: pass с именем набора ассертов /
# fail с именем не сошедшего ассерта.
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-110.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-110: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-110 (дизайн, Решение 5); сюита красная до реализации Dev"
  exit 1
fi

# Стаб-портал: HTML с маркером и без (tier-1 открывает человекочитаемую страницу по pageUrlTemplate)
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-note-rendered": {
      "codes": [200],
      "html": "<html><body><div data-testid=\"note-block\">Заметка отрисована</div></body></html>"
    },
    "stub-note-absent": {
      "codes": [200],
      "html": "<html><body><p>маркера нет</p></body></html>"
    }
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
  echo "  FAIL: AC-110 — стаб-портал не поднялся (это дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-110: инфраструктура стаба сломана"; exit 1
fi

mkdir -p "$TMP/fixtures"
cat > "$TMP/fixtures/stub-note-rendered.md" <<'EOF'
---
title: "Стаб: маркер есть"
order: 1
---

Страница стаба, отдающая HTML с маркером note-block.
EOF
cat > "$TMP/fixtures/stub-note-rendered.expect.json" <<'EOF'
{
  "tableRow": "control",
  "expect": {
    "tier0": "ok",
    "tier1": "pass",
    "asserts": [ { "name": "note-block-present", "selector": "[data-testid=note-block]", "count": 1 } ]
  }
}
EOF
cat > "$TMP/fixtures/stub-note-absent.md" <<'EOF'
---
title: "Стаб: маркера нет"
order: 2
---

Страница стаба, отдающая HTML без маркера note-block.
EOF
cat > "$TMP/fixtures/stub-note-absent.expect.json" <<'EOF'
{
  "tableRow": "control",
  "expect": {
    "tier0": "ok",
    "tier1": "pass",
    "asserts": [ { "name": "note-block-present", "selector": "[data-testid=note-block]", "count": 1 } ]
  }
}
EOF

# pageUrlTemplate указывает на стаб (tier-1 нужен человекочитаемый URL страницы)
cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "pageUrlTemplate": "{base}/api/catalogs/{catalog}/articles/{slug}/html",
  "tiers": ["tier0", "tier1"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

OUT="$(bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" --report "$TMP/report.md" 2>&1)"
RC=$?

# Маркер есть: pass; маркера нет: fail с именем не сошедшего ассерта -> расхождение -> rc=1
assert_eq "$RC" "1" "AC-110: несошедший ассерт фикстуры-дефекта — расхождение, rc=1"
assert_grep "$TMP/report.md" "stub-note-rendered: match" "AC-110: фикстура с маркером — match"
assert_grep "$TMP/report.md" "stub-note-absent: divergence" "AC-110: фикстура без маркера — divergence"
if ! grep -qF "note-block-present" "$TMP/report.md"; then
  echo "  FAIL: AC-110 — отчёт обязан называть имя не сошедшего ассерта (note-block-present)" >&2
  FAIL=$((FAIL + 1))
fi
assert_grep "$TMP/report.md" "pass" "AC-110: вердикт тира-1 по сошедшей фикстуре назван (pass)"
if printf '%s\n' "$OUT" | grep -qF "REFUSAL"; then
  echo "  FAIL: AC-110 — отказ окружения: на прогретой машине стаб не ожидает REFUSAL;" >&2
  echo "  на непрогретой машине (uv-кэш/браузер) это D8-классифицированное поведение окружения —" >&2
  echo "  прогрей (bash scripts/render-quality/warm.sh) и перезапусти, не триажь как дефект сюиты" >&2
  printf '%s\n' "$OUT" | head -10 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-110: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-110: tier-1 — pass по маркеру, fail с именем ассерта note-block-present без маркера, rc=1"
