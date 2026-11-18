#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-096-composite-check-fast.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-096 (композитный).
# Дизайн: контракт с QA-author — AC-096 единственный e2e-уровень:
#   bash scripts/check.sh --fast, код возврата.
# Warden — AC-096 сформулирован как послепубликационный гейт: обязан быть
#   зелёным ПОСЛЕ публикации изменения. На момент авторской предпроверки
#   (2026-11-18, red on a59db10 для остальных 22 AC) гейт ЗЕЛЁНЫЙ — тот же
#   старт, что у catalog-validator/ac-036; цвет ВНЕШНЕ обусловлен: бриф потока
#   допускает персистентный C1 от незарегистрированного дизайн-документа
#   writer-sync (docs/40-architecture/) до PM-wiring, и находки параллельных
#   потоков могут покрасить гейт независимо от этого suite'а. Красный
#   результат — всегда триаж: запусти `bash scripts/check.sh --fast` вручную
#   и раздели (а) внешние docs/-причины параллельных потоков, (б)
#   незавершённую реализацию Dev (AC-073…AC-095), (в) регрессию от изменения.
# Рекурсии нет: suite в scripts/check.sh не подключён (по брифу изоляции —
#   регистрацию делает Dev/PM), так что --fast этот suite не запускает.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! (cd "$ROOT" && bash scripts/check.sh --fast) >/dev/null 2>&1; then
  # Триаж на момент внешней окраски: параллельные потоки / незавершённая реализация Dev / регрессия.
  echo "  FAIL: AC-096 — композитный гейт 'bash scripts/check.sh --fast' красный; запусти вручную для деталей (триаж: параллельные потоки / незавершённая реализация Dev / регрессия)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-096: AC-096 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-096: AC-096 — композитный гейт check.sh --fast зелёный (PASS)"
