#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-004-nested-doc-root-decision-documented.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-004 (FR-067).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел B —
#   решение "у потребителя" (вариант (в) FR-067), явная пометка в
#   references/doc-root-schema.md, не молчание.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).
#
# AC-004 по тексту требования принимает ЛЮБОЕ из трёх решений (а)/(б)/(в) — тест проверяет
# только факт наличия явного решения (ключевое слово "вложенн...doc-root.yaml"/"nested
# doc-root"), не то, какое именно решение выбрано (это выбрала диспозиция, не предмет AC).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

if ! grep -rliE 'вложенн.{0,15}\.doc-root\.yaml|nested.{0,10}doc-root' "$WRITER_DIR" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-004 — ни один файл skills/writer/ не документирует решение по вложенным .doc-root.yaml-каталогам (FR-067 требует явное решение (а)/(б)/(в), не молчание)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: решение по вложенным .doc-root.yaml задокументировано"
