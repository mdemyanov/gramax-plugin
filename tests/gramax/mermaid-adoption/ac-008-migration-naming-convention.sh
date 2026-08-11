#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-008-migration-naming-convention.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-008
#   (FR-060).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 4 —
#   «переиспользуется fallback-слаг `existing` из ADR-0010 Решение 3
#   (<page-slug>-existing.mermaid) — у batch-прогона нет пользовательской темы». Это
#   архитектурный закон ADR (Accepted), не деталь реализации на усмотрение Dev — тест вправе
#   сверять точное имя файла, не только паттерн.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_mermaid.py — DEV-003, не
#   начат; файлы не создаются — оба assert_file_exists ниже падают).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_mermaid.py "$WORKDIR" --fix --yes 2>&1)

assert_file_exists "$WORKDIR/content/legacy-fenced-existing.mermaid" \
  "AC-008 — legacy-fenced.md должен получить content/legacy-fenced-existing.mermaid (<page-slug>-existing.mermaid, ADR-0013 Решение 4) рядом со статьёй-источником"
assert_file_exists "$WORKDIR/content/legacy-paired-existing.mermaid" \
  "AC-008 — legacy-paired.md должен получить content/legacy-paired-existing.mermaid рядом со статьёй-источником"

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод миграции ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: конвенция именования <page-slug>-existing.mermaid соблюдена"
