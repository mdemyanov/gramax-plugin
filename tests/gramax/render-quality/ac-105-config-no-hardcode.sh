#!/usr/bin/env bash
# tests/gramax/render-quality/ac-105-config-no-hardcode.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-105 (FR-188)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 1
#   («Гигиена хоста») и «Контракт с QA-author», строка ac-105.
# Проверка (контракт): (a) в python-модулях прибора scripts/render-quality/*.py нет ни одного
# литерала http:// или https:// — цель рендера не хардкодится, единственный коммитимый
# литерал живёт в render-target.example.json (JSON, не .py); (b) прогон прибора с --config
# на хосте-заполнителе .invalid (RFC 2606) называет цель из конфига в выводе — отчёт
# называет цель целиком.
# Цвет при создании: КРАСНЫЙ — каркас scripts/render-quality/ не реализован
# (вход scripts/render-quality/probe.sh отсутствует); закрывает Dev (Решение 5).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-105.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

# Шов стаба: именованный красный — вход прибора отсутствует.
if [ ! -f "$PROBE" ]; then
  fail_msg "ac-105: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-105 (дизайн, Решения 1/5); сюита красная до реализации Dev"
  exit 1
fi

# (a) Ноль литералов http(s):// в python-модулях прибора (AC-105, FR-195)
HITS="$(grep -nE 'https?://' "$ROOT"/scripts/render-quality/*.py 2> /dev/null || true)"
if [ -n "$HITS" ]; then
  echo "  FAIL: AC-105 — литералы http(s):// в коде прибора (цель не хардкодится, FR-188/FR-195):" >&2
  printf '%s\n' "$HITS" | head -10 >&2
  FAIL=$((FAIL + 1))
fi

# (b) Прогон с .invalid-хостом: отчёт/вывод называет цель из конфига
cat > "$TMP/config.json" <<'JSON'
{
  "baseUrl": "https://render-target.example.invalid",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON
mkdir -p "$TMP/fixtures"
cat > "$TMP/fixtures/control-clean.md" <<'EOF'
---
title: "Контроль"
order: 1
---

Чистая страница-фикстура стаба.
EOF
cat > "$TMP/fixtures/control-clean.expect.json" <<'EOF'
{
  "tableRow": "control",
  "expect": { "tier0": "ok", "tier1": "any", "asserts": [] }
}
EOF

OUT="$(bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" --report "$TMP/report.md" 2>&1)"
RC=$?

# Отказ окружения (rc=2) здесь не ожидается: цель валидна по схеме, проверка цели проходит
# до любых обращений к playwright (дизайн, Решение 1).
assert_eq "$RC" "1" "AC-105: недостижимая цель .invalid — расхождение NETWORK_ERR, rc=1 (отчёт написан)"
if ! printf '%s\n' "$OUT" | grep -qF "render-target.example.invalid"; then
  echo "  FAIL: AC-105 — вывод/отчёт обязан называть цель из конфига (render-target.example.invalid)" >&2
  echo "  --- вывод ---" >&2
  printf '%s\n' "$OUT" | head -20 >&2
  FAIL=$((FAIL + 1))
fi
if [ -f "$TMP/report.md" ] && ! grep -qF "render-target.example.invalid" "$TMP/report.md"; then
  echo "  FAIL: AC-105 — файл отчёта обязан называть цель из конфига" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-105: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-105: код прибора без литералов http(s)://, прогон с --config называет цель в выводе и отчёте"
