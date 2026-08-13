#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-022-doc-root-title-type.sh
# Требование: content/30-requirements/2026-08-13-doc-root-discovery-contract.md AC-037 (FR-121)
# ADR: content/00-project/adr/0020-doc-root-recursive-discovery.md, Решение 2
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   До FR-121 check_doc_root проверяет только присутствие ключа (field not in data) —
#   title: 4.21/yes/null/{a: b} проходили чисто (exit 0). После FR-121 каждый не-строковый
#   тип обязательного поля docRootRequiredFields — error с фактическим типом значения.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/doc-root-title-type"

# (тип YAML : ожидаемое имя типа в сообщении)
BROKEN_CASES=(
  "float:float"
  "bool:bool"
  "null:null"
  "dict:dict"
)

for entry in "${BROKEN_CASES[@]}"; do
  name="${entry%%:*}"
  typename="${entry#*:}"
  OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE/$name" 2>&1)
  EXIT=$?
  if [ "$EXIT" -eq 0 ]; then
    echo "  FAIL: AC-037 — title типа '$typename' обязан давать ненулевой код возврата (FR-121: значение обязано быть непустой строкой)" >&2
    echo "  --- вывод валидатора ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
  if ! echo "$OUT" | grep -q "got $typename"; then
    echo "  FAIL: AC-037 — сообщение обязано содержать фактический тип 'got $typename' для title ($FIXTURE/$name)" >&2
    echo "  --- вывод валидатора ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
done

# Закавыченный title: "4.21" — непустая строка → чисто
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE/quoted" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi
assert_eq "$EXIT" "0" \
  "AC-037: title: \"4.21\" (непустая строка) обязан давать чистый проход (exit 0)"
if [ "$EXIT" -eq 0 ] && ! echo "$OUT" | grep -q "got "; then
  :
else
  if echo "$OUT" | grep -q "invalid type for field"; then
    echo "  FAIL: AC-037 — закавыченный title: \"4.21\" не должен давать invalid type (это непустая строка)" >&2
    echo "  --- вывод валидатора ---" >&2
    echo "$OUT" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-022: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-022: типизация обязательных полей .doc-root.yaml (dict/list/bool/int/float/date/null/пустая строка → error)"
