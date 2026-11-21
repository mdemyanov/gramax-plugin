#!/usr/bin/env bash
# tests/gramax/render-quality/ac-106-refusal-target-unset.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-106 (FR-189)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 2
#   (RENDER_TARGET_UNSET, rc=2) и «Контракт с QA-author», строка ac-106.
# Проверка (контракт): конфиг без цели (--config на отсутствующий файл, env-поля цели сняты)
# -> rc!=0, вывод содержит именованный код RENDER_TARGET_UNSET и подсказку прогрева
# (bash scripts/render-quality/warm.sh); «зелёного» завершения нет — тихий skip запрещён.
# Проверка цели идёт до обращения к playwright — прогретое окружение не требуется.
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-106.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-106: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-106 (дизайн, Решения 2/5); сюита красная до реализации Dev"
  exit 1
fi

OUT="$(env -u GRAMAX_RENDER_BASE_URL -u GRAMAX_RENDER_CATALOG \
  bash "$PROBE" --check-env --config "$TMP/absent-config.json" 2>&1)"
RC=$?

if [ "$RC" -eq 0 ]; then
  echo "  FAIL: AC-106 — «зелёное» завершение без цели запрещено (тихий skip, FR-189)" >&2
  printf '%s\n' "$OUT" | head -10 >&2
  FAIL=$((FAIL + 1))
else
  assert_eq "$RC" "2" "AC-106: именованный отказ окружения несёт rc=2 (дизайн, Решение 2)"
fi
if ! printf '%s\n' "$OUT" | grep -qF "RENDER_TARGET_UNSET"; then
  echo "  FAIL: AC-106 — вывод обязан содержать именованный код RENDER_TARGET_UNSET" >&2
  echo "  --- вывод ---" >&2
  printf '%s\n' "$OUT" | head -20 >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF "warm.sh"; then
  echo "  FAIL: AC-106 — подсказка обязана звать рычаг прогрева bash scripts/render-quality/warm.sh" >&2
  FAIL=$((FAIL + 1))
fi
# Баннер отказа детерминирован и называется по имени: REFUSAL <КОД> (дизайн, Решение 2)
if ! printf '%s\n' "$OUT" | grep -qF "REFUSAL RENDER_TARGET_UNSET"; then
  echo "  FAIL: AC-106 — баннер отказа обязан иметь форму «REFUSAL RENDER_TARGET_UNSET: …»" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-106: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-106: конфиг без цели -> rc=2, RENDER_TARGET_UNSET + подсказка warm.sh, зелёного завершения нет"
