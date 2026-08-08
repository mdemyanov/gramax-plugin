#!/usr/bin/env bash
# scripts/check.sh — light pre-commit/pre-merge gate для gramax-marketplace.
# Без profile-валидаторов (профилей нет). Валидатор content/ — из nauta,
# доставлен через /nauta:sync-scripts, обновляется тем же каналом.
#
# Modes:
#   --fast   : whitespace + JSON validity + validate-content.py (uv обязателен; для pre-commit hook)
#   --full   : --fast + shellcheck (если установлен) + проверка submodule status
#
# Exit codes:
#   0 — all checks passed
#   1 — at least one check failed

set -euo pipefail

MODE="${1:---fast}"
FAILED=0

echo "==> mode: $MODE"

# --- 1. Whitespace check on staged/all files ---
echo "==> whitespace"
if git diff --check HEAD -- 2>&1 | grep -q .; then
  git diff --check HEAD --
  echo "FAIL: trailing whitespace or mixed indent detected"
  FAILED=1
else
  echo "OK: no whitespace issues"
fi

# --- 2. JSON validity for tracked .json files ---
echo "==> json"
JSON_FILES=$(git ls-files '*.json' 2>/dev/null || true)
if [ -n "$JSON_FILES" ]; then
  for f in $JSON_FILES; do
    # Skip submodule contents (claude-mermaid)
    if [[ "$f" == plugins/claude-mermaid/* ]]; then continue; fi
    if ! python3 -m json.tool "$f" > /dev/null 2>&1; then
      echo "FAIL: invalid JSON: $f"
      FAILED=1
    fi
  done
  echo "OK: JSON validated"
else
  echo "OK: no JSON files tracked"
fi

# --- 2.5. Gramax content/ validation (валидатор nauta, PEP 723) ---
echo "==> content"
if [ -d content ]; then
  if command -v uv > /dev/null 2>&1; then
    if ! uv run scripts/validate-content.py; then
      echo "FAIL: content/ validation"
      FAILED=1
    else
      echo "OK: content validated"
    fi
  else
    echo "FAIL: uv not installed — content/ validation not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi
else
  echo "OK: no content/ directory"
fi

# --- 3. (--full only) Shellcheck on tracked .sh files, if installed ---
if [ "$MODE" = "--full" ]; then
  echo "==> shellcheck"
  if command -v shellcheck > /dev/null 2>&1; then
    SH_FILES=$(git ls-files '*.sh' 2>/dev/null | grep -v '^plugins/claude-mermaid/' || true)
    if [ -n "$SH_FILES" ]; then
      # shellcheck disable=SC2086
      if ! shellcheck $SH_FILES; then
        echo "FAIL: shellcheck issues"
        FAILED=1
      else
        echo "OK: shellcheck clean"
      fi
    else
      echo "OK: no shell files tracked"
    fi
  else
    echo "WARN: shellcheck not installed — skipping"
  fi

  # --- 4. (--full only) Submodule status ---
  echo "==> submodule status"
  if git submodule status 2>&1 | grep -q '^[+-]'; then
    echo "WARN: submodule out of sync (not a hard fail)"
    git submodule status
  else
    echo "OK: submodules in sync"
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "==> RESULT: FAIL"
  exit 1
fi

echo "==> RESULT: PASS"
