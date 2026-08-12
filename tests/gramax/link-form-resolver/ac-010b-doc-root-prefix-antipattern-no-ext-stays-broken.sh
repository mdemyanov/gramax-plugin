#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-010b-doc-root-prefix-antipattern-no-ext-stays-broken.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md — edge case из
#   content/40-architecture/2026-08-13-link-form-contract-design.md, «Контракт с
#   QA-author» → «Edge cases»: «путь, начинающийся с имени doc-root-папки, но БЕЗ `.md` —
#   не тестировался явно ни в требовании, ни в RES-004 ... поведение не specified фактом,
#   кандидат для теста».
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1
#
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Поведение здесь НЕ выведено из
#   явной формулировки требования (пересечение антипаттерна FR-081 и инференса FR-082 не
#   specified буквально) — единственный исход, механически вычислимый из 3-шагового
#   алгоритма FR-082 применительно к этой фикстуре: все три попытки
#   (`content/section/doc`, `content/section/doc.md`, `content/section/doc/_index.md`) не
#   находят файла, потому что в фикстуре НЕТ каталога `content/` вовсе (реальная цель —
#   `section/doc.md`, без вложенности). Итог совпадает и для сегодняшнего буквального
#   резолвера, и для целевого 3-шагового — тест не навязывает трактовку, которую
#   требование не фиксирует, а лишь защищает единственный уже-детерминированный исход.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/doc-root-prefix-antipattern-no-ext"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-010 edge — ссылка [X](content/section/doc) обязана оставаться битой: ни один из трёх шагов инференса FR-082 не находит файл (в фикстуре нет каталога content/)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qi 'content/section/doc'; then
  echo "  FAIL: AC-010 edge — сообщение об ошибке обязано называть конкретную ссылку 'content/section/doc'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-010b: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-010b: антипаттерн без расширения тоже остаётся ошибкой (все 3 шага инференса промахиваются)"
