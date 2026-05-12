#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-001-mermaid-file-created.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
# AC coverage:
#   AC-001 → .mermaid-файл создаётся в той же директории, что и target_page
#
# TDD stub: ПАДАЕТ пока Dev не реализует file-based workflow в SKILL.md (v4.0.0).
# После реализации: skill создаёт .mermaid-файл через Write tool рядом со статьёй.
#
# Уровень: smoke (проверка наличия файла после симулированного вызова)
# Граничные кейсы:
#   - стандартный target_page (auth-flow.md) → auth-flow-login-sequence.mermaid рядом
#   - target_page = _index.md → page-slug берётся из родительской директории

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# --- Setup: создаём тестовую структуру каталога Gramax ---
mkdir -p "$TMPDIR_TEST/docs/auth"
cp "$SCRIPT_DIR/fixtures/clean-article.md" "$TMPDIR_TEST/docs/auth/overview.md"
# Симулируем _index.md кейс
mkdir -p "$TMPDIR_TEST/docs/payments"
cp "$SCRIPT_DIR/fixtures/clean-article.md" "$TMPDIR_TEST/docs/payments/_index.md"

# --- AC-001 (happy path): .mermaid-файл рядом с target_page ---
# После реализации skill создаст этот файл через Write tool.
# Сейчас файла нет — тест ДОЛЖЕН ПАДАТЬ.
EXPECTED_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"

echo "TODO: AC-001 (happy path) — skill должен создать $EXPECTED_FILE через Write tool" >&2
echo "  Ожидается: test -f $EXPECTED_FILE" >&2
assert_file_exists "$EXPECTED_FILE" \
  "AC-001: .mermaid-файл должен существовать рядом с target_page после вызова skill"

# --- AC-001 (boundary: _index.md) → page-slug = имя родительской директории ---
# Для _index.md в docs/payments/ → файл должен называться payments-diagram.mermaid
EXPECTED_INDEX_FILE="$TMPDIR_TEST/docs/payments/payments-diagram.mermaid"

echo "TODO: AC-001 (_index.md boundary) — для _index.md page-slug = родительская директория" >&2
echo "  Ожидается: test -f $EXPECTED_INDEX_FILE" >&2
assert_file_exists "$EXPECTED_INDEX_FILE" \
  "AC-001: для _index.md page-slug берётся из имени родительской директории"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-001-mermaid-file-created: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-001-mermaid-file-created: .mermaid-файл создаётся рядом с target_page"
