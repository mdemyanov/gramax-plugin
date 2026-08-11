#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-007-migration-idempotent.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-007
#   (NFR-050).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 4
#   («Идемпотентность — структурная: после миграции инлайн-блок физически не существует —
#   повторный прогон даёт ноль совпадений по построению regex, не по флагу состояния»).
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Та же ловушка вакуумной истины, что в ac-006: если инструмент не существует, оба прогона
# одинаково ничего не делают — diff(после-первого, после-второго) тривиально пуст. Тест
# сначала ТРЕБУЕТ, чтобы первый прогон реально смигрировал (создал .mermaid-файлы) — иначе он
# красный по этой причине прямо сейчас, а не по мнимой идемпотентности пустого действия.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
SNAPSHOT=""
trap 'rm -rf "$WORKDIR" "$SNAPSHOT"' EXIT

OUT1=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" --fix --yes 2>&1)

# --- позитивная гарантия против вакуумной истины (см. комментарий заголовка) ---
if [ ! -f "$WORKDIR/content/legacy-fenced-existing.mermaid" ] || [ ! -f "$WORKDIR/content/legacy-paired-existing.mermaid" ]; then
  echo "  FAIL: AC-007 (precondition) — первый прогон --fix --yes не создал .mermaid-файлы — без реальной миграции проверка идемпотентности ниже была бы тривиально пустой не по заслугам" >&2
  echo "  --- вывод первого прогона ---" >&2
  echo "$OUT1" >&2
  FAIL=$((FAIL + 1))
fi

SNAPSHOT="$(mktemp -d)"
cp -R "$WORKDIR/." "$SNAPSHOT/"

OUT2=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" --fix --yes 2>&1)

# --- собственно AC-007: повторный прогон не меняет состояние после первого ---
DIFF_OUT=$(diff -rq "$SNAPSHOT" "$WORKDIR" 2>&1 || true)
if [ -n "$DIFF_OUT" ]; then
  echo "  FAIL: AC-007 — повторный прогон --fix --yes изменил состояние после первого прогона (NFR-050 нарушена)" >&2
  echo "$DIFF_OUT" >&2
  echo "  --- вывод второго прогона ---" >&2
  echo "$OUT2" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: повторная миграция идемпотентна (NFR-050)"
