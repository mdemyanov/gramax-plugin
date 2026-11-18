#!/usr/bin/env bash
# tests/gramax/export-skill/ac-050-composite-gate.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-050 (композитный).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»:
#   AC-050 — единственный e2e-уровень suite'а, предмет — код возврата композитного гейта.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: предмет suite (plugins/gramax/skills/export/) отсутствует —
#   композитный гейт не принимается до создания навыка (guard против «зелёного
#   впустую»: гейт без предмета suite'а — вакуумный PASS AC-050).
# Уровень: e2e (ADR-0011; дизайн: AC-050 — e2e, остальные — integration).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/export/SKILL.md"

# Гейт существования предмета — до запуска композитного гейта: AC-050 принимает
# дерево, в котором навык уже создан; пока предмета нет, падение обязано называть
# одну причину и не тратить прогон check.sh --fast впустую.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-050: предмет suite отсутствует ($SKILL_MD) — композитный гейт не принимается до создания навыка (красная причина AC-050)"
  exit 1
fi

# AC-050, литерала требования: bash scripts/check.sh --fast → exit=0.
# C10-orphan warning на новый файл допустим (warnings код возврата не поднимают);
# Errors = 0 — ошибки блокирующие во всех ступенях гейта, rc=0 их исключает.
RC=0
OUT="$(bash "$ROOT/scripts/check.sh" --fast 2>&1)" || RC=$?
assert_exit_zero "$RC" \
  "AC-050 — bash scripts/check.sh --fast обязан завершаться кодом 0 (C10-orphan warning на новый файл допустим, Errors = 0)"
if [ "$RC" -ne 0 ]; then
  printf '%s\n' "$OUT" | tail -30 >&2
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-050: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-050: композитный гейт scripts/check.sh --fast зелёный"
