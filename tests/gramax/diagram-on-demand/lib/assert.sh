#!/usr/bin/env bash
# tests/gramax/diagram-on-demand/lib/assert.sh
# Mini assertion library for diagram-on-demand smoke tests.
# No external dependencies. Used by all ac-NNN-*.sh test files.

# Global failure counter — each test file sources this lib and uses FAIL.
# Individual test files must declare: FAIL=0 before sourcing or after.

assert_file_exists() {
  local path="$1" msg="${2:-file should exist}"
  if [ ! -f "$path" ]; then
    echo "FAIL: $msg — file not found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_exists() {
  local path="$1" msg="${2:-file should NOT exist}"
  if [ -f "$path" ]; then
    echo "FAIL: $msg — file unexpectedly found: $path" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep() {
  local file="$1" pattern="$2" msg="${3:-pattern should be found in file}"
  if ! grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "FAIL: $msg — pattern '$pattern' not found in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_regex() {
  local file="$1" pattern="$2" msg="${3:-regex should match in file}"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "FAIL: $msg — regex '$pattern' not matched in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_stdout() {
  local output="$1" pattern="$2" msg="${3:-pattern should be in stdout}"
  if ! echo "$output" | grep -qF "$pattern"; then
    echo "FAIL: $msg — pattern '$pattern' not found in output" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_not_grep_stdout() {
  local output="$1" pattern="$2" msg="${3:-pattern should NOT be in stdout}"
  if echo "$output" | grep -qF "$pattern"; then
    echo "FAIL: $msg — unexpected pattern '$pattern' found in output" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local actual="$1" expected="$2" msg="${3:-exit code should match}"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $msg — expected exit code $expected, got $actual" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_eq() {
  local actual="$1" expected="$2" msg="${3:-values should be equal}"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $msg — expected '$expected', got '$actual'" >&2
    FAIL=$((FAIL + 1))
  fi
}
