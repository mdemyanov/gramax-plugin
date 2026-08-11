#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-004-orphan-cross-catalog-boundary.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-014 (FR-047, граница)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 2
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Интерпретация границы (см. at-design.md, AC-014 — точная формулировка FR-047
# недоопределяет алгоритм, это явный выбор QA-author, задокументированный здесь и в
# at-design.md для Dev):
#   Валидатор запускается ТОЛЬКО на fixtures/.../catalog-a/. Внутри catalog-a/:
#     - hub.md ссылается на reachable.md (внутренняя ссылка) И на
#       ../catalog-b/external.md (cross-каталожная, нерезолвленная в рамках прогона),
#       cross-каталожная ссылка стоит по тексту РАНЬШЕ внутренней — стресс на порядок
#       обработки ссылок одного файла;
#     - truly-orphan.md не имеет входящих ссылок вовсе.
#   Два ассерта одновременно:
#     (a) truly-orphan.md обязана быть найдена как сирота — доказывает, что
#         orphan-проверка вообще сработала (иначе ассерт (b) был бы тривиально
#         «зелёным» просто по отсутствию проверки, не по уважению границы FR-047);
#     (b) reachable.md НЕ должна фигурировать в выводе вовсе — нерезолвленная
#         cross-каталожная ссылка в hub.md не должна портить учёт внутренней ссылки на
#         reachable.md (устойчивость реализации к недостижимым путям вне root).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/orphan-cross-catalog-boundary/catalog-a"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1)

if ! echo "$OUT" | grep -q "truly-orphan.md"; then
  echo "  FAIL: AC-014 (a) — truly-orphan.md не имеет входящих ссылок нигде в catalog-a/, орфан-проверка обязана её найти (иначе тест 'зелёный' по отсутствию проверки, не по границе FR-047)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -q "reachable.md"; then
  echo "  FAIL: AC-014 (b) — reachable.md ссылается на неё hub.md изнутри catalog-a/, она не должна упоминаться в выводе; нерезолвленная cross-каталожная ссылка в том же hub.md не должна портить учёт этой внутренней ссылки (граница FR-047)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: cross-каталожная ссылка не портит orphan-учёт внутри catalog-a/"
