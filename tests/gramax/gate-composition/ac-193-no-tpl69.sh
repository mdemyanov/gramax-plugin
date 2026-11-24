#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-193-no-tpl69.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-193 (FR-244, карточка gramax-o0q.16).
# Прибор: scripts/validate-content.py, правило C19/TPL-69 (склеенный абзац: run > 1500
#   символов И в среднем > 120 симв/строку; NA-EPIC-102 D3).
# Проверка (контракт): прогон валидатора на docs/ завершается кодом 0 и не печатает ни одной
#   строки TPL-69 (было 7 файлов — факт 9 требования; переформатирование санкционировано D3,
#   смысл блоков не менялся — только переносы строк).
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — rc=0, строк TPL-69 0 (замер роли).
# Мутация к красному (показана в at-design 2026-11-24-wave4-docs-at-design.md): /tmp-копия
#   docs с одним склеенным абзацем (> 1500 символов на нескольких длинных строках) → прибор
#   называет TPL-69 на посаженный файл. rc≠0 красит отдельной ногой — крушение прибора не
#   проходит как «тихо зелёный» (маскированный отказ назван).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TOOL="$ROOT/scripts/validate-content.py"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

assert_file_exists "$TOOL" "AC-193: прибор validate-content.py на месте"

PYTHONDONTWRITEBYTECODE=1 python3 -B "$TOOL" "$ROOT/docs" > "$OUT" 2>&1
RC=$?
TPL_COUNT="$(grep -c 'TPL-69' "$OUT" || true)"

assert_exit_zero "$RC" \
  "AC-193: rc validate-content.py на docs/ = 0 (ненулевой rc без TPL-69 — крушение прибора, не тихий проход)"

if [ "${TPL_COUNT:-0}" -eq 0 ]; then
  :
else
  echo "  FAIL: AC-193 — валидатор печатает ${TPL_COUNT} строк(и) TPL-69 (склеенные абзацы):" >&2
  grep 'TPL-69' "$OUT" | head -5 >&2
  echo "  (переформатирование TPL-69 проведено волной-4, D3: переносы строк восстановлены," >&2
  echo "  смысл не менялся; возврат склейки — регресс)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-193: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-193: строк TPL-69 на docs/ нет, rc validate-content.py = 0"
