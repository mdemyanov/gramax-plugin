#!/usr/bin/env bash
# scripts/install-hooks.sh — активирует .githooks/ как hook directory для git.
# Идемпотентен: повторный запуск не ломает.
# Disable: git config --unset core.hooksPath
# Bypass на коммит: git commit --no-verify

set -euo pipefail

if [ ! -d .githooks ]; then
  echo "FAIL: .githooks/ directory not found"
  exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

echo "OK: git hooks activated from .githooks/"
echo "  to disable: git config --unset core.hooksPath"
echo "  to bypass once: git commit --no-verify"
