#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-012-drawio-tag-syntax-preserved.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-012 (NFR-002).
# Диспозиция: NFR Mapping — "ни одно решение не переименовывает skill-имена и не меняет
#   подтверждённый синтаксис (<drawio path=.../>, inline-code ссылка, object-нотация)".
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Синтаксис `<drawio path="..."
#   width="..." height="..."/>` в references/drawio.md уже актуален (единый тег с v4.1.0, см.
#   AGENTS.md/CHANGELOG). Этот тест защищает синтаксис от случайной порчи при точечных правках
#   документации по темам A–F этого требования (ни одна из которых не должна касаться drawio).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DRAWIO_MD="$ROOT/plugins/gramax/skills/writer/references/drawio.md"

assert_grep_regex "$DRAWIO_MD" '<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>' \
  "AC-012 — references/drawio.md должен продолжать показывать синтаксис <drawio path=\"...\" width=\"...\" height=\"...\"/>"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-012: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-012: синтаксис <drawio path=.../> не тронут (regression guard)"
