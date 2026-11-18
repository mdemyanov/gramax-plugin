#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-056-article-embeds-bpmn-tag.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-056 (FR-143, FR-144).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт
#   тегов (Q-4)» подраздел «<bpmn>»: документированная форма — только файловая,
#   тег `<bpmn path="./<имя>.bpmn"/>`; verify-before-include (оговорка в
#   публичных обещаниях), рендер — ответственность движка (BR-009).
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Литеральна AC-056 (`grep -q '<bpmn path="./' <page>.md`) — на статью после
# живой сессии авторства (qa-runner); статическая половина: SKILL.md обязан
# документировать тег.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"

# Гейт существования — до контентных грейпов: ровно одна красная причина.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-056: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — контракт вставки тега <bpmn> не реализован (красная причина AC-056)"
  exit 1
fi

# --- AC-056/FR-143/FR-144: форма тега ---
assert_grep "$SKILL_MD" '<bpmn path="./' \
  "AC-056 — SKILL.md обязан документировать тег <bpmn path=\"./…\"/> (литераль AC-056)"
assert_grep_regex_i "$SKILL_MD" 'самозакрыва' \
  "AC-056/FR-144 — SKILL.md обязан фиксировать самозакрывающуюся форму тега <bpmn> (FR-144)"

# --- Q-4: только path; обещание рендера — с verify-оговоркой ---
assert_no_grep_regex "$SKILL_MD" '<bpmn[^>]*width=|<bpmn[^>]*height=' \
  "AC-056 (Q-4) — для <bpmn> документирован только path; размеры в каноническую форму не домысливаются"
assert_grep_regex_i "$SKILL_MD" 'не подтвержд|verify|оговорк' \
  "AC-056/Q-4 (verify-before-include) — SKILL.md обязан нести оговорку: рендер тега <bpmn> на проверенном окне движка не подтверждён (дизайн «Контракт тегов»)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-056: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-056: тег <bpmn path=\"./…\"/> документирован (самозакрывающийся, только path, verify-оговорка)"
