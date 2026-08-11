#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-009-divergent-consumers-documented.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-009
#   (FR-061, FR-062).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 5.
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Assert 1 — буквальный BA-grep из текста AC-009 ('валидатор'); проверено вручную, что он
# сегодня отсутствует нигде в skills/mermaid/ или README.md — красный по прямой причине.
#
# Assert 2 — усиление QA-author: голая проверка «blocks.md встречается где-то в
# skills/mermaid/» уже ложно проходит СЕГОДНЯ (SKILL.md:97 цитирует blocks.md как источник
# дефолтов width/height — причина не связана с конфликтом валидатора). Тот же паттерн, что в
# ac-001 (буквальный AC уже удовлетворён по несвязанной причине) — см. комментарий там.
# Co-occurrence 'валидатор' + 'blocks.md' В ОДНОМ ФАЙЛЕ страхует от этого false positive:
# сегодня ни один файл не содержит 'валидатор' вовсе, поэтому co-occurrence тоже красная —
# позеленеет только когда jurisdiction-and-validation.md (или SKILL.md) назовёт класс
# конфликта И контракт рендера вместе, как того требует Решение 5 ADR-0013.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- assert 1: буквальный текст AC-009 (трассируемость с BA-формулировкой) ---
if ! grep -rli 'валидатор' "$ROOT/plugins/gramax/skills/mermaid/" "$ROOT/plugins/gramax/README.md" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-009 (буквальный BA-grep) — ни skills/mermaid/, ни README.md не упоминают 'валидатор' (класс конфликта FR-052/FR-062 не задокументирован)" >&2
  FAIL=$((FAIL + 1))
fi

# --- assert 2: co-occurrence 'валидатор' + 'blocks.md' в одном файле (см. комментарий заголовка) ---
CANDIDATES=("$ROOT/plugins/gramax/skills/mermaid/SKILL.md" "$ROOT/plugins/gramax/README.md")
if [ -d "$ROOT/plugins/gramax/skills/mermaid/references" ]; then
  shopt -s nullglob
  for f in "$ROOT"/plugins/gramax/skills/mermaid/references/*.md; do
    CANDIDATES+=("$f")
  done
  shopt -u nullglob
fi

FOUND_COOCCURRENCE=0
for f in "${CANDIDATES[@]}"; do
  [ -f "$f" ] || continue
  if grep -qi 'валидатор' "$f" && grep -qi 'blocks\.md' "$f"; then
    FOUND_COOCCURRENCE=1
    break
  fi
done

if [ "$FOUND_COOCCURRENCE" -eq 0 ]; then
  echo "  FAIL: AC-009 — ни один файл не называет класс конфликта ('валидатор') И контракт рендера ('blocks.md') вместе (FR-062 требует оба факта рядом, не по отдельности; голое упоминание blocks.md уже существует в SKILL.md по несвязанной причине — недостаточно)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: класс конфликта и контракт рендера задокументированы вместе"
