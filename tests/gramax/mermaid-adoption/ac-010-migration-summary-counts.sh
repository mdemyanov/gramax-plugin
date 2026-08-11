#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-010-migration-summary-counts.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-010
#   (FR-064).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 4.
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# FR-064 фиксирует СОСТАВ сводки (мигрировано / вне юрисдикции / уже соответствует), не
# точную формулировку. QA-author предложил конкретный минимальный формат как контракт (см.
# README.md, раздел «Интерпретация AC-010»). Этот тест правлен PM-приёмкой (см. запись
# content/lessons-learned.md, дефект «Migrated: N в отчётном режиме до всякой мутации» —
# найден догфудингом при приёмке DEV-003, не BA/QA-author): исходная версия ассертила
# буквальный `Migrated: 2` даже в режиме отчёта (без `--fix`), где ни один файл не
# изменён — потребитель, читающий вывод самого частого сценария (первый вызов, всегда
# report-режимный), делал бы ложный вывод, что файлы уже мигрированы. Метка первого
# счётчика теперь зависит от режима (см. докстринг `migrate_mermaid.py`, «Режимы»):
#   report-режим (без --fix):  To-migrate: <N>   — найдено, ничего не тронуто
#   --fix --yes:               Migrated: <N>     — файлы реально изменены
# Два других счётчика (`Out-of-jurisdiction`, `Already-compliant`) не изменились — они
# верны и одинаково подписаны в обоих режимах. Тест проверяет ОБА режима на одной и той же
# композитной фикстуре (2 легаси-вхождения + 1 вне юрисдикции + 1 уже корректный тег),
# чтобы не потерять содержательность правки: сначала report-режим должен сказать
# «To-migrate: 2» и ничего не изменить, затем `--fix --yes` на свежей копии той же
# фикстуры — «Migrated: 2» и реально смигрировать.
#
# Если Dev/PM в будущем снова изменит формулировку — поправьте regex ниже вместе с
# обоснованием (прецедент AC-014, content/60-implementation/acceptance/
# 2026-08-11-validation-contract-at-design.md), не убирайте ассерт молча.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
REPORT_WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
FIX_WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$REPORT_WORKDIR" "$FIX_WORKDIR"' EXIT

# --- режим отчёта (без --fix): "к миграции", не "мигрировано" — ничего не тронуто ---
REPORT_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$REPORT_WORKDIR" 2>&1)

if ! echo "$REPORT_OUT" | grep -qE 'To-migrate:[[:space:]]*2\b'; then
  echo "  FAIL: AC-010 (режим отчёта) — сводка не содержит 'To-migrate: 2' (см. README «Интерпретация AC-010»)" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$REPORT_OUT" | grep -qE 'Out-of-jurisdiction:[[:space:]]*1\b'; then
  echo "  FAIL: AC-010 (режим отчёта) — сводка не содержит 'Out-of-jurisdiction: 1'" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$REPORT_OUT" | grep -qE 'Already-compliant:[[:space:]]*1\b'; then
  echo "  FAIL: AC-010 (режим отчёта) — сводка не содержит 'Already-compliant: 1'" >&2
  FAIL=$((FAIL + 1))
fi
DIFF_OUT=$(diff -rq "$SCRIPT_DIR/fixtures/composite" "$REPORT_WORKDIR" 2>&1 || true)
if [ -n "$DIFF_OUT" ]; then
  echo "  FAIL: AC-010 (режим отчёта) — режим без --fix не должен мутировать фикстуру (сама причина дефекта, который правит этот тест)" >&2
  echo "$DIFF_OUT" >&2
  FAIL=$((FAIL + 1))
fi

# --- --fix --yes на свежей копии той же фикстуры: "мигрировано" — файлы реально изменены ---
FIX_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$FIX_WORKDIR" --fix --yes 2>&1)

if ! echo "$FIX_OUT" | grep -qE 'Migrated:[[:space:]]*2\b'; then
  echo "  FAIL: AC-010 (--fix --yes) — сводка не содержит 'Migrated: 2'" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$FIX_OUT" | grep -qE 'Out-of-jurisdiction:[[:space:]]*1\b'; then
  echo "  FAIL: AC-010 (--fix --yes) — сводка не содержит 'Out-of-jurisdiction: 1'" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$FIX_OUT" | grep -qE 'Already-compliant:[[:space:]]*1\b'; then
  echo "  FAIL: AC-010 (--fix --yes) — сводка не содержит 'Already-compliant: 1'" >&2
  FAIL=$((FAIL + 1))
fi
if [ ! -f "$FIX_WORKDIR/content/legacy-fenced-existing.mermaid" ] || [ ! -f "$FIX_WORKDIR/content/legacy-paired-existing.mermaid" ]; then
  echo "  FAIL: AC-010 (--fix --yes) — 'Migrated: 2' обязан соответствовать реально смигрированным файлам, но .mermaid-файлы не созданы" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод режима отчёта ---" >&2
  echo "$REPORT_OUT" >&2
  echo "  --- вывод --fix --yes ---" >&2
  echo "$FIX_OUT" >&2
  fail_msg "ac-010: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-010: сводка прогона совпадает с составом фикстуры (2/1/1) в обоих режимах, метка первого счётчика верна для каждого"
