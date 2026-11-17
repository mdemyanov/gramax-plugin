#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-003-no-content-pointers.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-003 (FR-125).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 3 — зелёным делают
# коммиты D2 (переписывание пинов suite'ов) и D3 (ручные зоны AGENTS.md/CLAUDE.md).
# Контракт: команда из факта 3 (grep -rl "content/" по шести расширениям) после переезда
# возвращает пусто, кроме исключений, классифицированных по Решению 3 ADR-0021.
# Операционализация классов (механический протокол для остатков):
#   кл.1  — сам ADR-0021 и требование инверсии (их предмет — миграция);
#   кл.2  — RECORD: тела исторических ADR, выжившие отчёты и at-design'ы 60-implementation
#           (включая dev-notes верхнего уровня), append-only журнал уроков, аудиты безопасности
#           (content/00-project/security/), корпус-аудит link-form
#           (content/10-domain/research/2026-08-13-link-form-corpus-audit.md — 326 строк
#           цитирования; прецедент: whole-file запись allowlist suite doc-paths),
#           tests/gramax/archive/;
#   кл.3  — sha-пиновые доставленные скрипты validate-content.py / decide.py /
#           test-validate-content.sh (правка ломала бы базис);
#   кл.4  — payload plugins/** (релизный юнит плагина);
#   кл.5  — canon-текст nauta:managed / nauta:layout-map блоков AGENTS.md и CLAUDE.md
#           (единственный писатель — /nauta:init); вНЕ блоков упоминания content/
#           запрещены полностью (FR-127, коммит D3), включая «голый» токен;
#   кл.6  — ECOSYSTEM/FOREIGN: фикстуры (*/fixtures/*), антипаттерн-корпус link-form
#           (строки со markdown-ссылкой ]( и канон-путь content/section/…), канон-пути
#           спек плагина content/40-architecture/ADR-<N>…, исследования чужих деревьев
#           (content/10-domain/research/2026-08-11-plugin-consumers-gaps.md — прецедент:
#           построчные записи allowlist «чужие деревья»), «голый» токен-конвенция `content/`
#           без продолжения-пути (имя чужого корня, не путь этого дерева).
# Скан ведётся только по отслеживаемым (git-tracked) файлам: предмет FR-125 — 260
# отслеживаемых файлов; невеженные рабочие каталоги (.superpowers/ — заметки SDD-прогонов,
# git ls-files: 0 файлов) вне предмета.
# Остаток, не покрытый перечисленным, — находка: он обязан быть переписан (POINTER)
# либо классифицирован в Решение 3 с расширением списка здесь (с классом и основанием).
# RED on 8b2db0b (дерево до миграции): пины 14 suite'ов tests/gramax, scripts/
# (check-gramax.sh, apply-overlay.sh), функциональные home-globs .nauta-ids.yaml,
# ручные зоны AGENTS.md/CLAUDE.md и статьи docs/onboarding-nauta.md указывают на content/.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAIL=0
VIOLATIONS="$(mktemp)"
TRACKED="$(mktemp)"
trap 'rm -f "$VIOLATIONS" "$TRACKED"' EXIT
git ls-files >"$TRACKED" 2>/dev/null

is_tracked() {
  grep -Fxq -- "$1" "$TRACKED"
}

fail() {
  printf "  ${RED}FAIL:${NC} %s\n" "$1" >&2
  FAIL=$((FAIL + 1))
}

record() {
  printf '%s\n' "$1" >>"$VIOLATIONS"
}

# Файловые исключения — классы Решения 3 ADR-0021 (см. шапку).
file_excluded() {
  local f="$1"
  case "$f" in
    # кл.4 — payload плагина (релизный юнит, ADR-0006)
    ./plugins/*) return 0 ;;
    # кл.1/кл.2 — исторические ADR + сам ADR-0021 (RECORD дословно, NFR-003)
    ./content/00-project/adr/* | ./docs/00-project/adr/*) return 0 ;;
    # кл.1 — требование инверсии (его предмет — сама миграция)
    ./content/30-requirements/2026-11-17-docs-layout-inversion.md | \
      ./docs/30-requirements/2026-11-17-docs-layout-inversion.md) return 0 ;;
    # кл.2 — выжившие записи 60-implementation: отчёты, at-design'ы, dev-notes, индексы
    ./content/60-implementation/test-reports/* | ./docs/60-implementation/test-reports/* | \
      ./content/60-implementation/acceptance/* | ./docs/60-implementation/acceptance/* | \
      ./content/60-implementation/*.md | ./docs/60-implementation/*.md) return 0 ;;
    # кл.2 — выживший аудит безопасности завершённой волны (запись о работе: таблица
    # находок с вердиктами, цитаты путей-доказательств)
    ./content/00-project/security/* | ./docs/00-project/security/*) return 0 ;;
    # кл.2 — корпус-аудит link-form и требование миграции 2026-08-09: таблицы hits и
    # карты переездов (RECORD); прецедент — whole-file записи allowlist suite doc-paths
    # («whole-file: требование 2026-08-09, ADR-0011, link-form-corpus-audit»)
    ./content/10-domain/research/2026-08-13-link-form-corpus-audit.md | \
      ./docs/10-domain/research/2026-08-13-link-form-corpus-audit.md | \
      ./content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md | \
      ./docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md) return 0 ;;
    # кл.6 — исследование ЧУЖИХ деревьев (пути content/ чужих репозиториев-потребителей);
    # прецедент — построчные записи allowlist «чужие деревья» (plugin-consumers-gaps)
    ./content/10-domain/research/2026-08-11-plugin-consumers-gaps.md | \
      ./docs/10-domain/research/2026-08-11-plugin-consumers-gaps.md) return 0 ;;
    # кл.2 — append-only журнал уроков (записи не переписываются, NFR-003)
    ./content/lessons-learned.md | ./docs/lessons-learned.md) return 0 ;;
    # кл.2 — замороженные свидетельства приёмки прошлых релизов
    ./tests/gramax/archive/*) return 0 ;;
    # кл.6 — фикстуры (данные моделей потребителей, не пути этого дерева)
    */fixtures/*) return 0 ;;
    # сама harness-директория: литералы в её собственных grep-паттернах — не указатели
    ./tests/gramax/docs-migration/*) return 0 ;;
    # кл.3 — sha-пиновые доставленные скрипты (Решение 5 ADR-0021)
    ./scripts/validate-content.py | ./scripts/decide.py | ./scripts/test-validate-content.sh) return 0 ;;
    *) return 1 ;;
  esac
}

# Строчные исключения для файлов вне AGENTS.md/CLAUDE.md — кл.6 ECOSYSTEM/FOREIGN.
# Порядок существенен: канон и антипаттерн содержат «путеподобные» вхождения.
line_allowed() {
  local line="$1"
  # кл.6 FOREIGN — канон-пути спек плагина nauta (никогда не указывали в это дерево)
  if printf '%s' "$line" | grep -qE 'content/40-architecture/ADR-[0-9]'; then
    return 0
  fi
  # кл.6 — антипаттерн-корпус link-form-контракта: markdown-ссылка на content/…
  if printf '%s' "$line" | grep -qF '](content/'; then
    return 0
  fi
  # кл.6 — канонический антипаттерн-путь контракта `content/section/…` (фикстурная
  # модель чужого каталога из брифа link-form; тела ассертов suite'ов не меняются,
  # ADR-0021 Решение 3)
  if printf '%s' "$line" | grep -qF 'content/section/'; then
    return 0
  fi
  # кл.6 ECOSYSTEM — «голый» токен-конвенция: ни одного путеподобного вхождения.
  # Путеподобное = content/ + сегмент имени (буквы/цифры/_/-, либо скрытый файл
  # .имя); «content/.» с последующим пробелом (точка конца предложения) — не путь.
  if ! printf '%s' "$line" | grep -qE 'content/([A-Za-z0-9_-]|\.[A-Za-z0-9_-])'; then
    return 0
  fi
  return 1
}

# кл.5 — снять canon-текст управляемых блоков (писатель — /nauta:init, не это дерево).
# Блоки вложены (nauta:layout-map внутри nauta:managed); маркер begin содержит в своём
# тексте литерал nauta:managed:end — поэтому begin проверяется ПЕРВЫМ и поглощает строку.
strip_managed_blocks() {
  awk '
    /nauta:managed:begin/ {mg = 1; next}
    /nauta:managed:end/ {mg = 0; next}
    !mg && /nauta:layout-map:begin/ {lm = 1; next}
    !mg && /nauta:layout-map:end/ {lm = 0; next}
    !mg && !lm {print}
  ' "$1"
}

FILES=$(grep -rl "content/" \
  --include="*.md" --include="*.py" --include="*.sh" \
  --include="*.yaml" --include="*.yml" --include="*.txt" \
  --exclude-dir=.git --exclude-dir=__pycache__ \
  . 2>/dev/null) || true

for f in $FILES; do
  # предмет — отслеживаемое дерево: невеженные рабочие каталоги (.superpowers/ и пр.)
  # не мигрируют и вне FR-125
  is_tracked "${f#./}" || continue
  file_excluded "$f" && continue
  if [ "$f" = "./AGENTS.md" ] || [ "$f" = "./CLAUDE.md" ]; then
    # кл.5: внутри блоков канон нечитаем; вне блоков (FR-127, коммит D3) запрещено
    # любое упоминание content/ — включая «голый» токен.
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      record "$f:$line"
    done < <(strip_managed_blocks "$f" | grep -n "content/" 2>/dev/null | sed 's/^[0-9]*://')
  else
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if line_allowed "$line"; then
        continue
      fi
      record "$f:$line"
    done < <(grep -n "content/" "$f" 2>/dev/null)
  fi
done

TOTAL=$(wc -l <"$VIOLATIONS" | tr -d ' ')
LIMIT="${DOCS_MIGRATION_OUTPUT_LIMIT:-40}"
if [ "${TOTAL:-0}" -gt 0 ]; then
  fail "AC-003/FR-125: найдено $TOTAL строк с указателями/путями content/ вне исключений Решения 3 ADR-0021:"
  head -n "$LIMIT" "$VIOLATIONS" >&2
  if [ "${TOTAL:-0}" -gt "$LIMIT" ]; then
    printf "  ... и ещё %d строк (полный список: DOCS_MIGRATION_OUTPUT_LIMIT=%d bash %s)\n" "$((TOTAL - LIMIT))" "$TOTAL" "$0" >&2
  fi
  printf "  Каждая строка обязана быть переписана на docs/ (POINTER) либо классифицирована\n" >&2
  printf "  в Решение 3 ADR-0021 с расширением file_excluded/line_allowed здесь (класс + основание).\n" >&2
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-003: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-003: литерал content/ вне исключений Решения 3 ADR-0021 не встречается\n"
exit 0
