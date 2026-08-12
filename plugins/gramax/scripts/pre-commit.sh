#!/usr/bin/env bash
# plugins/gramax/scripts/pre-commit.sh
# Копируемый шаблон git pre-commit хука для потребителя плагина gramax (ADR-0012,
# «Контракт валидации Gramax-каталога», Решение 4; FR-037).
#
# Этот файл живёт ВНУТРИ плагина (${CLAUDE_PLUGIN_ROOT}), не в репозитории потребителя —
# он не устанавливается автоматически (плагин не может писать в чужой .git/hooks). Скопируйте
# его в свой репозиторий и подключите одним из способов:
#
#   cp "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit.sh" .githooks/pre-commit
#   chmod +x .githooks/pre-commit
#   git config core.hooksPath .githooks
#
# или напрямую:
#
#   cp "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit.sh" .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Замените CONTENT_DIR ниже на путь к своему Gramax-каталогу (там, где .doc-root.yaml).

set -euo pipefail

CONTENT_DIR="${GRAMAX_CONTENT_DIR:-content}"

if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo "pre-commit: CLAUDE_PLUGIN_ROOT не задан — плагин gramax не активен в этой сессии." >&2
  echo "  Установка: /plugin marketplace add mdemyanov/gramax-plugin && /plugin install gramax@gramax-marketplace" >&2
  exit 1
fi

echo "pre-commit: валидация Gramax-каталога ($CONTENT_DIR)…"
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py" "$CONTENT_DIR"
# Рендер-линтер (ADR-0019): киллеры рендера блокируют коммит, WARN-стиль подавлен
# через --errors-only (exit-контракт не меняется: ERROR → 1, WARN → 0).
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_render.py" "$CONTENT_DIR" --errors-only
