#!/usr/bin/env bash
# tests/gramax/render-quality/ac-142-named-refusals.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-142 (FR-219, D5)
# Решение: docs/00-project/adr/0027-full-gate-composition.md, Решение 2 — именованный отказ
#   с рычагом: два новых кода класса rc=2.
# Проверка (контракт): scripts/render-quality/live.sh существует и обёртывает probe.sh;
#   недоступная цель -> rc=2 и баннер «REFUSAL RENDER_TARGET_UNREACHABLE:», подсказка
#   называет bash scripts/render-quality/live.sh; uv с сигнатурой «Failed to fetch» -> rc=2
#   и баннер «REFUSAL PLAYWRIGHT_PIN_UNRESOLVED:», подсказка называет UV_OFFLINE=1 и
#   bash scripts/render-quality/warm.sh; runbook и README сюиты называют live.sh и
#   UV_OFFLINE=1. Сеть не нужна ни одной ноге: недостижимая цель — 127.0.0.1:1 (порт 1,
#   соединение отклоняется мгновенно), uv подменяется фейковым исполняемым первым на PATH
#   (выход 7, stderr «Failed to fetch»); UV_OFFLINE=1 экспортируется у реальных вызовов uv —
#   pypi.org с этой машины недостижим, пин решается только тёплым кэшем.
# Цвет на 7553da1: КРАСНЫЙ — scripts/render-quality/live.sh не существует; кодов
#   RENDER_TARGET_UNREACHABLE и PLAYWRIGHT_PIN_UNRESOLVED в приборе нет (сегодня полная
#   недоступность цели даёт rc=1 постранично — «не измерено» подаётся как «измерено и
#   разошлось», а сетевой отказ uv проходит сырой ошибкой); runbook и README не называют
#   ни live.sh, ни UV_OFFLINE=1.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
LIVE="$ROOT/scripts/render-quality/live.sh"
RUNBOOK="$ROOT/docs/70-operations/2026-11-21-render-quality-runbook.md"
README="$ROOT/tests/gramax/render-quality/README.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-142.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Конфиг недостижимой цели: baseUrl на порт 1 локалхоста — без сети и без DNS.
cat > "$TMP/unreachable.json" <<'JSON'
{
  "baseUrl": "http://127.0.0.1:1",
  "catalog": "probes",
  "tiers": ["tier0"]
}
JSON

# Мини-набор фикстур: один контроль .md + ожидание (пара обязательна).
printf '%s\n' '# Контроль' '' 'Абзац после конструкции.' > "$TMP/control.md"
cat > "$TMP/control.expect.json" <<'JSON'
{
  "tableRow": "control",
  "expect": { "tier0": "ok", "tier1": "any", "asserts": [] }
}
JSON

# Фейковый uv: сетевой отказ с сигнатурой ADR-0027, отличимый код выхода.
mkdir -p "$TMP/fake-uv"
cat > "$TMP/fake-uv/uv" <<'SH'
#!/usr/bin/env sh
echo "error: Failed to fetch" >&2
exit 7
SH
chmod +x "$TMP/fake-uv/uv"

# --- Нога 1: live.sh существует и обёртывает probe.sh ---
assert_file_exists "$LIVE" \
  "AC-142: scripts/render-quality/live.sh существует (именованный шаг замера, ADR-0027 Решение 1)"
if [ -f "$LIVE" ]; then
  assert_grep "$LIVE" 'probe.sh' \
    "AC-142: live.sh обёртывает probe.sh (дефолтные пути конфига цели и фикстур)"
fi

# --- Ноги 2-3: поведенческие — только при живом входе; отсутствие входа — именованный
# отказ стаба (дом-паттерн ac-106), не падение.
if [ ! -f "$LIVE" ]; then
  fail_msg "ac-142: отсутствует вход scripts/render-quality/live.sh — поведенческие ноги не исполнимы; сюита красная до реализации Dev (ADR-0027 Решения 1-2)"
  exit 1
fi

# --- Нога 2: недостижимая цель -> rc=2, REFUSAL RENDER_TARGET_UNREACHABLE с именем шага ---
OUT="$(cd "$ROOT" && UV_OFFLINE=1 bash "$LIVE" \
  --config "$TMP/unreachable.json" --fixtures "$TMP" --report "$TMP/report.md" 2>&1)"
RC=$?
if [ "$RC" -ne 2 ]; then
  echo "  FAIL: AC-142 — недостижимая цель обязана давать именованный отказ rc=2, получен rc=${RC}" >&2
  echo "  (сегодня «не измерено» подаётся как «измерено и разошлось»: rc=1 постранично;" >&2
  echo "  ADR-0027 Решение 2: полная недоступность цели отказывает до тиров 1-2)" >&2
  printf '%s\n' "$OUT" | head -8 >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF 'REFUSAL RENDER_TARGET_UNREACHABLE:'; then
  echo "  FAIL: AC-142 — вывод не содержит баннер «REFUSAL RENDER_TARGET_UNREACHABLE:»" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF 'bash scripts/render-quality/live.sh'; then
  echo "  FAIL: AC-142 — подсказка отказа не называет рычаг bash scripts/render-quality/live.sh" >&2
  echo "  (проверь сеть, VPN и baseUrl цели, затем повтори именованный шаг)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 3: uv с сигнатурой «Failed to fetch» -> rc=2, REFUSAL PLAYWRIGHT_PIN_UNRESOLVED,
# подсказка называет UV_OFFLINE=1 и warm.sh. Фейковый uv — первым на PATH в подоболочке.
OUT="$(cd "$ROOT" && env PATH="$TMP/fake-uv:$PATH" UV_OFFLINE=1 \
  bash "$LIVE" --check-env --config "$TMP/unreachable.json" 2>&1)"
RC=$?
if [ "$RC" -ne 2 ]; then
  echo "  FAIL: AC-142 — сетевой отказ uv с сигнатурой «Failed to fetch» обязан давать" >&2
  echo "  именованный отказ rc=2, получен rc=${RC} (сегодня отказ uv проходит сырой ошибкой," >&2
  echo "  обёртка probe.sh ловит только сигнатуру промаха кэша; ADR-0027 Решение 2)" >&2
  printf '%s\n' "$OUT" | head -8 >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF 'REFUSAL PLAYWRIGHT_PIN_UNRESOLVED:'; then
  echo "  FAIL: AC-142 — вывод не содержит баннер «REFUSAL PLAYWRIGHT_PIN_UNRESOLVED:»" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF 'UV_OFFLINE=1'; then
  echo "  FAIL: AC-142 — подсказка отказа не называет рычаг офлайна UV_OFFLINE=1" >&2
  echo "  (при тёплом кэше повтори с UV_OFFLINE=1, иначе прогрей: warm.sh)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -qF 'bash scripts/render-quality/warm.sh'; then
  echo "  FAIL: AC-142 — подсказка отказа не называет прогрев bash scripts/render-quality/warm.sh" >&2
  FAIL=$((FAIL + 1))
fi

# --- Ноги 4-5: runbook и README сюиты называют live.sh и UV_OFFLINE=1 ---
for DOC in "$RUNBOOK" "$README"; do
  for ANCHOR in 'scripts/render-quality/live.sh' 'UV_OFFLINE=1'; do
    if grep -qF "$ANCHOR" "$DOC" 2>/dev/null; then
      :
    else
      echo "  FAIL: AC-142 — $(basename "$DOC") не называет «${ANCHOR}»" >&2
      echo "  (рычаг офлайна и именованный шаг задокументированы — FR-219, gramax-o0q.1)" >&2
      FAIL=$((FAIL + 1))
    fi
  done
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-142: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-142: live.sh обёртка прибора; недостижимая цель и сетевой отказ uv дают именованные отказы rc=2 с рычагами; runbook и README называют live.sh и UV_OFFLINE=1"
