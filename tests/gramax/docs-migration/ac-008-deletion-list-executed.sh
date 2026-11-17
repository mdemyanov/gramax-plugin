#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-008-deletion-list-executed.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-008 (FR-129).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 2 — зелёным делают
# коммит B (git rm 19 путей, NFR-002) и коммит C (выжившие at-design'ы и отчёты читаются
# уже из docs/ после переезда).
# Контракт: все 19 путей FR-129 отсутствуют (координаты до переезда; форма `test ! -e`
# корректна и после переезда — удалять нечего, content/ и docs/superpowers/ исчезли);
# контроль остающихся: at-design'ы живых suite'ов и отчёты живой эпохи доезжают до docs/.
# RED on 8b2db0b (дерево до миграции): все 19 путей существуют, выжившие файлы ещё на content/.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAIL=0

fail() {
  printf "  ${RED}FAIL:${NC} %s\n" "$1" >&2
  FAIL=$((FAIL + 1))
}

# FR-129 — формальный список удаления, ровно 19 путей; дополнения запрещены.
FR129_PATHS=(
  docs/superpowers/_index.md
  docs/superpowers/plans/2026-05-08-apply-project-template.md
  docs/superpowers/plans/2026-08-07-nauta-integration.md
  docs/superpowers/plans/2026-08-09-test-harness-taxonomy.md
  docs/superpowers/plans/2026-08-12-healthcheck-port-plan.md
  docs/superpowers/plans/_index.md
  docs/superpowers/specs/2026-05-08-apply-project-template-design.md
  docs/superpowers/specs/2026-08-07-nauta-integration-design.md
  docs/superpowers/specs/2026-08-12-healthcheck-port-design.md
  docs/superpowers/specs/_index.md
  content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md
  content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md
  content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md
  content/60-implementation/test-reports/2026-05-12-mermaid-file-based-qa-report.md
  content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md
  content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md
  content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md
  content/60-implementation/acceptance/2026-05-11-routing-mermaid-drawio.md
  docs/doc-paths-disposition.md
)

for p in "${FR129_PATHS[@]}"; do
  if [ -e "$p" ]; then
    fail "AC-008/FR-129: путь из списка удаления ещё существует: $p"
  fi
done

# Контроль остающихся: живые at-design'ы и отчёты читаются из docs/ (после коммита C).
for f in \
  docs/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md \
  docs/60-implementation/test-reports/2026-08-13-render-killer-linter-qa-report.md; do
  if [ ! -f "$f" ]; then
    fail "AC-008/FR-129: выживший файл не найден по адресу $f"
  fi
done

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-008: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # color codes in the format string are the intended output styling
printf "${GREEN}[PASS]${NC} ac-008: 19 путей FR-129 отсутствуют, выжившие файлы читаются из docs/\n"
exit 0
