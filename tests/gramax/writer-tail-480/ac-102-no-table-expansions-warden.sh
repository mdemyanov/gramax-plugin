#!/usr/bin/env bash
# tests/gramax/writer-tail-480/ac-102-no-table-expansions-warden.sh
# Требование: docs/30-requirements/2026-11-18-writer-tail-480-requirement.md — AC-102 (BR-020).
# Дизайн: docs/40-architecture/2026-11-18-writer-tail-480-design.md — BR-020/AC-102:
#   литеральные ключи развёрток таблиц запрещены в дереве writer байтово; пункт
#   входит в справочник только тем же изменением, что и engine-вердикт (поток П2,
#   первое GES-окно) — тогда этот warden правится тем же изменением.
# Природа: ЗЕЛЁНЫЙ WARDEN (негативное ожидание — то, чего НЕ должно быть до
#   вердикта). Зелёный на 894f3fd (2026-11-18): aggregation/colspan/rowspan/
#   countDistinct и формы header="column|both|none" в дереве writer — ноль
#   совпадений, ВКЛЮЧАЯ код-спаны и код-блоки (байтовый негатив).
# Уровень: integration (рекурсивный grep по plugins/gramax/skills/writer/).
# Границы набора ключей (README, ловушка 6): В набор НЕ входят 'sort', 'align',
#   'width', '{width', 'row', 'column' — они легитимно встречаются или столкнутся
#   с другим контентом ({width — аннотации картинок SKILL.md:266 и под.;
#   header="row" — единственная документированная форма, SKILL.md:357 и под.);
#   точные негативы — только однозначные литералы развёрток. Формула AC
#   (aggregation, colspan) — подмножество этого набора.
# Edge case дизайна (прецедент AC-079): грепы не знают markdown — литеральные
#   ключи запрещены в том числе внутри код-блоков и примеров; проза FR-184 об
#   отложенных развёртках — без воспроизведения форм («развёртки таблиц»).
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

# Фиксированная строка (не regex) рекурсивно — байтовый негатив, прецедент
# assert_no_grep_fixed_recursive из lib/assert.sh волны writer-sync-470 (AC-079).
assert_no_grep_fixed_recursive() {
  local dir="$1" pattern="$2" msg="$3"
  local matches
  matches=$(grep -rnF "$pattern" "$dir" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$matches" -gt 0 ]; then
    fail "$msg — найдено $matches вхождений: '$pattern' (первые 5:)"
    grep -rnF "$pattern" "$dir" 2>/dev/null | head -5 >&2
  fi
}

WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

WARDEN_MSG="AC-102 — литерал развёрток таблиц не должен появляться в дереве writer до engine-вердикта (BR-020: включение — только тем же изменением, что и вердикт П2; проза об отложенных развёртках — без литеральной формы; байтовый негатив, включая код-блоки)"

# Формула AC-102 требования.
assert_no_grep_fixed_recursive "$WRITER_DIR" 'aggregation' "$WARDEN_MSG"
assert_no_grep_fixed_recursive "$WRITER_DIR" 'colspan' "$WARDEN_MSG"

# Факт 10 требования: остальные однозначные литералы класса развёрток.
assert_no_grep_fixed_recursive "$WRITER_DIR" 'rowspan' "$WARDEN_MSG"
assert_no_grep_fixed_recursive "$WRITER_DIR" 'countDistinct' "$WARDEN_MSG"

# Enum header: документирована только форма header="row" (легитимна); остальные
# три значения — развёртки, ждут вердикта.
assert_no_grep_fixed_recursive "$WRITER_DIR" 'header="column"' "$WARDEN_MSG"
assert_no_grep_fixed_recursive "$WRITER_DIR" 'header="both"' "$WARDEN_MSG"
assert_no_grep_fixed_recursive "$WRITER_DIR" 'header="none"' "$WARDEN_MSG"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-102: AC-102 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-102: AC-102 — warden: литеральные ключи развёрток таблиц в дереве writer отсутствуют (BR-020, до вердикта П2)"
