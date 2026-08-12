#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-008-marketplace-json-sync-decision.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-008 (FR-103).
# «Ровно одно из двух»: либо (а) diff marketplace.json пуст И ADR явно откладывает
# синхронизацию; либо (б) marketplace.json version == plugin.json version (4.2.1) И ADR явно
# авторизует bump. Молчание (diff не пуст, но ADR ничего не говорит о версии) — провал AC.
#
# ADR-0017, Решение 3 уже выбрал ветку (б) явно («этот ADR — разрешающий документ ... на
# синхронную правку .claude-plugin/marketplace.json»). Позитивный сигнал ветки (б) со стороны
# ADR уже ЗЕЛЁНЫЙ сегодня; версия marketplace.json — ещё нет (Tech-writer не бампнул) — итог
# сегодня: КРАСНЫЙ.
#
# ЛОВУШКА, найденная при написании этого теста (наивный grep на "отложить синхронизацию" даёт
# ложный PASS ветки (а)): ADR-0017 содержит фразу «Отклонено: отложить синхронизацию
# marketplace.json...» — это ОТКАЗ от варианта (а), а не его выбор. Наивный
# `grep -qiE 'отлож.*синхрониз'` совпал бы с этим текстом и ложно засчитал бы ветку (а)
# выполненной. Исправление: awk в режиме "абзац" (RS="") — ищем абзац, содержащий фразу про
# отложенную синхронизацию, который НЕ содержит слова "Отклонено" — то есть реальное,
# не отвергнутое решение отложить, а не пункт списка "что мы не выбрали". Проверено на реальном
# ADR-0017: даёт 0 совпадений (корректно — ветка (а) не выбрана этим ADR).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/baseline-commit.sh"

FAIL=0
MARKET_JSON="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"
ADR="$ROOT/content/00-project/adr/0017-cross-catalog-retraction.md"

assert_file_exists "$MARKET_JSON" "AC-008: marketplace.json должен существовать"
assert_file_exists "$PLUGIN_JSON" "AC-008: plugin.json должен существовать"
assert_file_exists "$ADR" "AC-008: content/00-project/adr/0017-cross-catalog-retraction.md должен существовать"

if [ ! -f "$MARKET_JSON" ] || [ ! -f "$PLUGIN_JSON" ] || [ ! -f "$ADR" ]; then
  : # предыдущие assert_file_exists уже зафиксировали FAIL; дальше проверять нечего
elif ! command -v jq > /dev/null 2>&1; then
  echo "  FAIL: AC-008 — jq не установлен, ветка (б) не может быть проверена" >&2
  FAIL=$((FAIL + 1))
else
  # Ветка (а): diff пуст И ADR явно (не отвергнуто) откладывает синхронизацию.
  BRANCH_A_DIFF_EMPTY=0
  if git -C "$ROOT" diff --quiet "$BASELINE_COMMIT"..HEAD -- .claude-plugin/marketplace.json 2>/dev/null; then
    BRANCH_A_DIFF_EMPTY=1
  fi
  DEFER_MATCH="$(awk -v RS="" '/отлож.{0,20}синхрониз/ && $0 !~ /Отклонено/' "$ADR" 2>/dev/null || true)"
  BRANCH_A_ADR_DEFERS=0
  [ -n "$DEFER_MATCH" ] && BRANCH_A_ADR_DEFERS=1
  BRANCH_A_OK=0
  [ "$BRANCH_A_DIFF_EMPTY" -eq 1 ] && [ "$BRANCH_A_ADR_DEFERS" -eq 1 ] && BRANCH_A_OK=1

  # Ветка (б): marketplace.json version == plugin.json version == "4.2.1" И ADR явно авторизует bump.
  PLUGIN_VERSION="$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null)"
  MARKET_VERSION="$(jq -r '.metadata.version' "$MARKET_JSON" 2>/dev/null)"
  BRANCH_B_VERSION_MATCH=0
  if [ -n "$PLUGIN_VERSION" ] && [ "$PLUGIN_VERSION" != "null" ] \
     && [ "$MARKET_VERSION" = "$PLUGIN_VERSION" ] && [ "$MARKET_VERSION" = "4.2.1" ]; then
    BRANCH_B_VERSION_MATCH=1
  fi
  BRANCH_B_ADR_AUTHORIZES=0
  grep -qiE 'разрешён этим ADR|авторизует.{0,20}bump|разрешающий документ' "$ADR" 2>/dev/null \
    && BRANCH_B_ADR_AUTHORIZES=1
  BRANCH_B_OK=0
  [ "$BRANCH_B_VERSION_MATCH" -eq 1 ] && [ "$BRANCH_B_ADR_AUTHORIZES" -eq 1 ] && BRANCH_B_OK=1

  if [ "$BRANCH_A_OK" -eq 0 ] && [ "$BRANCH_B_OK" -eq 0 ]; then
    echo "  FAIL: AC-008 — ни одна из двух веток FR-103 не выполнена целиком." >&2
    echo "        Ветка(а): diff_empty=$BRANCH_A_DIFF_EMPTY, adr_defers(не-отвергнуто)=$BRANCH_A_ADR_DEFERS" >&2
    echo "        Ветка(б): version_match=$BRANCH_B_VERSION_MATCH (marketplace=$MARKET_VERSION, plugin=$PLUGIN_VERSION), adr_authorizes=$BRANCH_B_ADR_AUTHORIZES" >&2
    echo "        FR-103 требует явного решения — молчание (ни одна ветка) недопустимо." >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-008: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-008: marketplace.json версия синхронизирована по решению ADR-0017 (ветка б)"
