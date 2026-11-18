#!/usr/bin/env bash
# tests/gramax/writer-tail-480/ac-099-html-restrictions.sh
# Требование: docs/30-requirements/2026-11-18-writer-tail-480-requirement.md — AC-099 (FR-185).
# Дизайн: docs/40-architecture/2026-11-18-writer-tail-480-design.md — FR-185, раздел
#   «HTML» blocks.md расширяется на месте списком условий компонента: изолированный
#   фрейм; только встроенные <script>/<style>; картинки только data:-URI; тёмная
#   тема через селектор html[data-theme="dark"].
# Природа: КРАСНАЯ на момент создания. Красный на 894f3fd (2026-11-18): маркеры
#   формул AC ('data-theme', 'data:') и design-derived («изолиров») в blocks.md —
#   ноль совпадений.
# Уровень: integration (grep по references/blocks.md; контракт с QA-author дизайна).
# Edge case дизайна: 'data:' — подстрока; Dev обязан употребить data:-форму
#   минимум однажды; ревью-пункт — 'data-theme' должен стоять именно в селекторе
#   тёмной темы, не в прозе о данных (грепом не дёшево — README, ловушка 3).
# Helper'ы инлайн (копия lib/assert.sh волны writer-sync-470): suite без lib/ и
#   без run.sh по брифу потока — семь скриптов + README, ничего больше.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

FAIL=0

fail() {
  printf '  FAIL: %s\n' "$1" >&2
  FAIL=$((FAIL + 1))
}

pass_msg() { printf '%b[PASS]%b %s\n' '\033[0;32m' '\033[0m' "$1"; }
fail_msg() { printf '%b[FAIL]%b %s\n' '\033[0;31m' '\033[0m' "$1"; }

assert_grep() {
  local file="$1" pattern="$2" msg="$3"
  if ! grep -qF "$pattern" "$file" 2>/dev/null; then
    fail "$msg — не найдено: '$pattern' в $file"
  fi
}

BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"

# Формула AC-099 требования.
assert_grep "$BLOCKS_MD" 'data-theme' \
  "AC-099 — blocks.md должен документировать селектор тёмной темы HTML-компонента (FR-185: html[data-theme=\"dark\"]; красный на 894f3fd — маркера нет)"
assert_grep "$BLOCKS_MD" 'data:' \
  "AC-099 — blocks.md должен документировать ограничение картинок data:-URI (FR-185: внешние и файловые пути не резолвятся; красный на 894f3fd — формы 'data:' нет; Dev обязан употребить data:-форму минимум однажды)"

# Design-derived: изолированный фрейм — первое условие компонента.
assert_grep "$BLOCKS_MD" 'изолиров' \
  "AC-099 — blocks.md должен указывать рендер HTML-компонента в изолированном фрейме (FR-185: стили и скрипты компонента не действуют на страницу статьи; красный на 894f3fd — стеммы «изолиров» нет)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-099: AC-099 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-099: AC-099 — ограничения HTML-компонента задокументированы (изолированный фрейм, data:-URI, тёмная тема)"
