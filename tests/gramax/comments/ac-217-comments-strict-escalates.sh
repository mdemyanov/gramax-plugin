#!/usr/bin/env bash
# tests/gramax/comments/ac-217-comments-strict-escalates.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-217
# (добавляется BA к §6.9, пункт 11 координатора).
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.11 (--strict
# эскалирует каждое предупреждение: has_warnings_strict = args.strict и есть warning;
# уровень info не эскалируется; метка WARNING в выводе сохраняется), §6.9 (строка 2);
# ADR-0028 Решение 11 (замер-основание: --strict на фикстуре с плохим dateTime даёт
# rc=0, справка «Warnings → errors.» ложна; ни одна нога стабов волны-3 не закрепляет
# нынешнее поведение).
# Проверка (фикстура ac-217-strict): bad-dt (dateTime не ISO 8601 UTC + ответ без
#   user.id) под --strict → rc=1 с прежней меткой WARNING; без --strict → rc=0;
#   информационная строка о позициях ID (уровень info) под --strict → rc=0.
# Red on 6e2db04: main() выходит 1 только при error-находках — --strict с warning даёт
#   rc=0 (замер 2026-11-24).
# Мутация к красному: убрать has_warnings_strict из main() — нога --strict краснеет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-217-strict"

# --- --strict эскалирует предупреждение: rc=1, метка WARNING сохранена ---
if OUT_STRICT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/bad-dt.md" --strict 2>&1); then
  RC_STRICT=0
else
  RC_STRICT=$?
fi
assert_eq "$RC_STRICT" "1" "AC-217 RED: --strict на фикстуре с предупреждением — rc=1 (сегодня 0: эскалируются лишь дубликат ответа и отсутствие answers, ADR-0028 Решение 11)"

if ! printf '%s\n' "$OUT_STRICT" | grep -qF "dateTime not ISO 8601 UTC"; then
  echo "  FAIL: AC-217 — находка «dateTime not ISO 8601 UTC» обязана остаться в выводе (эскалация кода выхода, не удаление находки)" >&2
  printf '%s\n' "$OUT_STRICT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_STRICT" | grep "dateTime not ISO 8601 UTC" | grep -qF "WARNING"; then
  echo "  FAIL: AC-217 — метка обязана остаться WARNING: --strict эскалирует код выхода, а не переименует находку (дизайн §3.11: «с прежней меткой WARNING»)" >&2
  printf '%s\n' "$OUT_STRICT" | grep -F "dateTime" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_STRICT" | grep -qF "у ответа нет user.id"; then
  echo "  FAIL: AC-217 — «у ответа нет user.id» — второе предупреждение фикстуры, обязано остаться в выводе под --strict" >&2
  FAIL=$((FAIL + 1))
fi

# --- без --strict предупреждение не эскалируется (гард, зелёный и сегодня) ---
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/bad-dt.md" >/dev/null 2>&1); then
  RC_PLAIN=0
else
  RC_PLAIN=$?
fi
assert_exit_zero "$RC_PLAIN" "AC-217: без --strict предупреждения не эскалируются — rc=0 (меняется только ветка --strict)"

# --- уровень info не эскалируется (гард, зелёный и сегодня; AC-129 модель) ---
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/info.md" --strict >/dev/null 2>&1); then
  RC_INFO=0
else
  RC_INFO=$?
fi
assert_exit_zero "$RC_INFO" "AC-217: информационная строка о позициях ID не эскалируется --strict'ом (уровень info вне эскалации, дизайн §3.11; AC-129)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-217: AC-217 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-217: AC-217 — --strict эскалирует предупреждения в rc=1 с меткой WARNING, без --strict и на info — rc=0"
