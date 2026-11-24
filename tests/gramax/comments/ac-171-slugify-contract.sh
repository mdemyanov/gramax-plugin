#!/usr/bin/env bash
# tests/gramax/comments/ac-171-slugify-contract.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-171 (FR-227)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.7 (контракт
# slugify.py закрепляется тестами: сигнатуры, инварианты 1–5, крайние случаи), §6.7
# (строка 1); ADR-0028 Решение 7 («поведение не меняется, закрепляется тестами»).
# Проверка (таблица «вход → выход, rc» по CLI slugify.py): кириллица транслитерируется в
#   нижний регистр (ё → yo); каждый символ вне буквы/цифры — дефис, дефисы схлопываются,
#   крайние срезаются; пустой/пробельный ввод — ValueError в stderr, rc=2; --filename
#   добавляет .md, при обоих флагах действует --filename, --folder ничего не добавляет;
#   ошибки argparse — rc=2; аргумент с ведущим дефисом — после `--`.
# Warden (зелёный при рождении, 6e2db04): все инварианты исполняются сегодняшним кодом.
# Мутация к красному (исполнена на scratch-копии): в TRANSLIT значение 'ё' → '' — нога
#   «Ёжик и Щука → yozhik-i-shchuka» краснеет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
ERRFILE="$(mktemp "${TMPDIR:-/tmp}/ac-171-slug-err.XXXXXX")"
trap 'rm -f "$ERRFILE"' EXIT

run_slug() {
  # $@ — аргументы slugify.py; печатает stdout, rc — в SLUG_RC, stderr — в $ERRFILE.
  SLUG_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/slugify.py "$@" 2>"$ERRFILE")
  SLUG_RC=$?
}

# --- инвариант 1: кириллица → транслит, нижний регистр ---
for pair in "Привет мир:privet-mir" "Ёжик и Щука:yozhik-i-shchuka" " подъезд :podezd"; do
  input="${pair%%:*}"
  expected="${pair##*:}"
  run_slug "$input"
  assert_eq "$SLUG_RC" "0" "AC-171: slugify «${input}» — rc=0"
  assert_eq "$SLUG_OUT" "$expected" "AC-171: slugify «${input}» → «${expected}» (транслит кириллицы, нижний регистр; 'ё' → yo)"
done

# --- инвариант 2: не-буквы — дефис, схлопывание, срез краёв ---
for pair in "C# и .NET:c-i-net" "a-b---c:a-b-c" "foo_bar baz:foo-bar-baz" "a  b:a-b"; do
  input="${pair%%:*}"
  expected="${pair##*:}"
  run_slug "$input"
  assert_eq "$SLUG_OUT" "$expected" "AC-171: slugify «${input}» → «${expected}» (дефисы схлопываются, крайние срезаются)"
done
run_slug $'tab\tx'
assert_eq "$SLUG_OUT" "tab-x" "AC-171: табуляция между буквами — один дефис (tab<TAB>x → tab-x)"

# --- инвариант 3: пустой/пробельный ввод — ValueError, rc=2, текст в stderr ---
run_slug ""
assert_eq "$SLUG_RC" "2" "AC-171: пустой ввод — rc=2"
assert_eq "$SLUG_OUT" "" "AC-171: пустой ввод — stdout пуст"
if ! grep -qF "empty input: slug requires non-empty string" "$ERRFILE"; then
  echo "  FAIL: AC-171 — пустой ввод: строка «empty input: slug requires non-empty string» обязана быть в stderr (дизайн §3.7 инвариант 3)" >&2
  FAIL=$((FAIL + 1))
fi
run_slug "   "
assert_eq "$SLUG_RC" "2" "AC-171: ввод из одних пробелов — rc=2"

# --- инвариант 4: --filename добавляет .md, оба флага → .md, --folder без расширения ---
run_slug "Привет мир" --filename
assert_eq "$SLUG_OUT" "privet-mir.md" "AC-171: --filename добавляет .md"
run_slug "Привет мир" --filename --folder
assert_eq "$SLUG_OUT" "privet-mir.md" "AC-171: при обоих флагах действует --filename"
run_slug "Привет мир" --folder
assert_eq "$SLUG_OUT" "privet-mir" "AC-171: --folder ничего не добавляет"

# --- инвариант 5: ошибки argparse — rc=2 ---
(cd "$ROOT" && uv run plugins/gramax/scripts/slugify.py >/dev/null 2>&1); assert_eq "$?" "2" "AC-171: без аргументов — rc=2 (ошибка argparse)"
(cd "$ROOT" && uv run plugins/gramax/scripts/slugify.py один лишний >/dev/null 2>&1); assert_eq "$?" "2" "AC-171: лишний позиционный — rc=2"
(cd "$ROOT" && uv run plugins/gramax/scripts/slugify.py текст --неизвестный >/dev/null 2>&1); assert_eq "$?" "2" "AC-171: неизвестный флаг — rc=2"
run_slug -- -lead-
assert_eq "$SLUG_OUT" "lead" "AC-171: аргумент с ведущим дефисом — после -- («-- -lead-» → lead)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-171: AC-171 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-171: AC-171 — контракт slugify: транслит с ё→yo, дефисы, пустой ввод rc=2, флаги, argparse rc=2"
