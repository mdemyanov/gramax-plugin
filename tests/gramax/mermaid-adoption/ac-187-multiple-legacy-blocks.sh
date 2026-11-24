#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-187-multiple-legacy-blocks.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-187 (FR-230, случай 1)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.8 (ожидаемое
# поведение случая 1: N legacy-блоков в файле — отчёт даёт N строк путь:строка и rc=1;
# --fix --yes создаёт N файлов <page-slug>-existing[-N].mermaid, нумерация продолжает
# существующие, DSL побайтово с завершающим LF, на месте каждого блока — самозакрытый тег
# с width="800px" height="450px"; повторный отчёт — To-migrate: 0, Already-compliant: N),
# §6.8 (строка 1, regression guard); ADR-0028 Решение 8.
# Проверка (фикстура fixtures/multi-block: docs/multi.md с тремя legacy-блоками —
#   fenced, paired, fenced — и существующим multi-existing.mermaid; работа на копии в
#   mktemp, никогда напрямую на фикстуре — по прецеденту lib/fixtures.sh).
# Warden (зелёный при рождении, 6e2db04): код уже ведёт себя так — фиксирует контракт
#   против регрессии «взять только первое совпадение find_occurrences» (мутация §6.8).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WORKDIR="$(mktemp -d)"
cp -R "$SCRIPT_DIR/fixtures/multi-block/." "$WORKDIR/"

# Оракул DSL — извлечение из ПРИСТИНОЙ копии (по образцу ac-005), до миграции:
# 1-й и 3-й блоки — fenced, 2-й — paired.
EXPECTED_F1="$(mktemp)"; EXPECTED_P1="$(mktemp)"; EXPECTED_F2="$(mktemp)"
trap 'rm -rf "$WORKDIR" "$EXPECTED_F1" "$EXPECTED_P1" "$EXPECTED_F2"' EXIT
awk '/^```mermaid$/ { n++; flag=1; next } /^```$/ { flag=0; next } flag && n==1 { print }' "$WORKDIR/docs/multi.md" > "$EXPECTED_F1"
sed -n '/<mermaid>/,/<\/mermaid>/p' "$WORKDIR/docs/multi.md" | sed '1d;$d' > "$EXPECTED_P1"
awk '/^```mermaid$/ { n++; flag=1; next } /^```$/ { flag=0; next } flag && n==2 { print }' "$WORKDIR/docs/multi.md" > "$EXPECTED_F2"

# --- отчёт: три строки путь:строка, rc=1, To-migrate: 3 ---
if OUT_REP=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" 2>&1); then
  RC_REP=0
else
  RC_REP=$?
fi
assert_eq "$RC_REP" "1" "AC-187: отчёт с находками — rc=1 (дизайн §3.8 случай 1)"
assert_eq "$(printf '%s\n' "$OUT_REP" | grep -cF 'docs/multi.md:')" "3" "AC-187: отчёт даёт три строки путь:строка — N legacy-блоков мигрируются все, а не только первый (дизайн §3.8)"
if ! printf '%s\n' "$OUT_REP" | grep -qF "To-migrate: 3"; then
  echo "  FAIL: AC-187 RED — счётчик обязан называть 3 находки (получено: «$(printf '%s\n' "$OUT_REP" | grep -F 'To-migrate:')») — если меньше, мигратор взял только первое совпадение find_occurrences (мутация из §6.8)" >&2
  FAIL=$((FAIL + 1))
fi

# --- --fix --yes: rc=0, Migrated: 3, нумерация продолжает существующие ---
if OUT_FIX=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" --fix --yes 2>&1); then
  RC_FIX=0
else
  RC_FIX=$?
fi
assert_exit_zero "$RC_FIX" "AC-187: --fix --yes — rc=0"
if ! printf '%s\n' "$OUT_FIX" | grep -qF "Migrated: 3"; then
  echo "  FAIL: AC-187 — Migrated обязан назвать 3 (получено: «$(printf '%s\n' "$OUT_FIX" | grep -F 'Migrated:')»)" >&2
  FAIL=$((FAIL + 1))
fi

assert_file_exists "$WORKDIR/docs/multi-existing-2.mermaid" "AC-187: multi-existing-2.mermaid создан (первое имя занято существующим multi-existing.mermaid)"
assert_file_exists "$WORKDIR/docs/multi-existing-3.mermaid" "AC-187: multi-existing-3.mermaid создан"
assert_file_exists "$WORKDIR/docs/multi-existing-4.mermaid" "AC-187: multi-existing-4.mermaid создан"

for pair in "multi-existing-2.mermaid:$EXPECTED_F1" "multi-existing-3.mermaid:$EXPECTED_P1" "multi-existing-4.mermaid:$EXPECTED_F2"; do
  created="${pair%%:*}"
  oracle="${pair##*:}"
  if ! diff -u "$oracle" "$WORKDIR/docs/$created" >/dev/null 2>&1; then
    echo "  FAIL: AC-187 — DSL в $created не побайтово совпадает с исходным блоком (дизайн §3.8: DSL побайтово с завершающим LF)" >&2
    diff -u "$oracle" "$WORKDIR/docs/$created" 2>&1 | head -10 >&2
    FAIL=$((FAIL + 1))
  fi
done

N_TAGS=$(grep -cF '<mermaid path="./multi-existing-' "$WORKDIR/docs/multi.md")
assert_eq "$N_TAGS" "3" "AC-187: на месте каждого блока — самозакрытый тег <mermaid path=…/> (3 шт.)"
if ! grep -qF 'width="800px" height="450px"' "$WORKDIR/docs/multi.md"; then
  echo '  FAIL: AC-187 — теги на месте блоков обязаны нести дефолты ADR-0010 Решение 5: width="800px" height="450px"' >&2
  FAIL=$((FAIL + 1))
fi

# --- повторный отчёт: To-migrate: 0, Already-compliant: 3 ---
if OUT_RE2=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" 2>&1); then
  RC_RE2=0
else
  RC_RE2=$?
fi
assert_exit_zero "$RC_RE2" "AC-187: повторный отчёт после миграции — rc=0"
if ! printf '%s\n' "$OUT_RE2" | grep -qF "To-migrate: 0"; then
  echo "  FAIL: AC-187 — повторный отчёт обязан дать To-migrate: 0 (получено: «$(printf '%s\n' "$OUT_RE2" | grep -F 'To-migrate:')»)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_RE2" | grep -qF "Already-compliant: 3"; then
  echo "  FAIL: AC-187 — повторный отчёт обязан дать Already-compliant: 3" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-187: AC-187 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-187: AC-187 — три legacy-блока мигрируются все: нумерация -2/-3/-4, DSL побайтово, дефолтные теги, повторный отчёт чист"
