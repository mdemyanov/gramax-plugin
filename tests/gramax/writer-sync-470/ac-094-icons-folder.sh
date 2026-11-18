#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-094-icons-folder.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-094 (FR-180).
# Дизайн: кластер B, строка FR-180 — doc-root-schema.md «Служебные папки и
#   файловые следы» + blocks.md «Иконки»: папка .icons/ рядом с
#   .doc-root.yaml, файл на код — .icons/<код>.svg; коды <icon code="…"/>
#   без префикса lucide- резолвятся против неё (источник RES-007 §2).
#   Граница: офлайн-проверку существования файлов иконок вводит требование
#   паритета валидаторов (там FR-153–FR-155, W035 — ADR-0024 Решение 5);
#   writer отвечает за документацию механизма, не за проверку.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   .icons/ в дереве writer не упомянут (упомянут только Lucide-набор).
# Уровень: integration.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

assert_grep_fixed_recursive "$WRITER_DIR" '.icons/' \
  "AC-094 — механизм собственных SVG-иконок (.icons/<код>.svg рядом с .doc-root.yaml) обязан быть задокументирован (красный на a59db10 — папка не упоминается)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-094: AC-094 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-094: AC-094 — .icons/ задокументировано"
