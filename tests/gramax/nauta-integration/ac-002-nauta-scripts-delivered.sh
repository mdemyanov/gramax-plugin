#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-002-nauta-scripts-delivered.sh
# Спека: спека волны nauta-integration (2026-08-07; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021) FR-7
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
  "валидатор каталога должен быть доставлен"
assert_file_exists "scripts/_validate_common.py" \
  "общий модуль валидаторов должен быть доставлен"
assert_file_exists ".nauta-scripts-basis.yaml" \
  "базис синка должен быть создан"

# AC-10 (позиция PM после qa-057 F2): canon-раннер scripts/check.sh (nauta, ADR-037) —
# принятое состояние дерева; payload-синки 1f44891/bfc0aa7/849e1da — committed decisions.
# Владение гейтами контролируется парой «делегирование + носитель»: projectGates в
# .nauta-gates.yaml передаёт быстрый/полный гейт в scripts/check-gramax.sh, где живут
# грамax-гейты. Прежний маркер «check.sh должен остаться версией gramax» ретирирован
# вместе с умершей посылкой (canon-файл маркер не несёт по построению).
assert_grep ".nauta-gates.yaml" "gate-gramax-fast.sh" \
  "AC-10: projectGates делегирует быстрый гейт в scripts/gate-gramax-fast.sh (носитель владения — конфиг, ADR-077)"
assert_file_exists "scripts/check-gramax.sh" \
  "AC-10: проектный гейт-раннер scripts/check-gramax.sh должен существовать"
assert_grep "scripts/check-gramax.sh" "gramax-marketplace" \
  "AC-10: scripts/check-gramax.sh несёт грамax-гейты (носитель владения — проектный раннер)"
assert_grep ".githooks/pre-commit" "scripts/check.sh --fast" \
  "AC-10: .githooks/pre-commit остаётся проводкой быстрого гейта"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002: валидаторы nauta доставлены; грамax-гейты делегируются через projectGates в check-gramax.sh"
