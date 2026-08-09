#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7
# AC coverage:
#   AC-10 → свои check.sh / install-hooks.sh / pre-commit не перезаписаны синком
#   (валидатор доставлен и запускается)

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "scripts/validate-content.py" \
  "валидатор content/ должен быть доставлен"
assert_file_exists "scripts/_validate_common.py" \
  "общий модуль валидаторов должен быть доставлен"
assert_file_exists ".nauta-scripts-basis.yaml" \
  "базис синка должен быть создан"

# AC-10: собственные гейты остались нашими — deliver.sh относит их к «чужим».
assert_grep "scripts/check.sh" "gramax-marketplace" \
  "AC-10: scripts/check.sh должен остаться версией gramax, не nauta"
assert_grep ".githooks/pre-commit" "scripts/check.sh --fast" \
  "AC-10: .githooks/pre-commit должен остаться версией gramax"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002: валидаторы nauta доставлены, собственные гейты не тронуты"
