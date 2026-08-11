#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-008-xml-blocks-as-structure-list.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-008 (FR-071).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел D —
#   новый раздел "XML-блоки, засчитываемые как структура" в references/structure.md:
#   <note>, <tabs>, <view>, <snippet>, <mermaid>, <drawio>, <image>, <openapi>.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).
#
# Реализовано явным циклом по кандидатам (не grep|xargs|grep) — по прецеденту ac-002 в этом
# suite'е: xargs на этой платформе (BSD, /usr/bin/xargs) не запускает команду при пустом stdin
# и завершается кодом 0, из-за чего "&& echo PASS" на конце такой цепочки может быть vacuously
# true. Здесь риск ниже (сегодня уже есть файлы references/*.md, упоминающие <note>/<tabs>/
# <snippet> по несвязанной причине — справочник блоков), но явный цикл используется
# последовательно во всём suite'е, а не только там, где landmine эмпирически подтверждён.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
REFERENCES_DIR="$ROOT/plugins/gramax/skills/writer/references"

CANDIDATES=()
while IFS= read -r f; do
  [ -n "$f" ] && CANDIDATES+=("$f")
done < <(grep -rlE '<note>|<tabs>|<snippet' "$REFERENCES_DIR"/*.md 2>/dev/null)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "  FAIL: AC-008 — ни один файл references/*.md не упоминает XML-теги-блоки вовсе (sanity-предусловие не выполнено)" >&2
  FAIL=$((FAIL + 1))
else
  FOUND=0
  for f in "${CANDIDATES[@]}"; do
    if grep -qiE 'структур' "$f" 2>/dev/null; then
      FOUND=1
      break
    fi
  done
  if [ "$FOUND" -eq 0 ]; then
    echo "  FAIL: AC-008 — ни один файл, упоминающий XML-теги-блоки, не называет их 'структурой' (FR-071 требует явный перечень блоков, засчитываемых как структурный элемент)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-008: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-008: перечень XML-блоков, засчитываемых как структура, задокументирован"
