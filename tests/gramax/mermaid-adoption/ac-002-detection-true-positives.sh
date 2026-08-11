#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-002-detection-true-positives.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-002
#   (FR-054, FR-056).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 3.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_mermaid.py — DEV-003, не начат;
#   uv run на несуществующий файл завершается ненулевым кодом, вывод не содержит ожидаемых
#   строк — тест падает по правильной причине).
#
# Контракт вывода (FR-056 «путь файла и номер строки») — QA-author предполагает grep/rg-подобный
# формат `<путь>:<строка>` как ближайшую естественную реализацию; ассерты ищут подстроку
# `<имя файла>:<число>` где угодно в stdout, не привязываясь к абсолютности/относительности
# пути. Если реальный формат Dev расходится — поправьте regex вместе с обоснованием (прецедент
# AC-014, content/60-implementation/acceptance/2026-08-11-validation-contract-at-design.md),
# не убирайте ассерт молча.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" 2>&1)

if ! echo "$OUT" | grep -qE 'legacy-fenced\.md:[0-9]+'; then
  echo "  FAIL: AC-002 — отчёт не называет content/legacy-fenced.md:<номер строки> (fenced \`\`\`mermaid блок не обнаружен)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qE 'legacy-paired\.md:[0-9]+'; then
  echo "  FAIL: AC-002 — отчёт не называет content/legacy-paired.md:<номер строки> (<mermaid>…</mermaid> блок не обнаружен)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: оба легаси-вхождения обнаружены с указанием строки"
