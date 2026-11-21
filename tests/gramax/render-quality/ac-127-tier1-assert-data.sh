#!/usr/bin/env bash
# tests/gramax/render-quality/ac-127-tier1-assert-data.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-127 (FR-206)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 3
#   («Ассерты — данные, не код»: tier-1 судит деградационные симптомы класса 2 разбора
#   волны-1, которых tier-0 не видит; ассерты заводятся в expect.json как данные —
#   код прибора не меняется; ожидания tier0 симптом-фикстур остаются kill).
# Проверка (контракт данных, офлайн-парсинг expect.json):
#   - unbalanced-pair-tags.expect.json: tier0="ok" (ВЫРОВНЕНО follow-up коммитом после
#     цикла-2 волны-2 по BR-021: 200 дважды — записи замера волны-1 и волны-2; прежний
#     варден tier0="kill" охранял апстрим-гипотезу ДО замера и утратил силу),
#     tier1="pass", ассерты = [{"name": "tail-paragraph",
#     "selector": "text=Абзац после конструкции", "count": 1}] (волна-1: хвостовой абзац
#     присутствует в HTML — symptom грубой пробой не пойман, судит только tier-1);
#   - multiple-images.expect.json: tier0="ok" (та же выравнивающая правка), tier1="pass",
#     ассерты = [{"name": "img-count", "selector": "img", "count": 2}] (волна-1: 2/2 img
#     отрендерились);
#   - контролы control-balanced-tags / control-images хранят свои pass-ассерты
#     (роль контролов — подтверждение селекторов на легальной форме, R2).
#   Механику ассертов (примитив {name, selector, count}, вердикт pass/fail по имени)
#   стаб не дублирует — её закрывает ac-110 волны-1 (дизайн, «Контракт с QA-author»).
#   Нога AC-127 «вердикты validate_render по этим правилам не менялись» — владелец
#   BA-acceptance (в волна-2 не входит по BR-021). Селекторы — гипотезы R2: расхождение
#   с живым фактом разбирается по протоколу FR-196 записью замера, молчаливая правка
#   селектора (= правка этого стаба без записи) запрещена.
#   Follow-up после живого tier-1 прогона (config tiers=[tier0,tier1]): две ноги скоупа
#   FR-206 прошли на живом портале (unbalanced-pair-tags tail-paragraph=1 PASS,
#   multiple-images img-count=2 PASS — селекторы скоупа подтверждены, риск R2 снят).
#   Семь ног волны-1 (контролы и спорные: tabs-render, text-renders, note-block-renders,
#   table-renders, page-renders, note-in-cell/note-in-note renders) провалились live —
#   их селекторы НЕ калиброваны ни одним замером (волна-1 шла tier0-only); ожидания
#   переведены "any" (= «не судится», прибора-решения нет до калибровочной волны
#   tier-1), ассерты-гипотезы ОСТАВЛЕНЫ в expect.json — инертны под any, остаются
#   записью гипотез. Ноги стаба этого не пинят: ASSERTS_MATCH сверяет только массив
#   ассертов (он не менялся), tier1 контрольных ног стаб не ассертит. Легальный
#   читатель массивов — будущая калибровочная волна tier-1.
# Цвет при создании: КРАСНЫЙ — tier1-ноги данных пусты (tier1="any", asserts=[] в обеих
#   симптом-фикстурах); закрывает Dev как данные тем же циклом (файлы ожиданий меняются,
#   код прибора — нет). Адаптация tier0-ног (kill -> ok) — follow-up после цикла-2
#   волны-2 по решению владельца (BR-021: ожидание следует дважды измеренному факту —
#   записи замера 2026-11-21-render-calibration-validate-render.md и
#   2026-11-21-render-calibration-th.md; вердикты validate_render не менялись).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
FIXTURES="$ROOT/tests/gramax/render-quality/fixtures"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PY_OUT="$(python3 -I - "$FIXTURES" <<'PYEOF'
import json, os, sys
fixtures = sys.argv[1]

def load(name):
    with open(os.path.join(fixtures, name + ".expect.json"), encoding="utf-8") as handle:
        return json.load(handle)

# Пост-состояние по таблице Решения 3 дизайна
EXP_UNBALANCED = [{"name": "tail-paragraph",
                   "selector": "text=Абзац после конструкции", "count": 1}]
EXP_IMAGES = [{"name": "img-count", "selector": "img", "count": 2}]
EXP_TABS = [{"name": "tabs-render", "selector": "[data-testid=tab]", "count": 2}]
EXP_CTRL_IMAGES = [{"name": "images-render", "selector": "img", "count": 2}]

def report(name, data, exp_asserts):
    expect = data.get("expect") or {}
    asserts = expect.get("asserts") or []
    print("%s.TIER0=%s" % (name, expect.get("tier0", "<absent>")))
    print("%s.TIER1=%s" % (name, expect.get("tier1", "<absent>")))
    print("%s.ASSERTS_MATCH=%s" % (name, "true" if asserts == exp_asserts else "false"))
    if asserts != exp_asserts:
        print("%s.ASSERTS_ACTUAL=%s" % (name, json.dumps(asserts, ensure_ascii=False)))

report("unbalanced", load("unbalanced-pair-tags"), EXP_UNBALANCED)
report("images", load("multiple-images"), EXP_IMAGES)
report("ctrl-tags", load("control-balanced-tags"), EXP_TABS)
report("ctrl-images", load("control-images"), EXP_CTRL_IMAGES)
PYEOF
)"

# --- симптом-фикстуры: tier1-нога данных заведена, tier0 выровнен по дважды измеренному факту ---
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^unbalanced\.TIER0=ok' || true)" "1" "AC-127: unbalanced-pair-tags — ожидание tier0 ok (выровнено по дважды измеренному 200, BR-021; прежний kill — гипотеза до замера)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^unbalanced\.TIER1=pass' || true)" "1" "AC-127: unbalanced-pair-tags — tier1 ожидает pass (симптом судится ассертом, не тиром-0)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^unbalanced\.ASSERTS_MATCH=true' || true)" "1" "AC-127: unbalanced-pair-tags — ассерт tail-paragraph («text=Абзац после конструкции», count 1) по таблице Решения 3"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^images\.TIER0=ok' || true)" "1" "AC-127: multiple-images — ожидание tier0 ok (выровнено по дважды измеренному 200, BR-021)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^images\.TIER1=pass' || true)" "1" "AC-127: multiple-images — tier1 ожидает pass"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^images\.ASSERTS_MATCH=true' || true)" "1" "AC-127: multiple-images — ассерт img-count (img, count 2) по таблице Решения 3"

# --- контролы: pass-ассерты сохранены (warden — подтверждение селекторов на легальной форме) ---
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^ctrl-tags\.ASSERTS_MATCH=true' || true)" "1" "AC-127: control-balanced-tags хранит свой pass-ассерт (роль контроля, R2)"
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c '^ctrl-images\.ASSERTS_MATCH=true' || true)" "1" "AC-127: control-images хранит свой pass-ассерт (роль контроля, R2)"

if [ "$FAIL" -gt 0 ]; then
  if printf '%s\n' "$PY_OUT" | grep -q 'ASSERTS_ACTUAL='; then
    echo "  --- фактическое состояние tier1-ног данных (ожидание — таблица Решения 3) ---" >&2
    printf '%s\n' "$PY_OUT" | grep 'ASSERTS_ACTUAL=\|\.TIER1=' >&2
  fi
  fail_msg "ac-127: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-127: tier1-ассерты данных заведены (tail-paragraph count 1; img-count count 2), tier0 симптом-фикстур выровнен по факту (ok), контролы на месте"
