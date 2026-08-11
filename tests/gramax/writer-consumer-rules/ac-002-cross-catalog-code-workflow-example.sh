#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-002-cross-catalog-code-workflow-example.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-002 (FR-065).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел A —
#   references/doc-root-schema.md получает новый подраздел с реальным `code: GRAMAX-PLUGIN`
#   и рабочей cross-каталожной ссылкой `` `GRAMAX-PLUGIN/40-architecture/...` `` — один и тот
#   же файл несёт оба сигнала.
#
# НАХОДКА QA-author (не покрыта явно диспозицией, шире её предупреждения): буквальная формула
# AC-002 из требования —
#   grep -rlE 'code:' … | xargs grep -liE 'cross-каталож' | xargs grep -lE '`A/b`' >/dev/null && echo PASS
# НЕ используется здесь как есть. Проверено эмпирически на этом окружении (macOS
# /usr/bin/xargs, BSD-семантика: команда НЕ запускается при пустом stdin, xargs завершается
# кодом 0): когда любая стадия конвейера получает нулевой ввод — что верно ПРЯМО СЕЙЧАС (0
# файлов writer-skill содержат 'code:', DEV-004 ещё не начат) — xargs просто ничего не делает
# и код возврата последней стадии всё равно 0. `>/dev/null && echo PASS` смотрит только на
# код возврата последней стадии, не на её реальный вывод — итог: буквальная формула сегодня
# печатает PASS, хотя FR-065 не реализован ни на йоту. Тот же эффект и на дизъюнктном сценарии,
# который диспозиция называет "ломает цепочку" (`code:` в файле A, `cross-каталож` в файле B,
# разные файлы) — цепочка снова тихо возвращает PASS через xargs, а не FAIL, как можно было бы
# предположить из формулировки диспозиции "разнесение по двум ломает цепочку" (проверено
# вручную на синтетической фикстуре двух файлов). Это отдельная находка, шире предупреждения
# диспозиции про разнесение — зафиксирована в at-design.md и content/lessons-learned.md.
#
# Проверка ниже реализует ТОТ ЖЕ контракт (все три сигнала — 'code:', 'cross-каталож', паттерн
# `` `A/b` `` — обязаны совпасть в ОДНОМ файле, edge case диспозиции), но без уязвимого
# xargs-конвейера: явный цикл по кандидатам, с позитивным предусловием «кандидатов вообще
# найдено ≥1» перед проверкой совпадения (по прецеденту "вакуумная истина" из
# content/lessons-learned.md, 2026-08-11).
#
# Природа: живой контракт — КРАСНЫЙ на момент создания (references/doc-root-schema.md не
# содержит 'code:' вовсе — DEV-004).
#
# НЕ покрывает (диспозиция, «Открытые вопросы» п.2 / требование, открытый вопрос BA №4):
# проверку примера на РЕАЛЬНОМ двухкаталожном сетапе — этот тест проверяет только синтаксис
# одного файла, не факт, что ссылка реально резолвится в живом Gramax между двумя каталогами.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

CANDIDATES=()
while IFS= read -r f; do
  [ -n "$f" ] && CANDIDATES+=("$f")
done < <(grep -rlE 'code:' "$WRITER_DIR" 2>/dev/null)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "  FAIL: AC-002 — ни один файл writer-skill не содержит 'code:' — рабочий пример поля code (FR-065) отсутствует" >&2
  FAIL=$((FAIL + 1))
else
  FOUND_SINGLE_FILE=0
  for f in "${CANDIDATES[@]}"; do
    # shellcheck disable=SC2016  # backticks в regex-литерале, не command substitution
    if grep -qiE 'cross-каталож' "$f" 2>/dev/null && grep -qE '`[A-Za-z0-9_-]+/[^`]+`' "$f" 2>/dev/null; then
      FOUND_SINGLE_FILE=1
      break
    fi
  done
  if [ "$FOUND_SINGLE_FILE" -eq 0 ]; then
    echo "  FAIL: AC-002 — ни один из ${#CANDIDATES[@]} файлов с 'code:' не содержит ОДНОВРЕМЕННО упоминание 'cross-каталож' и паттерн inline-code-ссылки \`A/b\` в ОДНОМ файле (FR-065 требует сквозной пример, не разнесение по нескольким файлам)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: рабочий пример cross-каталожной ссылки через поле code найден в одном файле"
