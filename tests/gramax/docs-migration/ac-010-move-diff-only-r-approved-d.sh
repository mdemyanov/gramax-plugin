#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-010-move-diff-only-r-approved-d.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-010
# (NFR-001/002/005, инвариант полноты переезда).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 7 — meaningful+green
# после коммита C и до конца цепочки (содержательно наполняется уже с B).
# Контракт: дифф миграции base..HEAD по content/ и docs/ не содержит созданий (A —
# никакого delete+create вместо move); удаления D — только 21 одобренный путь
# (19 FR-129 + поглощаемые content/.doc-root.yaml и content/_index.md); перемещения — R.
# Отклонение от буквальной формулировки AC («остальные строки — R/R100»), зафиксированное
# с обеими сторонами: цепочка ADR-0021 порождает неизбежные строки M на стороне docs/ —
# коммит A (Решение 7: docs/.doc-root.yaml — супермножество enum + «Плагин»,
# docs/_index.md — поглощение роли корневого индекса, docs/onboarding-nauta.md — backfill
# «Плагин») и переписывание указателей FR-125 в переезжающих статьях после коммита C
# (мертвые ссылки на удаляемое снимаются — измерение дает десятки таких правок).
# Буквальный запрет M сделал бы AC неисполнимым одновременно с FR-125/FR-128.
# Зубы критерия сохраняются полностью: A запрещены (никакого delete+create), D — только
# 21 одобренный путь, сторона content/ допустима ТОЛЬКО в R (M на content/ означал бы,
# что файл до сих пор живёт под content/ — противоречит AC-001 и запрещается здесь).
# BASE = HEAD на момент старта работ (QA-author, 2026-11-17); по ADR-0021 (Решение 7)
# base уже содержит требование и ADR-0021 — строки A в цепочке отсутствуют.
# RED on 8b2db0b (дерево до миграции): миграция не исполнена, content/ существует —
# дифф base..HEAD по content//docs/ пуст, проверка pre-guard'ом честно красная
# (не зелёно-по-пустоте).
# Окно заморожено (PM, 2026-11-18, правка AC-010 требования): END = конец Dev-цепочки
# (ad7f1a4, шаг D4). Пост-цепочечные коммиты (фикс docs/overlays, регистрация отчёта
# qa-057, ре-ключи ассертов) за окном — их дисциплину несут гейты их собственных
# коммитов; открытый ..HEAD ронял бы AC-010 на любом легитимном пост-цепочечном
# коммите, трогающем docs/.

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

BASE="8b2db0bdb41643551163d7dcbdbe5c5c5c171c53"
# Конец окна — конец Dev-цепочки миграции (шаг D4); см. комментарий выше.
END="ad7f1a4db844f580fff32618ed4ca140c6cadd12"

# 21 одобренный путь удаления: 19 FR-129 + 2 поглощаемых при слиянии (FR-128).
approved_deletion() {
  case "$1" in
    docs/superpowers/_index.md | \
      docs/superpowers/plans/2026-05-08-apply-project-template.md | \
      docs/superpowers/plans/2026-08-07-nauta-integration.md | \
      docs/superpowers/plans/2026-08-09-test-harness-taxonomy.md | \
      docs/superpowers/plans/2026-08-12-healthcheck-port-plan.md | \
      docs/superpowers/plans/_index.md | \
      docs/superpowers/specs/2026-05-08-apply-project-template-design.md | \
      docs/superpowers/specs/2026-08-07-nauta-integration-design.md | \
      docs/superpowers/specs/2026-08-12-healthcheck-port-design.md | \
      docs/superpowers/specs/_index.md | \
      content/60-implementation/test-reports/2026-05-08-diagram-on-demand-qa-report.md | \
      content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md | \
      content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md | \
      content/60-implementation/test-reports/2026-05-12-mermaid-file-based-qa-report.md | \
      content/60-implementation/test-reports/2026-08-10-test-harness-taxonomy-qa-report.md | \
      content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md | \
      content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md | \
      content/60-implementation/acceptance/2026-05-11-routing-mermaid-drawio.md | \
      docs/doc-paths-disposition.md | \
      content/.doc-root.yaml | \
      content/_index.md) return 0 ;;
    *) return 1 ;;
  esac
}

# Pre-guard: до миграции дифф пуст и проверка была бы зелёной по пустоте —
# честный red состоит в том, что конечное состояние ещё не достигнуто.
if [ -d content ]; then
  fail "AC-010/NFR-001/002/005: миграция не исполнена (content/ существует на 8b2db0b) — конечное состояние диффа ещё не достижимо"
fi

if ! git cat-file -e "${BASE}^{commit}" 2>/dev/null; then
  fail "AC-010: base $BASE не существует в истории — проверка не может быть исполнена честно"
fi

DIFF_OUT=$(git diff --name-status "${BASE}..${END}" -- content/ docs/ 2>/dev/null) || true
if [ -z "$DIFF_OUT" ]; then
  fail "AC-010: дифф ${BASE}..${END} по content//docs/ пуст — переезд не отразился в истории (маскировка отказа)"
fi

while read -r STATUS REST; do
  [ -n "$STATUS" ] || continue
  case "$STATUS" in
    A)
      fail "AC-010/NFR-001: строка A (создание вместо переезда): $REST"
      ;;
    D)
      if ! approved_deletion "$REST"; then
        fail "AC-010/NFR-002: удаление вне одобренных 21 путей: $REST"
      fi
      ;;
    R[0-9]*)
      # R/R100 — распознанное переименование; законно (NFR-001/005).
      :
      ;;
    M)
      # Правки на стороне docs/ — законные правки FR-125/FR-128 (коммит A и
      # переписывание указателей после переезда). M на стороне content/ означал бы
      # файл, живущий под content/ в HEAD, — противоречит AC-001.
      case "$REST" in
        docs/*)
          :
          ;;
        *)
          fail "AC-010: правка M на стороне content/ (файл живёт вне docs/): $REST"
          ;;
      esac
      ;;
    *)
      fail "AC-010: неожиданный статус '$STATUS': $REST"
      ;;
  esac
done <<<"$DIFF_OUT"

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-010: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-010: дифф миграции — только R и одобренные D/M коммита A\n"
exit 0
