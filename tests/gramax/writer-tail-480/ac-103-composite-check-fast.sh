#!/usr/bin/env bash
# tests/gramax/writer-tail-480/ac-103-composite-check-fast.sh
# Требование: docs/30-requirements/2026-11-18-writer-tail-480-requirement.md — AC-103 (композитный).
# Дизайн: контракт с QA-author — AC-103 единственный e2e-уровень suite'а:
#   bash scripts/check.sh --fast, код возврата.
# Warden с внешне обусловленным цветом (тот же старт, что ac-096 волны
#   writer-sync-470 и catalog-validator/ac-036): AC-103 сформулирован как
#   послепубликационный гейт. На авторской предпроверке (2026-11-18, 894f3fd)
#   ЗЕЛЁНЫЙ. Красный результат — ВСЕГДА триаж: запусти `bash scripts/check.sh
#   --fast` вручную и раздели (а) внешние причины параллельных потоков, (б)
#   незавершённую реализацию Dev (AC-097…AC-100), (в) регрессию от изменения.
# Рекурсии нет: suite в scripts/check.sh НЕ подключён (регистрация — стадия dev
#   после позеленения, прецедент writer-sync-470 c255f98), --fast этот suite не
#   запускает и сам от себя не зависит.
# Helper'ы инлайн (копия lib/assert.sh волны writer-sync-470): suite без lib/ и
#   без run.sh по брифу потока — семь скриптов + README, ничего больше.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

FAIL=0

pass_msg() { printf '%b[PASS]%b %s\n' '\033[0;32m' '\033[0m' "$1"; }
fail_msg() { printf '%b[FAIL]%b %s\n' '\033[0;31m' '\033[0m' "$1"; }

if ! (cd "$ROOT" && bash scripts/check.sh --fast) >/dev/null 2>&1; then
  printf '  FAIL: AC-103 — композитный гейт %s красный; запусти вручную для деталей (триаж: параллельные потоки / незавершённая реализация Dev AC-097…AC-100 / регрессия)\n' "'bash scripts/check.sh --fast'" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-103: AC-103 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-103: AC-103 — композитный гейт check.sh --fast зелёный (PASS)"
