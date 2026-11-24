#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-167-diagram-tag-without-self-closing.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-167 (FR-224)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.3 (детектор
# `_diagram_tag_re` без требования самозакрытия; находка дословно W031, уровень warning,
# ADR-0024 Решение 2), §6.3; ADR-0028 Решение 3 (факт движка: атрибуты читаются из
# открывающего тега в обеих формах — tag.pegjs:19-36, markdocModel.ts:27,
# Healthcheck.ts:238-252 на пине 48592b36).
# Проверка (фикстура с четырьмя статьями): тег парный с битой целью → W031; тег без
#   закрывающего `>` с битой целью → W031; самозакрытая форма с битой целью → W031
#   (контроль неизменности); парная форма с существующей целью → ноль находок.
# Red on 6e2db04: `_diagram_tag_re` требует `/>` — парная и незакрытая формы дают 0
#   находок (слепая зона, замер 2026-11-24 — дизайн §2: «самозакрытый: W031 = 1; парный:
#   0; без закрывающего `>`: 0»); паритетный замок ADR-0024 снят решением 3 (BR-029).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-167-diagram-forms"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

# W031 — warning: rc=0 и сегодня, и после правки; находки судятся по строкам вывода.
assert_exit_zero "$RC" "AC-167: W031 остаётся warning-уровнем (ADR-0024 Решение 2) — rc=0"

w031_for() {
  # Строки W031 конкретной статьи с указанной целью (матчер по реальному выводу
  # валидатора: «WARNING  <путь>  W031: … : "<цель>" → …» — не сравнение голой метки).
  printf '%s\n' "$OUT" | grep "W031" | grep -F "$1" | grep -cF "$2"
}

N_PAIRED=$(w031_for "paired.md" './missing.puml')
if [ "$N_PAIRED" -lt 1 ]; then
  echo "  FAIL: AC-167 RED — парная форма <plant-uml path=\"./missing.puml\">…</plant-uml> даёт 0 находок W031: детектор всё ещё требует самозакрытия (ADR-0028 Решение 3, дизайн §3.3)" >&2
  printf '%s\n' "$OUT" | grep -F "paired.md" >&2
  FAIL=$((FAIL + 1))
fi

N_UNCLOSED=$(w031_for "unclosed.md" './missing.puml')
if [ "$N_UNCLOSED" -lt 1 ]; then
  echo "  FAIL: AC-167 RED — тег без закрывающего угла (ближайший > дальше по статье) даёт 0 находок W031: слепая зона не закрыта (ADR-0028 Решение 3)" >&2
  printf '%s\n' "$OUT" | grep -F "unclosed.md" >&2
  FAIL=$((FAIL + 1))
fi

N_SELFCLOSED=$(w031_for "selfclosed.md" './missing2.puml')
if [ "$N_SELFCLOSED" -lt 1 ]; then
  echo "  FAIL: AC-167 — самозакрытая форма обязана сохранить находку W031 (контроль неизменности прежнего поведения, дизайн §3.3 «находка та же, дословно»)" >&2
  FAIL=$((FAIL + 1))
fi

N_OK=$(printf '%s\n' "$OUT" | grep -cF "paired-ok.md")
if [ "$N_OK" -ne 0 ]; then
  echo "  FAIL: AC-167 — парная форма с существующей целью обязана остаться чистой (0 находок), найдено $N_OK строк: $N_OK" >&2
  printf '%s\n' "$OUT" | grep -F "paired-ok.md" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-167: AC-167 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-167: AC-167 — парная и незакрытая формы дают W031 как самозакрытая, форма с существующей целью чиста"
