#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-032-w034-unknown-hyphen.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-068 (FR-157)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (матчер получает дефис в
# имени [a-z][a-z0-9-]* И опциональный / перед > — обе правки обязательны; ADR-0024 Решение 4)
# Проверка: <fancy-widget-x/> вне контрактов → W034 находит; автоссылка и закрывающий тег — нет
# Red on 99201c0 (2026-11-18): _UNSUPPORTED_HTML_RE = [a-z][a-z0-9]* с обязательным whitespace
# перед атрибутами (validate_structure.py:744) — <fancy-widget-x/> невидим по ОБЕИМ причинам
# (дефис в имени + голый self-closing без атрибутов), находок W034 ноль.
# Форма fixture обязательна — голый self-closing <fancy-widget-x/> различает /?-ветку матчера
# (QA-контракт дизайна, AC-068). Истинный позитив обязан держаться и ПОСЛЕ реализации.
# Истинные негативы (границы матчера, сохраняемое поведение): автоссылка <https://…> и
# закрывающий </plant-uml> невидимы — ассерты защищают от перерасширения матчера.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/w034-unknown-hyphen"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qE 'W034.*fancy-widget-x'; then
  echo "  FAIL: AC-068 — неизвестный дефисный тег <fancy-widget-x/> вне контрактов должен получать W034 (FR-157); матчер слеп к дефису и/или голой self-closing-форме" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qE 'W034.*https'; then
  echo "  FAIL: AC-068 — автоссылка <https://…> обязана оставаться невидимой для W034 (сохранённое поведение матчера)" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qE 'W034.*plant-uml'; then
  echo "  FAIL: AC-068 — закрывающий </plant-uml> не репортится W034 (сохранённое поведение матчера)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-032: AC-068 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-032: AC-068 — неизвестный дефисный тег <fancy-widget-x/> репортится (W034), границы матчера держатся"
