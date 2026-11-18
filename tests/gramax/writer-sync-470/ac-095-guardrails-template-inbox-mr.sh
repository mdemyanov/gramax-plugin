#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-095-guardrails-template-inbox-mr.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-095 (FR-181/FR-182).
# Дизайн: кластер C — SKILL.md Guardrails + staging-чеклист (BR-018):
#   FR-181: hard rule «никогда не правь тело статьи с frontmatter template: <id>»
#   — текст хранится в .gramax/templates/<id>.md, файл статьи тела не содержит;
#   правка допустима только во frontmatter-блоке properties; механизм шаблонов —
#   рядом. Q3 дополняет: правка самого файла шаблона — только отдельная явно
#   запрошенная операция (меняет всех потребителей разом, TemplateProvider.ts:50-71);
#   тело потребителя пусто by design — не «восстанавливать» копированием.
#   FR-182: hard rules — не создавать/не редактировать/не удалять .gramax/inbox/
#   (личные заметки) и .gramax/mr/ (состояние ревью) — обе папки «не редактировать».
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   ни template:, ни .gramax/templates, ни .gramax/inbox, ни .gramax/mr в
#   SKILL.md не упоминаются.
# Уровень: integration.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep "$SKILL_MD" 'template:' \
  "AC-095/FR-181 — hard rule о статьях с frontmatter template: <id> обязан появиться в SKILL.md (красный на a59db10 — не упоминается)"
assert_grep "$SKILL_MD" '.gramax/templates' \
  "AC-095/FR-181 — механизм: тело хранится в .gramax/templates/<id>.md (правка файла — только по явному запросу, Q3; красный на a59db10)"
assert_grep "$SKILL_MD" '.gramax/inbox' \
  "AC-095/FR-182 — hard rule: .gramax/inbox/ (личные заметки пользователей) — не создавать/не редактировать/не удалять (красный на a59db10)"
assert_grep "$SKILL_MD" '.gramax/mr' \
  "AC-095/FR-182 — hard rule: .gramax/mr/ (состояние ревью и согласований) — не создавать/не редактировать/не удалять (красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-095: AC-095 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-095: AC-095 — guardrails template:/templates/inbox/mr в SKILL.md"
