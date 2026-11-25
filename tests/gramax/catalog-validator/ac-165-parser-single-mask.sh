#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-165-parser-single-mask.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-165 (FR-222)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.1 («собственная
# _mask_code (:43-60), _FENCE_RE и _INLINE_CODE_RE (:13-14) удаляются — маска
# импортируется из lib.md_code_mask»); ADR-0028 Решение 1; контракт QA-author — §6.1
# (строка 2, статическая проверка исходника).
# Проверка: маска кода одна — в lib/md_link_parser.py нет ни определения _mask_code, ни
#   собственных _FENCE_RE/_INLINE_CODE_RE; единственное определение _mask_code — в
#   lib/md_code_mask.py (замер-основание ADR-0028: grep -c 'def _mask_code' по трём
#   файлам → 1, 1, 1).
# Дополнено ревью r1 (2026-11-25, эпик-бид, находки [F] AC-165 anchor
# migrate_nav_codespans.py:91 и ac-165:41; решения PM 1):
#   (a) список файлов с def _mask_code по plugins/gramax/scripts — РОВНО ДВА:
#   lib/md_code_mask.py (одна маска двух контуров: парсер и валидаторы) и
#   migrate_nav_codespans.py (ЗАПИСАННОЕ ИСКЛЮЧЕНИЕ — побайтовая копия без фазы 2,
#   ADR-0028 Решение 2 и дизайн §3.2 «Побайтовая копия … не меняется»; мигратор —
#   замороженный ручной диагност, ADR-0029 Решение 3). Ногa замкнута против «1 по
#   построению»: третья копия в любом файле красит;
#   (b) текст мигратора НЕ содержит ни одной ссылки вида validate_structure.py::<имя>
#   — все определения-образцы удалены из validate_structure.py (ADR-0028 Решение 1).
#   Ревью r2 (2026-11-25, anchor migrate_nav_codespans.py:91): после правки r1 у
#   мигратора осталась ЧЕТВЁРТАЯ ссылка того же класса — validate_structure.py::
#   _MD_LINK_RE (:91); нога обобщена с одного литерала на весь класс ссылок.
# Red on 6e2db04: парсер держит собственную копию _mask_code (:43-60) и оба выражения
#   (:13-14) — второй путь маскирования рядом с lib/md_code_mask.py.
# Red on f3d16a5 (по дизайну, нога (b) в редакции r2): ссылка validate_structure.py::
#   _MD_LINK_RE на :91 ещё на месте — нога красная до правки текста Dev (идёт
#   параллельно); нога (a) зелёная.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PARSER="$ROOT/plugins/gramax/scripts/lib/md_link_parser.py"
MASKLIB="$ROOT/plugins/gramax/scripts/lib/md_code_mask.py"

assert_file_exists "$PARSER" "AC-165: lib/md_link_parser.py на месте"
assert_file_exists "$MASKLIB" "AC-165: lib/md_code_mask.py на месте"

N_PARSER_MASK=$(grep -c 'def _mask_code' "$PARSER")
if [ "$N_PARSER_MASK" -ne 0 ]; then
  echo "  FAIL: AC-165 RED — в lib/md_link_parser.py собственная копия _mask_code ($N_PARSER_MASK шт.): второй путь маскирования, маска обязана быть одна (ADR-0028 Решение 1, дизайн §3.1)" >&2
  grep -n 'def _mask_code' "$PARSER" >&2
  FAIL=$((FAIL + 1))
fi

N_PARSER_RES=$(grep -cE '^_FENCE_RE|^_INLINE_CODE_RE' "$PARSER")
if [ "$N_PARSER_RES" -ne 0 ]; then
  echo "  FAIL: AC-165 — в lib/md_link_parser.py собственные _FENCE_RE/_INLINE_CODE_RE ($N_PARSER_RES шт.): выражения маски дублируют lib/md_code_mask.py (дизайн §3.1)" >&2
  grep -nE '^_FENCE_RE|^_INLINE_CODE_RE' "$PARSER" >&2
  FAIL=$((FAIL + 1))
fi

N_MASKLIB=$(grep -c 'def _mask_code' "$MASKLIB")
assert_eq "$N_MASKLIB" "1" "AC-165: единственное определение _mask_code — в lib/md_code_mask.py (одна маска на валидатор, парсер и рендер; замер ADR-0028: 1)"

# --- (r1, a): по plugins/gramax/scripts РОВНО ДВА файла с def _mask_code ---
MIGRATOR="$ROOT/plugins/gramax/scripts/migrate_nav_codespans.py"
assert_file_exists "$MIGRATOR" "AC-165: migrate_nav_codespans.py на месте"

ACTUAL_MASK_FILES=$(grep -rl 'def _mask_code' "$ROOT/plugins/gramax/scripts" | sed "s|^$ROOT/plugins/gramax/scripts/||" | sort)
EXPECTED_MASK_FILES=$'lib/md_code_mask.py\nmigrate_nav_codespans.py'
if [ "$ACTUAL_MASK_FILES" != "$EXPECTED_MASK_FILES" ]; then
  echo "  FAIL: AC-165 (r1-a) — с def _mask_code РОВНО ДВА файла: lib/md_code_mask.py (одна маска двух контуров: парсер и валидаторы) и migrate_nav_codespans.py (записанное исключение: побайтовая копия без фазы 2 — ADR-0028 Решение 2, дизайн §3.2, ADR-0029 Решение 3); фактический список:" >&2
  printf '%s\n' "$ACTUAL_MASK_FILES" >&2
  FAIL=$((FAIL + 1))
fi

# --- (r1-b, обобщено ревью r2 2026-11-25): НИ ОДНОЙ ссылки вида
# validate_structure.py::<имя> — все определения-образцы, на которые мигратор ссылался
# как на модели копий (_mask_code, _MD_LINK_RE, _FENCE_RE, _INLINE_CODE_RE,
# _EXTERNAL_RE), из validate_structure.py удалены (ADR-0028 Решение 1: маска — в
# lib/md_code_mask.py); упоминание «территории validate_structure.py» без ::<имя>
# указателем модели не является ---
if grep -qE 'validate_structure\.py::' "$MIGRATOR"; then
  echo "  FAIL: AC-165 (r1-b, r2) RED — migrate_nav_codespans.py ссылается на модельную копию вида validate_structure.py::<имя>: ни одно из определений-образцов в validate_structure.py больше не существует (ADR-0028 Решение 1) — текст правит Dev" >&2
  grep -nE 'validate_structure\.py::' "$MIGRATOR" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-165: AC-165 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-165: AC-165 — маска одна: у парсера нет копии и собственных выражений; с def _mask_code ровно два файла (md_code_mask + записанное исключение-мигратор); в тексте мигратора нет ни одной ссылки вида validate_structure.py::<имя>"
