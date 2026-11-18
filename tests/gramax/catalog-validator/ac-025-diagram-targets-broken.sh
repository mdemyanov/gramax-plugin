#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-025-diagram-targets-broken.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-061 (FR-151)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (W031 наследуется, ADR-0024 Решения 1/3)
# Проверка: битые цели <mermaid>/<plant-uml>/<bpmn> → вывод валидатора называет каждую из трёх целей
# Red on 99201c0 (2026-11-18): parse_md_resources извлекает только target_type "drawio"
# (scripts/lib/md_link_parser.py:26), check_diagrams фильтрует target_type != "drawio"
# (validate_structure.py:727) — цели трёх новых тегов не извлекаются, находок по ним ноль.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/diagrams-broken-targets"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

for target in missing.mmd missing.puml missing.bpmn; do
  if ! echo "$OUT" | grep -qF "$target"; then
    echo "  FAIL: AC-061 — вывод должен упоминать отсутствующую цель '$target' (проверка существования цели диаграммного тега, FR-151)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-025: AC-061 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-025: AC-061 — битые цели mermaid/plant-uml/bpmn называются в выводе (W031)"
