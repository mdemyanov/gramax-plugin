#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-075-quizzes-reference.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-075 (FR-163).
# Дизайн: кластер A, строка FR-163 + «Состав references/quizzes.md» — NEW файл
#   references/quizzes.md: <question> (id/type/required), <questionAnswer>
#   (answerId/correct; camelCase обязателен), showIf (список answerId — пометка
#   «поверхность GES», в OSS-дереве движка не найден), frontmatter quiz
#   (mode test/survey, showAnswers, canRetake, shuffleQuestions,
#   countOfCorrectAnswers — каждая строка с пометкой источника).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18): файла
#   quizzes.md не существует; вопрос-блоки в writer не упоминаются нигде.
# Уровень: integration.
# NFR-072 (одним изменением с writer): теги question/questionAnswer входят в
#   pairedTags gramax-tags.json (дизайн «Контракт тегов», selfClosing: false в
#   схемах question.ts:8, answer.ts:7). SUBSET-проверка, не равенство —
#   diagramTags/schemaVersion параллельного ADR-0024 не затрагиваются.
# Граница (контракт с QA-author): тест проверяет наличие строк showIf /
#   mode / shuffleQuestions в справочнике, не engine-семантику GES — её в
#   OSS-дереве нет (Q-проб дизайна, открытый вопрос 3).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
QUIZZES_MD="$ROOT/plugins/gramax/skills/writer/references/quizzes.md"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

assert_file_exists "$QUIZZES_MD" \
  "AC-075 — справочник вопрос-блоков references/quizzes.md должен существовать (FR-163; красный на a59db10 — файла нет)"
if [ -f "$QUIZZES_MD" ]; then
  assert_grep "$QUIZZES_MD" 'questionAnswer' \
    "AC-075 — quizzes.md должен документировать тег <questionAnswer> (атрибуты answerId/correct)"
  assert_grep "$QUIZZES_MD" 'showIf' \
    "AC-075 — quizzes.md должен документировать условие показа showIf (список answerId; пометка «поверхность GES»)"
  assert_grep "$QUIZZES_MD" 'countOfCorrectAnswers' \
    "AC-075 — quizzes.md должен документировать frontmatter quiz → countOfCorrectAnswers"
fi

MISSING_PAIRED=$(tags_contract_missing "$TAGS_JSON" pairedTags question questionAnswer)
if [ -n "$MISSING_PAIRED" ]; then
  echo "  FAIL: NFR-072 — pairedTags gramax-tags.json не содержит: $MISSING_PAIRED (одним изменением с writer; красный на a59db10)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-075: AC-075 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-075: AC-075 — references/quizzes.md существует с маркерами questionAnswer/showIf/countOfCorrectAnswers; NFR-072: question/questionAnswer в pairedTags"
