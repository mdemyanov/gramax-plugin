#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-146-root-texts.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-146 (FR-221б)
# Задача: gramax-o0q.10; грамотные якоря README выведены из ADR-0008 (Решения 4/6, AC-009,
#   RISK-001/002) и RES-001 (docs/10-domain/research/2026-05-11-drawio-skill-external.md,
#   раздел «Prerequisites (точный список)» и «Триггеры»).
# Проверка (контракт): CLAUDE.md называет все 7 навыков и агента в строке состава плагина;
#   несёт никакого «v0.3.1»; описание --full называет оба своих валидатора и число сюит (17);
#   сумма строк CLAUDE.md + AGENTS.md в пороге 550 (.nauta-gates.yaml, C14);
#   корневой README несёт блок предусловий drawio (ADR-0008/RES-001) и предупреждение
#   о конфликте триггеров с mermaid.
# Цвет на 7553da1: КРАСНЫЙ — в строке состава нет plantuml/export; ref «v0.3.1» на месте;
#   описание --full называет два сюита; README без якорей предусловий и без предупреждения.
# Ноги «сумма строк в пороге» и «агент в составе» зелёные с рождения — регресс-охрана
# (расширение текста под AC-146 не должно вывести CLAUDE.md+AGENTS.md за порог C14).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CLAUDE_MD="$ROOT/CLAUDE.md"
AGENTS_MD="$ROOT/AGENTS.md"
README="$ROOT/README.md"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CLAUDE_MD" "AC-146: CLAUDE.md на месте"
assert_file_exists "$AGENTS_MD" "AC-146: AGENTS.md на месте"
assert_file_exists "$README" "AC-146: README.md на месте"

# --- Нога 1: строка состава плагина называет все 7 навыков + агента ---
COMPOSITION="$(grep -F 'plugins/gramax/' "$CLAUDE_MD" || true)"
for NAME in writer comments-read comments-write mermaid plantuml drawio export review-agent; do
  if printf '%s\n' "$COMPOSITION" | grep -qF "$NAME"; then
    :
  else
    echo "  FAIL: AC-146 — строки состава plugins/gramax/ в CLAUDE.md не называют «${NAME}»" >&2
    echo "  (в плагине 7 навыков и агент: writer, comments-read, comments-write, mermaid," >&2
    echo "  plantuml, drawio, export + review-agent — gramax-o0q.10)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- Нога 2: устаревшего пина «v0.3.1» нет (установлен nauta 2.27.0) ---
assert_no_grep "$CLAUDE_MD" 'v0.3.1' \
  "AC-146: CLAUDE.md не несёт устаревший пин v0.3.1 (ref nauta актуален, gramax-o0q.10)"

# --- Нога 3: описание --full называет оба своих валидатора и число сюит (17) ---
FULL_BLOCK="$(awk '/check\.sh --full/ { show = 1 } show { print; n++ } n >= 6 { exit }' "$CLAUDE_MD")"
for ANCHOR in validate_structure.py validate_comments.py; do
  if printf '%s\n' "$FULL_BLOCK" | grep -qF "$ANCHOR"; then
    :
  else
    echo "  FAIL: AC-146 — описание --full в CLAUDE.md не называет ${ANCHOR}" >&2
    echo "  (FR-220б: оба валидатора входят в --full с порогом 0 ERROR, ADR-0027 Решение 4)" >&2
    FAIL=$((FAIL + 1))
  fi
done
if printf '%s\n' "$FULL_BLOCK" | grep -qE '(^|[^0-9])17([^0-9]|$)'; then
  :
else
  echo "  FAIL: AC-146 — описание --full в CLAUDE.md не называет фактическое число сюит (17)" >&2
  echo "  (16 сюит по ADR-0027 + настоящая сюита последним шагом — поправка PM)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 4: порог C14 (promptLayerSizeBudget, 550 строк) не нарушен ---
LINES_CLAUDE="$(wc -l < "$CLAUDE_MD" | tr -d ' ')"
LINES_AGENTS="$(wc -l < "$AGENTS_MD" | tr -d ' ')"
TOTAL_LINES=$((LINES_CLAUDE + LINES_AGENTS))
if [ "$TOTAL_LINES" -gt 550 ]; then
  echo "  FAIL: AC-146 — сумма строк CLAUDE.md (${LINES_CLAUDE}) + AGENTS.md (${LINES_AGENTS})" >&2
  echo "  = ${TOTAL_LINES} превышает порог 550 строк (.nauta-gates.yaml, promptLayerSizeBudget)" >&2
  FAIL=$((FAIL + 1))
fi

# --- Нога 5: README — якоря блока предусловий drawio (ADR-0008/RES-001) ---
for ANCHOR in 'Agents365-ai/365-skills' 'xvfb' 'Python 3'; do
  if grep -qF "$ANCHOR" "$README"; then
    :
  else
    echo "  FAIL: AC-146 — README.md не несёт якорь предусловий «${ANCHOR}»" >&2
    echo "  (ADR-0008 AC-009/RISK-001/RISK-002 + RES-001 «Prerequisites (точный список)»;" >&2
    echo "  якоря перечислены в docs/60-implementation/acceptance/2026-11-23-wave3-gates-at-design.md)" >&2
    FAIL=$((FAIL + 1))
  fi
done
# --- Нога 6: предупреждение о конфликте триггеров mermaid vs drawio-skill ---
if grep -iE 'gramax:mermaid.*конфликт|конфликт.*gramax:mermaid' "$README" > /dev/null; then
  :
else
  echo "  FAIL: AC-146 — README.md не предупреждает о конфликте триггеров gramax:mermaid" >&2
  echo "  и внешнего drawio-skill (ADR-0008 Решение 6 WARNING; RES-001 «Конфликт триггеров»)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-146: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-146: CLAUDE.md называет 7 навыков + агента, без v0.3.1, --full = 2 валидатора + 17 сюит, порог C14 цел; README несёт предусловия ADR-0008/RES-001 и предупреждение о конфликте триггеров"
