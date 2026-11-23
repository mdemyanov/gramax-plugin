#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-137-html-block-mask.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-137 (FR-216)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-137
# (маска тела html-блока — функция рядом с lib/md_code_mask.py, применяется ПОСЛЕ _mask_code;
# check_tags продолжает балансировать внешнюю пару html); beads gramax-4jf.9.
# Проверка:
#   (a) теги внутри <html>…</html> (title/div/br, W035 на icon) → W034/W035 нет
#       (замер 2026-11-23: W034 на каждый тег блока);
#   (b) genuinely неизвестный тег вне блока → W034 остаётся (зелёная нога);
#   (c) <html> в inline-коде и fenced-блоке маску НЕ переключает: дефекты после упоминания
#       по-прежнему ловятся (зелёная нога — сегодня их ловит _mask_code, обязана и после);
#   (d) внешняя пара html по-прежнему балансируется check_tags: непарный <html> даёт
#       «unpaired <html>» (зелёная нога).
# Red on 7553da1: маски html-блока нет (замер 2026-11-23: четыре W034/W035 внутри блока).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-137-html"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
if [ "$RC" -eq 0 ]; then
  echo "  FAIL: AC-137 — настоящие дефекты вне блока и непарный внешний <html> обязаны давать rc≠0" >&2
  FAIL=$((FAIL + 1))
fi

# --- (a): содержимое html-блока молчит ---
for tag in title div br; do
  if printf '%s\n' "$OUT" | grep "W034" | grep -qF "<$tag>"; then
    echo "  FAIL: AC-137 — W034 на <$tag> внутри html-блока: содержимое <html>…</html> обязано маскироваться (FR-216)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if printf '%s\n' "$OUT" | grep "W035" | grep -qF "html-block.md"; then
  echo "  FAIL: AC-137 — W035 на иконке внутри html-блока: тело блока вне проверок W035 (gramax-4jf.9)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): неизвестный тег вне блока — W034 остаётся ---
if ! printf '%s\n' "$OUT" | grep "W034" | grep -qF '<mytag>'; then
  echo "  FAIL: AC-137 регрессия — genuinely неизвестный тег <mytag> вне блока обязан давать W034: маска не глушит страницу целиком" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): упоминание <html> в коде маску не переключает ---
if ! printf '%s\n' "$OUT" | grep "W034" | grep -qF '<fancy-tag>'; then
  echo "  FAIL: AC-137 — <html> в inline-коде не должен переключать маску: <fancy-tag/> после упоминания обязан ловиться" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep "W034" | grep -qF '<othertag>'; then
  echo "  FAIL: AC-137 — <html> в fenced-блоке не должен переключать маску: <othertag/> после блока обязан ловиться" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): внешняя пара html балансируется как прежде ---
if ! printf '%s\n' "$OUT" | grep -qF 'unpaired <html>'; then
  echo "  FAIL: AC-137 регрессия — непарный внешний <html> обязан давать «unpaired <html>»: маска тела не отменяет баланс внешней пары (дизайн §6)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  printf '%s\n' "$OUT" | grep -E "W034|W035|unpaired" >&2
  fail_msg "ac-137: AC-137 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-137: AC-137 — html-блок замаскирован, код маску не переключает, внешняя пара балансируется"
