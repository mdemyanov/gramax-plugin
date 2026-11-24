#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-196-admonition-rewrite-caveat.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-196 (FR-247, карточка gramax-o0q.23).
# Сюита: writer-sync-470 — владелец контента скилла writer (SKILL.md и references/*.md,
#   cf. ac-077, пиннящий legacy-оговорку «редактор переписывает при сохранении» у <cut> в
#   том же blocks.md; оговорка AC-196 пишется по её образцу).
# Проверка (контракт):
#   (1) references/blocks.md при описании формы `:::` несёт оговорку rewrite-on-save
#       («legacy: движок читает её, но редактор переписывает её при сохранении») и
#       ограничение формы каталогами Legacy/GFM;
#   (2) SKILL.md в перечислении admonitions говорит то же («:::info — legacy: редактор
#       переписывает её при сохранении»).
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — обе оговорки на месте (замер роли;
#   до волны их не было — факт 12 требования).
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   оговорки из /tmp-копии blocks.md или предложения из /tmp-копии SKILL.md — grep теряет
#   литерал.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
SKILL="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_file_exists "$BLOCKS" "AC-196: references/blocks.md на месте"
assert_file_exists "$SKILL" "AC-196: skills/writer/SKILL.md на месте"

# --- Нога 1: blocks.md — оговорка rewrite-on-save и ограничение Legacy/GFM ---
# shellcheck disable=SC2016  # бэктики — дословный литерал markdown из blocks.md
assert_grep "$BLOCKS" 'Форма `:::` — legacy: движок читает её, но редактор переписывает её при сохранении' \
  "AC-196: blocks.md несёт оговорку rewrite-on-save у формы ::: (по образцу оговорки <cut>)"
# shellcheck disable=SC2016  # бэктики — дословный литерал markdown из blocks.md
assert_grep "$BLOCKS" 'Форма `:::` — для синтаксиса `Legacy` и `GitHub Flavored Markdown`' \
  "AC-196: blocks.md держит ограничение формы ::: каталогами Legacy/GFM"
assert_grep "$BLOCKS" 'в новом контенте использовать каноническую форму' \
  "AC-196: blocks.md уводит новый контент на каноническую форму <note>"

# --- Нога 2: SKILL.md — то же в перечислении admonitions ---
# shellcheck disable=SC2016  # бэктики — дословный литерал markdown из SKILL.md
assert_grep "$SKILL" 'markdown-admonitions `:::info` — legacy: редактор переписывает её при сохранении' \
  "AC-196: SKILL.md в перечислении admonitions говорит то же об :::info (rewrite-on-save)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-196: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-196: оговорка rewrite-on-save у ::: в blocks.md (с ограничением Legacy/GFM) и то же предложение в SKILL.md на месте"
