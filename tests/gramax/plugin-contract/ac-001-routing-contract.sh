#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-001-routing-contract.sh
# Требование: content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md FR-006
# Происхождение: обобщает archive/routing-mermaid-drawio ac-001…008 и
#                archive/remove-diagram-skills ac-014 — живая часть, без версионных пинов.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DRAWIO="$ROOT/plugins/gramax/skills/drawio/SKILL.md"
MERMAID="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$DRAWIO"  "FR-006: skills/drawio/SKILL.md должен существовать"
assert_file_exists "$MERMAID" "FR-006: skills/mermaid/SKILL.md должен существовать"

# Границы скиллов друг относительно друга — обе стороны, иначе роутинг однонаправленный
assert_grep_regex "$DRAWIO" 'НЕ для mermaid|не для mermaid' \
  "FR-006: description drawio обязан явно исключать mermaid"
assert_grep "$DRAWIO" "gramax:mermaid" \
  "FR-006: drawio обязан перекрёстно ссылаться на gramax:mermaid"
assert_grep_regex "$MERMAID" 'НЕ для drawio|не для drawio' \
  "FR-006: description mermaid обязан явно исключать drawio"
assert_grep "$MERMAID" "gramax:drawio" \
  "FR-006: mermaid обязан перекрёстно ссылаться на gramax:drawio"

# Подсказка установки внешнего плагина — без неё делегирование необнаружимо
assert_grep "$DRAWIO" "Agents365-ai" \
  "FR-006: drawio обязан называть внешний плагин Agents365-ai"

# Секции тела
assert_grep_regex "$DRAWIO" '^## Workflow' \
  "FR-006: drawio обязан иметь секцию Workflow"
assert_grep_regex "$DRAWIO" '^## Fallback' \
  "FR-006: drawio обязан иметь секцию Fallback при ambiguous-request"
assert_grep_regex "$MERMAID" 'Fallback|ambiguous' \
  "FR-006: mermaid обязан иметь fallback-секцию с альтернативой drawio"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: контракт роутинга drawio ↔ mermaid соблюдён"
