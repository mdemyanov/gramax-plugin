#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-165-parser-no-second-reading.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-165 (FR-222)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.1 (в
# validate_structure.py удаляются _parse_resources (:331-371) и _resolve_link_target
# (:607-622): ресурсные проверки получают ресурсы от тонкого адаптера над
# scan_md_resources, резолв — общий resolve_link_target); ADR-0028 Решение 1 и поправка к
# ADR-0016 Решение 1; контракт QA-author — §6.1 (строка 3, статическая проверка исходника).
# Проверка: структурный валидатор не оборачивает парсер вторым чтением — определений
#   _parse_resources и _resolve_link_target в validate_structure.py нет.
# Red on 6e2db04: оба определения на месте (обёртка ресурсов и собственный резолвер
#   валидатора) — второй читатель и второй резолвер рядом с парсером и lib/link_resolver.py.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
VALIDATOR="$ROOT/plugins/gramax/scripts/validate_structure.py"

assert_file_exists "$VALIDATOR" "AC-165: validate_structure.py на месте"

for symbol in _parse_resources _resolve_link_target; do
  N=$(grep -c "def $symbol" "$VALIDATOR")
  if [ "$N" -ne 0 ]; then
    echo "  FAIL: AC-165 RED — в validate_structure.py есть def $symbol ($N шт.): валидатор оборачивает парсер вторым чтением/резолвом; ресурсный скан и резолв обязаны идти через lib/ (ADR-0028 Решение 1, дизайн §3.1)" >&2
    grep -n "def $symbol" "$VALIDATOR" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-165: AC-165 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-165: AC-165 — у валидатора нет собственного чтения ресурсов (_parse_resources) и собственного резолвера (_resolve_link_target)"
