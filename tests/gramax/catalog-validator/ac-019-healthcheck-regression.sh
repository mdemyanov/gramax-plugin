#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-019-healthcheck-regression.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md
# Проверка: прогон ВСЕХ gramax-fixtures через validate_structure.py,
#           каждый должен выдать ожидаемый код (W030-W034).
# Это регрессионный тест: ловит случай, когда новая правка отключает проверку.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
GFX="$SCRIPT_DIR/fixtures/gramax-fixtures"

# Пары "fixture:ожидаемый-паттерн" для битых фикстур.
# Используем формат key:value вместо declare -A — ассоциативных массивов нет в bash 3.2.
BAD_CASES=(
  "broken-image:W030"
  "broken-diagram:W031"
  "link-no-ext-broken:битая ссылка"
  "link-hash-broken:W033"
  "unsupported-html:W034"
)

for entry in "${BAD_CASES[@]}"; do
  fixture="${entry%%:*}"
  pattern="${entry#*:}"
  OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$GFX/$fixture" 2>&1) || true
  if ! echo "$OUT" | grep -qiE "$pattern"; then
    echo "  FAIL: fixture '$fixture' — expected pattern '$pattern' not found in output" >&2
    echo "  --- вывод ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
done

# link-no-ext-ok и link-hash-ok должны быть чистыми (exit 0, без broken link / W033)
for fixture in "link-no-ext-ok" "link-hash-ok"; do
  if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$GFX/$fixture" 2>&1); then
    EXIT=0
  else
    EXIT=$?
  fi
  if [ "$EXIT" -ne 0 ]; then
    echo "  FAIL: fixture '$fixture' должна давать чистый проход (exit 0), получили exit=$EXIT" >&2
    echo "  --- вывод ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
  if echo "$OUT" | grep -qiE 'битая ссылка|broken link|W033'; then
    echo "  FAIL: fixture '$fixture' не должна содержать broken link или W033" >&2
    echo "  --- вывод ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-019: $FAIL regression(s) failed"; exit 1; fi
pass_msg "ac-019: все gramax-fixtures выдают ожидаемые коды (W030-W034)"
