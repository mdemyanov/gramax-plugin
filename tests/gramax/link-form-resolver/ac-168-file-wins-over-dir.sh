#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-168-file-wins-over-dir.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-168 (FR-225 ветка (г))
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.4 (правило 2:
# при одноимённых файле и каталоге побеждает файл — каталог не проходит шаг 1 is_file(),
# файл находится на шаге 2), §6.4 (строка 3); ADR-0028 Решение 4; факт движка
# linkCreator.ts:156-162 («папка — не файл»).
# Проверка (фикстура file-wins-over-dir: [x](section) при существующих section.md и
#   section/_index.md): входящей считается section.md — находка «статья-сирота» на
#   section.md исчезает, битой ссылки на "section" нет.
# Red on 6e2db04: шаг 1 резолвера возвращает каталог по exists() — ссылка считается
#   входящей у каталога, section.md остаётся «сиротой» (замер 2026-11-24 — дизайн §2:
#   «ссылка резолвится в каталог; section.md получает WARNING статья-сирота»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/file-wins-over-dir"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_exit_zero "$RC" "AC-168: при побеждающем файле находок не остаётся — rc=0"

if printf '%s\n' "$OUT" | grep -F "section.md" | grep -qF "статья-сирота"; then
  echo "  FAIL: AC-168 RED — section.md остаётся «сиротой»: ссылка [x](section) засчитана каталогу, а не файлу (ADR-0028 Решение 4: «при одноимённых файле и каталоге побеждает файл»; замер 2026-11-24)" >&2
  printf '%s\n' "$OUT" | grep -F "статья-сирота" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF "битая ссылка"; then
  echo "  FAIL: AC-168 — ссылка [x](section) обязана резолвиться в section.md (шаг 2), битой ссылки нет" >&2
  printf '%s\n' "$OUT" | grep -F "article.md" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "missing _index.md"; then
  echo "  FAIL: AC-168 — section/_index.md на месте, структурное правило молчит (фикстура одноимённости, не ветка без индекса)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-168: AC-168 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-168: AC-168 — при одноимённых файле и каталоге входящей считается section.md, сирот и битых ссылок нет"
