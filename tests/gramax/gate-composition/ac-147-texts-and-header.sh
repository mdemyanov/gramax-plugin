#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-147-texts-and-header.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-147 (FR-221в)
# Задача: gramax-o0q.11.
# Проверка (контракт): README сюиты render-quality больше не говорит «не подключён ни к
#   одному гейту» и «10 красных / 2 зелёных»; README plantuml-bpmn больше не говорит,
#   что реализация ещё не создана; заголовок scripts/check-gramax.sh перечисляет ровно те
#   сюиты, что исполняет тело --full (равенство множеств «tests/gramax/<имя>» заголовка и
#   исполняемых строк тела); варден ac-118 сохраняет силу после перевода (NFR-084, ADR-0027).
# Цвет на 7553da1: КРАСНЫЙ — обе устаревшие фразы в README render-quality на месте
#   (README.md:16-17 и :55); фраза «реализация ещё не создана» в README plantuml-bpmn:8;
#   заголовок называет 13 сюит, тело исполняет 14 (нет render-quality).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
RQ_README="$ROOT/tests/gramax/render-quality/README.md"
PB_README="$ROOT/tests/gramax/plantuml-bpmn/README.md"
AC118="$ROOT/tests/gramax/render-quality/ac-118-fast-isolation.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- Ноги 1-2: README render-quality без устаревших утверждений ---
assert_file_exists "$RQ_README" "AC-147: tests/gramax/render-quality/README.md на месте"
if [ -f "$RQ_README" ]; then
  assert_no_grep "$RQ_README" 'не подключён ни к одному гейту' \
    "AC-147: README render-quality не говорит «не подключён ни к одному гейту» (шаг 18 --full существует, gramax-o0q.11)"
  assert_no_grep "$RQ_README" '10 красных / 2 зелёных' \
    "AC-147: README render-quality не говорит «10 красных / 2 зелёных» (счёт против собственной таблицы, gramax-o0q.11)"
fi

# --- Нога 3: README plantuml-bpmn актуален ---
assert_file_exists "$PB_README" "AC-147: tests/gramax/plantuml-bpmn/README.md на месте"
if [ -f "$PB_README" ]; then
  assert_no_grep "$PB_README" 'ещё не создана' \
    "AC-147: README plantuml-bpmn не говорит, что реализация ещё не создана (навык plantuml принят волной 2026-11-18)"
fi

# --- Нога 4: заголовок check-gramax.sh == множеству сюит тела --full ---
assert_file_exists "$CHECK_GRAMAX" "AC-147: scripts/check-gramax.sh на месте"
# Заголовок — комментарий до set -euo pipefail; тело — исполняемые строки --full-блока
# (комментарии тела исключены: упоминание archive в комментарии шага shellcheck — не шаг).
# tests/gramax/archive исключён из обоих множеств по принципу: замороженные свидетельства
# не запускаются ни одним агрегатором (archive/README.md) — шаг shellcheck грепает каталог
# архивных .sh (grep -v '^tests/gramax/archive/'), это не вызов сюиты.
HEADER_SET="$(awk '/^set -euo pipefail$/ { exit }
  { while (match($0, /tests\/gramax\/[a-z0-9-]+/)) { print substr($0, RSTART, RLENGTH); $0 = substr($0, RSTART + RLENGTH) } }
' "$CHECK_GRAMAX" | grep -v '^tests/gramax/archive$' | sort -u)"
BODY_SET="$(awk '
  /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
  infull && /^fi$/                      { infull = 0; next }
  {
    l = $0; sub(/^[ \t]+/, "", l)
    if (l ~ /^#/) next
    while (match(l, /tests\/gramax\/[a-z0-9-]+/)) { print substr(l, RSTART, RLENGTH); l = substr(l, RSTART + RLENGTH) }
  }
' "$CHECK_GRAMAX" | grep -v '^tests/gramax/archive$' | sort -u)"
if [ "$HEADER_SET" = "$BODY_SET" ] && [ -n "$BODY_SET" ]; then
  :
else
  echo "  FAIL: AC-147 — множества сюит заголовка и тела --full не равны:" >&2
  echo "  --- только в заголовке ---" >&2
  comm -23 <(printf '%s\n' "$HEADER_SET") <(printf '%s\n' "$BODY_SET") | head -10 >&2
  echo "  --- только в теле ---" >&2
  comm -13 <(printf '%s\n' "$HEADER_SET") <(printf '%s\n' "$BODY_SET") | head -10 >&2
  echo "  (заголовок перечисляет ВСЕ сюиты тела — AC-147, gramax-o0q.11)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 5: варден ac-118 жив после перевода (NFR-084) ---
assert_file_exists "$AC118" "AC-147: варден ac-118-fast-isolation.sh на месте (перевод, не удаление)"
if [ -f "$AC118" ]; then
  if bash "$AC118" > /dev/null 2>&1; then
    :
  else
    echo "  FAIL: AC-147 — варден ac-118 красный: сила изоляции --fast потеряна (NFR-084," >&2
    echo "  перевод по ADR-0027: комментарий заголовка не «вне --full», исполняемая строка вне блока краснит)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-147: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-147: README сюит соответствуют дереву; множества сюит заголовка и тела --full равны; ac-118 держит изоляцию"
