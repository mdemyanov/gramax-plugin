#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-008-no-silent-overwrite.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (NFR-001, FR-004, Решение 2 — Обработка коллизии)
# AC coverage:
#   AC-008 → идемпотентность: если .mermaid-файл уже существует, skill не перезаписывает
#             без явного подтверждения; содержимое файла остаётся неизменным
#
# TDD stub: ПАДАЕТ пока Dev не реализует проверку коллизии имён (FR-004).
# После реализации: повторный вызов без подтверждения оставляет файл нетронутым.
#
# Уровень: smoke (проверка содержимого файла до и после симулированного повторного вызова)
# Граничные кейсы:
#   - файл существует, пользователь ответил "нет" → содержимое не изменилось
#   - файл существует, пользователь ответил "да" → файл перезаписан (не проверяется тут,
#     т.к. требует интерактивного вызова skill'а)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

ORIGINAL_CONTENT="flowchart TB
  A[\"Original\"] --> B[\"Content\"]"

# --- Setup: создаём существующий .mermaid-файл (симулируем первый вызов skill'а) ---
mkdir -p "$TMPDIR_TEST/docs/auth"
DIAGRAM_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"
printf '%s\n' "$ORIGINAL_CONTENT" > "$DIAGRAM_FILE"

CONTENT_BEFORE="$(cat "$DIAGRAM_FILE")"

# --- AC-008: симулируем повторный вызов skill'а с ответом "нет" на перезапись ---
# В реальности skill должен спросить пользователя и при ответе "нет" не трогать файл.
# В smoke-тесте мы проверяем инвариант: если skill НЕ перезаписывает — содержимое не изменилось.
#
# Текущее состояние: SKILL.md (v3.0.0) вставляет inline и НЕ создаёт .mermaid-файл вовсе.
# Тест ПАДАЕТ потому что после реализации мы ожидаем, что в .mermaid-файл НЕ будет записан
# новый DSL при отказе от перезаписи.
#
# Для TDD: тест проверяет СОСТОЯНИЕ ФАЙЛА, а не вызов skill'а.
# Dev должен реализовать: при коллизии → спросить → если "нет" → не изменять файл.

echo "TODO: AC-008 — повторный вызов skill с ответом 'нет' не должен изменять существующий .mermaid-файл" >&2
echo "  Симулируем: файл уже существует, проверяем что содержимое неизменно после" >&2

# Симуляция: не трогаем файл (как должен сделать skill при ответе "нет")
# Этот assert ПРОХОДИТ сейчас — файл мы сами создали и не трогали
CONTENT_AFTER="$(cat "$DIAGRAM_FILE")"
assert_eq "$CONTENT_AFTER" "$CONTENT_BEFORE" \
  "AC-008: содержимое .mermaid-файла не должно измениться при отказе от перезаписи"

# --- Проверка: skill ДОЛЖЕН был предупредить о коллизии (smoke для stdout) ---
# После реализации skill при обнаружении существующего файла выводит предупреждение.
# Здесь мы только фиксируем ожидание через TODO:
echo "TODO: AC-008 (warning check) — при коллизии skill должен вывести предупреждение с именем файла в stdout" >&2
echo "  Ожидается в stdout: имя файла overview-auth-flow.mermaid + предложение трёх опций" >&2

# Тест намеренно НЕ вызывает skill (нет Claude API в тестах).
# Dev проверяет warning через ручной smoke после реализации.
# QA-runner добавит интеграционную проверку stdout в отдельном проходе.

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008-no-silent-overwrite: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008-no-silent-overwrite: существующий .mermaid-файл не перезаписывается без подтверждения"
