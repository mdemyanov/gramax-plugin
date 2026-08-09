#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-003-doc-root-contract.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-4
# AC coverage:
#   AC-6 → validate-content.py зелёный (ноль errors)

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "content/.doc-root.yaml" ".doc-root.yaml должен существовать"
assert_file_exists "content/_index.md" "корневой _index.md должен существовать"

# Контракт схемы: type: Enum с заглавной, значения в ключе values.
assert_grep_regex "content/.doc-root.yaml" '^\s+type: Enum' \
  "properties должны объявлять type: Enum (регистр важен)"
assert_grep "content/.doc-root.yaml" "filterProperties" \
  "filterProperties должен быть объявлен"
assert_grep "content/.doc-root.yaml" "Тип контента" \
  "свойство «Тип контента» должно быть объявлено"

# C2: _index.md не несёт properties.
assert_no_grep "content/_index.md" "properties:" \
  "C2: _index.md не должен содержать properties"

set +e
VALIDATOR_OUT="$(uv run scripts/validate-content.py 2>&1)"
VALIDATOR_RC=$?
set -e
if [ "$VALIDATOR_RC" -ne 0 ]; then
  echo "  FAIL: AC-6: validate-content.py exit=$VALIDATOR_RC" >&2
  echo "$VALIDATOR_OUT" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-003: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-003: контракт .doc-root.yaml валиден, validate-content.py зелёный"
