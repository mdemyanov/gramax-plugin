#!/usr/bin/env bash
# tests/gramax/diagram-on-demand/run.sh
# Entry point: запускает все 12 AC-тестов для фичи diagram-on-demand.
#
# TDD-фаза: все тесты ДОЛЖНЫ падать (Dev ещё не реализовал фичу).
# После реализации Dev'ом: все тесты должны проходить.
#
# Использование:
#   bash tests/gramax/diagram-on-demand/run.sh
#
# Exit code:
#   0 — все тесты прошли (зелёная фаза — после реализации)
#   1 — есть упавшие тесты

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0
FAIL=0
FAIL_NAMES=()

run_test() {
  local test_file="$1"
  local test_name
  test_name="$(basename "$test_file")"
  echo "==> $test_name"
  if bash "$test_file"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAIL_NAMES+=("$test_name")
  fi
  echo ""
}

# Запуск всех ac-NNN-*.sh в порядке номеров
for test_file in "$DIR"/ac-[0-9][0-9][0-9]-*.sh; do
  if [ -f "$test_file" ]; then
    run_test "$test_file"
  fi
done

echo "============================================"
echo "Results: passed=$PASS failed=$FAIL"
echo "============================================"

if [ "${#FAIL_NAMES[@]}" -gt 0 ]; then
  echo "Failed tests:" >&2
  for name in "${FAIL_NAMES[@]}"; do
    echo "  - $name" >&2
  done
  exit 1
fi

echo "All tests passed."
exit 0
