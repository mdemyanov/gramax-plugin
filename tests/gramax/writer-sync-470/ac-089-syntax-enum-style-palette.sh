#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-089-syntax-enum-style-palette.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-089 (FR-175).
# Дизайн: кластер B, строка FR-175 + Q1а/Q1г — три расхождения с явной пометкой
#   источника каждого значения (молчаливая замена запрещена):
#   (а) enum syntax — ровно три значения движка XML / Legacy / GitHub Flavored
#       Markdown (Syntax.ts:1-6); значение Markdown из writer 4.6.0 в движке не
#       существует — пометка «трактуется как Legacy» (NFR-071, не молча);
#   (б) палитра style — 20 значений enum движка, включая двухцветные
#       (blue-pink, orange-red, … — Style.ts:1-22); бывшие 11 writer —
#       legacy-строкой, 6 значений вне enum — «не использовать в новом контенте»;
#   (в) filterProperty — см. ac-088.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   doc-root-schema.md перечисляет syntax: XML|Markdown и палитру из 11 значений
#   без двухцветных.
# Уровень: integration.
# Edge case дизайна: значения-источники несут пометки (engine путь:строка /
#   docs / writer-практика) — формулируются Dev, байтовых маркеров на пометки
#   нет (кроме самих значений enum).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCHEMA_MD="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_grep "$SCHEMA_MD" 'GitHub Flavored Markdown' \
  "AC-089 — enum syntax обязан содержать значение движка GitHub Flavored Markdown (Q1а; красный на a59db10 — перечислены XML/Markdown)"
assert_grep_regex "$SCHEMA_MD" 'blue-pink|orange-red' \
  "AC-089 — палитра style расширена до 20 значений enum движка, включая двухцветные (Q1г; красный на a59db10 — палитра из 11 значений)"
assert_grep "$SCHEMA_MD" 'Legacy' \
  "FR-175(а) — второе значение enum syntax — Legacy (Q1а: неизвестное значение молча падает в Legacy-форматтер; красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-089: AC-089 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-089: AC-089 — enum syntax из трёх значений движка и двухцветная палитра в doc-root-schema.md"
