#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-023-unparseable-doc-root-diagnostics.sh
# Требование: content/30-requirements/2026-08-13-doc-root-discovery-contract.md AC-038 (FR-122, FR-123)
# ADR: content/00-project/adr/0020-doc-root-recursive-discovery.md, Решение 3
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   До FR-122/FR-123 ошибка парсинга схлопывалась до `invalid yaml: <str(e)>` без номера
#   строки, слова о плейсхолдере и подсказки закавычивания. После — сообщение несёт
#   номер строки/колонки из problem_mark pyyaml, слово «плейсхолдер» и пример исправления
#   с кавычками (title: "{{PROJECT_NAME}}").

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/doc-root-parse-error"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-038 — незакавыченный {{...}} в .doc-root.yaml обязан давать ненулевой код возврата (FR-122)" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qE 'строк[а-я]* [0-9]+'; then
  echo "  FAIL: AC-038 — сообщение об ошибке парсинга обязано содержать номер строки (FR-122, problem_mark.line)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qiE 'плейсхолдер|placeholder'; then
  echo "  FAIL: AC-038 — сообщение обязано упоминать плейсхолдер (плейсхолдер/placeholder) как причину ошибки парсинга (FR-123)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -q 'title: "{{PROJECT_NAME}}"'; then
  echo "  FAIL: AC-038 — сообщение обязано предлагать конкретное исправление — закавычивание title: \"{{PROJECT_NAME}}\" (FR-123)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -q 'плейсхолдер шаблона {{PROJECT_NAME}} не заменён'; then
  echo "  FAIL: AC-038 (BR-004) — parse-error-находка с подсказкой обязана поглощать placeholder-находку того же токена (одна находка на дефект, ADR-0020 Решение 3)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-023: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-023: parse-error несёт номер строки, слово о плейсхолдере и подсказку закавычивания"
