#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-169-dir-without-index-flag-ok.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-169 (FR-225 ветка (в))
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.4 (шаг 4: литерал
# — каталог, только при index_optional=True; validate_structure.py передаёт флаг из
# indexPolicy.subfolderOptionalFlag корня), §6.4 (строка 2, regression guard); ADR-0028
# Решение 4; ADR-0026 Решение 4 (ветка «с флагом — тишина» не добавляет ошибок штатным
# состояниям, NFR-001).
# Проверка (фикстура dir-without-index-flag: тот же каталог с optionalCategoryIndex:
#   true): находок по ссылке нет — rc=0.
# Warden (зелёный при рождении, 6e2db04): сегодня ссылка «резолвится» побочно (exists()
#   истинен для директорий) — тест фиксирует наблюдаемое поведение, не путь резолва.
# Мутация к красному (исполнена на scratch-копии): убрать шаг 4 (эквивалент на нынешнем
#   коде — exists() → is_file() в _resolve_link_target) → ссылка перестаёт резолвиться,
#   нога «битая ссылка» краснеет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/dir-without-index-flag"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_exit_zero "$RC" "AC-169: каталог без _index.md с optionalCategoryIndex: true — rc=0 (штатное состояние, ADR-0026 Решение 4)"

if printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF "битая ссылка"; then
  echo "  FAIL: AC-169 — находка по ссылке [x](section) не допускается при optionalCategoryIndex: true (шаг 4: литерал — каталог при index_optional)" >&2
  printf '%s\n' "$OUT" | grep -F "article.md" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "missing _index.md"; then
  echo "  FAIL: AC-169 — флаг обязан снимать структурное missing _index.md (строго YAML true, ADR-0026 Решение 4)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-169: AC-169 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-169: AC-169 — тот же каталог с флагом true тих: находок по ссылке нет (regression guard)"
