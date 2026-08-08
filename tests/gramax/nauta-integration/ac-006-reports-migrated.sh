#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-006-reports-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → отчёты прогона и приёмки переехали, docs/ очищен от них
#   AC-7 → «Тип контента» проставлен

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_dir_not_exists "docs/qa-reports" "AC-3: docs/qa-reports удалён"
assert_dir_not_exists "docs/acceptance" "AC-3: docs/acceptance удалён"

assert_file_exists "content/60-implementation/_index.md" "C1: 60-implementation индекс"
assert_file_exists "content/60-implementation/test-reports/_index.md" "C1: test-reports индекс"
assert_file_exists "content/60-implementation/acceptance/_index.md" "C1: acceptance индекс"

for f in 2026-05-08-diagram-on-demand-qa-report.md \
         2026-05-11-remove-diagram-skills-qa-report.md \
         2026-05-11-routing-mermaid-drawio.md \
         2026-05-12-mermaid-file-based-qa-report.md; do
  p="content/60-implementation/test-reports/$f"
  assert_file_exists "$p" "AC-3: тест-отчёт $f переехал"
  [ -f "$p" ] && assert_grep "$p" "value: [Тест-отчёт]" "AC-7: $f имеет тип Тест-отчёт"
done

for f in 2026-05-08-diagram-on-demand-acceptance.md \
         2026-05-11-remove-diagram-skills-acceptance.md \
         2026-05-11-routing-mermaid-drawio.md; do
  p="content/60-implementation/acceptance/$f"
  assert_file_exists "$p" "AC-3: приёмка $f переехала"
  [ -f "$p" ] && assert_grep "$p" "value: [Приёмка]" "AC-7: $f имеет тип Приёмка"
done

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006: 7 отчётов мигрированы"
