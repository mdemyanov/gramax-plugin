#!/usr/bin/env bash
# tests/gramax/render-linter/ac-137-html-block-render.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-137 (FR-216)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-137
# (маска применяется ПОСЛЕ _mask_code — <html> внутри кода маску не переключает; читают
# маску построчные проверки и баланс validate_render); beads gramax-4jf.9.
# Проверка:
#   (a) приманка в html-блоке (инлайновый <note> в одну строку + незакрытый <td>) →
#       ERROR нет, rc=0 (замер 2026-11-23: ERROR L4 «Инлайновый <note>» и баланс <td>);
#   (b) варден: <html> в inline-коде и fenced-блоке не переключает маску — настоящий
#       <th> после упоминаний по-прежнему даёт warn и баланс-ERROR (зелёная нога:
#       замер 2026-11-23 — находки есть; обязаны остаться и после посадки маски).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BAIT="$SCRIPT_DIR/fixtures/ac-137-html-bait.md"
MENTION="$SCRIPT_DIR/fixtures/ac-137-code-mention.md"

# --- (a): приманки внутри html-блока молчат ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$BAIT" 2>&1); then
  RC=0
else
  RC=$?
fi

if printf '%s\n' "$OUT" | grep -qF "Инлайновый <note>"; then
  echo "  FAIL: AC-137 — инлайновый <note> внутри html-блока не должен проверяться как разметка страницы (FR-216)" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -qF "Несбалансированный <td>"; then
  echo "  FAIL: AC-137 — незакрытый <td> внутри html-блока не должен входить в баланс (FR-216)" >&2
  FAIL=$((FAIL + 1))
fi
assert_exit_zero "$RC" "AC-137: файл-приманка (дефекты только внутри html-блока) — rc=0 (замер 2026-11-23: rc=1)"

# --- (b): варден — упоминание <html> в коде маску не переключает ---
if OUT_MENTION=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$MENTION" 2>&1); then
  RC_MENTION=0
else
  RC_MENTION=$?
fi
assert_eq "$RC_MENTION" "1" "AC-137 варден: настоящий дефект после упоминания <html> в коде — rc=1 (маска не переключилась)"

if ! printf '%s\n' "$OUT_MENTION" | grep -qF "Несбалансированный <th>"; then
  echo "  FAIL: AC-137 варден — <th> после inline-упоминания \`<html>\` обязан давать баланс-ERROR: код не переключает маску (дизайн §6)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод validate_render (приманка) ---" >&2
  printf '%s\n' "$OUT" >&2
  fail_msg "ac-137: AC-137 (рендер) — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-137: содержимое html-блока вне построчных проверок и баланса; код маску не переключает"
