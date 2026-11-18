#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-081-image-scale-size-semantics.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-081 (FR-167).
# Дизайн: кластер A, строка FR-167 + Q2 — семантика по вердикту 5 RES-008:
#   width/height — реальные размеры файла в px (резерв места до загрузки,
#   ограничение шириной колонки), НЕ «размер отображения»; scale — ширина на
#   странице: px — абсолютная, число — проценты ширины колонки. Engine-
#   уточнение: в markdown-аннотации {…} плагин применяет только width/height
#   (imgSizePlugin.ts:24-25) — scale документируется атрибутом XML-формы
#   <image scale="…"/> (image.ts:11-22). Q2: <img-h>/<img-v> — включаются
#   (engine-верифицированы), с пометкой unsupported в HTML-фолбэке.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   scale writer не знает; img-h/img-v не упомянуты.
# Уровень: integration.
# Edge case дизайна: дословная фраза «реальный размер» (не «фактический»).
# Ревью-пункт (процессная проверка, НЕ гейт — контракт с QA-author): если Dev
#   задокументирует {scale=…} как рабочую markdown-форму, ни один AC этого не
#   поймает ('scale=' сматчится и на неё) — ревьюер сверяет с engine-фактом
#   imgSizePlugin.ts:24-25 вручную.
# NFR-072: selfClosingTags += img-h, img-v (Q2, одним изменением с writer).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

assert_grep "$BLOCKS_MD" 'scale=' \
  "AC-081 — blocks.md должен документировать scale (ширина на странице: px или проценты ширины колонки; красный на a59db10 — scale writer не знает)"
assert_grep "$BLOCKS_MD" 'реальный размер' \
  "AC-081 — дословная фраза «реальный размер» для width/height (реальные размеры файла в px, резерв места; НЕ «фактический», НЕ «размер отображения» — вердикт 5 RES-008)"
assert_grep "$BLOCKS_MD" 'img-h' \
  "FR-167/Q2, решение SA — парные теги <img-h>/<img-v> включаются в справочник (engine-верифицированы; пометка unsupported в HTML-фолбэке; красный на a59db10)"

MISSING_SC=$(tags_contract_missing "$TAGS_JSON" selfClosingTags img-h img-v)
if [ -n "$MISSING_SC" ]; then
  echo "  FAIL: NFR-072 — selfClosingTags gramax-tags.json не содержит: $MISSING_SC (Q2, одним изменением с writer; красный на a59db10)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-081: AC-081 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-081: AC-081 — scale и «реальный размер» в blocks.md, img-h/img-v включены; NFR-072: img-h/img-v в selfClosingTags"
