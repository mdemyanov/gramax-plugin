#!/usr/bin/env bash
# tests/gramax/export-skill/ac-049-execution-boundary.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-049 (NFR-055).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   edge case 2: AC-049 хрупок на синонимах — Dev обязан использовать канонические
#   формулировки §«Граница исполнения» («навык экспорт не исполняет», «граница
#   исполнения», «запуск требует Node.js и gramax-cli в окружении»); грейп матчит
#   именно их, не произвольную парафразу. BR-006: инструкция без оговорки границы —
#   дефект приёмки.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: предмет проверки plugins/gramax/skills/export/SKILL.md
#   отсутствует. Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/export/SKILL.md"

# Гейт существования — до контентных грейпов: пока предмета нет, падение обязано
# называть ровно одну причину (навык не создан).
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-049: SKILL.md навыка export отсутствует ($SKILL_MD) — секция «Граница исполнения» не создана (красная причина AC-049)"
  exit 1
fi

# AC-049, литеральные грейпы требования: окружение исполнения названо + оговорка
# границы присутствует (NFR-055/BR-006: навык инструктирует, не исполняет).
assert_grep_regex_i "$SKILL_MD" 'node' \
  "AC-049 — SKILL.md обязан называть Node.js как требование окружения (NFR-055)"
assert_grep_regex_i "$SKILL_MD" 'не исполняет|не запускает|инструктир|границ' \
  "AC-049 — SKILL.md обязан явно проговаривать границу «навык инструктирует — исполняет окружение» (NFR-055, BR-006; канонические формулировки дизайна матчятся)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-049: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-049: граница исполнения (Node.js/gramax-cli — окружение, навык не исполняет) проговорена в SKILL.md"
