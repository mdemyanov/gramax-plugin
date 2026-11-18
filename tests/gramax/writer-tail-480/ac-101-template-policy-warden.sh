#!/usr/bin/env bash
# tests/gramax/writer-tail-480/ac-101-template-policy-warden.sh
# Требование: docs/30-requirements/2026-11-18-writer-tail-480-requirement.md — AC-101 (BR-019).
# Дизайн: docs/40-architecture/2026-11-18-writer-tail-480-design.md — BR-019/BR-020,
#   «кодирование без правок текста»: политика файлов шаблонов уже действует в
#   Guardrails SKILL.md (сейчас — строки 409/412: «правится только как отдельная
#   явно запрошенная операция»); текстовой правки срез не требует, BR-019
#   кодифицируется regression-guard'ом.
# Природа: ЗЕЛЁНЫЙ WARDEN (регрессия уже действующей политики — инвариант до и
#   после dev). Зелёный на 894f3fd (2026-11-18): '.gramax/templates' — три
#   вхождения в SKILL.md (142, 409, 412), «явно запрошен» — одно (412).
#   Слабое место (дизайн, edge case AC-101): дословная формулировка «явно
#   запрошен» может деградировать при будущем редактировании Guardrails —
#   ассерт защищает фразу.
# Уровень: integration (grep по SKILL.md; контракт с QA-author дизайна).
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

SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

# Формула AC-101 требования.
assert_grep "$SKILL_MD" '.gramax/templates' \
  "AC-101 — SKILL.md обязан сохранять указатель на хранение тела статьи в .gramax/templates (BR-019: правка файла шаблона меняет все статьи-потребители разом; warden — формулировка не должна деградировать при правках Guardrails)"
assert_grep "$SKILL_MD" 'явно запрошен' \
  "AC-101 — SKILL.md обязан сохранять дословную политику: правка файла шаблона — только как отдельная «явно запрошен[ная]» операция (BR-019; warden дословной фразы — слабое место по edge case AC-101 дизайна)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-101: AC-101 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-101: AC-101 — warden: политика шаблонов BR-019 действует в Guardrails SKILL.md (.gramax/templates + «явно запрошен»)"
