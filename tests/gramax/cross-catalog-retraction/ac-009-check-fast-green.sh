#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-009-check-fast-green.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-009
#             (композитный). «bash scripts/check.sh --fast; echo exit=$?» — exit=0, проверено
#             по коду возврата, не по grep на PASS в выводе (content/lessons-learned.md,
#             2026-08-10 «зелёный по грепу — не зелёный»).
#
# Природа: PRE-PASSING regression guard — ЗЕЛЁНЫЙ на момент создания. `--fast` не запускает ни
# один suite tests/gramax/** (только whitespace + JSON + `uv run scripts/validate-content.py` —
# см. scripts/check.sh, шаги 1-2.5) — текст writer-skill вне его периметра. Тест защищает от
# регрессии в ДРУГОМ измерении: что правки Dev/Tech-writer (doc-root-schema.md, SKILL.md,
# CHANGELOG.md, plugin.json, marketplace.json) не сломают structural-валидацию content/
# (сироты, битые ссылки, JSON-синтаксис) — то, что --fast реально проверяет.
#
# Отдельный от AC-001(в) скрипт — намеренное дублирование прогона check.sh --fast (лишняя
# секунда на прогон), а не delegation-ссылка на AC-001: каждый AC этого suite'а обязан
# самостоятельно, без скрытой зависимости от порядка запуска других ac-*.sh, доказывать
# собственный буквальный критерий (см. at-design.md → «Находки»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
LOG_FILE="$(mktemp)"
( cd "$ROOT" && bash scripts/check.sh --fast ) > "$LOG_FILE" 2>&1
CHECK_EXIT=$?

if [ "$CHECK_EXIT" -ne 0 ]; then
  echo "  FAIL: AC-009 — bash scripts/check.sh --fast завершился exit=$CHECK_EXIT (ожидался 0). Полный вывод:" >&2
  cat "$LOG_FILE" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$LOG_FILE"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: bash scripts/check.sh --fast зелёный (exit=0)"
