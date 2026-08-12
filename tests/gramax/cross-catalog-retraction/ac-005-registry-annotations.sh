#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-005-registry-annotations.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-005 (FR-099).
#
# Природа: смешанная.
#   (a) content/40-architecture/_index.md — строка диспозиции — КРАСНАЯ сегодня: буллет ещё не
#       несёт отметку вида «(Тема A дополнена ADR-0017)» — задача Dev (ADR-0017, «Бриф для
#       Dev», шаг 3).
#   (b) content/00-project/adr/_index.md — строка ADR-0017 — ЗЕЛЁНАЯ сегодня (regression
#       guard): PM уже внёс строку реестра, чьё название решения само несёт формулировку
#       «амендмент к диспозиции Тема A/FR-065» — это и есть отметка частичного амендмента для
#       (б)-половины AC-005. Dev не трогает этот файл (ADR-0017, «Примечание для PM»: «строку в
#       content/00-project/adr/_index.md не добавляет и SA этого ADR»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
ARCH_INDEX="$ROOT/content/40-architecture/_index.md"
ADR_INDEX="$ROOT/content/00-project/adr/_index.md"
DISPOSITION_FILENAME="2026-08-11-writer-rules-disposition.md"
ADR_FILENAME="0017-cross-catalog-retraction.md"

assert_file_exists "$ARCH_INDEX" "AC-005(a): content/40-architecture/_index.md должен существовать"
assert_file_exists "$ADR_INDEX" "AC-005(b): content/00-project/adr/_index.md должен существовать"

# (a) — строка диспозиции в content/40-architecture/_index.md
if [ -f "$ARCH_INDEX" ]; then
  DISPOSITION_LINE="$(grep -F "$DISPOSITION_FILENAME" "$ARCH_INDEX" 2>/dev/null | head -1 || true)"
  if [ -z "$DISPOSITION_LINE" ]; then
    echo "  FAIL: AC-005(a) — content/40-architecture/_index.md не содержит строку про $DISPOSITION_FILENAME вовсе" >&2
    FAIL=$((FAIL + 1))
  else
    if ! printf '%s' "$DISPOSITION_LINE" | grep -qiE '0017'; then
      echo "  FAIL: AC-005(a) — строка диспозиции не упоминает ADR-0017 (FR-099а): $DISPOSITION_LINE" >&2
      FAIL=$((FAIL + 1))
    elif ! printf '%s' "$DISPOSITION_LINE" | grep -qiE 'дополнен|амендмент'; then
      echo "  FAIL: AC-005(a) — строка диспозиции упоминает 0017, но не несёт слова 'дополнен*'/'амендмент*' (FR-099а): $DISPOSITION_LINE" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

# (b) — строка ADR-0017 в content/00-project/adr/_index.md
if [ -f "$ADR_INDEX" ]; then
  ADR_LINE="$(grep -F "$ADR_FILENAME" "$ADR_INDEX" 2>/dev/null | head -1 || true)"
  if [ -z "$ADR_LINE" ]; then
    echo "  FAIL: AC-005(b) — content/00-project/adr/_index.md не содержит строку реестра для $ADR_FILENAME (FR-099б)" >&2
    FAIL=$((FAIL + 1))
  else
    if ! printf '%s' "$ADR_LINE" | grep -qiE 'Тема A|FR-065'; then
      echo "  FAIL: AC-005(b) — строка ADR-0017 в реестре не ссылается на 'Тема A'/'FR-065' диспозиции (FR-099б): $ADR_LINE" >&2
      FAIL=$((FAIL + 1))
    elif ! printf '%s' "$ADR_LINE" | grep -qiE 'амендмент|дополнен'; then
      echo "  FAIL: AC-005(b) — строка ADR-0017 не несёт слова 'амендмент*'/'дополнен*' (FR-099б): $ADR_LINE" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: реестровые аннотации согласованы (a — задача Dev; b — уже внесено PM, regression guard)"
