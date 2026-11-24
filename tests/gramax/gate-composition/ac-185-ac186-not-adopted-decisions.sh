#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-185-ac186-not-adopted-decisions.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md —
#   AC-185 (FR-233) и AC-186 (FR-234).
# Решение: ADR-0029 (вне индекса на момент письма), Решение 3 — report-режим мигратора
#   nav-спанов в состав гейта не входит (скрипт остаётся ручным диагностом); Решение 4 —
#   два инструмента ростера с исходом «не усыновлять» (check-backlog-closure.py — предмета
#   суждения нет: tracked-бэклога 0, стор локальный; check-breaking-change-section.py —
#   не доставлен и не вызывается, advisory-применение остаётся ручной проверкой приёмки).
# Проверка (контракт) — варден записанных решений, зелёный от рождения:
#   (a) report-режим не шаг гейта: ни одна ИСПОЛНЯЕМАЯ строка scripts/check-gramax.sh не
#       зовёт migrate_nav_codespans (комментарий шага link-form-migration называет мигратор
#       правомерно — сюита классификации живёт, не живёт гейт-шаг отчёта); скрипт остаётся
#       в дереве как ручной диагност (зелёный);
#   (b) ADR-0029 несёт оба решения «не усыновлять» (Решение 4): строк с «не усыновлять» ≥ 2
#       и названы оба инструмента. Появление шага отчёта в гейте, удаление мигратора или
#       вычеркивание решения из ADR красит стаб (тихий адопшн запрещён).
# Цвет на текущем дереве: ЗЕЛЁНЫЙ (гард состояния — пины зафиксированных решений).
# Мутации к красному: добавить шаг report-режима в check-gramax.sh; удалить
#   plugins/gramax/scripts/migrate_nav_codespans.py; вычеркнуть «не усыновлять»/имя
#   инструмента из ADR-0029 Решения 4.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
MIGRATOR="$ROOT/plugins/gramax/scripts/migrate_nav_codespans.py"
ADR="$ROOT/docs/00-project/adr/0029-wave4-gate-suite-composition.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-185: scripts/check-gramax.sh на месте"

# --- (a): report-режим мигратора не шаг гейта (AC-185) ---
# Судятся исполняемые строки гейта (комментарии о сюите link-form-migration не вызов).
EXEC_LINES="$(awk '{ l = $0; sub(/^[ \t]+/, "", l); if (l !~ /^#/) print l }' "$CHECK_GRAMAX")"
if printf '%s\n' "$EXEC_LINES" | grep -qF 'migrate_nav_codespans'; then
  echo "  FAIL: AC-185 — исполняемая строка check-gramax.sh зовёт migrate_nav_codespans:" >&2
  echo "  report-режим мигратора стал шагом гейта вопреки ADR-0029 Решению 3 (гейт остаётся" >&2
  echo "  n/a, мигратор — ручной диагност); AC-185: «в составе --full его нет»" >&2
  printf '%s\n' "$EXEC_LINES" | grep -F 'migrate_nav_codespans' | head -3 >&2
  FAIL=$((FAIL + 1))
fi

# --- (a2): скрипт остаётся в дереве как ручной диагност (AC-185) ---
assert_file_exists "$MIGRATOR" \
  "AC-185: мигратор остаётся в дереве ручным диагностом (ADR-0029 Решение 3 — снят с планов гейта, не удалён)"

# --- (b): ADR-0029 несёт оба решения «не усыновлять» (AC-186) ---
if [ ! -f "$ADR" ]; then
  echo "  FAIL: AC-186 — ADR-0029 (docs/00-project/adr/0029-wave4-gate-suite-composition.md)" >&2
  echo "  не найден: решения о двух инструментах ростера негде читать (AC-186)" >&2
  FAIL=$((FAIL + 1))
else
  NOT_ADOPTED="$(grep -c 'не усыновлять' "$ADR" || true)"
  if [ "${NOT_ADOPTED:-0}" -lt 2 ]; then
    echo "  FAIL: AC-186 — строк с «не усыновлять» в ADR-0029: ${NOT_ADOPTED} (< 2) —" >&2
    echo "  решение по одному из инструментов ростера вычеркнуто (Решение 4: оба исхода —" >&2
    echo "  «не усыновлять», гейт остаётся n/a; AC-186 требует запись с названным исходом)" >&2
    FAIL=$((FAIL + 1))
  fi
  for TOOL in 'check-backlog-closure' 'check-breaking-change-section'; do
    if grep -qF "$TOOL" "$ADR"; then
      :
    else
      echo "  FAIL: AC-186 — ADR-0029 Решение 4 не называет «${TOOL}»:" >&2
      echo "  исход «не усыновлять» обязан быть поимённым (AC-186, основание каждого)" >&2
      FAIL=$((FAIL + 1))
    fi
  done
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-185-ac186: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-185-ac186: report-режим не шаг гейта, мигратор остаётся ручным диагностом; ADR-0029 несёт оба решения «не усыновлять» поимённо"
