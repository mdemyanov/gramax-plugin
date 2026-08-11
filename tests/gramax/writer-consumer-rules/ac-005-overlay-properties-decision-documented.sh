#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-005-overlay-properties-decision-documented.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-005 (FR-068).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел B —
#   overlay-расширение `properties` технически не запрещено, но не валидируется; рекомендована
#   необязывающая конвенция провенанса (комментарий `# добавлено overlay'ем <имя>`) в
#   references/doc-root-schema.md.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DOC_ROOT_SCHEMA="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_grep_regex_i "$DOC_ROOT_SCHEMA" 'overlay' \
  "AC-005 — references/doc-root-schema.md должен документировать решение по расширению схемы properties overlay'ем (FR-068)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: решение по overlay-расширению properties задокументировано в doc-root-schema.md"
