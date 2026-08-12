#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-012-outside-catalog-codespan-ignored.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-012 (FR-084)
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 3 (FR-084 уже
#   удовлетворена архитектурой `_mask_code` + `in_scope`, без нового кода — см.
#   content/40-architecture/2026-08-13-link-form-contract-design.md, «FR/NFR Mapping»)
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Код-спан (backtick), не
#   markdown-ссылка — `_mask_code` вырезает его до сканирования `_MD_LINK_RE`, поэтому
#   `_collect_links` никогда не видит этот путь как ссылку, независимо от инференса
#   расширения (FR-082). Тест защищает границу FR-084/BR-005 от будущей регрессии —
#   например, если резолвер когда-нибудь начнёт резолвить голые пути вне `[]()`-разметки.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/outside-catalog-codespan"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -ne 0 ]; then
  echo "  FAIL: AC-012 — код-спан на несуществующий вне-каталожный путь ('plugins/gramax/...') не должен считаться битой ссылкой (границы FR-084: код-спаны не резолвятся вовсе)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qi 'plugins/gramax'; then
  echo "  FAIL: AC-012 — вывод не должен вообще упоминать путь код-спана 'plugins/gramax/...' (не резолвится и не проверяется, FR-084)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-012: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-012: путь код-спана вне каталога не проверяется вовсе"
