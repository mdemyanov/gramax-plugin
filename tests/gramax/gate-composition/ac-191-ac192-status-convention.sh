#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-191-ac192-status-convention.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-191, AC-192 (FR-243, карточка gramax-o0q.15).
# Проверка (контракт):
#   (а) AC-191 — конвенция статусов записана указателем в ADR-0030 с событиями
#       Draft → Accepted → Done (словарь покрывает конвенцию);
#   (б) AC-191 — словарь «Статус» docs/.doc-root.yaml покрывает статусы конвенции;
#   (в) AC-192 — по docs/30-requirements маркер «[Draft]» не несёт ни одна статья:
#       grep -rlE '\[Draft\]' docs/30-requirements/*.md | wc -l → 0 (было 14, факт 7
#       требования). Стаб печатает файлы, которые ещё видит, — статус соответствует факту.
# Цвет на момент письма (2026-11-24): КРАСНЫЙ ПО ЗАМЫСЛУ — нога (в): статус-проход исполняет
#   PM в релизном коммите волны-4 (D15 — единственный коммиттер), сейчас «[Draft]» несут
#   16 файлов (замер роли 2026-11-24). Ноги (а) и (б) зелёные с рождения.
# Мутации к красному ног (а)/(б) (показаны в at-design 2026-11-24-wave4-docs-at-design.md):
#   изъятие указателя конвенции из ADR-0030 / изъятие статуса из enum словаря.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
ADR30="$ROOT/docs/00-project/adr/0030-plugin-perimeter-deferred-capabilities.md"
DOC_ROOT="$ROOT/docs/.doc-root.yaml"
REQ_DIR="$ROOT/docs/30-requirements"

assert_file_exists "$ADR30" "AC-191: ADR-0030 на месте"
assert_file_exists "$DOC_ROOT" "AC-191: docs/.doc-root.yaml на месте"

# --- Нога (а): указатель конвенции с событиями в ADR-0030 ---
assert_grep "$ADR30" 'Конвенция требований FR-243 (Draft → Accepted → Done)' \
  "AC-191: ADR-0030 несёт указатель конвенции статусов с событиями Draft → Accepted → Done (Решение 5)"

# --- Нога (б): словарь «Статус» покрывает конвенцию ---
assert_grep "$DOC_ROOT" 'values: [Draft, Active, Accepted, Superseded, Historical, Done]' \
  "AC-191: словарь «Статус» .doc-root.yaml покрывает статусы конвенции (Draft/Accepted/Done в enum)"

# --- Нога (в): «[Draft]» в docs/30-requirements — 0 файлов ---
DRAFT_FILES="$(grep -rlE '\[Draft\]' "$REQ_DIR"/*.md || true)"
DRAFT_COUNT="$(printf '%s\n' "$DRAFT_FILES" | grep -c . || true)"
if [ "$DRAFT_COUNT" -eq 0 ]; then
  :
else
  echo "  FAIL: AC-192 — маркер «[Draft]» несут ${DRAFT_COUNT} статей docs/30-requirements:" >&2
  printf '%s\n' "$DRAFT_FILES" >&2
  echo "  (конвенция FR-243: статус по событию — Accepted по записи at-acceptance pass," >&2
  echo "  Done по релизной записи CHANGELOG плагина; перенос статусов исполняет PM в" >&2
  echo "  релизном коммите волны-4, D15; «[Draft]» после него не остаётся)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-191/192: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-191/192: конвенция записана в ADR-0030, словарь покрывает, «[Draft]» в requirements — 0 файлов"
