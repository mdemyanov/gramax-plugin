#!/usr/bin/env bash
# tests/gramax/render-quality/ac-123-downgrade-cycle.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-123 (FR-202)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 4
#   («Один цикл — полный перечень артефактов» + таблица полного регресс-перечня
#   адаптации; NFR-083 — адаптация без ослабления).
# Проверка (контракт, статические маркеры пост-состояния): цикл понижения содержит
#   ОДНОВРЕМЕННО все элементы перечня FR-200 — отсутствие хотя бы одного = красный
#   с именованным перечнем недостающего:
#   (1) запись замера (журнал приёмки, путь из Решения 4);
#   (2) CHANGELOG-пункт в plugins/gramax/CHANGELOG.md (строка, называющая th и warn);
#   (3) render-quality: th-in-table.expect.json переведён kill -> ok (фикстура проверяет
#       факт рендера; tableRow остаётся ERROR-1);
#   (4) render-linter: фикстура ac-013-error-dir без th (заменена понижение-независимым
#       инлайновым <note>, чтобы rc-тест сохранил силу);
#   (5) render-linter ac-001: ассерты на WARN-семантике (warn есть, «ERROR L10» нет);
#   (6) render-linter ac-007: аналогично по строке 17;
#   (7) render-linter ac-011: инверсия severity-ассертов (rc-ассерт не «1», негативной
#       фразы «не должен понижаться» нет);
#   (8) render-linter ac-012: validate_render-нога на warn (rc2-ассерт не «1», warn есть).
#   Маркеры — пост-состояние из таблицы Решения 4 дизайна, не догадки. Правку носителей
#   (оба файла факта 3) ассертит ac-121; синхрон README/SKILL плагина — вне маркеров,
#   владелец Dev (полный перечень цикла в дизайне). Файлы render-linter только читаются.
# Цвет при создании: КРАСНЫЙ — ни один элемент цикла не исполнен (записи нет, CHANGELOG
#   без пункта, expect.json в kill, фикстура ac-013 на th, ассерты ac-001/007/011/012 на
#   ERROR-семантике). Закрывает Dev тем же циклом, что и ac-121.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
RECORD="$ROOT/docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md"
CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"
EXPECT_TH="$ROOT/tests/gramax/render-quality/fixtures/th-in-table.expect.json"
LINTER="$ROOT/tests/gramax/render-linter"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
MISSING=""

# (1) запись замера
if [ ! -f "$RECORD" ]; then
  echo "  FAIL: AC-123 — элемент «запись замера» отсутствует: $RECORD" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING запись-замера"
fi

# (2) CHANGELOG-пункт (строка, называющая th и понижение/warn)
if ! grep -qEi 'th([^a-z]|$).*(понижен|warn)|warn.*th([^a-z]|$)' "$CHANGELOG"; then
  echo "  FAIL: AC-123 — элемент «CHANGELOG-пункт» отсутствует: в plugins/gramax/CHANGELOG.md нет строки о понижении th в WARN" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING CHANGELOG"
fi

# (3) th-in-table.expect.json: tier0 ok (tableRow не трогается — warden)
PY_OUT="$(python3 -I - "$EXPECT_TH" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
expect = data.get("expect") or {}
print("TIER0=%s" % expect.get("tier0", "<absent>"))
print("TABLEROW=%s" % data.get("tableRow", "<absent>"))
PYEOF
)"
if ! printf '%s\n' "$PY_OUT" | grep -qF "TIER0=ok"; then
  echo "  FAIL: AC-123 — элемент «фикстура th-in-table» не адаптирован: expect.tier0 обязан стать ok (kill -> ok по FR-200); сейчас:" >&2
  printf '%s\n' "$PY_OUT" | grep -E "TIER0=|TABLEROW=" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING th-in-table.expect.json"
fi
assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'TABLEROW=ERROR-1' || true)" "1" "AC-123: tableRow фикстуры остаётся ERROR-1 (апстрим-строка карты не меняется, Решение 4)"

# (4) фикстура ac-013-error-dir без th, с инлайновым note
AC13="$LINTER/fixtures/ac-013-error-dir/article.md"
if [ ! -f "$AC13" ]; then
  echo "  FAIL: AC-123 — фикстура ac-013-error-dir/article.md не найдена" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING ac-013-фикстура"
else
  TH_COUNT="$(grep -c '<th' "$AC13" || true)"
  if [ "$TH_COUNT" -ne 0 ] || ! grep -q '<note>' "$AC13"; then
    echo "  FAIL: AC-123 — элемент «подмена фикстуры ac-013-error-dir» не исполнен: единственный её ERROR (th) заменяется инлайновым <note>…</note>, чтобы rc-тест сохранил силу (Решение 4, таблица адаптации)" >&2
    FAIL=$((FAIL + 1)); MISSING="$MISSING ac-013-фикстура"
  fi
fi

# (5)-(8) ассерты ac-001/007/011/012 на WARN-семантике
# ac-001: warn есть, ERROR L10 нет
if ! grep -q 'warn' "$LINTER/ac-001-th-positive.sh" || grep -qF 'ERROR L10' "$LINTER/ac-001-th-positive.sh"; then
  echo "  FAIL: AC-123 — элемент «адаптация ac-001-th-positive» не исполнен: ассерты переводятся на warn L10 + rc=0 (таблица Решения 4)" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING ac-001"
fi
# ac-007: warn есть, ERROR L17 нет
if ! grep -q 'warn' "$LINTER/ac-007-fenced-code.sh" || grep -qF 'ERROR L17' "$LINTER/ac-007-fenced-code.sh"; then
  echo "  FAIL: AC-123 — элемент «адаптация ac-007-fenced-code» не исполнен: реальный th на L17 ловится warn'ом, нога маскирования сохраняется" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING ac-007"
fi
# ac-011: инверсия — rc-ассерт не «1», негативной фразы «не должен понижаться» нет
if grep -qF "assert_eq \"\$RC\" \"1\"" "$LINTER/ac-011-th-severity.sh" || grep -qF 'не должен понижаться' "$LINTER/ac-011-th-severity.sh"; then
  echo "  FAIL: AC-123 — элемент «адаптация ac-011-th-severity» не исполнен: инверсия severity-ассертов (warn есть, ERROR нет, rc=0)" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING ac-011"
fi
# ac-012: validate_render-нога на warn — rc2-ассерт не «1», warn есть
if grep -qF "assert_eq \"\$RC2\" \"1\"" "$LINTER/ac-012-dedup-w034.sh" || ! grep -q 'warn' "$LINTER/ac-012-dedup-w034.sh"; then
  echo "  FAIL: AC-123 — элемент «адаптация ac-012-dedup-w034 (validate_render-нога)» не исполнен: паритетная находка th — warn, W034-молчание сохраняется (membership th в killerTags)" >&2
  FAIL=$((FAIL + 1)); MISSING="$MISSING ac-012"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-123: $FAIL assertion(s) failed; недостающие элементы цикла понижения (FR-202):$MISSING"
  exit 1
fi
pass_msg "ac-123: цикл понижения полон — запись, CHANGELOG, th-in-table ok, ac-013-фикстура, ac-001/007/011/012 на WARN-семантике"
