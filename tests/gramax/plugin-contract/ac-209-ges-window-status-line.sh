#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-209-ges-window-status-line.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-209 (FR-257, карточка gramax-o0q.4, D12; ADR-0030 — GES-окно
#   закрывается документарно).
# Проверка (контракт):
#   (1) строка статуса plantuml в plugins/gramax/README.md называет дату 2026-11-24, говорит,
#       что runtime-проверка в живом окружении не выполнялась, называет решение D12 и
#       именованную точку вердиктов docs/60-implementation/acceptance/2026-11-24-ges-window-verdicts.md;
#   (2) сама запись вердиктов несёт решение D12 и семь строк чек-листа: шесть «не проверено»
#       и одна «вне этого репозитория» (репоинт каталога в менеджере workspace).
#   Запись вердиктов — датированная, судится тем же стабом (бриф волны); строка README —
#   предмет сюиты plugin-contract (владелец README-контрактов, cf. ac-004, ac-140).
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД.
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   упоминания D12/записи из /tmp-копии README; перевертывание одного вердикта в /tmp-копии
#   записи → счёт 5 вместо 6. Счёт «6+1» — счёт, не номер строки.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
README="$ROOT/plugins/gramax/README.md"
VERDICTS="$ROOT/docs/60-implementation/acceptance/2026-11-24-ges-window-verdicts.md"

assert_file_exists "$README" "AC-209: plugins/gramax/README.md на месте"
assert_file_exists "$VERDICTS" "AC-209: именованная точка вердиктов GES-окна на месте"

# --- Нога 1: строка статуса plantuml в README ---
assert_grep "$README" 'окно живых проверок закрыто документарно 2026-11-24 решением владельца D12' \
  "AC-209: строка статуса plantuml называет дату 2026-11-24 и решение D12"
assert_grep "$README" 'не выполнялась' \
  "AC-209: строка статуса говорит, что runtime-проверка в живом окружении не выполнялась"
assert_grep "$README" 'docs/60-implementation/acceptance/2026-11-24-ges-window-verdicts.md' \
  "AC-209: строка статуса называет именованную точку вердиктов"

# --- Нога 2: запись вердиктов — D12 и семь строк (6 «не проверено» + 1 «вне этого репозитория») ---
assert_grep "$VERDICTS" '**Решение:** D12' \
  "AC-209: запись вердиктов называет решение D12 дерева волны-4"

NOT_CHECKED="$(grep -cF '| не проверено |' "$VERDICTS" || true)"
OUT_OF_REPO="$(grep -cF '| вне этого репозитория |' "$VERDICTS" || true)"
assert_eq "${NOT_CHECKED:-0}" "6" \
  "AC-209: вердиктов «не проверено» с причинами — 6 (пункты 1–5 и 7 чек-листа)"
assert_eq "${OUT_OF_REPO:-0}" "1" \
  "AC-209: вердикт «вне этого репозитория» — 1 (репоинт каталога в менеджере workspace, пункт 6)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-209: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-209: строка статуса plantuml в README отсылает к D12 и записи вердиктов; запись несёт 6 «не проверено» + 1 «вне этого репозитория»"
