#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-003-backtick-trap-warning.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-003 (FR-066).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел A —
#   1–2 строки в SKILL.md рядом со строками 204–208 (тот же ❌/✅-блок, что и правило AC-001):
#   чужой regex-валидатор не отличает код-спан `` `[X](Y)` `` от markdown-ссылки `[X](Y)`.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).
#
# Assert 1 — буквальный BA-grep из текста AC-003 (любое из ключевых слов, где угодно в
# skills/writer/). Assert 2 — семантическое усиление QA-author: BR-003 и сама диспозиция
# ("Вне контекста ловушки бесполезно") требуют, чтобы предупреждение стояло РЯДОМ с правилом
# cross-каталожных ссылок, а не было отдельной несвязанной репликой где-нибудь ещё в дереве
# skills/writer/ (например, в staging.md по случайному поводу). Assert 2 проверяет
# co-occurrence — ключевое слово ловушки и 'cross-каталож' в ОДНОМ файле.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"
TRAP_PATTERN='обратн(ых|ые) кавыч|backtick|код-спан'

# --- assert 1: буквальный текст AC-003 (трассируемость с BA-формулировкой) ---
if ! grep -rliE "$TRAP_PATTERN" "$WRITER_DIR" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-003 (буквальный BA-grep) — ни один файл skills/writer/ не упоминает ловушку обратных кавычек/backtick/код-спан" >&2
  FAIL=$((FAIL + 1))
fi

# --- assert 2: co-occurrence с cross-каталож в одном файле (см. комментарий заголовка) ---
FOUND_COOCCURRENCE=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qiE "$TRAP_PATTERN" "$f" 2>/dev/null && grep -qiE 'cross-каталож' "$f" 2>/dev/null; then
    FOUND_COOCCURRENCE=1
    break
  fi
done < <(find "$WRITER_DIR" -name '*.md' 2>/dev/null)

if [ "$FOUND_COOCCURRENCE" -eq 0 ]; then
  echo "  FAIL: AC-003 — предупреждение о ловушке обратных кавычек должно стоять рядом с правилом cross-каталожных ссылок (тот же файл), не быть изолированной репликой (BR-003, диспозиция: 'вне контекста ловушки бесполезно')" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: предупреждение о ловушке обратных кавычек задокументировано рядом с правилом cross-каталожных ссылок"
