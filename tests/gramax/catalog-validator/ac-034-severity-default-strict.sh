#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-034-severity-default-strict.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-161 (NFR-066, BR-014)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (все новые находки — warning
# по умолчанию, --strict — единственный переключатель эскалации; ADR-0024 Решение 2)
# Проверка: фикстура, где единственный дефект — битая цель диаграммы:
#   (a) без флагов exit 0; (b) с --strict exit 1;
#   (c) strict-вывод называет отсутствующую цель — эскалация идёт от находки о битой цели.
# Ассерт (c) операционализирует «единственный дефект — битая цель» из AC-161: без него прогон
# краснеет под --strict уже сегодня по ложному W034 на тег <mermaid> (red on 99201c0 —
# проверка цели диаграммы отсутствует), и ассерты (a)+(b) не отличают реализацию от её отсутствия.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/severity-default"

DEFAULT_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1)
DEFAULT_RC=$?
STRICT_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" --strict 2>&1)
STRICT_RC=$?

assert_exit_zero "$DEFAULT_RC" "AC-161 (NFR-066) — warning по умолчанию: прогон без флагов обязан завершиться exit 0 (получено $DEFAULT_RC)"

if [ "$STRICT_RC" -ne 1 ]; then
  echo "  FAIL: AC-161 — --strict эскалирует warning до error: прогон обязан завершиться exit 1 (получено $STRICT_RC)" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$STRICT_OUT" | grep -qF 'missing.mmd'; then
  echo "  FAIL: AC-161 — strict-вывод обязан называть отсутствующую цель 'missing.mmd': эскалация --strict обязана идти от находки о битой цели диаграммы, а не от ложной W034 на тег" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод без флагов (rc=$DEFAULT_RC) ---" >&2
  echo "$DEFAULT_OUT" >&2
  echo "  --- вывод --strict (rc=$STRICT_RC) ---" >&2
  echo "$STRICT_OUT" >&2
  fail_msg "ac-034: AC-161 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-034: AC-161 — warning по умолчанию (exit 0), --strict эскалирует находку о битой цели (exit 1)"
