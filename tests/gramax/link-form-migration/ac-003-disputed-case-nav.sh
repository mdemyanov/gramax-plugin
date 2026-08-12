#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-003-disputed-case-nav.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-003 (FR-079,
#   прецедент RES-005 «Задача 1», строка #83 — content/10-domain/research/
#   2026-08-13-link-form-corpus-audit.md, «Пояснение к спорной строке (# 83)»).
# ADR: content/40-architecture/2026-08-13-link-form-contract-design.md, FR/NFR Mapping —
#   «FR-079 — уже решено требованием, миграционный скрипт применяет решённое правило».
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py не существует).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=2 2>&1)

if ! grep -qE '\[[^]]+\]\([./]*disputed-target\.md\)' "$WORKDIR/content/disputed-source.md"; then
  echo "  FAIL: AC-003 — код-спан на disputed-target.md (прецедент #83, FR-079) не преобразован в markdown-ссылку; ожидалась классификация NAV по СОБСТВЕННОЙ цели код-спана, не SUBJECT/спорно по предмету абзаца" >&2
  echo "  --- фактическое содержимое disputed-source.md ---" >&2
  cat "$WORKDIR/content/disputed-source.md" >&2
  echo "  --- вывод миграции ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if grep -qF '`content/disputed-target.md`' "$WORKDIR/content/disputed-source.md"; then
  echo "  FAIL: AC-003 — исходный код-спан на disputed-target.md всё ещё присутствует буквально (не заменён)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: спорный случай (прецедент #83) классифицирован как NAV по собственной цели код-спана, не по предмету абзаца"
