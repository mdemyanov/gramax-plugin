#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-003-detection-respects-boundary.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-003
#   (FR-055).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решения 1 и 3.
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Та же составная фикстура, что ac-002 — буквально по тексту AC-003 требования («та же
# фикстура дополнена соседним файлом вне поддерева content/»).
#
# Ловушка вакуумной истины: если инструмент не запускается (сейчас — файла не существует),
# проверка «outside/no-doc-root.md отсутствует в выводе» тривиально истинна просто потому, что
# вывода вообще нет — тест выглядел бы ЗЕЛЁНЫМ без единой строчки кода Dev, хотя ничего не
# проверено по существу. Поэтому сначала ТРЕБУЕТСЯ то же позитивное подтверждение, что в
# ac-002 (оба легаси-вхождения найдены) — это делает тест красным по правильной причине прямо
# сейчас, а не по случайному отсутствию вывода.

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
  echo "  FAIL: AC-003 (precondition) — content/legacy-fenced.md не найден отчётом — без этого негативная проверка ниже была бы тривиально пустой не по заслугам (инструмент не запускался)" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$OUT" | grep -qE 'legacy-paired\.md:[0-9]+'; then
  echo "  FAIL: AC-003 (precondition) — content/legacy-paired.md не найден отчётом — та же вакуумная ловушка" >&2
  FAIL=$((FAIL + 1))
fi

# --- собственно AC-003: файл вне юрисдикции не должен упоминаться в отчёте вовсе ---
if echo "$OUT" | grep -qE 'no-doc-root\.md'; then
  echo "  FAIL: AC-003 — outside/no-doc-root.md (без .doc-root.yaml-предка) ошибочно упомянут в отчёте (FR-055 — должен быть пропущен молча, не появляться как нарушение)" >&2
  echo "$OUT" | grep -E 'no-doc-root\.md' >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: обнаружение уважает границу юрисдикции (FR-055)"
