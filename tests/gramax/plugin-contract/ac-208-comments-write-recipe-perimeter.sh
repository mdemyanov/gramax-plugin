#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-208-comments-write-recipe-perimeter.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-208 (FR-256, карточка gramax-o0q.37, D9; ADR-0030 Решение 3 —
#   G11 закрывается рецептом: validate_comments.py в цикле коммита).
# Проверка (контракт):
#   (1) plugins/gramax/skills/comments-write/SKILL.md несёт подраздел «В каталоге и в цикле
#       коммита» с обеими командами дословного рецепта ADR-0030 Решение 3 — по каталогу
#       (uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py content) и строка для
#       скопированного pre-commit-хука (… "$CONTENT_DIR");
#   (2) plugins/gramax/README.md несёт строку-указатель на рецепт (дом обнаружимости —
#       ADR-0012 Решение 4; «одна строка-указатель, не копия рецепта»);
#   (3) периметр плагина не менялся (D9): семь каталогов навыков и review-agent на месте.
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД.
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   заголовка подраздела или одной из команд в /tmp-копии SKILL.md / строки-указателя в
#   /tmp-копии README — соответствующий grep теряет литерал; изъятие каталога навыка красит
#   ногу периметра.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL="$ROOT/plugins/gramax/skills/comments-write/SKILL.md"
README="$ROOT/plugins/gramax/README.md"
SKILLS_DIR="$ROOT/plugins/gramax/skills"

assert_file_exists "$SKILL" "AC-208: skills/comments-write/SKILL.md на месте"
assert_file_exists "$README" "AC-208: plugins/gramax/README.md на месте"

# --- Нога 1: рецепт в SKILL.md — подраздел и обе команды ADR-0030 Решение 3 ---
assert_grep "$SKILL" '### В каталоге и в цикле коммита' \
  "AC-208: SKILL.md comments-write несёт подраздел «В каталоге и в цикле коммита» (ADR-0030 Решение 3, дом рецепта)"
# shellcheck disable=SC2016  # ${CLAUDE_PLUGIN_ROOT} — дословный литерал команды рецепта ADR-0030
assert_grep "$SKILL" 'uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py content' \
  "AC-208: команда по каталогу (первая команда рецепта)"
# shellcheck disable=SC2016  # ${...} — дословный литерал строки хука рецепта ADR-0030
assert_grep "$SKILL" 'uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py" "$CONTENT_DIR"' \
  "AC-208: строка для pre-commit-хука со скопированным шаблоном (вторая команда рецепта)"

# --- Нога 2: строка-указатель в README плагина ---
assert_grep "$README" 'Комментарии эти валидаторы не проверяют: команда по каталогу и способ включения в хук — в' \
  "AC-208: README несёт строку-указатель на рецепт (дом обнаружимости, ADR-0012 Решение 4)"
assert_grep "$README" 'skills/comments-write/SKILL.md`, раздел «В каталоге и в цикле коммита»' \
  "AC-208: указатель называет дом и раздел рецепта поимённо"

# --- Нога 3: периметр плагина не менялся (D9) ---
for SKILL_DIR in writer comments-read comments-write mermaid plantuml drawio export; do
  assert_dir_exists "$SKILLS_DIR/$SKILL_DIR" \
    "AC-208: периметр D9 — каталог навыка ${SKILL_DIR} на месте"
done
assert_file_exists "$ROOT/plugins/gramax/agents/review-agent.md" \
  "AC-208: периметр D9 — agents/review-agent.md на месте"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-208: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-208: рецепт validate_comments.py в SKILL.md и указатель в README на месте, периметр D9 (7 навыков + review-agent) неизменен"
