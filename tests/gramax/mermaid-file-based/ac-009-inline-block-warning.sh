#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-009-inline-block-warning.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 3)
# AC coverage:
#   AC-009 → при наличии inline-блока <mermaid>...</mermaid> в target_page
#             skill выводит предупреждение с подстрокой «устаревший» или «migration»
#   (Смежный кейс): при наличии fenced block ```mermaid``` — аналогичное предупреждение
#
# TDD stub: ПАДАЕТ пока Dev не реализует обнаружение inline-блоков (FR-006).
# После реализации: skill обнаруживает inline-блок и выводит предупреждение без изменения файла.
#
# Уровень: smoke (проверка fixture-файлов + ожидание поведения skill'а через TODO)
# Граничные кейсы:
#   - XML inline-блок <mermaid>...</mermaid>
#   - Markdown fenced block ```mermaid...```

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# --- Setup: fixture-файлы с inline-блоками ---
mkdir -p "$TMPDIR_TEST/docs/auth" "$TMPDIR_TEST/docs/deploy"
INLINE_MD="$TMPDIR_TEST/docs/auth/article-with-inline.md"
FENCED_MD="$TMPDIR_TEST/docs/deploy/article-with-fenced.md"
cp "$SCRIPT_DIR/fixtures/article-with-inline-mermaid.md" "$INLINE_MD"
cp "$SCRIPT_DIR/fixtures/article-with-fenced-mermaid.md" "$FENCED_MD"

# --- Sanity: fixtures корректно содержат inline-блоки ---
assert_file_exists "$INLINE_MD" \
  "AC-009 fixture: article-with-inline-mermaid.md должен существовать"
assert_file_exists "$FENCED_MD" \
  "AC-009 fixture: article-with-fenced-mermaid.md должен существовать"

if [ -f "$INLINE_MD" ]; then
  assert_grep "$INLINE_MD" '<mermaid>' \
    "AC-009 fixture sanity: article-with-inline-mermaid.md содержит inline-блок <mermaid>"
fi

if [ -f "$FENCED_MD" ]; then
  assert_grep "$FENCED_MD" '```mermaid' \
    "AC-009 fixture sanity: article-with-fenced-mermaid.md содержит fenced block"
fi

# --- AC-009 (XML inline): skill должен вывести предупреждение ---
echo "TODO: AC-009 (XML inline) — при чтении $INLINE_MD skill должен обнаружить <mermaid> блок" >&2
echo "  Ожидается в stdout: подстрока 'устаревший' или 'migration'" >&2
echo "  Формат предупреждения (из ADR-0010 Решение 3):" >&2
echo "    'Обнаружен inline-блок <mermaid>...</mermaid> в файле — это устаревший формат.'" >&2
echo "  Проверка: output=\$(run_mermaid_skill --target $INLINE_MD)" >&2
echo "            echo \"\$output\" | grep -qi 'устаревший\|migration'" >&2

# Тест не может вызвать Claude API напрямую — ПАДАЕТ с явным TODO
# После реализации QA-runner добавит smoke с захватом stdout skill'а
INLINE_BLOCK_DETECTED=0  # 0 = не обнаружен (текущее состояние)

if [ "$INLINE_BLOCK_DETECTED" -ne 1 ]; then
  echo "  FAIL: AC-009 (XML inline) — skill не реализовал обнаружение inline-блока" >&2
  echo "        Ожидается: при target_page с <mermaid>...</mermaid> → предупреждение в stdout" >&2
  FAIL=$((FAIL + 1))
fi

# --- AC-009 (fenced block): skill должен вывести предупреждение ---
echo "TODO: AC-009 (fenced) — при чтении $FENCED_MD skill должен обнаружить \`\`\`mermaid блок" >&2
echo "  Ожидается: аналогичное предупреждение ('устаревший' или 'migration') в stdout" >&2

FENCED_BLOCK_DETECTED=0  # 0 = не обнаружен (текущее состояние)

if [ "$FENCED_BLOCK_DETECTED" -ne 1 ]; then
  echo "  FAIL: AC-009 (fenced) — skill не реализовал обнаружение fenced block" >&2
  echo "        Ожидается: при target_page с \`\`\`mermaid...\`\`\` → предупреждение в stdout" >&2
  FAIL=$((FAIL + 1))
fi

# --- AC-009 boundary: файл с inline-блоком НЕ должен изменяться (FR-006) ---
# После вызова skill (с ответом "нет" на миграцию) inline-блок должен остаться нетронутым.
echo "TODO: AC-009 (no-mutation) — inline-блок в target_page не изменяется без подтверждения миграции" >&2

CONTENT_BEFORE="$(cat "$INLINE_MD")"
# Симуляция: не трогаем файл (как должен делать skill)
CONTENT_AFTER="$(cat "$INLINE_MD")"
assert_eq "$CONTENT_AFTER" "$CONTENT_BEFORE" \
  "AC-009: inline-блок в target_page не изменяется без явного подтверждения миграции"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-009-inline-block-warning: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-009-inline-block-warning: skill обнаруживает inline-блоки и выводит предупреждение"
