#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-082-video-hostings-cover-negative.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-082 (FR-168).
# Дизайн: кластер A, строка FR-168 + Q4 — хостинги Dropbox и Mega (к семи
#   известным: youtube/youtu.be/drive.google/mega.nz/rutube/dropbox/instagram —
#   список это гейт пути вставки, isVideoSupported.ts:1-12); embed-правило
#   рендера: внешний URL с подстрокой embed отдаётся в iframe как есть
#   (RenderVideo.tsx:163-166) — способ для хостингов вне списка семи.
#   Атрибуты title и scale — engine-верифицированы (video.ts:12-16).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   Dropbox/Mega/cover/embed в blocks.md не упоминаются.
# Уровень: integration.
# НЕГАТИВ AC-079-типа про cover (бриф: «AC-079 negative cover-expectation»,
#   дизайн Q4 по образцу AC-079): атрибут cover в движке на пине ОТСУТСТВУЕТ —
#   документируется ТОЛЬКО негативной пометкой («атрибут обложки, названный в
#   docs, в движке не найден — не использовать в новом контенте»), слово cover
#   в пометке есть (иначе AC-082 не сматчится), литеральная ФОРМА атрибута
#   cover= — не воспроизводится. Warden: 'cover=' отсутствует в дереве writer
#   (зелёный на a59db10) — ловит случайный «рабочий пример» cover.
# Edge case дизайна: позитивный grep 'cover' не различает позитивное и
#   негативное употребление — ревьюер сверяет смысл вручную (в шапке и README).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

assert_grep_regex_i "$BLOCKS_MD" 'dropbox' \
  "AC-082 — blocks.md должен пополниться хостингом Dropbox (красный на a59db10 — не упоминается)"
assert_grep_regex_i "$BLOCKS_MD" 'mega' \
  "AC-082 — blocks.md должен пополниться хостингом Mega (mega.nz; красный на a59db10)"
assert_grep_regex_i "$BLOCKS_MD" 'cover' \
  "AC-082 — слово cover обязано присутствовать в blocks.md КАК НЕГАТИВНАЯ пометка Q4 («в движке на пине не найден — не использовать в новом контенте»); красный на a59db10"
assert_grep_regex_i "$BLOCKS_MD" 'embed' \
  "FR-168/Q4 — embed-правило рендера: внешний URL с подстрокой embed рендерится iframe как есть (хостинги вне списка семи; красный на a59db10)"

assert_no_grep_fixed_recursive "$WRITER_DIR" 'cover=' \
  "AC-082/Q4 warden — литеральная форма атрибута cover= не воспроизводится нигде в дереве writer: атрибута в движке нет, документируется только негативной прозой с голым словом cover (зелёный warden на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-082: AC-082 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-082: AC-082 — Dropbox/Mega/embed задокументированы, cover — негативной пометкой без литеральной формы"
