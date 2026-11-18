#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-078-view-defs-hiding-rewrite.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-078 (FR-165).
# Дизайн: кластер A, строка FR-165 + «Переписанный раздел <view>» — переписать
#   ОБА места (SKILL.md «Дашборды через view» и blocks.md «Дашборды») по
#   вердикту 3 RES-008. Семантика defs — СОКРЫТИЕ: перечисленные значения
#   исключают статьи из выборки; none — только статьи, у которых свойство есть;
#   yes — только статьи без него; orderby (свойство=v1&v2 или голое имя);
#   select (перечень колонок); display = List/Table/Kanban, дефолт List;
#   иерархия — записью системного свойства в defs (defs="hierarchy=child-to-current"),
#   НЕ атрибутом тега. Целевая таблица дизайна — «оба файла, формулировки Dev —
#   матчи AC-078: слово «скрыт…»».
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   writer 4.6.0 знает только defs/groupby/display="List", семантика defs
#   перевёрнута («фильтр отбора», none как «и статьи без значения»).
# Уровень: integration.
# Негатив (NFR-071, не молча): старый пример с перевёрнутой семантикой
#   defs="Тип контента=ADR&Архитектура&none" заменяется; заметка «прежняя
#   формулировка writer 4.6.0 была обратной реальному поведению» — прозой,
#   без воспроизведения литеральной формы (паттерн AC-079). Байтовый негатив
#   на литерал старого примера — два живых вхождения на a59db10.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

assert_grep "$BLOCKS_MD" 'orderby' \
  "AC-078 — blocks.md должен документировать атрибут orderby (сортировка: свойство=v1&v2 или голое имя; красный на a59db10 — атрибута нет)"
assert_grep "$BLOCKS_MD" 'Kanban' \
  "AC-078 — blocks.md должен документировать display=Table/Kanban (дефолт List; красный на a59db10 — только List)"
assert_grep_regex_i "$BLOCKS_MD" 'скрыт' \
  "AC-078 — blocks.md должен называть семантику defs сокрытием («скрыт…» в любой форме — маркер формулы AC-078 и вердикта 3 RES-008)"
assert_grep "$BLOCKS_MD" 'select=' \
  "FR-165(в), дизайн — blocks.md должен документировать атрибут select (перечень показываемых колонок свойств)"
assert_grep "$BLOCKS_MD" 'hierarchy=child-to-current' \
  "FR-165(д), дизайн — иерархическая выборка задаётся записью defs=\"hierarchy=child-to-current\", не атрибутом тега"
assert_grep "$SKILL_MD" 'orderby' \
  "FR-165, дизайн («оба файла») — SKILL.md раздел «Дашборды через view» тоже переписывается по вердикту 3"

assert_no_grep_fixed_recursive "$WRITER_DIR" 'Тип контента=ADR&Архитектура&none' \
  "FR-165/NFR-071 — старый пример с перевёрнутой семантикой defs заменён (заметка о прежней формулировке — прозой, без литеральной формы; на a59db10 — 2 вхождения в SKILL.md и blocks.md)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-078: AC-078 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-078: AC-078 — <view> переписан: defs-сокрытие, orderby/select/Kanban, hierarchy в defs; старый пример удалён"
