#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-143-suite-statuses.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-143 (FR-220а)
# Решение: docs/00-project/adr/0027-full-gate-composition.md, Решение 3 (статусы двух сюит);
#   поправка PM к целевому списку ADR-0027: tests/gramax/gate-composition — последним шагом
#   --full, 18 сюит с ней (волна-4 добавляет docs-layout-invariants — ADR-0029 Решение 2).
# Проверка (контракт): у cross-catalog-retraction и docs-migration явный статус —
#   cross-catalog-retraction подключена к --full (шаг в теле check-gramax.sh и строка
#   заголовка); docs-migration лежит в tests/gramax/archive/docs-migration/ с записью в
#   tests/gramax/archive/README.md, старого каталога tests/gramax/docs-migration/ нет.
#   Настоящая сюита зарегистрирована последним шагом --full-блока (поправка PM).
# Волна-4 (ADR-0029, вне индекса на момент письма; Решение 2): живая сюита
#   tests/gramax/docs-layout-invariants/ — ноги 7-10: run.sh существует; шаг в теле
#   --full сразу после nauta-integration; заголовок называет сюиту; пять стабов на месте
#   («17-я сюита» → «18-я»; порядок сюит стаб не пришивает).
# Цвет на 7553da1: КРАСНЫЙ — cross-catalog-retraction не упомянута ни в заголовке, ни в
#   теле check-gramax.sh; tests/gramax/docs-migration/ ещё не переехала в archive/;
#   настоящая сюита шагом --full ещё не зарегистрирована.
# Цвет на текущем дереве: КРАСНЫЙ (ноги 8-9) — сюиты docs-layout-invariants нет в теле
#   и в заголовке check-gramax.sh; ноги 7, 10 зеленеют с появлением каталога сюиты.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-143: scripts/check-gramax.sh на месте"

# Регион --full-блока: открывается строкой `if [ "$MODE" = "--full" ]; then` в нулевой
# колонке, закрывается `fi` в нулевой колонке (вложенные if внутри блока отбиты отступом).
# Исполняемые строки блока — без комментариев (комментарий статуса не вызов).
FULL_LINES="$(awk '
  /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
  infull && /^fi$/                      { infull = 0; next }
  {
    l = $0; sub(/^[ \t]+/, "", l)
    if (l !~ /^#/) print NR "\t" $0
  }
' "$CHECK_GRAMAX")"

# Заголовок — комментарий до `set -euo pipefail` (строки Modes).
HEADER_LINES="$(awk '/^set -euo pipefail$/ { exit } { print NR "\t" $0 }' "$CHECK_GRAMAX")"

# --- Нога 1: cross-catalog-retraction — шаг тела --full через run.sh ---
if printf '%s\n' "$FULL_LINES" | grep -qF 'bash tests/gramax/cross-catalog-retraction/run.sh'; then
  :
else
  echo "  FAIL: AC-143 — в --full-блоке check-gramax.sh нет вызова" >&2
  echo "  bash tests/gramax/cross-catalog-retraction/run.sh (ADR-0027, Решение 3: шаг перед сторожевой gate-composition)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 2: cross-catalog-retraction названа в заголовке ---
if printf '%s\n' "$HEADER_LINES" | grep -qF 'tests/gramax/cross-catalog-retraction'; then
  :
else
  echo "  FAIL: AC-143 — заголовок check-gramax.sh не называет tests/gramax/cross-catalog-retraction" >&2
  echo "  (AC-147: заголовок перечисляет все сюиты тела)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 3: docs-migration живёт в archive/ с run.sh ---
assert_file_exists "$ROOT/tests/gramax/archive/docs-migration/run.sh" \
  "AC-143: tests/gramax/archive/docs-migration/run.sh существует (git mv без правки байтов, ADR-0027 Решение 3)"

# --- Нога 4: старого каталога tests/gramax/docs-migration/ нет ---
assert_dir_not_exists "$ROOT/tests/gramax/docs-migration" \
  "AC-143: tests/gramax/docs-migration/ переехала в archive/, старого каталога нет"

# --- Нога 5: archive/README.md несёт строку о docs-migration ---
if [ -f "$ROOT/tests/gramax/archive/README.md" ]; then
  if grep -qF 'docs-migration' "$ROOT/tests/gramax/archive/README.md"; then
    :
  else
    echo "  FAIL: AC-143 — tests/gramax/archive/README.md не упоминает docs-migration" >&2
    echo "  (запись о переносе: свидетельство инверсии ADR-0021, окно 8b6332d..ad7f1a4)" >&2
    FAIL=$((FAIL + 1))
  fi
else
  echo "  FAIL: AC-143 — tests/gramax/archive/README.md отсутствует" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 6 (поправка PM к ADR-0027): настоящая сюита — последний шаг --full ---
GC_LINE="$(printf '%s\n' "$FULL_LINES" | awk -F '\t' '/bash tests\/gramax\/gate-composition\/run\.sh/ { print $1; exit }')"
if [ -z "$GC_LINE" ]; then
  echo "  FAIL: AC-143 — настоящая сюита не зарегистрирована шагом --full" >&2
  echo "  (поправка PM к списку ADR-0027: tests/gramax/gate-composition — 18-я сюита, последним шагом)" >&2
  FAIL=$((FAIL + 1))
else
  OTHER_AFTER="$(printf '%s\n' "$FULL_LINES" | awk -v gc="$GC_LINE" -F '\t' '$1 > gc' \
    | grep -oE 'tests/gramax/[a-z0-9-]+/' | wc -l | tr -d ' ')"
  if [ "$OTHER_AFTER" -gt 0 ]; then
    echo "  FAIL: AC-143 — после шага gate-composition в --full-блоке есть другие шаги сюит" >&2
    echo "  (поправка PM к списку ADR-0027: настоящая сюита исполняется последней)" >&2
    printf '%s\n' "$FULL_LINES" | awk -v gc="$GC_LINE" -F '\t' '$1 > gc' | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Ноги 7-10 (ADR-0029 Решение 2): живая сюита docs-layout-invariants ---

# --- Нога 7: run.sh живой сюиты существует ---
assert_file_exists "$ROOT/tests/gramax/docs-layout-invariants/run.sh" \
  "AC-143: tests/gramax/docs-layout-invariants/run.sh существует (живая сюита инвариантов раскладки, ADR-0029 Решение 2)"

# --- Нога 8: шаг сюиты в теле --full (сразу после nauta-integration; порядок не пришит) ---
if printf '%s\n' "$FULL_LINES" | grep -qF 'bash tests/gramax/docs-layout-invariants/run.sh'; then
  :
else
  echo "  FAIL: AC-143 — в --full-блоке check-gramax.sh нет вызова" >&2
  echo "  bash tests/gramax/docs-layout-invariants/run.sh (ADR-0029 Решение 2: после nauta-integration, хвост cross-catalog-retraction → gate-composition не трогается)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 9: заголовок называет сюиту ---
if printf '%s\n' "$HEADER_LINES" | grep -qF 'tests/gramax/docs-layout-invariants'; then
  :
else
  echo "  FAIL: AC-143 — заголовок check-gramax.sh не называет tests/gramax/docs-layout-invariants" >&2
  echo "  (ADR-0029 Решение 2: 18-я сюита в самописце состава)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 10: пять стабов инвариантов на месте ---
for N in 003 004 005 006 007; do
  STUB=""
  for CAND in "$ROOT"/tests/gramax/docs-layout-invariants/ac-"$N"-*.sh; do
    if [ -f "$CAND" ]; then STUB="$CAND"; break; fi
  done
  if [ -n "$STUB" ]; then
    :
  else
    echo "  FAIL: AC-143 — стаба ac-${N}-*.sh нет в tests/gramax/docs-layout-invariants/" >&2
    echo "  (ADR-0029 Решение 2: пять инвариантов AC-003…AC-007 требования инверсии раскладки)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-143: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-143: cross-catalog-retraction подключена к --full (шаг + заголовок); docs-migration в archive/ с записью; docs-layout-invariants живая (run.sh, пять стабов, шаг и строка заголовка --full); gate-composition — последний шаг --full (18-я сюита)"
