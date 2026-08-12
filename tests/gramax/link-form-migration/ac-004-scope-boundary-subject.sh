#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-004-scope-boundary-subject.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-004 (FR-077 тест 3
#   «scope», по образцу RES-005 3.4 — гомоним пути из другого репозитория).
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 3 — «existence+scope уже
#   механичны» ссылается на _collect_links (markdown-ссылки), НЕ на код-спаны с прозой вокруг;
#   этот тест — регрессионная защита от НАИВНОЙ механики применительно к код-спанам: код-спан
#   `content/_index.md` физически СУЩЕСТВУЕТ внутри фикстурного каталога (существование
#   мехонически истинно), но по тексту абзаца относится к ДРУГОМУ репозиторию — наивная
#   проверка «файл существует внутри .doc-root.yaml» классифицировала бы его как NAV;
#   корректный классификатор обязан учитывать контекст абзаца, не только резолвить путь.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py не существует).
#
# «Вакуумная истина» — как в ac-002: сначала позитивная гарантия (известный NAV-кейс
# смигрирован), только затем негативная проверка (scope-homonym.md нетронут).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

BEFORE=$(cat "$WORKDIR/content/scope-homonym.md")

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=2 2>&1)

if ! grep -qE '\[[^]]+\]\([./]*nav-target\.md\)' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-004 (позитивная гарантия) — известный NAV-кейс nav-source.md не смигрирован; тест не может отличить «scope защищён» от «инструмент вообще не запускался»" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

AFTER=$(cat "$WORKDIR/content/scope-homonym.md")
if [ "$BEFORE" != "$AFTER" ]; then
  echo "  FAIL: AC-004 — scope-homonym.md изменён миграцией: код-спан-гомоним (существующий файл, но по тексту принадлежащий другому репозиторию) не должен превращаться в markdown-ссылку" >&2
  diff <(echo "$BEFORE") <(echo "$AFTER") >&2
  FAIL=$((FAIL + 1))
fi
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if ! grep -qF '`content/_index.md`' "$WORKDIR/content/scope-homonym.md"; then
  echo "  FAIL: AC-004 — код-спан content/_index.md исчез из scope-homonym.md" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: гомоним чужого репозитория остаётся SUBJECT (scope не пройден), несмотря на существующую цель и NAV-маркер"
