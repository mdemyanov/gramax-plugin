#!/usr/bin/env bash
# tests/gramax/comments/ac-130-xml-block-form.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-130 (FR-211)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-130;
# beads gramax-4jf.4 (форма из commentModifyFormatters.ts: openTag("comment", {id}, true)).
# Проверка: фикстура с XML-блочной формой (самозакрытый открывающий <comment id="ID"/>,
#   пустая строка, текст, пустая строка, закрывающий </comment>) + парный yaml →
#   (a) parse_comments выводит якорь (status ok, текст якоря в отчёте);
#   (b) validate_comments rc=0 без «md missing tag for yaml id»;
#   (c) скобочная legacy-форма по-прежнему читается (контроль, зелёная нога);
#   (d) навыки comments-write/comments-read показывают XML-форму и называют её каноном.
# Red on 7553da1: INLINE_RE/BLOCK_RE (validate_comments.py:16-17, parse_comments.py:17-18)
#   требуют «>» сразу после id — самозакрытая форма не матчится (замер 2026-11-23:
#   parse_comments даёт anchor_not_found, validate_comments — «md missing tag for yaml id»,
#   rc=1); навыки знают только скобочную форму (gramax-4jf.4).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-130-xml-block"
ANCHOR_TEXT="Текст якоря блочного комментария в XML-форме"

# --- (a): parse_comments распознаёт XML-форму ---
if OUT_PARSE=$(cd "$ROOT" && uv run plugins/gramax/scripts/parse_comments.py "$FIXTURE/page.md" 2>&1); then
  RC_PARSE=0
else
  RC_PARSE=$?
fi
assert_exit_zero "$RC_PARSE" "AC-130: parse_comments на XML-форме — rc=0"

if printf '%s\n' "$OUT_PARSE" | grep -qF 'anchor_not_found'; then
  echo "  FAIL: AC-130 — якорь XML-блочной формы не найден (status anchor_not_found): самозакрытый открывающий тег <comment id=\"ID\"/> не матчится (FR-211)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_PARSE" | grep -qF "$ANCHOR_TEXT"; then
  echo "  FAIL: AC-130 — отчёт parse_comments обязан выводить текст якоря XML-блочной формы" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): validate_comments видит парность md↔yaml для XML-формы ---
if OUT_VAL=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/page.md" 2>&1); then
  RC_VAL=0
else
  RC_VAL=$?
fi
assert_eq "$RC_VAL" "0" "AC-130: validate_comments на XML-форме — rc=0 (парность видна)"

if printf '%s\n' "$OUT_VAL" | grep -qF 'md missing tag for yaml id'; then
  echo "  FAIL: AC-130 — «md missing tag for yaml id» на XML-форме: тег формы <comment id=\"ID\"/> … </comment> обязан распознаваться (FR-211)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): контроль — скобочная legacy-форма читается по-прежнему ---
if OUT_LEGACY=$(cd "$ROOT" && uv run plugins/gramax/scripts/parse_comments.py "$FIXTURE/page-legacy.md" 2>&1); then
  RC_LEGACY=0
else
  RC_LEGACY=$?
fi
assert_exit_zero "$RC_LEGACY" "AC-130 контроль: parse_comments на скобочной legacy-форме — rc=0"

if printf '%s\n' "$OUT_LEGACY" | grep -qF 'anchor_not_found'; then
  echo "  FAIL: AC-130 контроль — скобочная legacy-форма перестала читаться (8 открывающих в корпусе сравнения обязаны остаться читаемыми)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): навыки называют XML-форму каноном для syntax: XML ---
WRITE_SKILL="$ROOT/plugins/gramax/skills/comments-write/SKILL.md"
READ_SKILL="$ROOT/plugins/gramax/skills/comments-read/SKILL.md"
assert_grep_regex "$WRITE_SKILL" '<comment id=[^>]*/>' "AC-130 — comments-write показывает самозакрытую XML-форму <comment id=\"ID\"/> (красный на 7553da1 — знает только скобочную)"
assert_grep_regex "$READ_SKILL" '<comment id=[^>]*/>' "AC-130 — comments-read показывает самозакрытую XML-форму <comment id=\"ID\"/> (красный на 7553da1)"
assert_grep "$WRITE_SKILL" "канон" "AC-130 — comments-write называет XML-форму каноном для syntax: XML (красный на 7553da1)"
assert_grep "$READ_SKILL" "канон" "AC-130 — comments-read называет XML-форму каноном для syntax: XML (красный на 7553da1)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-130: AC-130 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-130: AC-130 — XML-блочная форма распознана parse/validate, legacy читается, навыки называют XML-форму каноном"
