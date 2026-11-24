#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-203-digest-verdicts.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-203 (FR-252, карточка gramax-o0q.42).
# Проверка (контракт): дайджест кандидатов волны-4 существует по заявленному пути,
#   зарегистрирован в индексе research и несёт заполненную колонку вердиктов PM во всех
#   строках трёх таблиц: grep -c '| P[0-9] — ' даёт 24 (замер роли 2026-11-24, совпал с
#   замером координатора; каждая строка-кандидат групп A/B/C несёт приоритет и маршрут).
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД.
# Мутация к красному (показана в at-design 2026-11-24-wave4-docs-at-design.md): в /tmp-копии
#   дайджеста опустошена одна ячейка вердикта → счёт 23, нога краснеет. Число строк пришито
#   как счёт (24), не как номер строки; дайджест — датированная запись, BR-030 её не
#   переписывает, счёт стабилен.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DIGEST="$ROOT/docs/10-domain/research/2026-11-24-wave4-candidates-digest.md"
INDEX="$ROOT/docs/10-domain/research/_index.md"

assert_file_exists "$DIGEST" "AC-203: дайджест на заявленном пути docs/10-domain/research/"
assert_file_exists "$INDEX" "AC-203: индекс research на месте"

assert_grep "$INDEX" '2026-11-24-wave4-candidates-digest.md' \
  "AC-203: дайджест зарегистрирован в индексе docs/10-domain/research/_index.md"

TABLES="$(grep -c '| Вердикт PM |' "$DIGEST" || true)"
assert_eq "${TABLES:-0}" "3" \
  "AC-203: в дайджесте три таблицы кандидатов с колонкой «Вердикт PM» (группы A/B/C)"

VERDICTS="$(grep -c '| P[0-9] — ' "$DIGEST" || true)"
assert_eq "${VERDICTS:-0}" "24" \
  "AC-203: заполненных ячеек вердиктов PM (| P<цифра> — приоритет и маршрут) — 24, по одной на каждую строку-кандидат"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-203: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-203: дайджест зарегистрирован, 3 таблицы, 24 заполненных вердикта PM"
