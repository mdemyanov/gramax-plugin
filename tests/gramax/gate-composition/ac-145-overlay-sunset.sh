#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-145-overlay-sunset.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-145 (FR-220в)
# Решение: docs/00-project/adr/0027-full-gate-composition.md, Решение 6 — мёртвый
#   overlay-тулинг удаляется (переключение на templates/overlays/ отклонено: профилей нет,
#   scripts/init.sh не существовал).
# Проверка (контракт): пять файлов (apply-overlay.sh и четыре хелпера) отсутствуют;
#   tests/gramax/orphan-references/sunset-registry.txt несёт все пять якорных шаблонов
#   дословно (путь или вызов, не голое слово — форма ADR-0011 Решение 3).
# Цвет на 7553da1: КРАСНЫЙ — все пять файлов в scripts/ ещё на месте; записей реестра нет.
# Нога «запись ночного отчёта исправлена или помечена» — процедурная, владелец PM
# (N/A для стаба, см. at-design).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
REGISTRY="$ROOT/tests/gramax/orphan-references/sunset-registry.txt"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- Нога 1: пять файлов удалены (ADR-0027 Решение 6) ---
assert_file_not_exists "$ROOT/scripts/apply-overlay.sh" \
  "AC-145: scripts/apply-overlay.sh удалён"
assert_file_not_exists "$ROOT/scripts/_init_helpers.py" \
  "AC-145: scripts/_init_helpers.py удалён"
assert_file_not_exists "$ROOT/scripts/_resolve_agents.py" \
  "AC-145: scripts/_resolve_agents.py удалён"
assert_file_not_exists "$ROOT/scripts/_apply_profile.py" \
  "AC-145: scripts/_apply_profile.py удалён"
assert_file_not_exists "$ROOT/scripts/_apply_yaml_patch.py" \
  "AC-145: scripts/_apply_yaml_patch.py удалён"

# --- Нога 2: sunset-registry несёт пять якорных шаблонов дословно ---
assert_file_exists "$REGISTRY" "AC-145: sunset-registry.txt на месте"
if [ -f "$REGISTRY" ]; then
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if grep -qF "$pattern" "$REGISTRY"; then
      :
    else
      echo "  FAIL: AC-145 — в sunset-registry.txt нет дословного шаблона: ${pattern}" >&2
      echo "  (якорь — путь или вызов, не голое слово; голое имя задевает комментарии payload," >&2
      echo "  см. уточнение SA в gramax-o0q.9 и форму ADR-0011 Решение 3)" >&2
      FAIL=$((FAIL + 1))
    fi
  done <<'PATTERNS'
scripts/apply-overlay\.sh
scripts/_init_helpers\.py|(from|import) _init_helpers([^a-zA-Z0-9_]|$)
scripts/_resolve_agents\.py|(from|import) _resolve_agents([^a-zA-Z0-9_]|$)
scripts/_apply_profile\.py|(from|import) _apply_profile([^a-zA-Z0-9_]|$)
scripts/_apply_yaml_patch\.py|(from|import) _apply_yaml_patch([^a-zA-Z0-9_]|$)
PATTERNS
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-145: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-145: пять файлов overlay-тулинга удалены; sunset-registry несёт пять якорных шаблонов дословно"
