#!/usr/bin/env bash
# tests/gramax/render-quality/ac-120-th-record.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-120 (FR-199)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 4
#   («Один цикл» — запись замера по пути
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md, форма девяти
#   полей runbook: tier-0 факт из отчёта прибора, прогон валидатора, решение).
# Проверка (контракт): запись повторного замера th существует в журнале приёмки и несёт
#   (1) имя замеряемой фикстуры th-in-table, (2) tier-0 факт из отчёта прибора
#   (форма «OK 2xx» / «HTTP 200» / «200»), (3) оба носителя th-вердикта —
#   gramax-render-rules.json и validate_render.py. Судьба th решается только замером
#   против факта рендера (FR-199, BR-021) — запись есть записанное основание вердикта.
#   Нога «th-вердикт не менялся иначе как по этой записи» (сверка коммитов) — владелец
#   BA-acceptance, стабом не покрывается.
# Цвет при создании: КРАСНЫЙ — записи замера th в журнале приёмки нет; закрывает Dev
#   в цикле понижения (FR-202: запись без правки и правка без записи приёмку не проходят).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

RECORD="$ROOT/docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md"

FAIL=0

if [ ! -f "$RECORD" ]; then
  fail_msg "ac-120: записи повторного замера th нет — docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md отсутствует; судьба th-вердикта без записанного основания (AC-120, FR-199, BR-021)"
  exit 1
fi

# (1) фикстура замера названа
if ! grep -qF "th-in-table" "$RECORD"; then
  echo "  FAIL: AC-120 — запись замера обязана называть фикстуру th-in-table (предмет замера, FR-199)" >&2
  FAIL=$((FAIL + 1))
fi

# (2) tier-0 факт из отчёта прибора (форма «OK 2xx» / «HTTP 200» / «200»)
if ! grep -qEi 'OK 2xx|HTTP 200|(^|[^0-9])200([^0-9]|$)' "$RECORD"; then
  echo "  FAIL: AC-120 — запись обязана нести tier-0 факт по th-in-table из отчёта прибора (форма «OK 2xx»/«HTTP 200»/«200», поле 5 формы девяти полей runbook)" >&2
  FAIL=$((FAIL + 1))
fi

# (3) оба носителя вердикта названы
assert_grep "$RECORD" "gramax-render-rules.json" "AC-120: запись называет носитель gramax-render-rules.json (факт 3)"
assert_grep "$RECORD" "validate_render.py" "AC-120: запись называет носитель validate_render.py (факт 3)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-120: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-120: запись замера th в журнале приёмки несёт фикстуру, tier-0 факт и оба носителя вердикта"
