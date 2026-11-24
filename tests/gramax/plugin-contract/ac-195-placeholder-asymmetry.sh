#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-195-placeholder-asymmetry.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-195 (FR-246, карточка gramax-o0q.20; ADR-0012:223-224 требует
#   документации обеих сторон строгости плейсхолдеров).
# Проверка (контракт): документация плагина называет обе стороны строгости и источник истины:
#   (1) plugins/gramax/README.md — абзац «Строгость плейсхолдеров задана неодинаково…»:
#       сторона плагина — «error без условия» (блокирует и без --strict); сторона nauta —
#       validate-content.py, проверка C7, «только предупреждением»; источник истины по
#       строгости nauta — «её собственная документация вне этого репозитория»;
#   (2) README плагина упоминает nauta ненулевое число раз (было 0 — факт 11 требования);
#   (3) plugins/gramax/skills/writer/references/staging.md — предложение о намеренной
#       асимметрии: там (C7) — предупреждение и только для frontmatter; здесь — error без
#       условия.
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — оба текста на месте (замер роли).
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   абзаца/предложения в /tmp-копиях — соответствующий grep теряет литерал; замена слова
#   «nauta» в README обнуляет счётчик ноги 2.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
README="$ROOT/plugins/gramax/README.md"
STAGING="$ROOT/plugins/gramax/skills/writer/references/staging.md"

assert_file_exists "$README" "AC-195: plugins/gramax/README.md на месте"
assert_file_exists "$STAGING" "AC-195: skills/writer/references/staging.md на месте"

# --- Нога 1: README называет обе стороны и источник истины ---
assert_grep "$README" 'Строгость плейсхолдеров задана неодинаково, и это намеренно (ADR-0012, Решение 2)' \
  "AC-195: README вводит абзац о намеренной неодинаковости строгости (ADR-0012, Решение 2)"
assert_grep "$README" 'выдаёт error без условия' \
  "AC-195: сторона плагина названа — error без условия (коммит блокирует и без --strict)"
assert_grep "$README" 'Контур nauta проверяет плейсхолдеры своим validate-content.py' \
  "AC-195: сторона nauta названа с именем прибора — validate-content.py"
assert_grep "$README" '(проверка C7)' \
  "AC-195: сторона nauta названа с классом проверки — C7"
assert_grep "$README" 'только предупреждением' \
  "AC-195: сторона nauta названа с уровнем — только предупреждение"
assert_grep "$README" 'собственная документация вне этого репозитория' \
  "AC-195: источник истины по строгости nauta — вне этого репозитория"

# --- Нога 2: nauta упомянут в README плагина (было 0 упоминаний — факт 11) ---
NAUTA_MENTIONS="$(grep -ci nauta "$README" || true)"
if [ "${NAUTA_MENTIONS:-0}" -gt 0 ]; then
  :
else
  echo "  FAIL: AC-195 — plugins/gramax/README.md не упоминает контур nauta (замер: 0)" >&2
  echo "  (AC-195 требует ненулевой счёт grep -ci nauta — README перестаёт молчать о" >&2
  echo "  стороне nauta, факт 11 требования)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 3: staging.md несёт предложение об асимметрии ---
assert_grep "$STAGING" 'Строгость плейсхолдеров — намеренная асимметрия с контуром nauta' \
  "AC-195: staging.md называет асимметрию намеренной и называет контур nauta"
assert_grep "$STAGING" 'предупреждение и только для frontmatter; здесь — error без условия' \
  "AC-195: staging.md несёт обе стороны: там предупреждение (frontmatter), здесь error без условия"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-195: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-195: README и staging.md называют обе стороны строгости плейсхолдеров (плагин — error, nauta — C7 warning) и источник истины вне репозитория"
