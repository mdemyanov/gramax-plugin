#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-006-adr-status-recommendation-ordered.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-006 (FR-069).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел C —
#   новый подраздел "Content type ADR — `Статус`" в references/doc-root-schema.md.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).
#
# ВАЖНО (edge case явно указан в брифе задачи QA-author): grep с -A5 порядково-чувствителен.
# "статус"/"status" обязано встретиться В ПРЕДЕЛАХ ПЯТИ СТРОК ПОСЛЕ упоминания
# "Тип контента ... ADR"/"content type ... ADR", не до него и не где угодно в файле. Формула
# сохранена буквально из требования — проверена вручную на разъединённом сценарии (см.
# at-design.md), поведение соответствует ожиданию.
#
# AC-006 не различает, какой из двух суб-вариантов FR-069 выбран (рекомендованный enum vs
# явная таблица соответствия per-каталог) — как и сама формулировка AC в требовании; выбор
# суб-варианта — предмет диспозиции (Решение C), не этого теста.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DOC_ROOT_SCHEMA="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

if ! grep -A5 -iE 'Тип контента.{0,20}ADR|content type.{0,10}ADR' "$DOC_ROOT_SCHEMA" 2>/dev/null \
    | grep -qiE 'статус|status'; then
  echo "  FAIL: AC-006 — doc-root-schema.md не даёт рекомендации по property 'Статус' для content type ADR в пределах 5 строк после упоминания 'Тип контента ... ADR' (FR-069)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: рекомендация по property Статус для content type ADR задокументирована"
