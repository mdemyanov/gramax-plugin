#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-008-check-includes-validator.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7
# AC coverage:
#   AC-9 → check.sh --fast включает validate-content.py и зелёный
#   AC-9 → отсутствие uv — провал гейта (FAILED=1), а не WARN с exit 0
#     (найдено ревью task-9: WARN + exit 0 рапортует PASS, не сделав работы —
#     для pre-commit-хука это худший исход, он молча пропускает всё)

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_grep "scripts/check.sh" "validate-content.py" \
  "AC-9: check.sh должен вызывать валидатор content/"
assert_grep "scripts/check.sh" "uv run" \
  "AC-9: валидатор должен запускаться через uv run (PEP 723)"
assert_no_grep "scripts/check.sh" "validate-profile.py" \
  "профильный валидатор не подключается — профилей в gramax нет"

# Ветка "uv not installed" обязана ставить FAILED=1 сразу следующей строкой,
# а не только печатать сообщение. Ассерт по подстроке "FAILED=1" был бы бесполезен —
# оно уже встречается в других (не связанных с uv) секциях check.sh — поэтому
# смотрим именно на строку, идущую сразу за сообщением об отсутствии uv.
UV_BRANCH_NEXT_LINE="$(grep -A1 'uv not installed' scripts/check.sh 2>/dev/null | tail -1)"
if ! printf '%s' "$UV_BRANCH_NEXT_LINE" | grep -q 'FAILED=1'; then
  echo "  FAIL: AC-9: ветка отсутствия uv должна ставить FAILED=1, а не только сообщать" >&2
  FAIL=$((FAIL + 1))
fi

set +e
OUT="$(bash scripts/check.sh --fast 2>&1)"
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-9: check.sh --fast exit=$RC" >&2
  echo "$OUT" | tail -20 >&2
  FAIL=$((FAIL + 1))
fi

# Содержательная проверка вместо grep -q "content": "==> content" печатается
# безусловно при входе в блок 2.5, этот ассерт не мог бы упасть, пока блок вообще
# существует. "OK: content validated" появляется только если uv run
# scripts/validate-content.py реально отработал и прошёл — доказательство работы,
# а не только наличия шага.
if ! printf '%s\n' "$OUT" | grep -q "OK: content validated"; then
  echo "  FAIL: AC-9: в выводе check.sh нет подтверждения, что content/ реально провалидирован" >&2
  FAIL=$((FAIL + 1))
fi

# Поведенческая проверка (честнее ассерта по тексту): гоним check.sh --fast в PATH,
# из которого вычищены все директории, где есть исполняемый uv (их может быть
# несколько — command -v видит только первую). Если чисто вычистить не удалось
# (uv всё ещё виден под новым PATH) — пропускаем поведенческую часть, не выдаём
# её за пройденную, и полагаемся на текстовый ассерт FAILED=1 выше.
UV_PATH="$(command -v uv 2>/dev/null || true)"
if [ -z "$UV_PATH" ]; then
  echo "  SKIP: uv не установлен в этом окружении вовсе — поведенческую проверку без uv пропускаем" >&2
else
  STRIPPED_PATH=""
  OLD_IFS="$IFS"
  IFS=':'
  for d in $PATH; do
    if [ -x "$d/uv" ]; then continue; fi
    if [ -z "$STRIPPED_PATH" ]; then STRIPPED_PATH="$d"; else STRIPPED_PATH="$STRIPPED_PATH:$d"; fi
  done
  IFS="$OLD_IFS"

  if env PATH="$STRIPPED_PATH" command -v uv > /dev/null 2>&1; then
    echo "  SKIP: не удалось чисто убрать uv из PATH (несколько установок) — поведенческую проверку пропускаем" >&2
  else
    set +e
    OUT_NOUV="$(env PATH="$STRIPPED_PATH" bash scripts/check.sh --fast 2>&1)"
    RC_NOUV=$?
    set -e

    if [ "$RC_NOUV" -eq 0 ]; then
      echo "  FAIL: AC-9: check.sh --fast без uv в PATH обязан упасть (exit!=0), а вышел с $RC_NOUV" >&2
      FAIL=$((FAIL + 1))
    fi

    if ! printf '%s\n' "$OUT_NOUV" | grep -q "OK: no whitespace issues"; then
      echo "  FAIL: AC-9: секция whitespace не отработала штатно без uv в PATH (git недоступен?)" >&2
      FAIL=$((FAIL + 1))
    fi

    if ! printf '%s\n' "$OUT_NOUV" | grep -qE "OK: JSON validated|OK: no JSON files tracked"; then
      echo "  FAIL: AC-9: секция json не отработала штатно без uv в PATH (python3 недоступен?)" >&2
      FAIL=$((FAIL + 1))
    fi

    if ! printf '%s\n' "$OUT_NOUV" | grep -qi "uv not installed"; then
      echo "  FAIL: AC-9: без uv в PATH сообщение об отсутствии uv не выведено" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: check.sh --fast включает validate-content.py, требует uv (FAILED=1 при отсутствии) и зелёный"
