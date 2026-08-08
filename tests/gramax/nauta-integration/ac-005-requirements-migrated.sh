#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-005-requirements-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → уроки, research и требования переехали
#   AC-5 → мета-спека и мета-план остались в docs/
#   AC-7 → «Тип контента» проставлен

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "content/lessons-learned.md" "AC-3: журнал уроков в корне content/"
assert_file_not_exists "docs/lessons-learned.md" "AC-3: старый путь журнала удалён"
assert_dir_not_exists "docs/research" "AC-3: docs/research удалён"

assert_file_exists "content/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "AC-3: research переехал"
assert_file_exists "content/10-domain/_index.md" "C1: 10-domain должен иметь _index.md"
assert_file_exists "content/10-domain/research/_index.md" "C1: research должен иметь _index.md"
assert_file_exists "content/30-requirements/_index.md" "C1: 30-requirements должен иметь _index.md"

for f in 2026-05-08-diagram-on-demand-design.md \
         2026-05-11-remove-diagram-skills.md \
         2026-05-11-routing-mermaid-drawio.md \
         2026-05-12-mermaid-file-based-design.md; do
  assert_file_exists "content/30-requirements/$f" "AC-3: требование $f переехало"
  assert_file_not_exists "docs/superpowers/specs/$f" "AC-3: старый путь $f удалён"
  [ -f "content/30-requirements/$f" ] && \
    assert_grep "content/30-requirements/$f" "value: [Требование]" \
      "AC-7: $f имеет тип Требование"
done

# AC-5: мета-артефакты остаются в docs/.
assert_file_exists "docs/superpowers/specs/2026-05-08-apply-project-template-design.md" \
  "AC-5: мета-спека остаётся в docs/"
assert_file_exists "docs/superpowers/plans/2026-05-08-apply-project-template.md" \
  "AC-5: мета-план остаётся в docs/"

assert_grep "content/lessons-learned.md" "value: [Урок]" "AC-7: журнал имеет тип Урок"
assert_grep "content/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "value: [Research]" "AC-7: research имеет тип Research"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: уроки, research и требования мигрированы; мета осталась в docs/"
