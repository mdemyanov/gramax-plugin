#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/ac-001-jurisdiction-boundary-documented.sh
# Требование: content/30-requirements/2026-08-11-mermaid-file-based-adoption.md AC-001
#   (FR-050, FR-051).
# ADR: content/00-project/adr/0013-mermaid-adoption-and-migration.md, Решение 1.
#   Носитель: короткая формулировка в skills/mermaid/SKILL.md (грузится при каждом вызове) +
#   развёрнутый on-demand skills/mermaid/references/jurisdiction-and-validation.md (new) +
#   одна ссылочная строка в README.md.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-003 не начат).
#
# НАХОДКА QA-author: буквальный grep из текста AC-001 самого требования
#   (`grep -rliE '\.doc-root\.yaml' plugins/gramax/skills/mermaid/ plugins/gramax/README.md`)
# уже проходит СЕГОДНЯ, до всякой реализации — SKILL.md уже упоминает `.doc-root.yaml` (секции
# «Синтаксис каталога» и «Backward compatibility»), но по НЕСВЯЗАННОЙ причине: определение
# XML/Markdown-синтаксиса каталога, не граница юрисдикции file-based mermaid (FR-050). Буквальный
# grep AC-001 — false positive относительно намерения FR-050/FR-051, не про факт присутствия
# нужного содержания. Assert 1 ниже сохраняет буквальную BA-формулировку для трассируемости
# (сама по себе — недостаточный барьер, уже удовлетворена случайно). Assert 2 — обязательная
# семантическая проверка QA-author: ключевое слово «юрисдикц» обязано встречаться в тех же
# материалах — это то, что реально сигнализирует «граница задокументирована», а не случайное
# совпадение подстроки. См. content/60-implementation/acceptance/
# 2026-08-11-mermaid-adoption-at-design.md, раздел «Находка: буквальный AC уже удовлетворён».

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- assert 1: буквальный текст AC-001 (трассируемость с BA-формулировкой) ---
if ! grep -rliE '\.doc-root\.yaml' "$ROOT/plugins/gramax/skills/mermaid/" "$ROOT/plugins/gramax/README.md" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-001 (буквальный BA-grep) — ни один файл skills/mermaid/ или README.md не упоминает .doc-root.yaml" >&2
  FAIL=$((FAIL + 1))
fi

# --- assert 2: семантическое усиление QA-author (см. комментарий заголовка) ---
if ! grep -rliE 'юрисдикц' "$ROOT/plugins/gramax/skills/mermaid/" "$ROOT/plugins/gramax/README.md" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-001 — граница юрисдикции (FR-050/FR-051, ADR-0013 Решение 1) не задокументирована явно: ни SKILL.md, ни jurisdiction-and-validation.md (new), ни README.md не содержат ключевого слова 'юрисдикц'. Ожидается короткая формулировка в SKILL.md + развёрнутая в references/jurisdiction-and-validation.md" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: граница юрисдикции задокументирована и обнаружима"
