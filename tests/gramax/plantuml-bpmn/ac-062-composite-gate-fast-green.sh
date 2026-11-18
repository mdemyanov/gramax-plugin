#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-062-composite-gate-fast-green.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-062 (NFR-064).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт с
#   QA-author»: AC-062 — единственный e2e-уровень suite'а, предмет — код
#   возврата композитного гейта.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: предмет suite (plugins/gramax/skills/plantuml/)
#   отсутствует — композитный гейт не принимается до создания навыка (guard
#   против «зелёного впустую»: гейт без предмета suite'а — вакуумный PASS
#   AC-062; прецедент — ac-050 suite'а export-skill). Контракт — спецификация,
#   не описание текущего кода.
# Уровень: e2e (ADR-0011; дизайн: AC-062 — e2e, остальные — integration).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"

# Гейт существования предмета — до запуска композитного гейта: AC-062 принимает
# дерево, в котором навык уже создан; пока предмета нет, падение обязано
# называть одну причину и не тратить прогон check.sh --fast впустую (параллельные
# потоки держат дерево транзитно красным — их ошибки не предмет этого suite'а).
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-062: предмет suite отсутствует ($SKILL_MD) — композитный гейт не принимается до создания навыка (красная причина AC-062)"
  exit 1
fi

# AC-062, литерала требования: bash scripts/check.sh --fast → exit=0.
# C10-orphan warning на новый файл допустим (warnings код возврата не поднимают);
# Errors = 0 — ошибки блокирующие во всех ступенях гейта, rc=0 их исключает.
RC=0
OUT="$(bash "$ROOT/scripts/check.sh" --fast 2>&1)" || RC=$?
assert_exit_zero "$RC" \
  "AC-062 — bash scripts/check.sh --fast обязан завершаться кодом 0 (C10-orphan warning на новый файл допустим, Errors = 0)"
if [ "$RC" -ne 0 ]; then
  printf '%s\n' "$OUT" | tail -30 >&2
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-062: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-062: композитный гейт scripts/check.sh --fast зелёный"
