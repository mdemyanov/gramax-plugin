#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-007-retired-skills-field.sh
# Требование: FR-012. Происхождение: archive/routing-mermaid-drawio ac-014 — РЕТИРОВАН.
# Замер SA: 53 файла plugin.json, 22 плагина, 0 с полем skills — skills обнаруживаются
# автоматически из каталога skills/. AC опиралось на ложную посылку (ADR-0011 Решение 2).
# Этот тест сторожит саму ретировку: ассерт на поле skills не должен вернуться в suite.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

REVIVED=$(grep -rlE "get\('skills'\)|\[.skills.\]|\"skills\"" "$SCRIPT_DIR" \
          --include='ac-*.sh' 2>/dev/null | grep -v 'ac-007-retired' || true)

if [ -n "$REVIVED" ]; then
  echo "  FAIL: FR-012: ассерт на поле 'skills' в plugin.json вернулся в suite:" >&2
  echo "$REVIVED" >&2
  echo "  Ретировка обоснована в ADR-0011 Решение 2 и tests/gramax/archive/README.md." >&2
  echo "  Возврат требует новой санкции, а не молчаливого добавления." >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: ретировка AC про поле skills соблюдена"
