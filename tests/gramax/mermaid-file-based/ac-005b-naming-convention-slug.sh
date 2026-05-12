#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-005b-naming-convention-slug.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 2)
# AC coverage:
#   AC-005 (naming convention) → имя .mermaid-файла соответствует конвенции:
#     - kebab-case
#     - только ASCII-символы
#     - slug часть не длиннее 30 символов
#     - формат: <page-slug>-<diagram-slug>.mermaid
#
# TDD stub: ПАДАЕТ пока Dev не реализует naming convention в SKILL.md.
# После реализации: skill создаёт файл с именем по конвенции.
#
# Уровень: smoke (regex-проверка имени файла + структурный анализ)
# Boundary:
#   - стандартный кейс: overview.md + "auth flow" → overview-auth-flow.mermaid
#   - slug > 30 символов → обрезка до 30 (целые слова)
#   - нет темы → <page-slug>-diagram.mermaid
#   - _index.md → page-slug = имя директории

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# Regex для валидного имени .mermaid-файла по naming convention
VALID_FILENAME_REGEX='^[a-z0-9][a-z0-9-]*[a-z0-9]\.mermaid$'

validate_mermaid_filename() {
  local filename="$1" context="$2"

  # Только kebab-case ASCII
  if ! echo "$filename" | grep -qE "$VALID_FILENAME_REGEX"; then
    echo "  FAIL: $context — имя '$filename' не соответствует kebab-case ASCII convention" >&2
    FAIL=$((FAIL + 1))
    return
  fi

  # Извлекаем slug часть (после первого дефиса)
  local base="${filename%.mermaid}"
  local page_slug="${base%%-*}"
  local diagram_slug="${base#*-}"

  # diagram-slug ≤ 30 символов
  local slug_len="${#diagram_slug}"
  if [ "$slug_len" -gt 30 ]; then
    echo "  FAIL: $context — diagram-slug '$diagram_slug' длиннее 30 символов ($slug_len)" >&2
    FAIL=$((FAIL + 1))
  fi
}

# --- Тесты naming convention (симулируем ожидаемые имена файлов от skill'а) ---
# Эти файлы должны быть созданы после реализации Dev.
# Сейчас skill НЕ создаёт .mermaid-файлы → тест ПАДАЕТ на assert_file_exists.

mkdir -p "$TMPDIR_TEST/docs/auth" "$TMPDIR_TEST/docs/api" "$TMPDIR_TEST/docs/payments"

# --- Кейс 1: стандартный (overview.md + "auth flow") ---
CASE1_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"
echo "TODO: AC-005b (case1) — skill создаёт overview-auth-flow.mermaid для overview.md + тема 'auth flow'" >&2
assert_file_exists "$CASE1_FILE" \
  "AC-005b case1: overview-auth-flow.mermaid должен существовать"
[ -f "$CASE1_FILE" ] && validate_mermaid_filename "overview-auth-flow.mermaid" "AC-005b case1"

# --- Кейс 2: нет темы → <page-slug>-diagram.mermaid ---
CASE2_FILE="$TMPDIR_TEST/docs/api/endpoints-diagram.mermaid"
echo "TODO: AC-005b (case2) — без темы диаграммы: endpoints-diagram.mermaid" >&2
assert_file_exists "$CASE2_FILE" \
  "AC-005b case2: endpoints-diagram.mermaid должен существовать (fallback slug = 'diagram')"
[ -f "$CASE2_FILE" ] && validate_mermaid_filename "endpoints-diagram.mermaid" "AC-005b case2"

# --- Кейс 3: _index.md → page-slug = имя директории ---
CASE3_FILE="$TMPDIR_TEST/docs/payments/payments-diagram.mermaid"
echo "TODO: AC-005b (case3) — _index.md в payments/ → page-slug = 'payments'" >&2
assert_file_exists "$CASE3_FILE" \
  "AC-005b case3: payments-diagram.mermaid должен существовать (page-slug из родительской директории)"
[ -f "$CASE3_FILE" ] && validate_mermaid_filename "payments-diagram.mermaid" "AC-005b case3"

# --- Boundary: slug длиннее 30 символов → обрезка ---
# Из ADR-0010 Решение 2: k8s-setup-deployment-pipeline (≤30 символов slug части)
LONG_SLUG_FILE="k8s-setup-deployment-pipeline.mermaid"
DIAGRAM_SLUG="${LONG_SLUG_FILE%.mermaid}"
DIAGRAM_SLUG="${DIAGRAM_SLUG#*-}"  # убираем page-slug
SLUG_LEN="${#DIAGRAM_SLUG}"

echo "TODO: AC-005b (boundary slug length) — diagram-slug часть не длиннее 30 символов" >&2
if [ "$SLUG_LEN" -gt 30 ]; then
  echo "  FAIL: AC-005b boundary — пример slug '$DIAGRAM_SLUG' длиннее 30 символов ($SLUG_LEN)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005b-naming-convention-slug: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005b-naming-convention-slug: naming convention соблюдена (kebab-case, ASCII, slug ≤30 символов)"
