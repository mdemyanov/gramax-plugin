#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-090-gramax-views-storage.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-090 (FR-176).
# Дизайн: кластер B, строка FR-176 — doc-root-schema.md, новый раздел
#   «Служебные папки и файловые следы»: именованные фильтры, переменные и
#   группировка навигации хранятся в каталоге по пути .gramax/views
#   (engine: CatalogViewProvider.ts:26); агент не изобретает собственное место
#   хранения и не удаляет папку.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   путь .gramax/views нигде в дереве writer не упомянут.
# Уровень: integration.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

assert_grep_fixed_recursive "$WRITER_DIR" '.gramax/views' \
  "AC-090 — хранилище представлений каталога .gramax/views обязано быть задокументировано в дереве writer (красный на a59db10 — путь не упоминается)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-090: AC-090 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-090: AC-090 — .gramax/views задокументировано"
