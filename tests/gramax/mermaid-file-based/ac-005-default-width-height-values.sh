#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-005-default-width-height-values.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 5)
# AC coverage:
#   AC-005 → тег в md использует дефолты width="800px" height="450px",
#             если пользователь не задал явно
#
# TDD stub: ПАДАЕТ пока Dev не реализует вставку тега с дефолтными значениями.
#
# Уровень: smoke (grep на точный паттерн дефолтов)
# Граничные кейсы:
#   - пользователь не указал ни width ни height → оба дефолтные
#   - пользователь указал только width=1200px → height дефолтный 450px
#   (второй boundary смоделирован как TODO-комментарий, т.к. не может быть
#    автоматически проверен без вызова skill'а)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# --- Setup ---
mkdir -p "$TMPDIR_TEST/docs/api"
TARGET_PAGE="$TMPDIR_TEST/docs/api/endpoints.md"
cp "$SCRIPT_DIR/fixtures/clean-article.md" "$TARGET_PAGE"

# --- AC-005: дефолты width="800px" height="450px" (blocks.md ground-truth) ---
echo "TODO: AC-005 — skill без явных width/height должен вставить width=\"800px\" height=\"450px\"" >&2
echo "  Ожидается: grep -q 'width=\"800px\" height=\"450px\"' $TARGET_PAGE" >&2

assert_grep "$TARGET_PAGE" 'width="800px" height="450px"' \
  "AC-005: тег должен содержать дефолтные значения width=\"800px\" height=\"450px\""

# --- Boundary (reference fixture): expected-tag.md уже содержит корректные дефолты ---
FIXTURE="$SCRIPT_DIR/fixtures/expected-tag.md"
if [ -f "$FIXTURE" ]; then
  assert_grep "$FIXTURE" 'width="800px" height="450px"' \
    "AC-005 fixture: expected-tag.md демонстрирует правильный формат дефолтов"
fi

# --- Boundary NOTE (не автоматизировано): ---
# Если пользователь указал width=1200px без height:
#   тег должен быть: width="1200px" height="450px"
# Если пользователь указал height=600px без width:
#   тег должен быть: width="800px" height="600px"
# Эти кейсы проверяются вручную QA-runner после реализации Dev.

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005-default-width-height-values: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005-default-width-height-values: тег содержит дефолтные width=\"800px\" height=\"450px\""
