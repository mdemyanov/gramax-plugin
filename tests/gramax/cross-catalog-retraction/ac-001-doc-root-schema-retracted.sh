#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-001-doc-root-schema-retracted.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-001
#             (FR-093/FR-094).
# ADR: content/00-project/adr/0017-cross-catalog-retraction.md, Решение 2 — точный текст
#      замены таблицы «Корневые ключи» (строка `code`) и раздела «## Cross-каталожные ссылки
#      через `code`» в references/doc-root-schema.md.
#
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   (а) сегодня файл нигде не называет `code` декоративным/UI-only — текущая формулировка
#       (таблица «Корневые ключи», строка 15) — «Короткий идентификатор каталога (для
#       cross-каталожных ссылок)» — ровно то функциональное назначение, которое FR-094
#       предписывает убрать.
#   (б) сегодня файл СОДЕРЖИТ обе ретируемые фразы (заголовок раздела и «Полный рецепт,
#       реальный пример из этого репозитория») — негативная проверка красна намеренно.
#   (в) `bash scripts/check.sh --fast` уже зелёный сегодня — НЕ регрессионный признак того, что
#       (а)/(б) уже выполнены: `--fast` (whitespace + JSON + `uv run scripts/validate-content.py`)
#       не запускает ни один suite `tests/gramax/**` и не проверяет прозу writer-skill вообще
#       (см. README.md suite'а, «Стартовое состояние»). Проверка (в) — самостоятельный сигнал,
#       который может независимо покраснеть, если правка Dev случайно сломает structural-
#       валидацию content/ (сироты, битые ссылки, JSON) — не имеет отношения к тексту
#       doc-root-schema.md конкретно.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DOC_ROOT_SCHEMA="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_file_exists "$DOC_ROOT_SCHEMA" "AC-001: references/doc-root-schema.md должен существовать"

if [ -f "$DOC_ROOT_SCHEMA" ]; then
  # Все многословные проверки идут по FLAT-версии файла (переводы строк схлопнуты в пробел), не
  # по сырым строкам. Причина, найденная эмпирически при написании ac-006 этого suite'а на
  # синтетической фикстуре CHANGELOG: content/*.md и ADR-тексты в этом репозитории пишутся с
  # ручным переносом строк на ~90 столбце (в отличие от plugins/gramax/skills/writer/**, где
  # принят стиль «один длинный абзац — одна строка», но полагаться на конвенцию конкретного
  # файла — хрупко). Многословная фраза, случайно разорванная переносом строки ровно между её
  # словами, дала бы grep -F/-E ложный "не найдено" — для негативной проверки это ложный PASS,
  # для позитивной — ложный FAIL. FLAT-нормализация убирает этот класс ложных срабатываний.
  FLAT="$(tr '\n' ' ' < "$DOC_ROOT_SCHEMA")"

  # (а) позитивная — независимый grep -c, не часть цепочки.
  DECOR_COUNT="$(printf '%s' "$FLAT" | grep -ci -- 'декоративн' || true)"
  DECOR_COUNT="${DECOR_COUNT:-0}"
  if [ "$DECOR_COUNT" -lt 1 ]; then
    echo "  FAIL: AC-001(а) — doc-root-schema.md не констатирует декоративный/UI-only характер поля 'code' (FR-093/FR-094)" >&2
    FAIL=$((FAIL + 1))
  fi

  # (б) негативная, отдельной командой: точная фраза исходного заголовка — 0 вхождений.
  # shellcheck disable=SC2016  # backtick — литерал Markdown-заголовка (` code `), не command substitution: интерполяция здесь не нужна и не должна происходить
  if printf '%s' "$FLAT" | grep -qF 'Cross-каталожные ссылки через `code`'; then
    echo "  FAIL: AC-001(б) — заголовок ретируемого раздела всё ещё присутствует (FR-093)" >&2
    FAIL=$((FAIL + 1))
  fi

  # (б) негативная, ОТДЕЛЬНОЙ командой: точная фраза «Полный рецепт...» — 0 вхождений.
  if printf '%s' "$FLAT" | grep -qF 'Полный рецепт, реальный пример из этого репозитория'; then
    echo "  FAIL: AC-001(б) — фраза, представляющая рецепт code: рабочим, всё ещё присутствует (FR-093)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# (в) композитный гейт задачи — код возврата полного непрефильтрованного прогона, не grep по
# stdout (content/lessons-learned.md, 2026-08-10 «зелёный по грепу — не зелёный»).
LOG_FILE="$(mktemp)"
( cd "$ROOT" && bash scripts/check.sh --fast ) > "$LOG_FILE" 2>&1
CHECK_EXIT=$?
if [ "$CHECK_EXIT" -ne 0 ]; then
  echo "  FAIL: AC-001(в) — bash scripts/check.sh --fast завершился exit=$CHECK_EXIT (ожидался 0). Хвост вывода:" >&2
  tail -30 "$LOG_FILE" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$LOG_FILE"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: doc-root-schema.md ретирован корректно, check.sh --fast зелёный"
