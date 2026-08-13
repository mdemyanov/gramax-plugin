#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-024-nested-doc-root-orphan-demarcation.sh
# Требование: content/30-requirements/2026-08-13-doc-root-discovery-contract.md AC-039 (FR-120 граница ownership)
# ADR: content/00-project/adr/0020-doc-root-recursive-discovery.md, Решение 1 (in_scope=False, FR-047)
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   До FR-120 вложенный root не валидируется вовсе (exit 0, дефект title: 4.21 невидим).
#   После: вложенный каталог валидируется как отдельный root, его статьи не orphan-ы
#   внешнего, дефект даёт ровно одну находку (не дубль от ancestor, BR-004).
#
#   Сценарий фикстуры:
#     - внешний каталог: outer-orphan.md без входящих ссылок → orphan внешнего (1 находка);
#     - вложенный examples/project-example/content/ — отдельный root, его статьи
#       (inner.md) ссылками связаны внутри вложенного root → НЕ orphan-ы внешнего;
#     - вложенный .doc-root.yaml несёт дефект title: 4.21 → ровно ОДНА находка
#       invalid type (каждый root валидирует свой .doc-root.yaml один раз).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/nested-doc-root-demarcation"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-039 — вложенный .doc-root.yaml с title: 4.21 обязан давать ненулевой код возврата (FR-120/FR-121, регресс-якорь: до FR-120 вложенный root не валидируется)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -q "outer-orphan.md" && ! echo "$OUT" | grep -q "статья-сирота"; then
  echo "  FAIL: AC-039 (a) — outer-orphan.md без входящих ссылок во внешнем каталоге обязан быть найден как сирота (иначе orphan-проверка отключена и ассерт (b) тривиален)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -q "inner.md" && echo "$OUT" | grep -q "статья-сирота"; then
  echo "  FAIL: AC-039 (b) — статья вложенного root (inner.md) не должна считаться сиротой внешнего каталога (FR-120 граница ownership, in_scope=False)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

FINDINGS=$(echo "$OUT" | grep -c 'invalid type for field "title"' || true)
assert_eq "$FINDINGS" "1" \
  "AC-039 — дефект вложенного .doc-root.yaml обязан давать ровно одну находку (BR-004: не дубль от ancestor)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-024: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-024: вложенный root валидируется отдельно, его статьи не orphan-ы внешнего, одна находка на дефект"
