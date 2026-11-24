#!/usr/bin/env bash
# tests/gramax/writer-sync-470/lib/assert.sh
# Копия tests/gramax/writer-consumer-rules/lib/assert.sh (та же природа — копия
# tests/gramax/mermaid-adoption/lib/assert.sh); suite'ы не шарят lib/ между собой
# (прецедент doc-paths/plugin-contract/catalog-validator/mermaid-adoption/
# writer-consumer-rules). Два добавленных хелпера для байтовых негативов
# AC-079/AC-082 и старого примера <view> — фиксированная строка рекурсивно.
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
  local file="$1" pattern="$2" msg="${3:-regex "'\$pattern'" should match in file}"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — regex '$pattern' not matched in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_regex_i() {
  local file="$1" pattern="$2" msg="${3:-case-insensitive regex should match in file}"
  if ! grep -qiE "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — regex (case-insensitive) '$pattern' not matched in $file" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_word() {
  local file="$1" pattern="$2" msg="${3:-whole word should be found in file}"
  if ! grep -qw "$pattern" "$file" 2>/dev/null; then
    echo "  FAIL: $msg — word '$pattern' not found in $file" >&2
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

# Фиксированная строка (не regex) рекурсивно — для байтовых негативов AC-079
# ('<gallery', 'display="Gantt"'), AC-082 ('cover=') и старого примера <view>.
assert_no_grep_fixed_recursive() {
  local dir="$1" pattern="$2" msg="${3:-fixed string should NOT appear recursively}"
  local matches
  matches=$(grep -rnF "$pattern" "$dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$matches" -gt 0 ]; then
    echo "  FAIL: $msg — fixed string '$pattern' found $matches time(s) under $dir" >&2
    grep -rnF "$pattern" "$dir" 2>/dev/null | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_fixed_recursive() {
  local dir="$1" pattern="$2" msg="${3:-fixed string should appear somewhere under dir}"
  if ! grep -rqF "$pattern" "$dir" 2>/dev/null; then
    echo "  FAIL: $msg — fixed string '$pattern' not found anywhere under $dir" >&2
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

# Читает gramax-tags.json и печатает через пробел теги из $2, отсутствующие в
# списке $1 (selfClosingTags|pairedTags). Пустой вывод — все на месте.
# SUBSET-семантика по уроку «неубиваемого теста» (catalog-validator ac-011):
# контракт вправе быть шире, равенство не требуется; diagramTags/schemaVersion
# ADR-0024 (Решение 3) не трогаются и не сверяются на равенство.
tags_contract_missing() {
  local tags_file="$1" list="$2"; shift 2
  python3 - "$tags_file" "$list" "$@" <<'PY'
import json, sys

tags_file, list_name, required = sys.argv[1], sys.argv[2], set(sys.argv[3:])
try:
    contract = json.load(open(tags_file, encoding="utf-8"))
except (json.JSONDecodeError, OSError) as e:
    print(f"PARSE_ERROR:{e}")
    sys.exit(0)

items = set(contract.get(list_name) or [])
missing = sorted(required - items)
if missing:
    print(" ".join(missing))
PY
}

# Цвет-хелперы
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass_msg() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; }
fail_msg() { printf "${RED}[FAIL]${NC} %s\n" "$1"; }
