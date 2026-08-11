#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-005-migration-preserves-dsl-and-defaults.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-005
#   (FR-057, дефолты — ADR-0010 Решение 5).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 4.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_mermaid.py — DEV-003, не
#   начат; ни один .mermaid-файл не создаётся — оба assert_file_exists-эквивалента ниже
#   падают).
#
# Оракул DSL — не хардкод строки дважды (риск дрейфа между фикстурой и ожиданием в тесте), а
# извлечение блока из ПРИСТИНОЙ копии фикстуры собственным sed/awk QA-author'а, ДО вызова
# инструмента — независимый от парсера Dev способ получить «то, что было внутри исходного
# блока», и сравнить побайтово через diff (AC-005 требует именно пустой diff).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
EXPECTED_FENCED="$(mktemp)"
EXPECTED_PAIRED="$(mktemp)"
trap 'rm -rf "$WORKDIR" "$EXPECTED_FENCED" "$EXPECTED_PAIRED"' EXIT

# Извлечение ДО миграции — оракул независим от реализации Dev.
awk '
  /^```mermaid$/ { flag=1; next }
  /^```$/ { if (flag) { flag=0 }; next }
  flag { print }
' "$WORKDIR/content/legacy-fenced.md" > "$EXPECTED_FENCED"

sed -n '/<mermaid>/,/<\/mermaid>/p' "$WORKDIR/content/legacy-paired.md" \
  | sed '1d;$d' > "$EXPECTED_PAIRED"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" --fix --yes 2>&1)

if [ ! -f "$WORKDIR/content/legacy-fenced-existing.mermaid" ]; then
  echo "  FAIL: AC-005 — content/legacy-fenced-existing.mermaid не создан миграцией" >&2
  FAIL=$((FAIL + 1))
else
  DIFF1=$(diff -u "$EXPECTED_FENCED" "$WORKDIR/content/legacy-fenced-existing.mermaid" 2>&1 || true)
  if [ -n "$DIFF1" ]; then
    echo "  FAIL: AC-005 — DSL в legacy-fenced-existing.mermaid не побайтово совпадает с исходным fenced-блоком" >&2
    echo "$DIFF1" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ ! -f "$WORKDIR/content/legacy-paired-existing.mermaid" ]; then
  echo "  FAIL: AC-005 — content/legacy-paired-existing.mermaid не создан миграцией" >&2
  FAIL=$((FAIL + 1))
else
  DIFF2=$(diff -u "$EXPECTED_PAIRED" "$WORKDIR/content/legacy-paired-existing.mermaid" 2>&1 || true)
  if [ -n "$DIFF2" ]; then
    echo "  FAIL: AC-005 — DSL в legacy-paired-existing.mermaid не побайтово совпадает с исходным paired-блоком" >&2
    echo "$DIFF2" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if ! grep -qE '<mermaid path="\./legacy-fenced-existing\.mermaid" width="800px" height="450px"/>' "$WORKDIR/content/legacy-fenced.md"; then
  echo "  FAIL: AC-005 — content/legacy-fenced.md не содержит тег с дефолтами width=\"800px\" height=\"450px\" (ADR-0010 Решение 5 — исходный блок без явных атрибутов размера)" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qE '<mermaid path="\./legacy-paired-existing\.mermaid" width="800px" height="450px"/>' "$WORKDIR/content/legacy-paired.md"; then
  echo "  FAIL: AC-005 — content/legacy-paired.md не содержит тег с дефолтами width=\"800px\" height=\"450px\"" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод миграции ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: DSL сохранён побайтово, тег несёт дефолты ADR-0010 Решение 5"
