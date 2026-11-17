#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-005-requirements-migrated.sh
# Спека: спека волны nauta-integration (2026-08-07; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021) FR-3, FR-5
# AC coverage:
#   AC-3 → уроки, research и требования переехали
#   AC-5 → мета-спека и мета-план удалены FR-129 при инверсии 2026-11-17 (ADR-0021)
#   AC-7 → «Тип контента» проставлен

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_file_exists "docs/lessons-learned.md" "AC-3: журнал уроков в корне docs/"
assert_file_not_exists "content/lessons-learned.md" "AC-3: старый путь журнала удалён (инверсия 2026-11-17)"
assert_dir_not_exists "content/10-domain" "AC-3: старый дом content/10-domain удалён (инверсия 2026-11-17)"

assert_file_exists "docs/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "AC-3: research переехал"
assert_file_exists "docs/10-domain/_index.md" "C1: 10-domain должен иметь _index.md"
assert_file_exists "docs/10-domain/research/_index.md" "C1: research должен иметь _index.md"
assert_file_exists "docs/30-requirements/_index.md" "C1: 30-requirements должен иметь _index.md"

for f in 2026-05-08-diagram-on-demand-design.md \
         2026-05-11-remove-diagram-skills.md \
         2026-05-11-routing-mermaid-drawio.md \
         2026-05-12-mermaid-file-based-design.md; do
  assert_file_exists "docs/30-requirements/$f" "AC-3: требование $f переехало"
  assert_file_not_exists "content/30-requirements/$f" "AC-3: старый путь $f удалён (инверсия 2026-11-17)"
  [ -f "docs/30-requirements/$f" ] && \
    assert_grep "docs/30-requirements/$f" "value: [Требование]" \
      "AC-7: $f имеет тип Требование"
done

# AC-5: мета-спека и мета-план 2026-05 удалены FR-129 при инверсии 2026-11-17
# (ADR-0021) — ассерты существования сняты, приёмника нет.

assert_grep "docs/lessons-learned.md" "value: [Урок]" "AC-7: журнал имеет тип Урок"
assert_grep "docs/10-domain/research/2026-05-11-drawio-skill-external.md" \
  "value: [Research]" "AC-7: research имеет тип Research"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: уроки, research и требования мигрированы; мета 2026-05 удалена FR-129"
