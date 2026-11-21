#!/usr/bin/env bash
# tests/gramax/render-quality/ac-107-refusal-no-browser.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-107 (FR-189)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 2
#   (PLAYWRIGHT_NO_BROWSER, rc=2; env-шов PLAYWRIGHT_BROWSERS_PATH) и «Контракт с
#   QA-author», строка ac-107.
# Проверка (контракт): валидный конфиг-шов (цель .invalid — валидна по схеме), но
# PLAYWRIGHT_BROWSERS_PATH указывает на пустой каталог -> запуск chromium штатно промахивается
# -> rc!=0, вывод содержит PLAYWRIGHT_NO_BROWSER и подсказку прогрева (warm.sh); гейт красный,
# «зелёный гейт без прогона» исключён.
# Цвет при создании: КРАСНЫЙ — вход scripts/render-quality/probe.sh отсутствует; закрывает Dev.
# Замечание D8 (README): на машине без прогрева uv-кэша отказ может быть иного класса
# (uv-промах, PLAYWRIGHT_UNAVAILABLE) — это D8-поведение окружения, не дефект сюиты.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-107.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-107: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт AC-107 (дизайн, Решения 2/5); сюита красная до реализации Dev"
  exit 1
fi

# Валидный конфиг-шов: цель валидна по схеме (проверка цели проходит до playwright)
cat > "$TMP/config.json" <<'JSON'
{
  "baseUrl": "https://render-target.example.invalid",
  "catalog": "render-probes",
  "pageUrlTemplate": "{base}/page/{slug}",
  "tiers": ["tier0", "tier1"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON
mkdir -p "$TMP/empty-browsers"

OUT="$(env PLAYWRIGHT_BROWSERS_PATH="$TMP/empty-browsers" \
  bash "$PROBE" --check-env --config "$TMP/config.json" 2>&1)"
RC=$?

if [ "$RC" -eq 0 ]; then
  echo "  FAIL: AC-107 — «зелёное» завершение без браузера запрещено (FR-189)" >&2
  printf '%s\n' "$OUT" | head -10 >&2
  FAIL=$((FAIL + 1))
else
  assert_eq "$RC" "2" "AC-107: именованный отказ окружения несёт rc=2 (дизайн, Решение 2)"
fi
if ! printf '%s\n' "$OUT" | grep -qF "PLAYWRIGHT_NO_BROWSER"; then
  echo "  FAIL: AC-107 — вывод обязан содержать именованный код PLAYWRIGHT_NO_BROWSER" >&2
  echo "  --- вывод ---" >&2
  printf '%s\n' "$OUT" | head -20 >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF "warm.sh"; then
  echo "  FAIL: AC-107 — подсказка обязана звать рычаг прогрева bash scripts/render-quality/warm.sh" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF "REFUSAL PLAYWRIGHT_NO_BROWSER"; then
  echo "  FAIL: AC-107 — баннер отказа обязан иметь форму «REFUSAL PLAYWRIGHT_NO_BROWSER: …»" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-107: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-107: пустой PLAYWRIGHT_BROWSERS_PATH -> rc=2, PLAYWRIGHT_NO_BROWSER + подсказка warm.sh"
