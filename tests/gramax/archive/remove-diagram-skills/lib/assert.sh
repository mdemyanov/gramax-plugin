#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/lib/assert.sh
# Mini assertion library — no external dependencies.
# Each test file sources this lib and increments global FAIL.

assert_dir_not_exists() {
  local path="$1" msg="${2:-directory should NOT exist}"
  if [ -d "$path" ]; then
    echo "  FAIL: $msg — directory unexpectedly found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_dir_exists() {
  local path="$1" msg="${2:-directory should exist}"
  if [ ! -d "$path" ]; then
    echo "  FAIL: $msg — directory not found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_exists() {
  local path="$1" msg="${2:-file should NOT exist}"
  if [ -f "$path" ]; then
    echo "  FAIL: $msg — file unexpectedly found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local path="$1" msg="${2:-file should exist}"
  if [ ! -f "$path" ]; then
    echo "  FAIL: $msg — file not found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_no_grep() {
  local file="$1" pattern="$2" msg="${3:-pattern should NOT be found in file}"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — unexpected pattern '$pattern' found in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_no_grep_regex() {
  local file="$1" pattern="$2" msg="${3:-regex should NOT match in file}"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — unexpected regex '$pattern' matched in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep() {
  local file="$1" pattern="$2" msg="${3:-pattern should be found in file}"
  if ! grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — pattern '$pattern' not found in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_regex() {
  local file="$1" pattern="$2" msg="${3:-regex should match in file}"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — regex '$pattern' not matched in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_no_grep_recursive() {
  local dir="$1" pattern="$2" msg="${3:-pattern should NOT appear recursively}"
  local matches
  matches=$(grep -rn "$pattern" "$dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$matches" -gt 0 ]; then
    echo "  FAIL: $msg — '$pattern' found $matches time(s) under $dir" >&2
    grep -rn "$pattern" "$dir" 2>/dev/null | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_eq() {
  local actual="$1" expected="$2" msg="${3:-values should be equal}"
  if [ "$actual" != "$expected" ]; then
    echo "  FAIL: $msg — expected '$expected', got '$actual'" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_zero() {
  local actual="$1" msg="${2:-command should exit 0}"
  if [ "$actual" -ne 0 ]; then
    echo "  FAIL: $msg — exit code was $actual (expected 0)" >&2
    FAIL=$((FAIL + 1))
  fi
}

# Colour helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass_msg() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; }
fail_msg() { printf "${RED}[FAIL]${NC} %s\n" "$1"; }
