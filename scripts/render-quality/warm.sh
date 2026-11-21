#!/usr/bin/env bash
# scripts/render-quality/warm.sh — единый рычаг прогрева окружения прибора рендер-проб
# (ADR-0025 Решение 2; дизайн, Решения 1/2): 1) кэш uv для playwright==<pin>;
# 2) браузер chromium в штатный пользовательский кэш playwright (вне репо);
# 3) --check-env прибора (цель -> импорт playwright -> браузер). Идемпотентен:
# повторный запуск ничего не ломает и сходится к зелёному check-env.
# Пин читается одной строкой из probe.sh — единственного дома пина (дизайн, Решение 3).

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_LINE="$(grep -E '^PLAYWRIGHT_PIN=' "$SCRIPT_DIR/probe.sh" | head -1)"
PLAYWRIGHT_PIN="${PIN_LINE#PLAYWRIGHT_PIN=}"
PLAYWRIGHT_PIN="${PLAYWRIGHT_PIN//\"/}"
if [ -z "$PLAYWRIGHT_PIN" ]; then
  echo "FAIL: warm — не смог прочитать PLAYWRIGHT_PIN из scripts/render-quality/probe.sh" >&2
  exit 2
fi

echo "==> warm: кэш uv для playwright==${PLAYWRIGHT_PIN}"
if ! uv run --quiet --with "playwright==${PLAYWRIGHT_PIN}" python -c 'import playwright'; then
  echo "FAIL: warm — uv не поставил playwright==${PLAYWRIGHT_PIN} (сеть/кэш);" >&2
  echo "  проверь сеть и повтори: bash scripts/render-quality/warm.sh" >&2
  exit 2
fi

echo "==> warm: playwright install chromium (пользовательский кэш, вне репо)"
if ! uv run --quiet --with "playwright==${PLAYWRIGHT_PIN}" playwright install chromium; then
  echo "FAIL: warm — playwright install chromium упал (сеть); проверь сеть и повтори" >&2
  exit 2
fi

echo "==> warm: check-env прибора"
bash "$SCRIPT_DIR/probe.sh" --check-env
