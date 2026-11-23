#!/usr/bin/env bash
# tests/gramax/comments/ac-129-multiposition-id.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-129 (FR-210)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-129
# (несколько позиций разметки у одного ID — штатная конструкция движка
# BlockMark.getCommentPosition(); «показывает ID с его позициями» — строка уровня info,
# на rc не влияет, --strict не эскалирует).
# Проверка: фикстура с одним ID в двух позициях md + парный .comments.yaml →
#   (a) rc=0, «duplicate comment id» нет; (b) ID упомянут в выводе (информационная строка);
#   (c) --strict тоже rc=0 — info не эскалируется.
# Негатив-нога (маскированный отказ): невалидный формат ID (abc!) — «invalid comment id
#   format» обязан остаться (снятие проверки уникальности не снимает проверку формата).
# Red on 7553da1: validate_comments.py:61-67 ставит ERROR «duplicate comment id in md»
#   на любую вторую позицию ID (замер 2026-11-23: rc=1 на фикстуре page.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-129-multiposition"

# --- (a)+(b): мультипозиционный ID — не ошибка, ID показан ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/page.md" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "AC-129: ID в двух позициях md — не ошибка, rc=0 (FR-210)"

if printf '%s\n' "$OUT" | grep -qF 'duplicate comment id'; then
  echo "  FAIL: AC-129 — повторный ID в md не должен давать «duplicate comment id» (несколько позиций — штатная конструкция движка)" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$OUT" | grep -qF 'abcde'; then
  echo "  FAIL: AC-129 — вывод должен показывать ID с его позициями (информационная строка), а не молчать" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): info-уровень не эскалируется --strict'ом ---
if OUT_STRICT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/page.md" --strict 2>&1); then
  RC_STRICT=0
else
  RC_STRICT=$?
fi
assert_eq "$RC_STRICT" "0" "AC-129: информационная строка о позициях не эскалируется --strict'ом (дизайн §6: на rc не влияет)"

# --- негатив-нога: проверка формата ID остаётся ---
if OUT_BAD=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/invalid-id.md" 2>&1); then
  RC_BAD=0
else
  RC_BAD=$?
fi
assert_eq "$RC_BAD" "1" "AC-129 негатив: невалидный формат ID (abc!) по-прежнему даёт rc=1"

if ! printf '%s\n' "$OUT_BAD" | grep -qF 'invalid comment id format'; then
  echo "  FAIL: AC-129 негатив — «invalid comment id format» обязан остаться: снятие проверки уникальности не снимает проверку формата" >&2
  FAIL=$((FAIL + 1))
fi

# --- parse_comments: отчёт по мультипозиционному файлу не падает и показывает ID ---
if OUT_PARSE=$(cd "$ROOT" && uv run plugins/gramax/scripts/parse_comments.py "$FIXTURE/page.md" 2>&1); then
  RC_PARSE=0
else
  RC_PARSE=$?
fi
assert_exit_zero "$RC_PARSE" "AC-129: parse_comments на мультипозиционном файле — rc=0"

if ! printf '%s\n' "$OUT_PARSE" | grep -qF 'abcde'; then
  echo "  FAIL: AC-129 — отчёт parse_comments обязан показывать мультипозиционный ID" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-129: AC-129 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-129: AC-129 — ID в нескольких позициях md не ошибка, ID показан, формат-ID проверка сохранена"
