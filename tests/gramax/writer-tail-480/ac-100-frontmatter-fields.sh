#!/usr/bin/env bash
# tests/gramax/writer-tail-480/ac-100-frontmatter-fields.sh
# Требование: docs/30-requirements/2026-11-18-writer-tail-480-requirement.md — AC-100 (FR-186).
# Дизайн: docs/40-architecture/2026-11-18-writer-tail-480-design.md — FR-186, четыре
#   правки SKILL.md: таблица «Дополнительные ключи frontmatter статьи»
#   (description, hidden); новая таблица «Дополнительные ключи _index.md»
#   (expanded, orderAsc); строка-абзац служебных ключей (welcome, external,
#   shouldBeCreated — «пишет движок, агенту не писать»); сопроводительная правка
#   навигационной строки полного справочника.
# Природа: КРАСНАЯ на момент создания. Красный на 894f3fd (2026-11-18): все шесть
#   маркеров в SKILL.md — ноль совпадений (факт 9 требования).
# Уровень: integration (grep по SKILL.md; контракт с QA-author дизайна).
# Edge case дизайна: 'expanded' — цель именно SKILL.md, не blocks.md (там
#   'expanded' — атрибут <cut>, остаётся и не должен гаситься — README, ловушка 2);
#   дизамбигуация с <cut expanded> — ревью-пункт, грепом не дёшево. Поля
#   description/hidden формулой AC не грепаются (слова слишком общие, уже в
#   тексте) — ревью-пункт (README, ловушка 4). Проверяется ONLY SKILL.md —
#   NFR-074: разделы FR-183–FR-185 живут в blocks.md, не в SKILL.md.
# Helper'ы инлайн (копия lib/assert.sh волны writer-sync-470): suite без lib/ и
#   без run.sh по брифу потока — семь скриптов + README, ничего больше.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

FAIL=0

fail() {
  printf '  FAIL: %s\n' "$1" >&2
  FAIL=$((FAIL + 1))
}

pass_msg() { printf '%b[PASS]%b %s\n' '\033[0;32m' '\033[0m' "$1"; }
fail_msg() { printf '%b[FAIL]%b %s\n' '\033[0;31m' '\033[0m' "$1"; }

assert_grep() {
  local file="$1" pattern="$2" msg="$3"
  if ! grep -qF "$pattern" "$file" 2>/dev/null; then
    fail "$msg — не найдено: '$pattern' в $file"
  fi
}

SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

# Формула AC-100 требования (три ключа).
assert_grep "$SKILL_MD" 'orderAsc' \
  "AC-100 — SKILL.md должен документировать ключ orderAsc _index.md (FR-186: false — сортировка статей раздела по убыванию; красный на 894f3fd — ключа нет)"
assert_grep "$SKILL_MD" 'expanded' \
  "AC-100 — SKILL.md должен документировать ключ expanded _index.md (FR-186: свернуть раздел в навигации; красный на 894f3fd — в SKILL.md ключа нет; в blocks.md 'expanded' остаётся атрибутом <cut> — его этот ассерт не трогает)"
assert_grep "$SKILL_MD" 'shouldBeCreated' \
  "AC-100 — SKILL.md должен называть служебный ключ shouldBeCreated (FR-186: пишет движок, агенту не писать; красный на 894f3fd — ключа нет)"

# Design-derived: строка-абзац служебных ключей — welcome и external рядом с
# shouldBeCreated (факт 9 требования: все три не документированы).
assert_grep "$SKILL_MD" 'welcome' \
  "AC-100 — SKILL.md должен называть служебный ключ welcome (FR-186; красный на 894f3fd)"
assert_grep "$SKILL_MD" 'external' \
  "AC-100 — SKILL.md должен называть служебный ключ external (FR-186; красный на 894f3fd)"

# Design-derived: дословная формулировка запрета на служебные ключи.
assert_grep "$SKILL_MD" 'агенту не писать' \
  "AC-100 — SKILL.md обязан нести дословную пометку служебных ключей «агенту не писать» (FR-186/дизайн: «пишет движок — агенту не писать (docs-пометка, RES-007 §4)»; красный на 894f3fd)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-100: AC-100 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-100: AC-100 — frontmatter-поля задокументированы в SKILL.md (orderAsc/expanded/shouldBeCreated + welcome/external, «агенту не писать»)"
