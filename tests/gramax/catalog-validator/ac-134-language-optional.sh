#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-134-language-optional.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-134 (FR-213)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.1
# (docRootRequiredFields: ["title","syntax"]; новый docRootOptionalFields: ["language"] —
# присутствующее поле проверяется на непустую строку при наличии), ADR-0026 Решение 1.
# Проверка (каждый вариант .doc-root.yaml подставляется во временную копию каталога):
#   (a) language отсутствует → «missing field: language» нет, rc=0;
#   (b) language: 123 / null / пустая строка → находка типа остаётся (FR-121;
#       зелёная нога — правило присутствующего поля сохраняется);
#   (c) контракт: schemaVersion 2, docRootRequiredFields без language,
#       docRootOptionalFields содержит language.
# Red on 7553da1: language в docRootRequiredFields (gramax-catalog-rules.json:3) →
#   «missing field: language» (замер 2026-11-23 на фикстуре no-language); нога (c) красная —
#   ключа docRootOptionalFields нет, schemaVersion 1.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-134-language"
RULES_JSON="$ROOT/plugins/gramax/gramax-catalog-rules.json"

run_variant() {
  local variant="$1"
  local tmp
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/ac-134.XXXXXX")
  cp -R "$FIXTURE/" "$tmp/"
  rm -f "$tmp"/*.doc-root.yaml
  cp "$FIXTURE/$variant.doc-root.yaml" "$tmp/.doc-root.yaml"
  (cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$tmp" 2>&1)
  rm -rf "$tmp"
}

# --- (a): language отсутствует → ошибки нет ---
if OUT=$(run_variant no-language); then
  RC=0
else
  RC=$?
fi
if printf '%s\n' "$OUT" | grep -qF 'missing field: language'; then
  echo "  FAIL: AC-134 — «missing field: language» на каталоге без language: поле необязательно по факту движка (FSLocalizationEvents.ts:19-22 на пине 48592b36)" >&2
  FAIL=$((FAIL + 1))
fi
assert_eq "$RC" "0" "AC-134: каталог без language — чист (rc=0; замер 2026-11-23: rc=1)"

# --- (b): присутствующее поле неверного типа по-прежнему даёт находку ---
for variant in int-language null-language empty-language; do
  if OUT_V=$(run_variant "$variant"); then
    RC_V=0
  else
    RC_V=$?
  fi
  if ! printf '%s\n' "$OUT_V" | grep -qF 'invalid type for field "language"'; then
    echo "  FAIL: AC-134 — вариант $variant: присутствующее поле language обязано проверяться на непустую строку (docRootOptionalFields, FR-121)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- (c): контракт — schemaVersion 2, language ушёл из обязательных, в опциональных ---
assert_eq "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("schemaVersion"))' "$RULES_JSON" 2>/dev/null)" "2" \
  "AC-134: schemaVersion gramax-catalog-rules.json = 2 (ADR-0026, подъём по прецеденту)"

REQ=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1],encoding="utf-8"));print(",".join(d.get("docRootRequiredFields",[])))' "$RULES_JSON" 2>/dev/null)
if printf '%s' "$REQ" | grep -q "language"; then
  echo "  FAIL: AC-134 — language обязан уйти из docRootRequiredFields (сейчас: [$REQ])" >&2
  FAIL=$((FAIL + 1))
fi

OPT=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1],encoding="utf-8"));print(",".join(d.get("docRootOptionalFields",[])))' "$RULES_JSON" 2>/dev/null)
if ! printf '%s' "$OPT" | grep -q "language"; then
  echo "  FAIL: AC-134 — docRootOptionalFields обязан содержать language: без ключа присутствующее поле выпадет из проверки типов (§2.1)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-134: AC-134 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-134: AC-134 — language необязателен, присутствующее поле проверяется по типу, контракт согласован"
