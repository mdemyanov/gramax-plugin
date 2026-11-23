#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-131-xml-comment-unpaired.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-131 (FR-211)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-131
# (в check_tags самозакрытый открывающий тег считается открывающим только для тега comment;
# скобочная форма считается, как прежде).
# Проверка: каталог, чьи статьи несут XML-блочную форму <comment id="ID"/> … </comment> и
#   скобочную legacy [comment:ID] … [/comment] → «unpaired <comment>» нет и
#   «unpaired [comment:id]» нет (обе формы парны).
# Red on 7553da1: regex opens в check_tags (validate_structure.py:391) не считает
#   самозакрытый тег открывающим → «unpaired <comment>: 0 open, 1 close»
#   (замер 2026-11-23 на фикстуре); нога скобочной формы — зелёный контроль.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-131-xml-comment"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

if printf '%s\n' "$OUT" | grep -qF 'unpaired <comment>'; then
  echo "  FAIL: AC-131 — «unpaired <comment>» на XML-блочной форме: самозакрытый открывающий <comment id=\"ID\"/> обязан считаться открывающим (FR-211)" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF 'unpaired [comment:id]'; then
  echo "  FAIL: AC-131 — «unpaired [comment:id]» на скобочной legacy-форме: скобочная форма обязана считаться, как прежде (8 открывающих в products-legacy)" >&2
  FAIL=$((FAIL + 1))
fi

assert_eq "$RC" "0" "AC-131: каталог с обеими блочными формами — чист (rc=0; замер 2026-11-23: rc=1 с unpaired)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-131: AC-131 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-131: AC-131 — XML-форма парна для validate_structure, скобочная legacy-форма парна как прежде"
