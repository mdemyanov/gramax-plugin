#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-168-dir-with-index-resolves.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-168 (FR-225 ветка (а))
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.4 (шаг 3:
# литерал / "_index.md"; ссылка на раздел резолвится в _index.md, поэтому #якорь раздела
# проверяется как у статьи), §6.4 (строка 4, regression guard); ADR-0028 Решение 4,
# поправка к ADR-0016 Решение 1; FR-082 (третий шаг инференса section/_index.md).
# Проверка (фикстура dir-with-index: [раздел](section) при section/_index.md и
#   section/child.md, обе с входящими): rc=0, находок по ссылкам нет.
# Warden (зелёный при рождении, 6e2db04; сестринский ac-009b — та же ветка без ребёнка).
# Мутация к красному (исполнена на scratch-копии): удалить шаг 3 (эквивалент на нынешнем
#   коде — exists() → is_file() в _resolve_link_target, литерал-каталог перестаёт
#   резолвиться) → «битая ссылка» на "section", нога краснеет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/dir-with-index"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_exit_zero "$RC" "AC-168: ссылка без расширения на раздел с _index.md — rc=0"

if printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF "битая ссылка"; then
  echo "  FAIL: AC-168 — ссылка [раздел](section) обязана резолвиться через section/_index.md (шаг 3 инференса FR-082)" >&2
  printf '%s\n' "$OUT" | grep -F "article.md" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "статья-сирота"; then
  echo "  FAIL: AC-168 — раздел с входящей ссылкой и child.md со входящей не сироты (входящие засчитаны обеим целям)" >&2
  printf '%s\n' "$OUT" | grep -F "статья-сирота" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-168: AC-168 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-168: AC-168 — ссылка на раздел с _index.md резолвится, находок нет (regression guard)"
