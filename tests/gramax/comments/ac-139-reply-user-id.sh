#!/usr/bin/env bash
# tests/gramax/comments/ac-139-reply-user-id.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-139 (FR-218)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-139
# (предупреждение об ответе без user.id — уровень warning; обе формы пустых answers
# не меняются); beads gramax-4jf.11 (у автора ответа user.id есть в 266 из 271 и равен mail).
# Проверка:
#   (a) validate_comments: ответ без user.id → WARNING, упоминание user.id;
#   (b) форма answers: [] и отсутствие ключа answers — rc=0 без находок (сохраняются);
#   (c) шаблон ответа comments-write содержит id, равный mail, под user;
#   (d) регресс-нога: предупреждение о дубликатах ответов остаётся.
# Red on 7553da1: validate_answers не читает user.id (замер 2026-11-23: ответ без
#   user.id — тишина, rc=0); шаблон ответа в comments-write/SKILL.md («Операция 2:
#   Ответить») несёт user без id.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-139-reply"

# --- (a): ответ без user.id → warning ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/full.md" 2>&1); then
  RC=0
else
  RC=$?
fi

if ! printf '%s\n' "$OUT" | grep -qi "warning"; then
  echo "  FAIL: AC-139 — ответ без user.id обязан давать предупреждение (FR-218; замер 2026-11-23: тишина)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qi "user.id"; then
  echo "  FAIL: AC-139 — предупреждение обязано называть user.id ответа" >&2
  FAIL=$((FAIL + 1))
fi
assert_eq "$RC" "0" "AC-139: отсутствие user.id — warning, не error (rc=0 без --strict; уровень — дизайн §6)"

# --- (b): обе формы пустых answers проходят без предупреждений ---
if OUT_EMPTY=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/empty-list.md" 2>&1); then
  RC_EMPTY=0
else
  RC_EMPTY=$?
fi
assert_exit_zero "$RC_EMPTY" "AC-139: форма answers: [] — проходит (факт 9: 253 треда)"

if printf '%s\n' "$OUT_EMPTY" | grep -qi "warning"; then
  echo "  FAIL: AC-139 — форма answers: [] не должна давать предупреждений" >&2
  FAIL=$((FAIL + 1))
fi

if OUT_NOKEY=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/no-key.md" 2>&1); then
  RC_NOKEY=0
else
  RC_NOKEY=$?
fi
assert_exit_zero "$RC_NOKEY" "AC-139: отсутствие ключа answers — проходит (факт 9: 79 тредов)"

if printf '%s\n' "$OUT_NOKEY" | grep -qi "warning"; then
  echo "  FAIL: AC-139 — отсутствие ключа answers не должно давать предупреждений" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): шаблон ответа comments-write несёт id, равный mail, под user ---
WRITE_SKILL="$ROOT/plugins/gramax/skills/comments-write/SKILL.md"
TEMPLATE_ID=$(awk '/## Операция 2: Ответить/,/## Операция 3/' "$WRITE_SKILL" | grep -c 'id:' || true)
if [ "$TEMPLATE_ID" -eq 0 ]; then
  echo "  FAIL: AC-139 — шаблон ответа в comments-write («Операция 2: Ответить») обязан содержать id под user, равный mail (красный на 7553da1: user несёт только mail и name)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): регресс-нога — дубликаты ответов по-прежнему ловятся ---
if OUT_DUP=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/dup-answers.md" 2>&1); then
  RC_DUP=0
else
  RC_DUP=$?
fi

if ! printf '%s\n' "$OUT_DUP" | grep -qF 'duplicate answer'; then
  echo "  FAIL: AC-139 регрессия — предупреждение «duplicate answer» обязано остаться: правка контура answers не должна снять существующую проверку" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-139: AC-139 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-139: AC-139 — ответ без user.id даёт warning, обе пустые формы answers проходят, шаблон несёт id=mail"
