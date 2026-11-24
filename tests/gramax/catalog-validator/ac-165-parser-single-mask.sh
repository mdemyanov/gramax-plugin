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
# Red on 6e2db04: парсер держит собственную копию _mask_code (:43-60) и оба выражения
#   (:13-14) — второй путь маскирования рядом с lib/md_code_mask.py.

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

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-165: AC-165 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-165: AC-165 — маска одна: у парсера нет копии _mask_code и собственных выражений, определение одно в md_code_mask.py"
