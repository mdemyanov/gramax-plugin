#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-006-reports-migrated.sh
# Спека: спека волны nauta-integration (2026-08-07; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021) FR-3, FR-5
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

assert_file_exists "docs/60-implementation/_index.md" "C1: 60-implementation индекс"
assert_file_exists "docs/60-implementation/test-reports/_index.md" "C1: test-reports индекс"
assert_file_exists "docs/60-implementation/acceptance/_index.md" "C1: acceptance индекс"

# Отчёты и записи приёмки эпохи superpowers (2026-05…2026-08-10) удалены FR-129
# (ADR-0021, инверсия 2026-11-17) — их ассерты сняты. Живой набор: 5 отчётов
# живой эпохи + 6 at-design живых suite'ов.
for f in 2026-08-12-wave-4.2.0-qa-report.md \
         2026-08-13-cross-catalog-retraction-qa-report.md \
         2026-08-13-doc-root-discovery-qa-report.md \
         2026-08-13-link-form-contract-qa-report.md \
         2026-08-13-render-killer-linter-qa-report.md; do
  p="docs/60-implementation/test-reports/$f"
  assert_file_exists "$p" "AC-3: тест-отчёт $f на месте"
  [ -f "$p" ] && assert_grep "$p" "value: [Тест-отчёт]" "AC-7: $f имеет тип Тест-отчёт"
done

for f in 2026-08-11-mermaid-adoption-at-design.md \
         2026-08-11-validation-contract-at-design.md \
         2026-08-11-writer-consumer-rules-at-design.md \
         2026-08-13-cross-catalog-retraction-at-design.md \
         2026-08-13-link-form-contract-migration-at-design.md \
         2026-08-13-link-form-contract-resolver-at-design.md; do
  p="docs/60-implementation/acceptance/$f"
  assert_file_exists "$p" "AC-3: at-design $f на месте"
  [ -f "$p" ] && assert_grep "$p" "value: [Тест-отчёт]" "AC-7: $f имеет тип Тест-отчёт"
done

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006: 5 отчётов и 6 at-design живой эпохи на месте"
