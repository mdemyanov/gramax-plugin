#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-079-no-gallery-no-gantt.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-079 (BR-015/BR-016).
# Негативный контроль отсутствующих в движке: формы <gallery и display="Gantt"
#   не встречаются нигде в дереве writer; проза об отсутствии элементов
#   допустима — проверяются именно формы тега/значения.
# Природа: ЗЕЛЁНЫЙ WARDEN (негативное ожидание — то, чего НЕ должно быть).
#   Зелёный на a59db10 (2026-11-18): обе литеральные формы в дереве
#   отсутствуют, включая код-спаны и код-блоки. Ассерт защищает границу
#   BR-016: `<gallery>`/`Gantt` попадают в справочник только после нового
#   engine-window-исследования; Dev обязан формулировать избегание БЕЗ
#   литеральной формы («тег галереи», «значение Gantt»).
# Уровень: integration.
# Edge case дизайна (контракт с QA-author): грепы не знают markdown —
#   литеральные формы запрещены В ТОМ ЧИСЛЕ внутри код-блоков и примеров;
#   негативная проза — без воспроизведения формы.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

assert_no_grep_fixed_recursive "$WRITER_DIR" '<gallery' \
  "AC-079 — форма '<gallery' не должна встречаться нигде в дереве writer (BR-016: в движке на пине 48592b36 отсутствует; проза об отсутствии — без литеральной формы)"
assert_no_grep_fixed_recursive "$WRITER_DIR" 'display="Gantt"' \
  "AC-079 — форма 'display=\"Gantt\"' не должна встречаться нигде в дереве writer (BR-016; фраза избегания — «значение Gantt» без display=\"-префикса)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-079: AC-079 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-079: AC-079 — warden: литеральные формы <gallery и display=\"Gantt\" в дереве writer отсутствуют (BR-016)"
