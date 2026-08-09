#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-005-mermaid-file-based-contract.sh
# Требование: FR-010. Происхождение: статически проверяемая половина
#             archive/mermaid-file-based (ac-005b, ac-006, ac-008, ac-011).
#             Динамическая половина — archive/mermaid-file-based/verify.sh.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$SKILL" "FR-010: skills/mermaid/SKILL.md должен существовать"
assert_grep "$SKILL" '<page-slug>-<diagram-slug>.mermaid' \
  "FR-010: SKILL.md обязан задавать naming convention файла"
assert_grep "$SKILL" '_index.md' \
  "FR-010: SKILL.md обязан описывать правило _index.md → имя родительского каталога"
assert_grep "$SKILL" '800px' "FR-010: SKILL.md обязан задавать дефолтную ширину"
assert_grep "$SKILL" '450px' "FR-010: SKILL.md обязан задавать дефолтную высоту"
assert_grep_regex "$SKILL" '<mermaid path="[^"]*"[^>]*/>' \
  "FR-010: SKILL.md обязан показывать самозакрывающийся тег"
assert_grep_regex "$SKILL" 'перезаписать|не трогай файл' \
  "FR-010: SKILL.md обязан запрещать молчаливую перезапись"
assert_no_grep "$SKILL" 'inline DSL, без файла' \
  "FR-010: устаревшая формулировка inline-workflow не должна вернуться"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: контракт file-based workflow в mermaid/SKILL.md соблюдён"
