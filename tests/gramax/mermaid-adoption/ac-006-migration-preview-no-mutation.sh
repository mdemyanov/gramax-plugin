#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-006-migration-preview-no-mutation.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-006
#   (FR-058, NFR-053).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 3/4.
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Ловушка вакуумной истины: если migrate_mermaid.py не существует (текущее состояние —
# DEV-003 не начат), diff «до/после» тривиально пуст просто потому, что инструмент вообще не
# запускался — тест выглядел бы ЗЕЛЁНЫМ без единой строчки кода Dev. Поэтому тест ОБЯЗАН
# сначала положительно подтвердить, что инструмент реально нашёл оба легаси-вхождения (как
# ac-002) — это делает тест красным по правильной причине прямо сейчас, — и только после этого
# спрашивает про diff.
#
# Изоляция: работает на mktemp-копии фикстуры (lib/fixtures.sh::copy_composite_fixture), diff
# сравнивает копию с git-tracked оригиналом fixtures/composite — оригинал никогда не
# запускается напрямую, поэтому баг в будущей реализации (случайная запись в режиме отчёта)
# не испортит git working tree.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" 2>&1)

# --- позитивная гарантия против вакуумной истины (см. комментарий заголовка) ---
if ! echo "$OUT" | grep -qE 'legacy-fenced\.md:[0-9]+'; then
  echo "  FAIL: AC-006 (precondition) — отчёт не нашёл content/legacy-fenced.md — без этого diff-проверка ниже была бы тривиально пустой не по заслугам (инструмент не запускался)" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$OUT" | grep -qE 'legacy-paired\.md:[0-9]+'; then
  echo "  FAIL: AC-006 (precondition) — отчёт не нашёл content/legacy-paired.md — та же вакуумная ловушка" >&2
  FAIL=$((FAIL + 1))
fi

# --- собственно AC-006: ни один файл фикстуры не изменён режимом отчёта ---
DIFF_OUT=$(diff -rq "$SCRIPT_DIR/fixtures/composite" "$WORKDIR" 2>&1 || true)
if [ -n "$DIFF_OUT" ]; then
  echo "  FAIL: AC-006 — режим отчёта (без --fix/--yes) изменил файлы фикстуры (FR-058/NFR-053 нарушены — миграция обязана требовать отдельного шага подтверждения)" >&2
  echo "$DIFF_OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: режим отчёта находит нарушения, но не мутирует фикстуру"
