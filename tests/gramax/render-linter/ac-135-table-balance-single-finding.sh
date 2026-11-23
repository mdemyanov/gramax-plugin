#!/usr/bin/env bash
# tests/gramax/render-linter/ac-135-table-balance-single-finding.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-135 в части рендера (FR-214, BR-027)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.2
# (баланс table/tr/td ведёт только validate_render через balanceTags; validate_structure
# их не балансирует — один дефект, одна находка), ADR-0026 Решение 2.
# Природа: ЗЕЛЁНЫЙ С РОЖДЕНИЯ — варден BR-027 (замер 2026-11-23: validate_render даёт
# ровно одну находку «Несбалансированный <td>», validate_structure молчит уже сегодня).
# Опасность, которую сторожит: при расширении pairedTags (Решение 2) баланс мог бы
# задвоиться структурным валидатором или исчезнуть из рендер-линтера — любая из этих
# регрессий красит стаб. Обоснование зелёного рождения — как у warden-ног ac-026/ac-029:
# проверяемое поведение уже в дереве и обязано ПЕРЕЖИТЬ правку контракта.
# Проверка:
#   (a) незакрытый <td> → у validate_render ровно одна баланс-находка, rc=1;
#   (b) validate_structure на том же файле — ноль баланс-находок (дубля нет);
#   (c) валидная таблица → validate_render чист, rc=0.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BAD="$SCRIPT_DIR/fixtures/ac-135-unbalanced-td.md"
GOOD="$SCRIPT_DIR/fixtures/ac-135-balanced-table.md"

# --- (a): одна баланс-находка от validate_render ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$BAD" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "1" "AC-135 (BR-027): незакрытый <td> — rc=1"

BALANCE_COUNT=$(printf '%s\n' "$OUT" | grep -c "Несбалансированный" || true)
assert_eq "$BALANCE_COUNT" "1" "AC-135 (BR-027): ровно одна баланс-находка на незакрытый <td>"

if ! printf '%s\n' "$OUT" | grep -qF "Несбалансированный <td>"; then
  echo "  FAIL: AC-135 (BR-027) — баланс <td> обязан остаться за validate_render (balanceTags)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): дубля от validate_structure нет ---
if OUT_STRUCT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$BAD" 2>&1); then
  RC_STRUCT=0
else
  RC_STRUCT=$?
fi
if printf '%s\n' "$OUT_STRUCT" | grep -qE 'unpaired <(table|tr|td)>|Несбалансированный'; then
  echo "  FAIL: AC-135 (BR-027) — validate_structure не должен балансировать table/tr/td: расширение pairedTags не вводит вторую находку" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): валидная таблица — validate_render чист ---
if OUT_GOOD=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$GOOD" 2>&1); then
  RC_GOOD=0
else
  RC_GOOD=$?
fi
assert_exit_zero "$RC_GOOD" "AC-135 (BR-027): валидная XML-таблица — validate_render чист (rc=0)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-135: AC-135 (рендер) — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-135: BR-027 — баланс table/tr/td несёт только validate_render, одной находкой (warden)"
