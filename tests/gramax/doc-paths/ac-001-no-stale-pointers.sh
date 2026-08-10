#!/usr/bin/env bash
# tests/gramax/doc-paths/ac-001-no-stale-pointers.sh
# Требование: FR-024, FR-025, FR-026. Область — только content/.
# plugins/, tests/ и корневые документы покрывает nauta-integration/ac-007 (BR-003).

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/scan.sh"
cd "$ROOT"

if scan_doc_paths "content" "$SCRIPT_DIR/allowlist.txt"; then
  pass_msg "ac-001: в content/ нет нерабочих docs/-указателей, allowlist актуален"
  exit 0
fi
fail_msg "ac-001: гейт doc-paths не пройден"
exit 1
