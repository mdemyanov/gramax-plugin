#!/usr/bin/env bash
# tests/gramax/render-linter/ac-166-multiline-span-masked.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-166 (FR-223)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.2 (маска
# _mask_code двухфазная: фаза 1 без изменений, фаза 2 спаривает бэктики, оставшиеся
# одинокими на своей строке, в пределах блока — пустая строка обрывает; замена сохраняет
# переводы строк), §6.2 (строка 1); ADR-0028 Решение 2 (однопроходный вариант отклонён
# замером: +8 находок на docs/; замер-основание: фикстура с <note>…</note> в разорванном
# спане → FAIL, ERROR L6, rc=1).
# Проверка (фикстура ac-166-multiline-span.md — <note>…</note> внутри код-спана,
#   разорванного переносом строки, span начинается на строке 6): правило-киллер не даёт
#   находки внутри спана — OK, rc=0, ни одной строки ERROR и FAIL.
# Red on 6e2db04: маска однофазная — спан не маскируется, правило даёт ложный
#   «ERROR L6: Инлайновый <note>…</note> в одну строку», rc=1 (замер на этой фикстуре,
#   2026-11-24).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-166-multiline-span.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-166 RED — фикстура с код-спаном, разорванным переносом строки, даёт rc=$RC: многострочный спан не маскируется, правило-киллер срабатывает внутри него (ADR-0028 Решение 2, дизайн §3.2)" >&2
  printf '%s\n' "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "FAIL"; then
  echo "  FAIL: AC-166 — вердикт FAIL не допускается: иллюстрация синтаксиса в многострочном спане не дефект страницы (FR-223)" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "ERROR L6"; then
  echo "  FAIL: AC-166 — «ERROR L6: Инлайновый <note>…</note> в одну строку» обязан уйти: спан разорван переносом и маскируется второй фазой (дизайн §6.2: зелёный — «OK, rc=0»)" >&2
  printf '%s\n' "$OUT" | grep -F "ERROR" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -qF "Инлайновый <note>"; then
  echo "  FAIL: AC-166 — правило-киллер не должно находить <note> внутри маскированного спана" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-166: AC-166 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-166: AC-166 — многострочный код-спан маскирован: OK, rc=0, правило-киллер молчит внутри спана"
