#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-007-cross-catalog-not-migrated.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-007 (FR-085).
# ADR: content/00-project/adr/0016-link-form-contract.md, Context — «зависимость на ADR-0017,
#   не решается здесь»: практический вывод FR-085 (кросс-каталожная ссылка остаётся
#   код-спаном) остаётся в силе для этой миграции независимо от исхода ADR-0017.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py не существует).
#
# «Вакуумная истина» — как в ac-002/ac-004: позитивная гарантия сначала, негативная проверка
# только затем.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

BEFORE=$(cat "$WORKDIR/content/cross-catalog-source.md")

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=2 2>&1)

if ! grep -qE '\[[^]]+\]\([./]*nav-target\.md\)' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-007 (позитивная гарантия) — известный NAV-кейс nav-source.md не смигрирован; тест не может отличить «кросс-каталожное защищено» от «инструмент вообще не запускался»" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

AFTER=$(cat "$WORKDIR/content/cross-catalog-source.md")
if [ "$BEFORE" != "$AFTER" ]; then
  echo "  FAIL: AC-007 — cross-catalog-source.md изменён миграцией: код-спан на путь вне текущего .doc-root.yaml-каталога не должен превращаться в markdown-ссылку (FR-085)" >&2
  diff <(echo "$BEFORE") <(echo "$AFTER") >&2
  FAIL=$((FAIL + 1))
fi
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if ! grep -qF '`other-catalog/path/to/file.md`' "$WORKDIR/content/cross-catalog-source.md"; then
  echo "  FAIL: AC-007 — код-спан other-catalog/path/to/file.md исчез из cross-catalog-source.md" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: кросс-каталожный код-спан не мигрирует (regression guard, FR-085)"
