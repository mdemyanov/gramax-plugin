#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-150-identifier-registry.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-150 (FR-221д)
# Задача: gramax-o0q.19; реестр — docs/30-requirements/2026-11-23-identifier-ranges-registry.md.
# Проверка (контракт): каждый идентификатор глобальной эры (AC >= 036, NFR >= 050,
#   BR >= 006) определён жирной записью «**AC-NNN» ровно в одном файле
#   docs/30-requirements/*.md; реестр диапазонов существует и каждую строку диапазона
#   снабжает ссылкой-владельцем; требование паритета больше не определяет AC-061…AC-072
#   и BR-011; карта tests/gramax/catalog-validator/README.md указывает на AC-152…AC-163,
#   имена стабов ac-025…ac-036 не менялись.
# Цвет на 7553da1: КРАСНЫЙ — коллизия: AC-061 и AC-062 определены в plantuml-bpmn и
#   validators-parity; BR-011 — в тех же двух; паритет ещё не перенумерован; карта README
#   catalog-validator указывает на AC-061…AC-072.
# Граница скана: только docs/30-requirements/*.md (эра локальных номеров до 13.08.2026
#  выведена порогами; жирные цитирования вне директории требований — вне контракта AC-150).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
REQ_DIR="$ROOT/docs/30-requirements"
REGISTRY="$REQ_DIR/2026-11-23-identifier-ranges-registry.md"
PARITY="$REQ_DIR/2026-11-18-validators-error-check-parity-requirement.md"
CV_README="$ROOT/tests/gramax/catalog-validator/README.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- Нога 1: каждый идентификатор глобальной эры определён ровно в одном требовании ---
DUPS="$(awk -v ac_min=36 -v nfr_min=50 -v br_min=6 '
{
  line = $0
  while (match(line, /\*\*(AC|NFR|BR)-[0-9][0-9][0-9]/)) {
    rest = substr(line, RSTART + 2)
    split(rest, parts, /[^A-Za-z0-9]+/)
    pre = parts[1]; num = parts[2] + 0
    if ((pre == "AC" && num >= ac_min) || (pre == "NFR" && num >= nfr_min) || (pre == "BR" && num >= br_min)) {
      id = pre "-" parts[2]
      key = id SUBSEP FILENAME
      if (!(key in seen)) { seen[key] = 1; cnt[id]++; where[id] = where[id] "\n      " FILENAME }
    }
    line = substr(line, RSTART + RLENGTH)
  }
}
END {
  n = 0
  for (id in cnt) if (cnt[id] > 1) { print id " — определён в " cnt[id] " файлах:" where[id]; n++ }
  if (n == 0) print "__CLEAN__"
}
' "$REQ_DIR"/*.md)"
if printf '%s\n' "$DUPS" | grep -q '__CLEAN__'; then
  :
else
  echo "  FAIL: AC-150 — идентификаторы, определённые более чем в одном требовании:" >&2
  printf '%s\n' "$DUPS" >&2
  echo "  (правило реестра: жирная запись «**ID-NNN**» ровно в одном требовании, в остальных —" >&2
  echo "  только цитирование; исправление — перенумерация диапазона паритета AC-152…AC-163)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 2: реестр существует, каждая строка диапазона снабжена владельцем ---
assert_file_exists "$REGISTRY" "AC-150: реестр диапазонов docs/30-requirements/2026-11-23-identifier-ranges-registry.md на месте"
if [ -f "$REGISTRY" ]; then
  OWNERLESS="$(grep -E '^\| (FR|AC|NFR|BR)-[0-9][0-9][0-9]' "$REGISTRY" | grep -v '](' || true)"
  if [ -n "$OWNERLESS" ]; then
    echo "  FAIL: AC-150 — строки диапазонов реестра без ссылки-владельца:" >&2
    printf '%s\n' "$OWNERLESS" | head -5 >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Нога 3: паритет больше не определяет AC-061…AC-072 и BR-011 ---
assert_file_exists "$PARITY" "AC-150: требование паритета валидаторов на месте"
if [ -f "$PARITY" ]; then
  assert_no_grep_regex "$PARITY" '\*\*AC-06[1-9]|\*\*AC-07[0-2]' \
    "AC-150: требование паритета не определяет AC-061…AC-072 жирной записью (перенумеровано AC-152…AC-163)"
  assert_no_grep "$PARITY" '**BR-011' \
    "AC-150: требование паритета не определяет BR-011 (перенесён на BR-028)"
fi

# --- Нога 4: карта catalog-validator указывает на AC-152…AC-163 ---
assert_file_exists "$CV_README" "AC-147/AC-150: README catalog-validator на месте"
if [ -f "$CV_README" ]; then
  assert_grep "$CV_README" 'AC-152' \
    "AC-150: карта tests/gramax/catalog-validator/README.md указывает на AC-152 (начало перенумерованного диапазона)"
  assert_grep "$CV_README" 'AC-163' \
    "AC-150: карта tests/gramax/catalog-validator/README.md указывает на AC-163 (конец перенумерованного диапазона)"
fi

# --- Нога 5: имена стабов ac-025…ac-036 не менялись ---
for N in 025 026 027 028 029 030 031 032 033 034 035 036; do
  FOUND="$(find "$ROOT/tests/gramax/catalog-validator" -maxdepth 1 -name "ac-${N}-*.sh" 2>/dev/null | head -1)"
  if [ -n "$FOUND" ]; then
    :
  else
    echo "  FAIL: AC-150 — стаб ac-${N}-*.sh не найден в tests/gramax/catalog-validator/" >&2
    echo "  (имена стабов при перенумерации не менялись — меняется только карта README)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-150: $FAIL assertion(s) failed"; exit 1; fi
# --- Нога 6: требование паритета определяет ровно AC-152…AC-163, каждый по одному разу ---
# (урок ревью 2026-11-23: сбой перенумерации дал вид AC-15-NN — ноги 1 и 3 его не видели)
for n in 152 153 154 155 156 157 158 159 160 161 162 163; do
  C_N="$(grep -cF "**AC-$n" "$PARITY")"
  if [ "$C_N" -ne 1 ]; then
    echo "  FAIL: AC-150 — требование паритета обязано определять **AC-$n ровно один раз (найдено $C_N)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- Нога 7: нет идентификаторов с лишним дефисом (вид AC-15-NN, AC-16-NN) в требованиях и сюитах ---
MALFORMED="$(grep -rnoE 'AC-1[0-9]-[0-9]{2}' "$REQ_DIR" "$ROOT/tests/gramax" 2>/dev/null | head -5)"
if [ -n "$MALFORMED" ]; then
  echo "  FAIL: AC-150 — найдены идентификаторы с лишним дефисом: $MALFORMED" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-150: $FAIL assertion(s) failed (ноги 6–7)"; exit 1; fi
pass_msg "ac-150: идентификаторы глобальной эры определены ровно один раз; реестр с владельцами на месте; паритет на AC-152…AC-163; имена стабов catalog-validator не менялись"
