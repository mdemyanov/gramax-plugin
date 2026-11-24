#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-187-enumeration-without-marker.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-187 (FR-230, случай 2)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.8 (ожидаемое
# поведение случая 2: перечисление без маркера — нет слова направления в окне и нет
# пункта списка с меткой — спаны остаются SUBJECT: в отчёте их нет, --fix --yes их не
# трогает, счётчик SUBJECT растёт; NAV в каталоге нет — rc=0, To-migrate: 0. Основание —
# Решение 3 ADR-0016 и точечный проход FR-235), §6.8 (строка 2, regression guard);
# ADR-0028 Решение 8.
# Проверка (фикстура fixtures/no-marker: content/no-marker.md с «Требования:
#   `content/a.md`, `content/b.md`» — метка с двоеточием, но без пункта списка; цели
#   a.md/b.md существуют, чтобы классификация судила маркер, а не существование цели;
#   работа на копии в mktemp, никогда напрямую на фикстуре — по прецеденту
#   lib/fixtures.sh; имя content/ в копии сохраняется — классификатор кандидатов требует
#   код-спан вида `<root.name>/…\.md`).
# Warden (зелёный при рождении, 6e2db04): код уже ведёт себя так — фиксирует контракт
#   против регрессии «принять метку с двоеточием за маркер пункта списка» (мутация §6.8).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
# Копия сохраняет имя корня content/: классификатор кандидатов требует код-спан вида
# `<root.name>/…\.md` — на безымянном mktemp-каталоге кандидаты бы не нашлись.
WORKDIR="$(mktemp -d)"
cp -R "$SCRIPT_DIR/fixtures/no-marker/." "$WORKDIR/"
trap 'rm -rf "$WORKDIR"' EXIT

BEFORE=$(cat "$WORKDIR/content/no-marker.md")

# --- отчёт: SUBJECT: 2, строк NAV -> нет, rc=0 ---
if OUT_REP=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" 2>&1); then
  RC_REP=0
else
  RC_REP=$?
fi
assert_exit_zero "$RC_REP" "AC-187: отчёт при отсутствии NAV — rc=0 (дизайн §3.8 случай 2)"
assert_eq "$(printf '%s\n' "$OUT_REP" | grep -cF 'NAV ->')" "0" "AC-187: строк NAV -> быть не должно — перечисление без маркера направления и без пункта списка не классифицируется NAV"
if ! printf '%s\n' "$OUT_REP" | grep -qF "SUBJECT: 2"; then
  echo "  FAIL: AC-187 RED — оба спана обязаны остаться SUBJECT (счётчик SUBJECT: 2; получено: «$(printf '%s\n' "$OUT_REP" | grep -F 'SUBJECT:')») — рост SUBJECT фиксирует, что классификатор не принял метку с двоеточием за маркер (мутация §6.8)" >&2
  printf '%s\n' "$OUT_REP" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_REP" | grep -qF "To-migrate: 0"; then
  echo "  FAIL: AC-187 — To-migrate: 0 при отсутствии NAV (получено: «$(printf '%s\n' "$OUT_REP" | grep -F 'To-migrate:')»)" >&2
  FAIL=$((FAIL + 1))
fi

# --- --fix --yes --expect-count=0: rc=0, файл не тронут ---
if OUT_FIX=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=0 2>&1); then
  RC_FIX=0
else
  RC_FIX=$?
fi
assert_exit_zero "$RC_FIX" "AC-187: --fix --yes без NAV — rc=0 (hard guard expect-count=0 исполнен)"
if ! printf '%s\n' "$OUT_FIX" | grep -qF "Migrated: 0"; then
  echo "  FAIL: AC-187 — Migrated: 0 — мигрировать нечего (получено: «$(printf '%s\n' "$OUT_FIX" | grep -F 'Migrated:')»)" >&2
  FAIL=$((FAIL + 1))
fi

AFTER=$(cat "$WORKDIR/content/no-marker.md")
if [ "$BEFORE" != "$AFTER" ]; then
  echo "  FAIL: AC-187 — файл изменён миграцией: SUBJECT-спаны --fix --yes не трогает (дизайн §3.8 случай 2; Решение 3 ADR-0016)" >&2
  diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") >&2
  FAIL=$((FAIL + 1))
fi
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if ! grep -qF '`content/a.md`' "$WORKDIR/content/no-marker.md"; then
  echo "  FAIL: AC-187 — код-спан content/a.md исчез из файла без классификации NAV" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-187: AC-187 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-187: AC-187 — перечисление без маркера остаётся SUBJECT: 2, отчёт и --fix не трогают файл (regression guard)"
