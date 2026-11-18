#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-026-diagram-targets-ok.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-062 (FR-151)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (формат сообщения W031 единый
# для всех четырёх тегов, суффикс аддитивен — grep 'W031|диаграмм' стабилен; ADR-0024 Решение 1)
# Проверка: существующие цели всех четырёх тегов → ноль находок по диаграммам
# Warden (зелёный при рождении, 99201c0): сегодня три новых тега не проверяются вовсе, поэтому
# находок нет; ассерт защищает от ЛОЖНЫХ диаграммных находок на существующих целях ПОСЛЕ
# реализации (grep -icE 'W031|диаграмм' → 0 обязан держаться и после расширения проверки).
# Шум фикстуры (не матчится ассертом): предупреждение «.drawio file should be converted to .svg»
# от check_no_drawio на файле ok.drawio и ложные W034 на <mermaid>/<bpmn> до реализации FR-156.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/diagrams-ok"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

COUNT=$(echo "$OUT" | grep -icE 'W031|диаграмм' || true)
assert_eq "$COUNT" "0" "AC-062 — существующие цели всех четырёх диаграммных тегов не дают находок по диаграммам (строк с 'W031|диаграмм' должно быть 0)"

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-026: AC-062 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-026: AC-062 — существующие цели не дают диаграммных находок"
