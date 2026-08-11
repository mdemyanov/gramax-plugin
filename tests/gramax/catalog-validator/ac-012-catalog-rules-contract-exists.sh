#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-012-catalog-rules-contract-exists.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-006 (FR-040)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 3
#      (plugins/gramax/gramax-catalog-rules.json: docRootRequiredFields,
#      frontmatterRequiredFields, indexPolicy, garbageFiles[]).
#      content/00-project/adr/0015-root-index-inert.md, Решение 4 (indexPolicy.root:
#      optional — значение не меняется, только сопровождающая документация).
# Природа: живой контракт — КРАСНЫЙ на момент создания (файл ещё не создан — DEV-001,
#   подтверждено ADR-0015: `find plugins/gramax -iname '*catalog-rules*'` — пусто).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
RULES_FILE=$(find "$ROOT/plugins/gramax" -iname '*catalog-rules*' -iname '*.json' 2>/dev/null | head -1)

if [ -z "$RULES_FILE" ]; then
  echo "  FAIL: AC-006 — машиночитаемый файл контракта правил каталога не найден (FR-040, ADR-0012 Решение 3: gramax-catalog-rules.json)" >&2
  FAIL=$((FAIL + 1))
else
  CONTENT_REPORT=$(python3 - "$RULES_FILE" <<'PY'
import json
import sys

rules_file = sys.argv[1]

try:
    contract = json.load(open(rules_file, encoding="utf-8"))
except (json.JSONDecodeError, OSError) as e:
    print(f"PARSE_ERROR: {rules_file} — {e}")
    sys.exit(1)

if not isinstance(contract, dict):
    print(f"PARSE_ERROR: {rules_file} — верхний уровень JSON не объект")
    sys.exit(1)

missing = [
    key for key in ("indexPolicy", "docRootRequiredFields", "frontmatterRequiredFields")
    if key not in contract
]
if missing:
    print(f"MISSING_KEYS: {missing}")
    sys.exit(1)

sys.exit(0)
PY
)
  CONTENT_EXIT=$?
  if [ "$CONTENT_EXIT" -ne 0 ]; then
    echo "  FAIL: AC-006 — файл контракта правил каталога ($RULES_FILE) обязан содержать indexPolicy/docRootRequiredFields/frontmatterRequiredFields (FR-040)" >&2
    echo "$CONTENT_REPORT" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-012: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-012: машиночитаемый файл контракта правил каталога существует и полон"
