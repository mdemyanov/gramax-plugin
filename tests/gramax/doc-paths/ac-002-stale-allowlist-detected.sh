#!/usr/bin/env bash
# tests/gramax/doc-paths/ac-002-stale-allowlist-detected.sh
# Требование: FR-027. Гейт обязан замечать протухшую запись allowlist, а не пропускать молча.
# Проверяется на фикстуре: мутировать живой content/ в pre-commit/CI нельзя.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/scan.sh"

FAIL=0
FIX="$SCRIPT_DIR/fixtures/stale-allowlist"

assert_dir_exists "$FIX" "FR-027: фикстура рассинхрона должна существовать"

cd "$FIX"
OUTPUT="$(scan_doc_paths "content" "$FIX/allowlist.txt" 2>&1)" && RC=0 || RC=$?

if [ "${RC:-0}" -eq 0 ]; then
  echo "  FAIL: FR-027: гейт пропустил протухшую запись allowlist — обязан был упасть" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s' "$OUTPUT" | grep -q 'allowlist устарел'; then
  echo "  FAIL: FR-027: в диагностике нет подстроки «allowlist устарел»" >&2
  echo "  Фактический вывод: $OUTPUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: протухшая запись allowlist обнаружена и названа явно"
