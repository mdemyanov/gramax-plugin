#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-151-index-properties-verdict.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-151 (FR-209)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, ADR-0026
# Решение 5 (вердикт: ключ штатный и видимый; ERROR снимается, WARN не вводится;
# V3–V5 применяются к _index.md подпапок; индекс корня вне проверки).
# Фикстура общая с переведённым pytest-тестом (прецедент ADR-0020: один набор фикстур
# на два прогона) — tests/gramax/catalog-validator/fixtures/ac-151-properties-index/.
# Проверка (один прогон валидатора по фикстуре):
#   (a) корневой _index.md со свойством — ноль находок (V2 снят, V3–V5 вне корня);
#   (b) sub/_index.md с объявленным enum-свойством — ноль находок (законная конструкция);
#   (c) sub2/_index.md с необъявленным свойством — V4 («не объявлен») остаётся;
#   (d) sub3/_index.md с плоской нотацией — V3-warning остаётся;
#   (e) sub4/_index.md со значением вне enum — V5 («не входит в») остаётся;
#   (f) «не должен содержать properties» нет нигде.
# Red on 7553da1: запрет V2 (validate_structure.py:337-338) даёт ERROR на все пять
#   индексов фикстуры, а V3/V4/V5 заглушены условием md_file.name != "_index.md"
#   (замер 2026-11-23: только V2, legs (c)/(d)/(e) молчат).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-151-properties-index"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
if [ "$RC" -eq 0 ]; then
  echo "  FAIL: AC-151 — истинные находки V3–V5 на _index.md подпапок обязаны давать rc≠0" >&2
  FAIL=$((FAIL + 1))
fi

# --- (f): запрет снят целиком ---
if printf '%s\n' "$OUT" | grep -qF 'не должен содержать properties'; then
  echo "  FAIL: AC-151 — запрет «_index.md не должен содержать properties» обязан быть снят: ключ штатный и видимый (вердикт gramax-4jf.2, ADR-0026 Решение 5)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (a): корневой индекс вне проверок ---
if printf '%s\n' "$OUT" | grep -F "$FIXTURE/_index.md" | grep -qE 'ERROR|WARNING'; then
  echo "  FAIL: AC-151 — корневой _index.md обязан остаться вне проверок V3–V5 (инертен для движка, ADR-0015): находок по нему быть не должно" >&2
  FAIL=$((FAIL + 1))
fi
# Слово «properties» само по себе в находках легитимно: V3–V5 применены к индексам
# подпапок, и их сообщения не меняются (дизайн §2.5: «Сообщения V3–V5 не меняются» —
# V3 несёт «плоская нотация properties»). Запрещена только V2-формулировка запрета (нога f).

# --- (b): объявленное enum-свойство у индекса подпапки — чисто ---
if printf '%s\n' "$OUT" | grep -F "sub/_index.md" | grep -qE 'ERROR|WARNING'; then
  echo "  FAIL: AC-151 — sub/_index.md с объявленным свойством Тип контента [ADR] обязан быть чист: законная конструкция не краснеет и под --strict" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): необъявленное свойство — V4 по-прежнему находит ---
if ! printf '%s\n' "$OUT" | grep -F "sub2/_index.md" | grep -qF 'не объявлен'; then
  echo "  FAIL: AC-151 — sub2/_index.md с необъявленным свойством обязан давать V4 «не объявлен»: V4 применяется к индексам подпапок наравне со статьями" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): плоская нотация — V3-warning по-прежнему находит ---
if ! printf '%s\n' "$OUT" | grep -F "sub3/_index.md" | grep -qF 'плоская нотация'; then
  echo "  FAIL: AC-151 — sub3/_index.md с плоской нотацией обязан давать V3-warning: V3 применяется к индексам подпапок" >&2
  FAIL=$((FAIL + 1))
fi

# --- (e): значение вне enum — V5 по-прежнему находит ---
if ! printf '%s\n' "$OUT" | grep -F "sub4/_index.md" | grep -qF 'не входит в'; then
  echo "  FAIL: AC-151 — sub4/_index.md со значением вне enum обязан давать V5 «не входит в»: V5 применяется к индексам подпапок" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  printf '%s\n' "$OUT" >&2
  fail_msg "ac-151: AC-151 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-151: AC-151 — properties в _index.md легальны, V3–V5 применяются к индексам подпапок, корень вне проверок"
