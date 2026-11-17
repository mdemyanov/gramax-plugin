#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-004-no-deleted-pointers.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-004 (FR-125/FR-129).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md — зелёным делают коммиты
# B (удаление docs/superpowers/ и диспозиции, снятие указателей из docs/_index.md),
# A (снятие указателей из docs/_index.md) и D2 (переформулировка provenance-шапок suite'ов).
# Контракт: живые файлы docs/, plugins/, tests/, scripts/ не содержат указателей на
# артефакты, удаляемые по FR-129 (superpowers/, диспозиция doc-paths-disposition,
# отчёты 2026-05-08-diagram-on-demand и 2026-08-10-test-harness-taxonomy).
# Отклонение от буквальной команды AC (grep -v "adr/" как единственный фильтр),
# согласованное с ADR-0021 Решение 3 кл.1/кл.2 и NFR-003:
#  — кл.1: само требование инверсии (docs/30-requirements/2026-11-17-docs-layout-inversion.md)
#    — его предмет и есть миграция, FR-129 цитирует удаляемые пути дословно;
#  — кл.2: выжившие отчёты живой эпохи (docs/60-implementation/test-reports/2026-08-1[23]-…-qa-report.md;
#    якорь — строка 258 отчёта wave-4.2.0), корпус-аудит и требование миграции 2026-08-09
#    (whole-file записи allowlist suite doc-paths), plugin-consumers-gaps (чужие деревья),
#    аудиты безопасности, dev-notes 60-implementation верхнего уровня.
# _index.md разделов НЕ исключается — это навигация (POINTER), мёртвые ссылки из него
# снимаются (FR-125).
# Самопомеха снята: литералы в grep-паттернах самой harness-директории — не указатели.
# RED on 8b2db0b (дерево до миграции): docs/superpowers/ (десятки строк), диспозиция
# (35 строк) существуют; provenance-шапки nauta-integration, catalog-validator,
# orphan-references и doc-paths пинят удаляемые пути.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAIL=0

fail() {
  printf "  ${RED}FAIL:${NC} %s\n" "$1" >&2
  FAIL=$((FAIL + 1))
}

# Маскировка отказа: без существующих областей скана grep замолчал бы и проверка
# прошла бы «зелёно» пусто. Области обязаны существовать (после миграции docs/ есть).
for d in docs plugins tests scripts; do
  if [ ! -d "$d" ]; then
    fail "AC-004: область скана $d/ не существует — проверка не может быть исполнена честно"
  fi
done

PATTERN='doc-paths-disposition\|superpowers/\|2026-05-08-diagram-on-demand-qa-report\|2026-08-10-test-harness-taxonomy'

# Предмет — отслеживаемое дерево (FR-125: 260 файлов); невеженные рабочие каталоги
# (.superpowers/ и пр.) вне предмета — фильтр по git ls-files.
TRACKED="$(mktemp)"
trap 'rm -f "$TRACKED"' EXIT
git ls-files >"$TRACKED" 2>/dev/null

RAW_HITS=$(grep -rn "$PATTERN" \
  --include="*.md" --include="*.sh" \
  docs/ plugins/ tests/ scripts/ 2>/dev/null || true)

# кл.1/кл.2/кл.6 по Решению 3 ADR-0021 — те же классы, что и в ac-003: требование
# инверсии (кл.1), корпус-аудит и требование миграции 2026-08-09 (whole-file прецедент
# allowlist), plugin-consumers-gaps (чужие деревья), аудиты безопасности, dev-notes
# 60-implementation верхнего уровня, выжившие отчёты живой эпохи.
RECORD_FILE_RE='^docs/30-requirements/2026-11-17-docs-layout-inversion\.md:|^docs/10-domain/research/2026-08-13-link-form-corpus-audit\.md:|^docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths\.md:|^docs/10-domain/research/2026-08-11-plugin-consumers-gaps\.md:|^docs/00-project/security/|^docs/60-implementation/[^/]+\.md:|^docs/60-implementation/test-reports/2026-08-1[23]-[a-z0-9.-]*-qa-report\.md:'

HITS=""
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  f="${hit%%:*}"
  grep -Fxq -- "$f" "$TRACKED" || continue
  printf '%s' "$hit" | grep -q "adr/" && continue
  printf '%s' "$hit" | grep -q "^tests/gramax/docs-migration/" && continue
  # instrument suite'а: ac-007 nauta-integration — детектор мёртвых префиксов
  # (PATTERN_SPECS называет docs/superpowers/specs/ как ассерт ОТСУТСТВИЯ ссылок на
  # него, не указатель; шапка файла именует принцип «устаревшие пути — предмет
  # ассертов их отсутствия»; то же основание, что у исключения в ac-003)
  printf '%s' "$hit" | grep -q "^tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh:" && continue
  printf '%s' "$hit" | grep -qE "$RECORD_FILE_RE" && continue
  HITS="${HITS}${hit}
"
done <<<"$RAW_HITS"
HITS=${HITS%$'\n'}

if [ -n "$HITS" ]; then
  N=$(printf '%s\n' "$HITS" | wc -l | tr -d ' ')
  fail "AC-004/FR-125/FR-129: $N указателеподобных упоминаний удаляемых артефактов вне RECORD-исключений:"
  printf '%s\n' "$HITS" | head -40 >&2
  if [ "${N:-0}" -gt 40 ]; then
    printf "  ... и ещё %d строк\n" "$((N - 40))" >&2
  fi
  printf "  Указатель на удаляемое не переписывается «на новый путь» — строка снимается или\n" >&2
  printf "  переформулируется без литерала (ADR-0021, Решение 3); упоминание в RECORD выжившего\n" >&2
  printf "  отчёта/ADR допустимо (NFR-003).\n" >&2
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-004: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-004: указателей на удаляемые по FR-129 артефакты нет (RECORD учтён)\n"
exit 0
