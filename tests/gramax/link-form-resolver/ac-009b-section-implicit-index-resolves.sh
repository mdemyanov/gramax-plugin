#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-009b-section-implicit-index-resolves.sh
# Требование: docs/30-requirements/2026-08-13-link-form-contract.md AC-009 (FR-082) —
#   edge case из docs/40-architecture/2026-08-13-link-form-contract-design.md,
#   раздел «Контракт с QA-author» → «Edge cases»: «Цель — раздел без явного `_index` в
#   тексте ссылки (`[X](section)`, не `[X](section/_index)`) — третий шаг инференса
#   (`section/_index.md`) описан FR-082 текстуально, но не был отдельно прогнан
#   исполняемым probe».
# ADR: docs/00-project/adr/0016-link-form-contract.md, Решение 1
#
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. `[X](section)` резолвится
#   сегодня уже сейчас, но ПОБОЧНО: `(md.parent / "section").resolve()` указывает на
#   существующую ДИРЕКТОРИЮ, а `Path.exists()` истинен для директорий так же, как для
#   файлов — сегодняшний буквальный резолвер не различает файл/директорию и не проверяет
#   именно `_index.md` внутри. Тест фиксирует НАБЛЮДАЕМОЕ поведение (exit=0), не то, каким
#   путём резолвер до него дошёл (BR запрета на тестирование деталей реализации) — валиден
#   и для сегодняшней реализации, и для целевой (3-шаговый инференс FR-082, шаг 3).
#
#   Закрыто волной-4 (было «открытый вопрос для Dev/SA», см. at-design.md): ветка
#   «директория есть, `_index.md` внутри нет» теперь СПЕЦИФИЦИРОВАНА — ADR-0028
#   Решение 4 (поправка к ADR-0016 Решение 1): файловые шаги резолвера требуют
#   `is_file()`, каталог — цель только через `_index.md` либо при флаге
#   `optionalCategoryIndex: true`; каталог без `_index.md` без флага даёт ERROR
#   «битая ссылка … — каталог без _index.md (раздела в дереве нет)». Ветка закреплена
#   стабами ac-169-dir-without-index-broken (без флага) и
#   ac-169-dir-without-index-flag-ok (с флагом — штатная тишина, ADR-0026 Решение 4);
#   единственный резолвер — `resolve_link_target` в `lib/link_resolver.py`. В этой
#   фикстуре `_index.md` внутри `section/` есть, поэтому итоговый exit=0 не меняется.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/section-index-implicit"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -ne 0 ]; then
  echo "  FAIL: AC-009 edge — ссылка [X](section) без явного _index в тексте обязана резолвиться через третий шаг инференса FR-082 (section/_index.md)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qi 'битая\|broken'; then
  echo "  FAIL: AC-009 edge — вывод не должен упоминать битую/broken ссылку на 'section'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009b: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009b: ссылка на раздел без явного _index резолвится (regression guard)"
