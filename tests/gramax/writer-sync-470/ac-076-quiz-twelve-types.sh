#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-076-quiz-twelve-types.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-076 (FR-163).
# Формула требования намеренно маркирует ПОЛНОТУ перечня редчайшими типами:
#   ranking и matrix. Полный перечень из 12 (one, many, select, text, date,
#   user, number, slider, scale, rating, ranking, matrix) — источник docs
#   (RES-007 §3); engine-пометка дизайна обязательна: парсер принимает любую
#   строку type без enum-валидации, OSS-рендер на пине покрывает one/many/text,
#   полный набор — поверхность модуля обучения GES.
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   references/quizzes.md не существует (маркерам не где жить).
# Уровень: integration.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
QUIZZES_MD="$ROOT/plugins/gramax/skills/writer/references/quizzes.md"

assert_file_exists "$QUIZZES_MD" \
  "AC-076 — маркеры полноты перечня типов живут в references/quizzes.md (зависимость от AC-075; красный на a59db10 — файла нет)"
if [ -f "$QUIZZES_MD" ]; then
  assert_grep "$QUIZZES_MD" 'ranking' \
    "AC-076 — редчайший тип ranking обязан присутствовать (маркер полного перечня 12 типов)"
  assert_grep "$QUIZZES_MD" 'matrix' \
    "AC-076 — редчайший тип matrix обязан присутствовать (маркер полного перечня 12 типов)"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-076: AC-076 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-076: AC-076 — перечень типов quizzes.md доведён до редчайших ranking/matrix"
