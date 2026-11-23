#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-149-changelog-calibration.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-149 (FR-221г)
# Задача: gramax-o0q.17.
# Проверка (контракт): plugins/gramax/CHANGELOG.md несёт запись калибровки волны-1 —
#   note-in-cell и note-in-note с WARN-семантикой, colgroup-multiline с ERROR; маркер
#   «**Опоры:**» стоит в шапке записи замера
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md
#   (первые 30 строк, до первого заголовка «## »); гейт актуальности
#   scripts/check-content-actuality.py не даёт SIGNAL по этому файлу.
# Цвет на 7553da1: КРАСНЫЙ — в 4.9.0 перечислен только th (note-in-cell/note-in-note/
#   colgroup-multiline отсутствуют); маркер «Опоры» стоит в конце файла (строка 90 из 90)
#   и check-content-actuality даёт SIGNAL «неопределим — маркера в шапке нет».

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"
RECORD="$ROOT/docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHANGELOG" "AC-149: plugins/gramax/CHANGELOG.md на месте"
assert_file_exists "$RECORD" "AC-149: запись замера калибровки волны-1 на месте"

# --- Ноги 1-3: запись калибровки называет три класса с их severity ---
for CLASS in note-in-cell note-in-note; do
  if grep -qF "$CLASS" "$CHANGELOG" \
     && grep -A4 -F "$CLASS" "$CHANGELOG" | grep -qF 'WARN'; then
    :
  else
    echo "  FAIL: AC-149 — CHANGELOG не несёт класс «${CLASS}» с WARN-семантикой в записи" >&2
    echo "  калибровки волны-1 (в 4.9.0 перечислен только th; gramax-o0q.17)" >&2
    FAIL=$((FAIL + 1))
  fi
done
if grep -qF 'colgroup-multiline' "$CHANGELOG" \
   && grep -A4 -F 'colgroup-multiline' "$CHANGELOG" | grep -qF 'ERROR'; then
  :
else
  echo "  FAIL: AC-149 — CHANGELOG не несёт класс «colgroup-multiline» с ERROR в записи" >&2
  echo "  калибровки волны-1 (подтверждённый киллер не мягчеет; gramax-o0q.17)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 4: маркер «Опоры» в шапке записи (первые 30 строк, до первого «## ») ---
if [ -f "$RECORD" ]; then
  MARKER_LINE="$(grep -nF '**Опоры:**' "$RECORD" | head -1 | cut -d: -f1)"
  FIRST_H2="$(grep -n '^## ' "$RECORD" | head -1 | cut -d: -f1)"
  if [ -z "$MARKER_LINE" ]; then
    echo "  FAIL: AC-149 — в записи замера нет маркера «**Опоры:**» вовсе" >&2
    FAIL=$((FAIL + 1))
  else
    if [ "$MARKER_LINE" -gt 30 ]; then
      echo "  FAIL: AC-149 — маркер «**Опоры:**» стоит в строке ${MARKER_LINE} (конец файла)," >&2
      echo "  а не в шапке записи: пере-сади маркер в первые 30 строк, сразу после H1" >&2
      echo "  (форма sibling-отчётов; находка 3 at-acceptance волны-2, gramax-o0q.17)" >&2
      FAIL=$((FAIL + 1))
    fi
    if [ -n "$FIRST_H2" ] && [ "$MARKER_LINE" -ge "$FIRST_H2" ]; then
      echo "  FAIL: AC-149 — маркер «**Опоры:**» не в шапке: шапка кончается первой «## »" >&2
      echo "  (строка ${FIRST_H2}), гейт актуальности мерит только шапку (ADR-076 Д6)" >&2
      FAIL=$((FAIL + 1))
    fi
  fi

  # --- Нога 5: гейт актуальности не даёт SIGNAL по записи замера ---
  ACTUAL_OUT="$(cd "$ROOT" && python3 scripts/check-content-actuality.py 2>&1)"
  if printf '%s\n' "$ACTUAL_OUT" \
     | grep -qF 'SIGNAL docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md'; then
    echo "  FAIL: AC-149 — check-content-actuality даёт SIGNAL по записи замера" >&2
    printf '%s\n' "$ACTUAL_OUT" \
      | grep -F 'SIGNAL docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md' >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-149: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-149: CHANGELOG несёт запись калибровки волны-1 (note-in-cell/note-in-note WARN, colgroup-multiline ERROR); маркер «Опоры» в шапке записи; SIGNAL по файлу нет"
