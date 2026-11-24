#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-197-record-pointer-convention.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-197 (FR-248, карточка gramax-o0q.24; соглашение FR-088 контракта
#   формы ссылки — docs/30-requirements/2026-08-13-link-form-contract.md).
# Сюита: writer-sync-470 — владелец контента скилла writer: предмет стаба — текст SKILL.md
#   writer (публикация соглашения), не механика миграции nav-спанов (предмет
#   link-form-migration); прецедент пина прозы SKILL.md в этой сюите — ac-006/ac-087.
# Проверка (контракт): SKILL.md writer публикует соглашение RECORD/POINTER —
#   (1) оба слова с определениями: RECORD («на HEAD=<хэш/дата> было верно») и
#       POINTER («сейчас верно»);
#   (2) правило по умолчанию: формулировка в настоящем времени без явной пометки RECORD
#       трактуется как POINTER.
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — публикация на месте (замер роли;
#   до волны grep -rniE 'RECORD|POINTER' plugins/gramax/skills/ давал 0 — факт 13).
# Мутация к красному (показана в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   правила по умолчанию из /tmp-копии SKILL.md — grep теряет литерал.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_file_exists "$SKILL" "AC-197: skills/writer/SKILL.md на месте"

# --- Нога 1: оба режима названы с определениями ---
# shellcheck disable=SC2016  # бэктики — дословный литерал markdown из SKILL.md
assert_grep "$SKILL" 'Цитата вида `путь:строка` — режим RECORD или POINTER (FR-088)' \
  "AC-197: SKILL.md публикует соглашение RECORD/POINTER (FR-088) для цитат путь:строка"
# Литералы без ведущего «-»: паттерн, начинающийся с тире, grep разбирает как опции.
assert_grep "$SKILL" '**RECORD** — «на HEAD=<хэш/дата> было верно»' \
  "AC-197: RECORD определён (прошедшее время, факт истории, с зафиксированным HEAD)"
assert_grep "$SKILL" '**POINTER** — «сейчас верно»' \
  "AC-197: POINTER определён (настоящее время, требует периодической ревалидации)"

# --- Нога 2: правило умолчания — настоящее время без пометки = POINTER ---
assert_grep "$SKILL" 'Формулировка в настоящем времени без явной пометки RECORD трактуется как POINTER' \
  "AC-197: правило умолчания — немаркированная цитата в настоящем времени читается как POINTER"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-197: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-197: SKILL.md публикует RECORD/POINTER (FR-088) с правилом умолчания POINTER для немаркированного настоящего времени"
