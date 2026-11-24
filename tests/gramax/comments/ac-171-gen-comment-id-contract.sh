#!/usr/bin/env bash
# tests/gramax/comments/ac-171-gen-comment-id-contract.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-171 (FR-227)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.7 (контракт
# gen_comment_id.py: ID — 5 знаков [A-Za-z0-9]; с --check напечатанный ID не совпадает ни
# с одним ключом файла; файла нет — rc=0; файл — не отображение — rc=0; ошибка YAML —
# «yaml parse error in {path}» в stderr, rc=2), §6.7 (строка 2); ADR-0028 Решение 7
# (замер-основание: 2000 запусков — 2000 различных ID).
# Проверка: 200 ID на уровне модуля — все ^[A-Za-z0-9]{5}$, все различные, алфавит несёт
#   и буквы, и цифры; CLI --check: уникальность против ключей файла; файла нет — rc=0;
#   список вместо отображения — rc=0; битый YAML — rc=2 с именованной строкой в stderr.
# Warden (зелёный при рождении, 6e2db04).
# Мутация к красному (исполнена на scratch-копии): ALPHABET сужается до цифр — нога
#   «алфавит несёт буквы» краснеет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCRIPT="$ROOT/plugins/gramax/scripts/gen_comment_id.py"
FIXTURE="$SCRIPT_DIR/fixtures/ac-171-gen-id"
MODULE_PROBE="$(mktemp "${TMPDIR:-/tmp}/ac-171-genid.XXXXXX")"
trap 'rm -f "$MODULE_PROBE"' EXIT

# --- инвариант 1: 200 ID — все 5 знаков [A-Za-z0-9], все различные, буквы и цифры в алфавите ---
python3 -B - "$SCRIPT" >"$MODULE_PROBE" <<'PY'
import importlib.util
import re
import sys

spec = importlib.util.spec_from_file_location("gen_comment_id", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

ids = {mod.generate_id() for _ in range(200)}
print(f"COUNT={len(ids)}")
print(f"ALL_FORMAT={all(re.fullmatch(r'[A-Za-z0-9]{5}', i) is not None for i in ids)}")
chars = set("".join(ids))
print(f"HAS_LETTERS={any(c.isalpha() for c in chars)}")
print(f"HAS_DIGITS={any(c.isdigit() for c in chars)}")
PY
assert_exit_zero "$?" "AC-171: проба модуля gen_comment_id выполняется"
assert_grep "$MODULE_PROBE" "ALL_FORMAT=True" "AC-171: все 200 ID — ровно 5 знаков [A-Za-z0-9] (инвариант 1; совпадает с ID_RE валидатора комментариев)"
assert_grep "$MODULE_PROBE" "COUNT=200" "AC-171: 200 запусков дают 200 различных ID (замер ADR-0028: 2000 → 2000)"
assert_grep "$MODULE_PROBE" "HAS_LETTERS=True" "AC-171: алфавит несёт буквы — нога мутации «ALPHABET до цифр»"
assert_grep "$MODULE_PROBE" "HAS_DIGITS=True" "AC-171: алфавит несёт цифры"

# --- инвариант 2: --check против ключей файла ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE/keys.comments.yaml" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_exit_zero "$RC" "AC-171: --check по существующему файлу — rc=0"
assert_eq "$(printf '%s\n' "$OUT" | grep -cvE '^[A-Za-z0-9]{5}$')" "0" "AC-171: --check печатает один ID формата [A-Za-z0-9]{5}"
if printf '%s\n' "$OUT" | grep -qE '^(key1|key2)$'; then
  echo "  FAIL: AC-171 — напечатанный ID совпал с ключом файла: generate_unique_id обязан отсекать ключи (инвариант 2)" >&2
  FAIL=$((FAIL + 1))
fi

# --- инвариант 3: файла нет — пустое множество, rc=0 ---
if (cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE/absent.comments.yaml" >/dev/null 2>&1); then
  RC=0
else
  RC=$?
fi
assert_exit_zero "$RC" "AC-171: --check по отсутствующему файлу — rc=0 (штатно для нового файла комментариев)"

# --- инвариант 4: файл — не отображение (список) — rc=0 ---
if (cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE/nonmap.comments.yaml" >/dev/null 2>&1); then
  RC=0
else
  RC=$?
fi
assert_exit_zero "$RC" "AC-171: файл-список вместо отображения — rc=0 (молчание, как у валидатора)"

# --- инвариант 5: ошибка YAML — именованная строка в stderr, rc=2 ---
if OUT_ERR=$(cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE/broken.comments.yaml" 2>&1 >/dev/null); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "2" "AC-171: битый YAML — rc=2"
if ! printf '%s\n' "$OUT_ERR" | grep -qF "yaml parse error in"; then
  echo "  FAIL: AC-171 — битый YAML: именованная строка «yaml parse error in {path}» обязана быть в stderr (инвариант 5)" >&2
  printf '%s\n' "$OUT_ERR" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-171: AC-171 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-171: AC-171 — контракт gen_comment_id: формат/уникальность 200 ID, --check против ключей, отсутствующий файл rc=0, список rc=0, битый YAML rc=2"
