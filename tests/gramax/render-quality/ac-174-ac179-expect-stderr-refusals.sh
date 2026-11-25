#!/usr/bin/env bash
# tests/gramax/render-quality/ac-174-ac179-expect-stderr-refusals.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md —
#   AC-174 (FR-229) и AC-179 (FR-229, D5).
# Решение: ADR-0029 (вне индекса на момент письма), Решение 5, строка 1 (нечитаемый
#   expect.json — именованная строка расхождения, не TypeError) и строка 7 (банк отказов
#   в stderr); поправка к ADR-0027 (часть 2) — баннер «REFUSAL <КОД>: <подсказка>» пишется
#   в stderr, stdout при rc=2 пуст.
# Проверка (контракт):
#   (a) AC-174: нечитаемый expect.json (битый JSON в паре к .md) — прибор печатает
#       именованную строку расхождения с нотой «expect.json не читается» (слаг назван),
#       НЕ TypeError; rc=1, отчёт написан; здоровая пара соседнего слага оценивается
#       (обход доведён до конца). Офлайн: стаб-портал lib/stub_portal.py на 127.0.0.1
#       (дом-паттерн ac-108), только tier-0.
#   (b) AC-179: оба пути именованного отказа — refuse() прибора (RENDER_TARGET_UNSET) и
#       обёртка uv (PLAYWRIGHT_PIN_UNRESOLVED, фейковый uv с сигнатурой «Failed to fetch»,
#       дом-паттерн ac-142) — пишут баннер в STDERR; stdout при rc=2 пуст; стаб судит
#       потоки раздельно.
# Цвет на текущем дереве: КРАСНЫЙ — expect=None даёт TypeError «'NoneType' object is not
#   subscriptable» (scripts/render-quality/probe.py:185-192: чтение expect["tier0"] ДО
#   проверки None), refuse() печатает баннер в stdout (:46-49) — ноги (a2), (a3), (b1) красные.
#   Мутации к красному после правки Dev: вернуть чтение expect["tier0"] до проверки None;
#   вернуть print(...) в refuse() (обе строки 1 и 7 Решения 5). Нога (b2) зелёная от
#   рождения — обёртка probe.sh уже пишет баннер в stderr (пин обоих путей AC-179).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PROBE="$ROOT/scripts/render-quality/probe.sh"
STUB_PORTAL="$SCRIPT_DIR/lib/stub_portal.py"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-174.XXXXXX")"
SERVER_PID=""
cleanup() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2> /dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

# Офлайн по построению (дом-паттерн run.sh сюиты): uv не ходит в сеть, портал — loopback.
export UV_OFFLINE=1

FAIL=0

if [ ! -f "$PROBE" ]; then
  fail_msg "ac-174-ac179: отсутствует вход прибора scripts/render-quality/probe.sh — стаб не может исполнить контракт (дом-паттерн ac-106)"
  exit 1
fi

# --- Инфраструктура: стаб-портал, обе цели отвечают 200 (факт tier-0 не мешает) ---
cat > "$TMP/routes.json" <<'JSON'
{
  "slugs": {
    "stub-control": { "codes": [200], "html": "<html><body><p>контроль</p></body></html>" },
    "stub-broken-expect": { "codes": [200], "html": "<html><body><p>страница с битой парой</p></body></html>" },
    "stub-nonobj-list": { "codes": [200], "html": "<html><body><p>expect — массив</p></body></html>" },
    "stub-nonobj-null": { "codes": [200], "html": "<html><body><p>expect — null</p></body></html>" }
  }
}
JSON
python3 -I "$STUB_PORTAL" --port 0 --routes "$TMP/routes.json" > "$TMP/portal.out" 2> "$TMP/portal.err" &
SERVER_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -s "$TMP/portal.out" ] && grep -q "STUB_READY" "$TMP/portal.out" && break
  sleep 0.2
done
PORT="$(sed -n 's/^STUB_READY port=//p' "$TMP/portal.out" | head -1)"
if [ -z "$PORT" ]; then
  echo "  FAIL: AC-174 — стаб-портал не поднялся (дефект стаба, не красный прибор)" >&2
  cat "$TMP/portal.err" >&2
  fail_msg "ac-174-ac179: инфраструктура стаба сломана"
  exit 1
fi

# Фикстуры: здоровая пара + пара с нечитаемым expect.json (битый JSON — ValueError).
mkdir -p "$TMP/fixtures"
printf '%s\n' '# Контроль' '' 'Здоровая страница стаба.' > "$TMP/fixtures/stub-control.md"
cat > "$TMP/fixtures/stub-control.expect.json" <<'JSON'
{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }
JSON
printf '%s\n' '# Пара с битым ожиданием' '' 'expect.json не парсится.' > "$TMP/fixtures/stub-broken-expect.md"
printf '%s\n' '{ "tableRow": "broken", "expect": { "tier0": ' > "$TMP/fixtures/stub-broken-expect.expect.json"

cat > "$TMP/config.json" <<JSON
{
  "baseUrl": "http://127.0.0.1:$PORT",
  "catalog": "render-probes",
  "tiers": ["tier0"],
  "viewport": { "width": 1280, "height": 720 }
}
JSON

# --- (a): нечитаемый expect.json — именованное расхождение, не TypeError ---
bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures" \
  --report "$TMP/report.md" > "$TMP/probe.out" 2> "$TMP/probe.err"
RC_PROBE=$?
COMBINED="$(cat "$TMP/probe.out" "$TMP/probe.err")"

if [ "$RC_PROBE" -ne 1 ]; then
  echo "  FAIL: AC-174 — прогон с нечитаемой парой обязан дать rc=1 (расхождение), получен rc=${RC_PROBE}" >&2
  printf '%s\n' "$COMBINED" | head -8 >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$COMBINED" | grep -qF 'TypeError'; then
  echo "  FAIL: AC-174 — прибор упал TypeError вместо именованной строки расхождения" >&2
  echo "  (ADR-0029 Решение 5, строка 1: проверка expect is None — первой, до чтения" >&2
  echo "  expect[\"tier0\"]; строка расхождения с нотой «expect.json не читается», rc=1)" >&2
  printf '%s\n' "$COMBINED" | grep -F 'TypeError' | head -3 >&2
  FAIL=$((FAIL + 1))
fi
assert_file_exists "$TMP/report.md" \
  "AC-174: отчёт написан (расхождение — не крушение прибора, отчёт живёт)"
if [ -f "$TMP/report.md" ]; then
  assert_grep "$TMP/report.md" 'expect.json не читается' \
    "AC-174: нота «expect.json не читается» в отчёте (именованная строка расхождения)"
  assert_grep "$TMP/report.md" 'stub-broken-expect: divergence' \
    "AC-174: слаг битой пары назван и помечен divergence (не молчаливый пропуск)"
  assert_grep "$TMP/report.md" 'stub-control: match' \
    "AC-174: здоровая пара соседнего слага оценена (обход доведён до конца)"
fi
if [ -s "$TMP/probe.out" ] && ! grep -qF 'expect.json не читается' "$TMP/probe.out"; then
  echo "  FAIL: AC-174 — stdout (зеркало отчёта) не несёт ноту «expect.json не читается»" >&2
  FAIL=$((FAIL + 1))
fi

# --- (a2): expect.json — валидный JSON, но НЕ объект ([] и null) — тот же контракт,
# что нечитаемый: именованная строка расхождения «expect.json не читается» по слагу,
# rc=1, отчёт написан, без Traceback. Ревью r3 (2026-11-25, [F] advisory AC-174,
# anchor scripts/render-quality/probe.py:82): data.get() на не-объекте ронял прибор
# AttributeError'ом (ловятся только OSError/ValueError) — AC-174 обещала именованную
# строку. Red on a1c229a по дизайну. ---
mkdir -p "$TMP/fixtures-nonobj"
printf '%s\n' '# Контроль' '' 'Здоровая страница стаба.' > "$TMP/fixtures-nonobj/stub-control.md"
cat > "$TMP/fixtures-nonobj/stub-control.expect.json" <<'JSON'
{ "tableRow": "control", "expect": { "tier0": "ok", "tier1": "any", "asserts": [] } }
JSON
printf '%s\n' '# Пара: expect — массив' '' 'Валидный JSON, но не объект.' > "$TMP/fixtures-nonobj/stub-nonobj-list.md"
printf '%s\n' '[]' > "$TMP/fixtures-nonobj/stub-nonobj-list.expect.json"
printf '%s\n' '# Пара: expect — null' '' 'Валидный JSON, не объект (второй случай).' > "$TMP/fixtures-nonobj/stub-nonobj-null.md"
printf '%s\n' 'null' > "$TMP/fixtures-nonobj/stub-nonobj-null.expect.json"

bash "$PROBE" --config "$TMP/config.json" --fixtures "$TMP/fixtures-nonobj" \
  --report "$TMP/report-nonobj.md" > "$TMP/nonobj.out" 2> "$TMP/nonobj.err"
RC_NONOBJ=$?
COMBINED_NONOBJ="$(cat "$TMP/nonobj.out" "$TMP/nonobj.err")"

if [ "$RC_NONOBJ" -ne 1 ]; then
  echo "  FAIL: AC-174 (r3) — прогон с не-объектными expect.json обязан дать rc=1 (расхождение с отчётом), получен rc=${RC_NONOBJ}" >&2
  printf '%s\n' "$COMBINED_NONOBJ" | head -8 >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$COMBINED_NONOBJ" | grep -qF 'Traceback'; then
  echo "  FAIL: AC-174 (r3) — не-объектный expect.json уронил прибор (traceback вместо именованной строки расхождения; ревью 2026-11-25)" >&2
  printf '%s\n' "$COMBINED_NONOBJ" | grep -F 'Traceback' | head -3 >&2
  FAIL=$((FAIL + 1))
fi
assert_file_exists "$TMP/report-nonobj.md" "AC-174 (r3): отчёт написан и для не-объектных expect.json"
if [ -f "$TMP/report-nonobj.md" ]; then
  assert_grep "$TMP/report-nonobj.md" 'expect.json не читается' \
    "AC-174 (r3): нота «expect.json не читается» — не-объект судится как нечитаемый (PM-рулинг r3)"
  assert_grep "$TMP/report-nonobj.md" 'stub-nonobj-list: divergence' \
    "AC-174 (r3): слаг expect-массива назван и помечен divergence"
  assert_grep "$TMP/report-nonobj.md" 'stub-nonobj-null: divergence' \
    "AC-174 (r3): слаг expect-null назван и помечен divergence"
  assert_grep "$TMP/report-nonobj.md" 'stub-control: match' \
    "AC-174 (r3): здоровая пара оценена — обход доведён до конца"
fi

# --- (b1): отказ refuse() прибора — баннер в stderr, stdout пуст при rc=2 (AC-179) ---
env -u GRAMAX_RENDER_BASE_URL -u GRAMAX_RENDER_CATALOG \
  bash "$PROBE" --check-env --config "$TMP/absent-config.json" \
  > "$TMP/unset.out" 2> "$TMP/unset.err"
RC_UNSET=$?
if [ "$RC_UNSET" -ne 2 ]; then
  echo "  FAIL: AC-179 — отказ без цели обязан дать rc=2, получен rc=${RC_UNSET}" >&2
  FAIL=$((FAIL + 1))
fi
if [ -s "$TMP/unset.out" ]; then
  echo "  FAIL: AC-179 — stdout при отказе refuse() не пуст: баннер ушёл не в тот поток" >&2
  echo "  (ADR-0029 Решение 5, строка 7 + поправка к ADR-0027 часть 2: REFUSAL — в stderr;" >&2
  echo "  сегодня refuse() печатает в stdout, probe.py:46-49)" >&2
  head -3 "$TMP/unset.out" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -qF 'REFUSAL RENDER_TARGET_UNSET' "$TMP/unset.err"; then
  echo "  FAIL: AC-179 — в stderr нет баннера «REFUSAL RENDER_TARGET_UNSET» (отказ refuse())" >&2
  head -5 "$TMP/unset.err" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b2): отказ обёртки uv — баннер в stderr, stdout пуст при rc=2 (AC-179;
# фейковый uv первым на PATH — дом-паттерн ac-142; нога зелёная от рождения) ---
mkdir -p "$TMP/fake-uv"
cat > "$TMP/fake-uv/uv" <<'SH'
#!/usr/bin/env sh
echo "error: Failed to fetch" >&2
exit 7
SH
chmod +x "$TMP/fake-uv/uv"
env PATH="$TMP/fake-uv:$PATH" bash "$PROBE" --check-env --config "$TMP/config.json" \
  > "$TMP/uv.out" 2> "$TMP/uv.err"
RC_UV=$?
if [ "$RC_UV" -ne 2 ]; then
  echo "  FAIL: AC-179 — сетевой отказ uv (сигнатура «Failed to fetch») обязан дать rc=2, получен rc=${RC_UV}" >&2
  FAIL=$((FAIL + 1))
fi
if [ -s "$TMP/uv.out" ]; then
  echo "  FAIL: AC-179 — stdout при отказе обёртки uv не пуст (баннер обязан жить в stderr)" >&2
  head -3 "$TMP/uv.out" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -qF 'REFUSAL PLAYWRIGHT_PIN_UNRESOLVED' "$TMP/uv.err"; then
  echo "  FAIL: AC-179 — в stderr нет баннера «REFUSAL PLAYWRIGHT_PIN_UNRESOLVED» (обёртка uv)" >&2
  head -5 "$TMP/uv.err" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-174-ac179: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-174-ac179: нечитаемый expect.json — именованное расхождение с нотой, не TypeError, обход полный; оба пути отказа (refuse и обёртка uv) пишут stderr, stdout пуст при rc=2"
