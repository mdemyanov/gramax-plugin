#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-181-absolute-path-leak.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-181 (FR-231)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.5 (правило
# E037: error, по сырой строке БЕЗ маски кода, одна находка на строку, сообщение называет
# строку и форму, но не сам путь; маскированные формы и адреса не совпадают), §6.5;
# ADR-0028 Решение 5 (форма /home/<имя>/… в сообщении, основание — замер: ручная форма
# пропустила 2 строки собственного корпуса и 10 строк корпуса сравнения).
# Проверка (фикстуры ac-181-abs-path/dirty и /clean; имя demouser — фиктивное, из [a-z]):
#   dirty — путь в прозе (формы /Users/, /home/, C:\Users\) и путь внутри код-спана →
#     E037 по одному на строку с находкой, rc=1, в выводе нет ни имени, ни пути;
#   clean — маскированные формы (/Users/...), $USER, адрес с /home/, относительный
#     путь → rc=0, находок нет;
#   нога догфудинга — check_absolute_paths определён в validate_structure.py и на docs/
#     0 находок E037.
# Red on 6e2db04: правила нет — ручная проверка; фикстура dirty даёт rc=0 и 0 находок
#   (именная нога), определение check_absolute_paths отсутствует (нога догфудинга).
#   Нога догфудинга зеленеет в два шага: после правки Dev она краснеет на двух
#   замеренных строках корпуса (docs/lessons-learned.md и
#   docs/30-requirements/2026-11-17-docs-layout-inversion.md — ADR-0028 Решение 5),
#   пока чистка D8 их не уберёт; зелёное состояние обеих ног — после чистки.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-181-abs-path"
VALIDATOR="$ROOT/plugins/gramax/scripts/validate_structure.py"

run_validator() {
  local target="$1" outfile="$2"
  if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$target" >"$outfile" 2>&1); then
    return 0
  fi
  return 1
}

# --- dirty: три формы в прозе + путь внутри код-спана ---
OUT_DIRTY="$(mktemp "${TMPDIR:-/tmp}/ac-181-dirty.XXXXXX")"
run_validator "$FIXTURE/dirty" "$OUT_DIRTY"
RC_DIRTY=$?

assert_eq "$RC_DIRTY" "1" "AC-181: фикстура с четырьмя личными путями — rc=1 (E037 — уровень error, ADR-0028 Решение 5; red on 6e2db04: правила нет, rc=0)"

N_E037=$(grep -c "E037" "$OUT_DIRTY")
assert_eq "$N_E037" "4" "AC-181: ровно четыре находки E037 — по одной на строку с путём (BR-004: одна находка на дефект; red on 6e2db04: 0)"

for article in prose-users.md prose-home.md prose-win.md code-span.md; do
  if ! grep "E037" "$OUT_DIRTY" | grep -qF "$article"; then
    echo "  FAIL: AC-181 RED — статья $article не дала E037: путь в этой статье не пойман правилом (дизайн §3.5)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if ! grep "E037" "$OUT_DIRTY" | grep -qF "на строке 6"; then
  echo "  FAIL: AC-181 — сообщение E037 обязано называть номер строки (фикстура несёт путь на строке 6; дизайн §3.5: «на строке {N}»)" >&2
  grep "E037" "$OUT_DIRTY" | head -2 >&2
  FAIL=$((FAIL + 1))
fi
if ! grep "E037" "$OUT_DIRTY" | grep -qF "(форма /Users/"; then
  echo "  FAIL: AC-181 — сообщение E037 обязано называть форму пути (дизайн §3.5: «форма /Users/<имя>/…»)" >&2
  FAIL=$((FAIL + 1))
fi
if grep -qF "demouser" "$OUT_DIRTY"; then
  echo "  FAIL: AC-181 — имя контрибьютора просочилось в вывод правила: сообщение называет строку и форму, но не сам путь (дизайн §3.5, FR-072)" >&2
  grep -F "demouser" "$OUT_DIRTY" | head -3 >&2
  FAIL=$((FAIL + 1))
fi
if grep -qF "notes/plan.md" "$OUT_DIRTY"; then
  echo "  FAIL: AC-181 — сам путь просочился в вывод правила (дизайн §3.5: «сам путь и имя в сообщение и вывод не попадают»)" >&2
  FAIL=$((FAIL + 1))
fi

# --- clean: маскированные и посторонние формы не совпадают ---
OUT_CLEAN="$(mktemp "${TMPDIR:-/tmp}/ac-181-clean.XXXXXX")"
run_validator "$FIXTURE/clean" "$OUT_CLEAN"
RC_CLEAN=$?

assert_exit_zero "$RC_CLEAN" "AC-181: маскированные и посторонние формы (/Users/..., \$USER, адрес с /home/, относительный путь) — rc=0"
assert_eq "$(grep -c "E037" "$OUT_CLEAN")" "0" "AC-181: маскированные формы не становятся находкой (дизайн §3.5: 8 синтетических случаев без находки)"

# --- нога догфудинга: правило заведено, docs/ чист после D8 ---
if ! grep -q "def check_absolute_paths" "$VALIDATOR"; then
  echo "  FAIL: AC-181 RED (нога догфудинга, статическая) — def check_absolute_paths отсутствует в validate_structure.py: ручная проверка утечки путей не заменена правилом (ADR-0028 Решение 5)" >&2
  FAIL=$((FAIL + 1))
fi

OUT_DOCS="$(mktemp "${TMPDIR:-/tmp}/ac-181-docs.XXXXXX")"
run_validator "$ROOT/docs" "$OUT_DOCS"
N_DOCS=$(grep -c "E037" "$OUT_DOCS")
if [ "$N_DOCS" -ne 0 ]; then
  echo "  FAIL: AC-181 (нога догфудинга, docs/) — $N_DOCS находок E037 на docs/: строки с личными путями не вычищены чисткой D8 (ADR-0028 Решение 5, §3.5 «правка кода входит после коммита чистки»)" >&2
  grep "E037" "$OUT_DOCS" | head -5 >&2
  FAIL=$((FAIL + 1))
fi

rm -f "$OUT_DIRTY" "$OUT_CLEAN" "$OUT_DOCS"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-181: AC-181 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-181: AC-181 — E037 на трёх формах и код-спане без утечки имени/пути, маскированные формы чисты, docs/ без находок"
