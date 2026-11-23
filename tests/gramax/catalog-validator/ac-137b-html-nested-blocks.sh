#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-137b-html-nested-blocks.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-137 (FR-216)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-137
# (маска тела html-блока); контракт вложенности — правка регрессии замера 2026-11-23 на
# корпусе сравнения: _mask_html_blocks обязана убирать СОДЕРЖИМОЕ между html-тегами, но
# никогда не убирать и не схлопывать сами теги <html …>/</html> — счёт баланса html точен
# на любой глубине вложенности (регрессия: «unpaired <html>: 1 open, 2 close» на странице
# с обёрткой <html scale> и вложенным <html lang="ru">…</html>).
# Проверка (каталог из двух страниц):
#   (a) вложенная обёртка (nested-ok.md: <html scale="…"> … <html lang="ru"> … </html> …
#       </html>) — находки «unpaired <html>» НЕТ;
#   (b) непарная внешняя обёртка (unbalanced-outer.md: <html> без закрытия, внутри
#       закрытый <html lang="ru">…</html>) — ровно одна находка «unpaired <html>», и это
#       находка страницы unbalanced-outer.md, а не nested-ok.md;
#   (c) тег <strangetag/> внутри внутреннего блока — W034 нет (содержимое замаскировано);
#   (d) нога-контроль: <outsidetag/> вне блоков — W034 остаётся (маска не глушит страницу).
# Red on d6ccab7: нерасширяющееся сопоставление «до ближайшего </html>» схлопывает
#   внутренний <html lang="ru"> в тело внешнего блока — на nested-ok.md ложная находка
#   «unpaired <html>: 1 open, 2 close», а unbalanced-outer.md проходит как парная.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-137b-html-nested"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
if [ "$RC" -eq 0 ]; then
  echo "  FAIL: AC-137 (вложенность) — непарная внешняя обёртка в unbalanced-outer.md обязана давать rc≠0" >&2
  FAIL=$((FAIL + 1))
fi

UNPAIRED_COUNT=$(printf '%s\n' "$OUT" | grep -c "unpaired <html>" || true)

# --- (a): вложенная обёртка — ложной находки нет ---
if printf '%s\n' "$OUT" | grep "unpaired <html>" | grep -qF "nested-ok.md"; then
  echo "  FAIL: AC-137b — «unpaired <html>» на странице с ВЛОЖЕННЫМИ блоками: маска не имеет права убирать/схлопывать сами теги <html …>/</html> (баланс html точен на любой глубине)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): непарная внешняя обёртка — ровно одна находка, и на той странице ---
if [ "$UNPAIRED_COUNT" -ne 1 ]; then
  echo "  FAIL: AC-137b — находок «unpaired <html>» обязана быть ровно одна (вся страница-обёртка без закрытия — один дефект, BR-004); сегодня: $UNPAIRED_COUNT" >&2
  FAIL=$((FAIL + 1))
fi
if [ "$UNPAIRED_COUNT" -eq 1 ] && ! printf '%s\n' "$OUT" | grep "unpaired <html>" | grep -qF "unbalanced-outer.md"; then
  echo "  FAIL: AC-137b — единственная находка «unpaired <html>» обязана указывать на unbalanced-outer.md (обёртка без закрытия)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): содержимое внутреннего блока молчит ---
if printf '%s\n' "$OUT" | grep "W034" | grep -qF '<strangetag>'; then
  echo "  FAIL: AC-137b — W034 на <strangetag/> внутри вложенного html-блока: содержимое между html-тегами обязано маскироваться (FR-216)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): контроль — дефект вне блоков ловится ---
if ! printf '%s\n' "$OUT" | grep "W034" | grep -qF '<outsidetag>'; then
  echo "  FAIL: AC-137b регрессия — <outsidetag/> вне html-блоков обязан давать W034: маска не глушит страницу целиком" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  printf '%s\n' "$OUT" | grep -E "W034|W035|unpaired" >&2
  fail_msg "ac-137b: AC-137b — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-137b: вложенность html-блоков — теги пар видны (баланс точен), содержимое молчит, дефект вне блоков ловится"
