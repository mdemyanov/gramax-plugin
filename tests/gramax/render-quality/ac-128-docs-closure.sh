#!/usr/bin/env bash
# tests/gramax/render-quality/ac-128-docs-closure.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-128 (FR-207)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 1
#   (пример схемы переводится на живую форму, host-заполнитель .invalid сохраняется)
#   и Решение 4/FR-207 (документарное закрытие одним контуром: at-acceptance дополнение,
#   README сюиты + runbook синхронно, живая форма в таблице настройки цели).
# Проверка (контракт, статические маркеры):
#   (a) scripts/render-quality/render-target.example.json: pageUrlTemplate ==
#       "{base}/{catalog}/{slug}" (без /page/), baseUrl == .invalid-заполнитель (RFC 2606) —
#       пример остаётся единственным коммитимым файлом прибора с литералом https://;
#   (b) runbook несёт живую форму в таблице настройки цели ({base}/{catalog}/{slug});
#   (c) runbook и README сюиты не несут устаревшей формы /page/ (синхрон документов);
#   (d) at-acceptance дополнение волны-2 существует в журнале приёмки (путь зафиксирован
#       at-design: docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md)
#       и называет судьбу th (фикстуру th-in-table).
#   Нога «урок волны-2 записан в docs/lessons-learned.md» — содержательная, маркер
#   формулировки дизайном не зафиксирован: владелец Dev/BA-acceptance, стабом не
#   покрывается (см. at-design, «Покрытие AC»).
# Цвет при создании: КРАСНЫЙ — пример в форме {base}/page/{catalog}/{slug}, живой формы
#   в runbook нет, дополнения нет. Закрывает Dev на шаге документарного закрытия (D4).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
EXAMPLE="$ROOT/scripts/render-quality/render-target.example.json"
RUNBOOK="$ROOT/docs/70-operations/2026-11-21-render-quality-runbook.md"
SUITE_README="$ROOT/tests/gramax/render-quality/README.md"
SUPPLEMENT="$ROOT/docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- (a) пример схемы: живая форма, .invalid сохранён ---
PY_OUT="$(python3 -I - "$EXAMPLE" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print("TEMPLATE=%s" % data.get("pageUrlTemplate", "<absent>"))
print("BASEURL=%s" % data.get("baseUrl", "<absent>"))
PYEOF
)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'TEMPLATE={base}/{catalog}/{slug}' || true)" "1" "AC-128: render-target.example.json переведён на живую форму {base}/{catalog}/{slug} без /page/ (Решение 1, FR-207б)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'BASEURL=https://render-target.example.invalid' || true)" "1" "AC-128: host-заполнитель .invalid (RFC 2606) сохранён — пример остаётся единственным коммитимым файлом с литералом https://"

# --- (b) runbook: живая форма в таблице настройки цели ---
assert_grep "$RUNBOOK" "{base}/{catalog}/{slug}" "AC-128: runbook несёт живую форму pageUrlTemplate в таблице настройки цели (FR-207б)"

# --- (c) устаревшей формы /page/ в документах нет ---
assert_no_grep "$RUNBOOK" "/page/" "AC-128: runbook без устаревшей формы /page/ (синхрон документов, FR-207б)"
assert_no_grep "$SUITE_README" "/page/" "AC-128: README сюиты без устаревшей формы /page/ (синхрон документов, FR-207б)"

# --- (d) at-acceptance дополнение волны-2 ---
if [ ! -f "$SUPPLEMENT" ]; then
  echo "  FAIL: AC-128 — at-acceptance дополнение волны-2 отсутствует: $SUPPLEMENT (FR-207а: судьба th, факты пробных страниц, заключения tier-1)" >&2
  FAIL=$((FAIL + 1))
else
  assert_grep "$SUPPLEMENT" "th-in-table" "AC-128: дополнение называет судьбу th (фикстура th-in-table, FR-207а)"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-128: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-128: пример на живой форме, runbook и README синхронны (без /page/), at-acceptance дополнение волны-2 существует"
