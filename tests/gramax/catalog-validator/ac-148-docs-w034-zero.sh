#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-148-docs-w034-zero.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-148 (FR-216)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-137
# (вторая половина FR-216): три W034-плейсхолдера на docs/ —
#   docs/00-project/adr/0021-docs-layout-inversion.md:389 (<home>, дважды, без code-span),
#   docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md:191 (<file>),
#   docs/60-implementation/2026-08-13-doc-root-discovery-dev-notes.md:42 (<raw>);
#   в двух последних строках нечётное число бэктиков разрывает code-span.
# Проверка: прогон validate_structure.py по docs/ → ноль W034-строк.
# Догфудинг-паттерн: ac-035 (AC-162) — прогон по живому docs/.
# Red on 7553da1: три W034-плейсхолдера (замер 2026-11-23, дословно совпадает с §6 дизайна).
# Владелец правки docs/ — Dev (формулировка или code-span); docs/ стабом не правится.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DOCS="$ROOT/docs"

OUT_FILE="$SCRIPT_DIR/.ac-148-out.txt"
trap 'rm -f "$OUT_FILE"' EXIT
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$DOCS" > "$OUT_FILE" 2>&1); then
  RC=0
else
  RC=$?
fi
if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-148 — validate_structure.py docs обязан заканчиваться с rc=0 (0 ERROR)" >&2
  FAIL=$((FAIL + 1))
fi

W034_COUNT=$(grep -c "W034" "$OUT_FILE" || true)

if [ "$W034_COUNT" -ne 0 ]; then
  echo "  FAIL: AC-148 — прогон validate_structure по docs/ обязан давать 0 W034 (сейчас: $W034_COUNT); плейсхолдеры путей устраняются формулировкой или code-span" >&2
  grep "W034" "$OUT_FILE" | head -5 >&2
  FAIL=$((FAIL + 1))
fi

rm -f "$OUT_FILE"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-148: AC-148 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-148: AC-148 — docs/ без W034-плейсхолдеров"
