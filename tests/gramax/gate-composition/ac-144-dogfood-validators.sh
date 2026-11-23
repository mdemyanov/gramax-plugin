#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-144-dogfood-validators.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-144 (FR-220б)
# Решение: docs/00-project/adr/0027-full-gate-composition.md, Решение 4 (два шага первыми
#   внутри --full-блока, подряд с быстрыми валидаторами docs/, порог 0 ERROR).
# Проверка (контракт): --full-блок scripts/check-gramax.sh вызывает validate_structure.py docs
#   и validate_comments.py docs с rc-гейтингом (rc≠0 — FAIL, хвост-подавлений на строке нет);
#   оба валидатора на docs/ дают rc=0 (предупреждения печатаются и не красят).
# Цвет на 7553da1: КРАСНЫЙ — шагов в --full-блоке нет; validate_comments.py docs даёт rc=1
#   (4 ложных ERROR «invalid comment id format» на примерах синтаксиса в code-span,
#   gramax-4jf.13 — маска кода); validate_structure.py docs — rc=0 (3 WARNING W034, красят
#   по контракту только ERROR).
# Зависимость: нога validate_comments зеленеет только после правки gramax-4jf.13 (ADR-0026).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-144: scripts/check-gramax.sh на месте"

FULL_LINES="$(awk '
  /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
  infull && /^fi$/                      { infull = 0; next }
  {
    l = $0; sub(/^[ \t]+/, "", l)
    if (l !~ /^#/) print NR "\t" $0
  }
' "$CHECK_GRAMAX")"

# --- Ноги 1-2: шаги догфудинга в --full-блоке ---
for V in validate_structure.py validate_comments.py; do
  LINE="$(printf '%s\n' "$FULL_LINES" | awk -F '\t' -v v="$V" 'index($2, v " docs") { print $1; exit }')"
  if [ -z "$LINE" ]; then
    echo "  FAIL: AC-144 — в --full-блоке check-gramax.sh нет шага «${V} docs»" >&2
    echo "  (ADR-0027 Решение 4: два шага первыми внутри --full-блока, порог 0 ERROR)" >&2
    FAIL=$((FAIL + 1))
  else
    # --- Нога 3: rc-гейтинг — на строке шага нет хвоста-подавления кода возврата
    # (маскированный отказ: шаг исполнен, rc проглочен — гейт зеленеет без проверки).
    SNIPPET="$(printf '%s\n' "$FULL_LINES" | awk -F '\t' -v n="$LINE" '$1 == n { print $2 }')"
    if printf '%s\n' "$SNIPPET" | grep -qE '\|\| *(true|:)|; *(true|:)[[:space:]]*$'; then
      echo "  FAIL: AC-144 — строка шага ${V} подавляет rc (хвост true/:) —" >&2
      echo "  маскированный отказ: порог 0 ERROR обязан гейтить через rc (ADR-0027 Решение 4)" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
done

# --- Нога 4: оба валидатора на docs/ дают rc=0 ---
if [ ! -d "$ROOT/docs" ]; then
  echo "  FAIL: AC-144 — каталога docs/ нет, догфудинг не на чём исполнить" >&2
  FAIL=$((FAIL + 1))
else
  for V in validate_structure.py validate_comments.py; do
    OUT="$(cd "$ROOT" && python3 -B "plugins/gramax/scripts/$V" docs 2>&1)"
    RC=$?
    if [ "$RC" -ne 0 ]; then
      echo "  FAIL: AC-144 — ${V} docs даёт rc=${RC}, порог 0 ERROR не достигнут:" >&2
      printf '%s\n' "$OUT" | grep -E '^(ERROR|Traceback)' | head -5 >&2
      echo "  (у валидатора rc≠0 только при ERROR; WARNING печатается и не красит)" >&2
      FAIL=$((FAIL + 1))
    fi
  done
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-144: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-144: оба валидатора в --full с rc-гейтингом; на docs/ 0 ERROR (rc=0)"
