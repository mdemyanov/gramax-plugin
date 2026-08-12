#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-001-nav-classification-deterministic.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-001 (FR-077).
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 3 (existence+scope —
#   механичны; directionality — эвристика по маркерным фразам «см.», «зафиксировано в» и т.п.).
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py — Dev-задача,
#   не начата; `uv run` на несуществующий файл завершается ненулевым кодом, отчёт не содержит
#   ожидаемой находки — тест падает по правильной причине).
#
# Контракт отчёта (report-mode, без --fix) — QA-author предполагает минимальный рабочий
# формат `<путь>:<номер строки>` где-то в stdout для каждого NAV-кандидата, по прецеденту
# tests/gramax/mermaid-adoption/ac-002-detection-true-positives.sh, не привязываясь к точному
# словесному лейблу класса кроме регистронезависимого вхождения "nav". Если реальный формат
# Dev расходится — поправьте regex вместе с обоснованием прямо в этом файле, не убирайте
# ассерт молча (прецедент AC-014, content/60-implementation/acceptance/
# 2026-08-11-validation-contract-at-design.md).
#
# «Вакуумная истина» (content/lessons-learned.md, tests/gramax/mermaid-adoption/README.md):
# если бы инструмент вообще не запускался, оба прогона report-mode дали бы ОДИНАКОВУЮ ошибку
# uv run — diff двух прогонов был бы пустым тривиально. Поэтому детерминизм проверяется ТОЛЬКО
# после позитивной гарантии, что run1 реально нашёл nav-source.md кандидатом.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT1=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" 2>&1)

if ! echo "$OUT1" | grep -qE 'nav-source\.md:[0-9]+'; then
  echo "  FAIL: AC-001 — отчёт (report-mode) не называет content/nav-source.md:<номер строки> как NAV-кандидата" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT1" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$OUT1" | grep -qi 'nav'; then
  echo "  FAIL: AC-001 — отчёт не маркирует находку как NAV (ни одного вхождения слова 'nav' в выводе)" >&2
  FAIL=$((FAIL + 1))
fi

# Детерминизм — только если позитивная гарантия уже выполнена (иначе diff двух ошибок uv run
# был бы тривиально пустым и маскировал бы отсутствие инструмента как «детерминизм»).
if [ "$FAIL" -eq 0 ]; then
  OUT2=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" 2>&1)
  if [ "$OUT1" != "$OUT2" ]; then
    echo "  FAIL: AC-001 — классификация не детерминирована: вывод первого и второго прогона различается" >&2
    diff <(echo "$OUT1") <(echo "$OUT2") >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: NAV-классификация nav-source.md найдена и детерминирована на двух независимых прогонах"
