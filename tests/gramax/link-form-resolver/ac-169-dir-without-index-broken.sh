#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-169-dir-without-index-broken.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-169 (FR-225 ветка (б))
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.4 (каталог без
# _index.md без флага не резолвится; формулировка дословно: «битая ссылка (broken link)
# на "{raw}" — каталог без _index.md (раздела в дереве нет): {resolved}», уровень error),
# §6.4 (строка 1); ADR-0028 Решение 4, поправка к ADR-0016 Решение 1 (файловые шаги
# is_file()); факты движка FileStructure.ts:528-531, linkCreator.ts:156-162.
# Проверка (фикстура dir-without-index: [x](section), section/ с child.md, без
#   _index.md, без флага): по ссылке — именованный ERROR класса битой ссылки с сырой
#   целью «section»; структурное правило «missing _index.md» остаётся — две находки судят
#   разные объекты (ссылку и каталог, FR-225).
# Red on 6e2db04: шаг 1 резолвера возвращает каталог по exists()
#   (validate_structure.py:619-621) — ссылка «резолвится» в директорию, 0 находок по
#   ссылке (замер 2026-11-24: rc=1 лишь от missing _index.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/dir-without-index"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "1" "AC-169: каталог без _index.md без флага — rc=1 (ERROR-класс находки; сегодня rc=1, но только от структурного правила)"

if ! printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF 'битая ссылка (broken link) на "section"'; then
  echo "  FAIL: AC-169 RED — ссылка [x](section) на каталог без _index.md не даёт именованного ERROR класса битой ссылки: шаг 1 резолвера принимает каталог по exists() (ADR-0028 Решение 4, дизайн §3.4)" >&2
  printf '%s\n' "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF "каталог без _index.md (раздела в дереве нет)"; then
  echo "  FAIL: AC-169 — формулировка обязана быть дословной: «каталог без _index.md (раздела в дереве нет)» (дизайн §3.4)" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$OUT" | grep -F "article.md" | grep -qF "битая ссылка (broken link) на \"section/child.md\""; then
  echo "  FAIL: AC-169 — ссылка на существующий child.md не должна ломаться (правится только ветка каталога, не файловые шаги)" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$OUT" | grep -qF "missing _index.md"; then
  echo "  FAIL: AC-169 — структурное правило missing _index.md обязано остаться: две находки судят разные объекты — ссылку и каталог (FR-225, дизайн §3.4 правило 1)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-169: AC-169 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-169: AC-169 — ссылка на каталог без _index.md даёт именованный ERROR битой ссылки, структурное правило каталога не тронуто"
