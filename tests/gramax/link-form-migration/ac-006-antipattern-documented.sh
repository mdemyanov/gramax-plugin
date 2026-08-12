#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-006-antipattern-documented.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-006 (FR-081, BR-002).
# Природа: НЕ живой контракт скрипта — grep на plugins/gramax/skills/writer/SKILL.md. Фикстура
#   не нужна.
#
# Находка QA-author (по прецеденту content/60-implementation/acceptance/
# 2026-08-11-mermaid-adoption-at-design.md, раздел «Находка» — AC-001/AC-009 того suite'а):
# буквальный grep из текста AC-006 —
#   grep -n 'content/section/doc.md\|doc-root' SKILL.md | grep -qi 'антипаттерн\|не работает\|не резолв'
# — УЖЕ проходит сегодня (exit=0), но по НЕСВЯЗАННОЙ причине: единственное совпадение —
# "Полный справочник (все ключи, палитра, антипаттерны) → `references/doc-root-schema.md`."
# (SKILL.md:181) — ссылка на общий раздел антипаттернов СХЕМЫ .doc-root.yaml (properties:
# required:, type: select). Сам referenced-раздел (references/doc-root-schema.md,
# "## Антипаттерны") НЕ содержит ни слова о повторе имени doc-root-каталога в тексте ссылки
# (FR-081) — проверено: `grep -n 'content/' SKILL.md` → 0 совпадений во всём файле. Assert 1
# (буквальный BA-grep) сохраняется как трассируемость с формулировкой AC; assert 2 —
# семантическое усиление, держит тест красным, пока Dev не добавит содержательный негативный
# пример именно для этого антипаттерна (по образцу уже существующего ❌/✅-примера для
# кросс-каталожных ссылок в разделе "## Ссылки" того же файла).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

if [ ! -f "$SKILL_MD" ]; then
  echo "  FAIL: AC-006 — $SKILL_MD не найден" >&2
  fail_msg "ac-006: SKILL.md отсутствует"
  exit 1
fi

# Assert 1 — буквальный BA-grep (уже PASS сегодня, по несвязанной причине — см. заголовок).
if ! grep -n 'content/section/doc.md\|doc-root' "$SKILL_MD" | grep -qi 'антипаттерн\|не работает\|не резолв'; then
  echo "  FAIL: AC-006 (assert 1, буквальный BA-grep) — неожиданно не проходит; проверьте, не удалена ли строка про 'references/doc-root-schema.md' из SKILL.md" >&2
  FAIL=$((FAIL + 1))
fi

# Assert 2 — семантическое усиление: явный негативный (❌) пример ИМЕННО для повтора имени
# doc-root-каталога (FR-081), по образцу уже существующего ❌-паттерна для кросс-каталожных
# ссылок в этом же файле ("❌ `[Документ](other-catalog/path/to/file.md)` — не резолвится").
# Красный сегодня: "content/" нигде не упоминается в SKILL.md буквально.
if ! grep -qE '❌.*content/' "$SKILL_MD"; then
  echo "  FAIL: AC-006 (assert 2, семантическое усиление) — SKILL.md не содержит явного ❌-примера с префиксом doc-root-каталога ('content/…') — раздел references/doc-root-schema.md#Антипаттерны сегодня посвящён СХЕМЕ properties, не форме ссылки (FR-081)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: антипаттерн FR-081 явно задокументирован содержательным примером"
