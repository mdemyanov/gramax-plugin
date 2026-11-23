#!/usr/bin/env bash
# tests/gramax/render-quality/ac-141-no-live-leg.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-141 (FR-219, D5)
# Решение: docs/00-project/adr/0027-full-gate-composition.md, Решение 1 — живая нога выходит
#   из --full в именованный шаг scripts/render-quality/live.sh.
# Проверка (контракт): --full-блок scripts/check-gramax.sh не вызывает ни live.sh, ни
#   probe.sh (прибор вообще не запускается гейтом); агрегатор сюиты
#   tests/gramax/render-quality/run.sh не вызывает probe.sh — по умолчанию исполняются
#   только офлайн-стабы ac-*.sh. Настоящий зелёный --full на чистом дереве — доказательство
#   координатора при приёмке, не стаб (NFR-085: в гейте нет сети, проб и токена).
# Цвет на 7553da1: КРАСНЫЙ — run.sh держит секцию «живой прогон» (строки 60-73) и вызывает
#   bash scripts/render-quality/probe.sh с дефолтными путями; на чистом дереве прибор даёт
#   fixtures=21 match=0 divergence=21 rc=1, поэтому шаг 18 --full красен всегда (NFR-085
#   нарушен). В check-gramax.sh упоминаний probe.sh/live.sh нет — та нога зелёная (варден).
# Исполняемые строки судятся; комментарии исключены (заголовок run.sh волен помнить историю).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
RUN_SH="$ROOT/tests/gramax/render-quality/run.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-141: scripts/check-gramax.sh на месте"
assert_file_exists "$RUN_SH" "AC-141: tests/gramax/render-quality/run.sh на месте"

# --- Нога 1 (варден): check-gramax.sh не упоминает probe.sh/live.sh исполняемой строкой ---
if [ -f "$CHECK_GRAMAX" ]; then
  HITS="$(awk '
    {
      l = $0; sub(/^[ \t]+/, "", l)
      if (l ~ /^#/) next
      if (l ~ /render-quality\/(probe|live)\.sh/) print NR "\t" $0
    }
  ' "$CHECK_GRAMAX")"
  if [ -n "$HITS" ]; then
    echo "  FAIL: AC-141 — check-gramax.sh упоминает прибор вне агрегатора (гейт не запускает" >&2
    echo "  ни probe.sh, ни live.sh ни в одном режиме, ADR-0027 Решение 1):" >&2
    printf '%s\n' "$HITS" | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Нога 2: run.sh не вызывает probe.sh исполняемой строкой ---
if [ -f "$RUN_SH" ]; then
  HITS="$(awk '
    {
      l = $0; sub(/^[ \t]+/, "", l)
      if (l ~ /^#/) next
      if (l ~ /probe\.sh/) print NR "\t" $0
    }
  ' "$RUN_SH")"
  if [ -n "$HITS" ]; then
    echo "  FAIL: AC-141 — run.sh держит живую ногу и вызывает probe.sh (ADR-0027 Решение 1:" >&2
    echo "  живой прогон уходит в именованный шаг scripts/render-quality/live.sh, агрегатор" >&2
    echo "  исполняет только офлайн-стабы; D5/NFR-085 — --full зелёный в стационарном состоянии):" >&2
    printf '%s\n' "$HITS" | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
  # --- Нога 3 (варден): run.sh не упоминает и live.sh — сетевая нога не возвращается
  # в агрегатор под другим именем (маскированный перенос живой ноги).
  HITS="$(awk '
    {
      l = $0; sub(/^[ \t]+/, "", l)
      if (l ~ /^#/) next
      if (l ~ /live\.sh/) print NR "\t" $0
    }
  ' "$RUN_SH")"
  if [ -n "$HITS" ]; then
    echo "  FAIL: AC-141 — run.sh упоминает live.sh исполняемой строкой: сетевая нога" >&2
    echo "  не возвращается в агрегатор (вызов живого прогона — только именованный шаг ритуала):" >&2
    printf '%s\n' "$HITS" | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-141: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-141: гейт не трогает прибор (ни probe.sh, ни live.sh); агрегатор сюиты исполняет только офлайн-стабы"
