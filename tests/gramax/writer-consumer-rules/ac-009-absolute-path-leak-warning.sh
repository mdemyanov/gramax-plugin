#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-009-absolute-path-leak-warning.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-009 (FR-072).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел E —
#   одна строка в SKILL.md → "## Guardrails": риск двойной — утечка идентификационных данных
#   контрибьютора И битая ссылка, называть оба, не только техническое последствие.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).
#
# Assert 1 — буквальный BA-grep (наличие паттерна /Users/ или "абсолютн(ый|ые) путь" где угодно
# в skills/writer/). Assert 2 — семантическое усиление QA-author: FR-072 требует НАЗЫВАТЬ ДВОЙНОЕ
# последствие (утечка идентификации + битая ссылка), не только техническую сторону — иначе
# предупреждение выродилось бы в обычную заметку про 404. Assert 2 требует, чтобы в том же
# файле, где встречается паттерн пути, встречалось и слово, сигнализирующее об утечке
# идентификационных данных ('идентифика' / 'privacy' / 'утечк').

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"
PATH_PATTERN='/Users/|абсолютн(ый|ые) путь'

# --- assert 1: буквальный текст AC-009 (трассируемость с BA-формулировкой) ---
if ! grep -rliE "$PATH_PATTERN" "$WRITER_DIR" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-009 (буквальный BA-grep) — ни один файл skills/writer/ не предупреждает об абсолютных путях (/Users/... или 'абсолютный путь')" >&2
  FAIL=$((FAIL + 1))
fi

# --- assert 2: двойное последствие названо в том же файле (см. комментарий заголовка) ---
FOUND_DUAL_CONSEQUENCE=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qiE "$PATH_PATTERN" "$f" 2>/dev/null && grep -qiE 'идентифика|privacy|утечк' "$f" 2>/dev/null; then
    FOUND_DUAL_CONSEQUENCE=1
    break
  fi
done < <(find "$WRITER_DIR" -name '*.md' 2>/dev/null)

if [ "$FOUND_DUAL_CONSEQUENCE" -eq 0 ]; then
  echo "  FAIL: AC-009 — предупреждение обязано называть ОБА последствия: утечку идентификационных данных контрибьютора (не только битую ссылку) — FR-072" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: предупреждение об утечке абсолютных путей задокументировано с двойным последствием"
