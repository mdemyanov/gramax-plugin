#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-092-multilanguage-rules.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-092 (FR-178).
# Дизайн: кластер B, строка FR-178 — doc-root-schema.md, новый раздел
#   «Мультиязычность» рядом с language/supportedLanguages; перенос в
#   structure.md ЯВНО ОТКЛОНЁН (правила — уровень каталога, не операции со
#   статьёй). Четыре правила (источник RES-007 §2, docs-пометка): структура
#   папки языка повторяет основную один-в-один; order/properties перевода
#   совпадают с оригиналом; файл перевода без title — непереведён; разделы
#   нельзя называть кодами языков.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   мультиязычность в references/ не описана вообще.
# Уровень: integration.
# Замечание к букве AC-092: формула требования ищет по любому
#   references/*.md; stub сильнее — размещение в doc-root-schema.md по
#   решению дизайна (перенос в structure.md отклонён).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCHEMA_MD="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_grep_regex_i "$SCHEMA_MD" 'мультиязыч' \
  "AC-092 — doc-root-schema.md должен получить раздел «Мультиязычность» (красный на a59db10 — темы нет; перенос в structure.md отклонён дизайном)"
assert_grep_regex_i "$SCHEMA_MD" 'непереведён' \
  "AC-092 — правило «файл перевода без title — непереведён» обязано присутствовать (красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-092: AC-092 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-092: AC-092 — правила мультиязычности в doc-root-schema.md"
