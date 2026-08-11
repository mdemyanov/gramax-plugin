#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-004-detection-zero-false-positives-scale.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-004
#   (NFR-051).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 3.
#   Самозакрывающийся <mermaid path="…"/> не совпадает ни с одним легаси-паттерном по
#   построению — уже корректные вхождения не задеваются на любом масштабе (образец — 156
#   тегов naumen-smp-mcp).
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_mermaid.py — DEV-003, не
#   начат; RC != 0 из-за отсутствующего скрипта форсирует assert_eq ниже в красный).
#
# Фикстура масштаба генерируется на лету (lib/fixtures.sh::generate_at_scale_fixture) в
# mktemp, не коммитится — 156×2 почти идентичных файлов раздули бы репозиторий без
# содержательного выигрыша; генератор сам по себе — содержательный, ревьюируемый артефакт.
# Подробности и обоснование — README.md, раздел «Фикстура масштаба (AC-004)».

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

generate_at_scale_fixture "$WORKDIR/content" 156

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" 2>&1)
RC=$?

assert_eq "$RC" "0" \
  "AC-004 — прогон обнаружения над 156 корректными тегами обязан завершаться exit=0 (чистый скан, нечего сообщать; интерпретация QA-author — см. README «Интерпретация AC-004»)"

if echo "$OUT" | grep -qE 'page-[0-9]+\.md:[0-9]+'; then
  echo "  FAIL: AC-004 — отчёт ошибочно называет один из 156 корректно смигрированных файлов как легаси-вхождение (NFR-051 нарушена, ложное срабатывание на масштабе)" >&2
  echo "$OUT" | grep -E 'page-[0-9]+\.md:[0-9]+' | head -5 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: 0 ложных срабатываний на 156 корректных тегах"
