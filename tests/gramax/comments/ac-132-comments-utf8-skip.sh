#!/usr/bin/env bash
# tests/gramax/comments/ac-132-comments-utf8-skip.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md —
#             AC-132 (FR-212), comments-нога
# Переподпись (ADR-0029 Решение 5, строка 6): стаб родился с подписью «AC-133 в части
# комментариев», а имя файла и все носители (определения требования, RECORD 49b2f37,
# at-acceptance волны-3) называют AC-132 — подпись приведена к имени; имя файла и
# ADR-0026 не меняются.
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.4 (сообщения
# дословно), §2.5, ADR-0026 Решение 6 (E036 — одна находка на файл; parse_comments пропускает
# файл со строкой на stderr, rc=0).
# Проверка: каталог с .md с битым UTF-8 и со «битым» .comments.yaml →
#   (a) validate_comments: rc=1, без traceback, ровно одна E036-строка на файл с путём и
#       позицией байта (для .md и для .comments.yaml отдельно), находки здорового файла
#       оцениваются (обход доведён до конца);
#   (b) parse_comments: rc=0, предупреждение на stderr с путём и позицией, отчёт по
#       здоровому файлу присутствует.
# Red on 7553da1: md_path.read_text/yaml read_text без обработки UnicodeDecodeError —
#   traceback и обрыв обхода (замер 2026-11-23: UnicodeDecodeError на битом .md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-132-utf8"
HEALTHY_FINDING="missing field comment.content"
HEALTHY_CONTENT="Текст здорового комментария"

# --- (a): validate_comments — E036, без traceback, обход доведён до конца ---
VAL_OUT="$FIXTURE/../.ac-132-val-out.txt"
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE" > "$VAL_OUT" 2>&1); then
  RC_VAL=0
else
  RC_VAL=$?
fi
assert_eq "$RC_VAL" "1" "AC-132 (комментарии): битый UTF-8 — rc=1"

if grep -q "Traceback" "$VAL_OUT"; then
  echo "  FAIL: AC-132 (комментарии) — traceback UnicodeDecodeError вместо именованной находки (FR-212)" >&2
  FAIL=$((FAIL + 1))
fi

E036_COUNT=$(grep -c "E036" "$VAL_OUT")
assert_eq "$E036_COUNT" "2" "AC-132 (комментарии): ровно две E036-находки — по одной на битый .md и на битый .comments.yaml (BR-004)"

if ! grep -F "page-broken-md.md" "$VAL_OUT" | grep -q "E036"; then
  echo "  FAIL: AC-132 (комментарии) — E036 обязан называть путь битого .md" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -F "page-broken-yaml.comments.yaml" "$VAL_OUT" | grep -q "E036"; then
  echo "  FAIL: AC-132 (комментарии) — E036 обязан называть путь битого .comments.yaml" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep "E036" "$VAL_OUT" | grep -q "0xd0"; then
  echo "  FAIL: AC-132 (комментарии) — E036 обязан называть позицию байта (0xd0)" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "$HEALTHY_FINDING" "$VAL_OUT"; then
  echo "  FAIL: AC-132 (комментарии) — находка здорового файла (missing field comment.content) обязана появиться: обход не обрывается на битом файле" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$VAL_OUT"

# --- (b): parse_comments — пропуск с предупреждением на stderr, rc=0 ---
PARSE_ERR="$FIXTURE/../.ac-132-parse-err.txt"
PARSE_OUT="$FIXTURE/../.ac-132-parse-out.txt"
trap 'rm -f "$VAL_OUT" "$PARSE_ERR" "$PARSE_OUT"' EXIT
if (cd "$ROOT" && uv run plugins/gramax/scripts/parse_comments.py "$FIXTURE" > "$PARSE_OUT" 2> "$PARSE_ERR"); then
  RC_PARSE=0
else
  RC_PARSE=$?
fi
assert_exit_zero "$RC_PARSE" "AC-132 (комментарии): parse_comments пропускает битый файл — rc=0"

if ! grep -qF "page-broken-md.md" "$PARSE_ERR"; then
  echo "  FAIL: AC-132 (комментарии) — parse_comments обязан предупреждать о пропуске на stderr с путём" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -qi "utf-8" "$PARSE_ERR"; then
  echo "  FAIL: AC-132 (комментарии) — предупреждение parse_comments обязано называть битый UTF-8" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -qF "$HEALTHY_CONTENT" "$PARSE_OUT"; then
  echo "  FAIL: AC-132 (комментарии) — отчёт parse_comments обязан содержать комментарий здорового файла (обход доведён до конца)" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$PARSE_ERR" "$PARSE_OUT"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-132: AC-132 (комментарии) — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-132: FR-212 комментарии — E036 на битый .md и .comments.yaml, parse_comments пропускает, обход полный"
