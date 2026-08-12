#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-004-corrective-adr-exists-and-links.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-004 (FR-098).
#
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. ADR-0017 уже написан SA и Accepted —
# работа SA этой волны предшествует QA-author по каноническому порядку
# (Researcher → BA → SA → Dev → QA), поэтому её артефакт уже полон на момент, когда QA-author
# пишет тест-дизайн. Все четыре сигнала AC-004 уже присутствуют в ADR-0017. Тест защищает
# содержимое ADR от будущей порчи (например, если кто-то отредактирует «Связанные артефакты» и
# уберёт одну из перекрёстных ссылок).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
ADR_DIR="$ROOT/content/00-project/adr"
REQ_FILENAME="2026-08-13-cross-catalog-retraction.md"
RES_FILENAME="2026-08-13-cross-catalog-links-probe.md"
DISPOSITION_FILENAME="2026-08-11-writer-rules-disposition.md"

# (a) кандидаты: файлы adr/*.md, упоминающие имя файла требования — позитивное предусловие
# перед co-occurrence-проверкой остальных сигналов (по прецеденту
# tests/gramax/writer-consumer-rules/ac-002-*.sh: цикл по кандидатам без xargs, явный FAIL при
# нуле кандидатов — не молчаливый вакуумный PASS).
CANDIDATES=()
while IFS= read -r f; do [ -n "$f" ] && CANDIDATES+=("$f"); done \
  < <(grep -rlF "$REQ_FILENAME" "$ADR_DIR" 2>/dev/null)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "  FAIL: AC-004(a) — ни один файл content/00-project/adr/ не упоминает $REQ_FILENAME — корректирующий ADR не найден (FR-098)" >&2
  FAIL=$((FAIL + 1))
else
  # (б)(в)(г) — среди кандидатов ищем ЕДИНСТВЕННЫЙ файл, несущий ВСЕ три оставшихся сигнала
  # (тот же самый корректирующий ADR, не разные документы).
  FOUND=0
  for f in "${CANDIDATES[@]}"; do
    HAS_RES=0; HAS_DISPOSITION_TOPIC=0; HAS_NO_EDIT_STATEMENT=0
    grep -qF "$RES_FILENAME" "$f" 2>/dev/null && HAS_RES=1
    if grep -qF "$DISPOSITION_FILENAME" "$f" 2>/dev/null && grep -qE 'Тема A|FR-065' "$f" 2>/dev/null; then
      HAS_DISPOSITION_TOPIC=1
    fi
    grep -qiE 'без правки тела|без изменения тела' "$f" 2>/dev/null && HAS_NO_EDIT_STATEMENT=1
    if [ "$HAS_RES" -eq 1 ] && [ "$HAS_DISPOSITION_TOPIC" -eq 1 ] && [ "$HAS_NO_EDIT_STATEMENT" -eq 1 ]; then
      FOUND=1
      break
    fi
  done
  if [ "$FOUND" -eq 0 ]; then
    echo "  FAIL: AC-004(б/в/г) — ни один из ${#CANDIDATES[@]} кандидатов не несёт ОДНОВРЕМЕННО: имя файла RES-006 ($RES_FILENAME), 'Тема A'/'FR-065' рядом с $DISPOSITION_FILENAME, и явную формулировку об отсутствии правки тела/статуса/frontmatter (FR-098)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: корректирующий ADR существует и несёт все четыре обязательных сигнала (regression guard)"
