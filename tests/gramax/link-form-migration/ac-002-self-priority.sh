#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-002-self-priority.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-002 (FR-078, BR-001).
# ADR: content/00-project/adr/0016-link-form-contract.md, «Границы» companion-статьи —
#   «миграционный скрипт не переписывает SELF- и SUBJECT-код-спаны — только NAV».
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py не существует).
#
# «Вакуумная истина» (урок content/lessons-learned.md, tests/gramax/mermaid-adoption/README.md
# «Вакуумная истина»): AC-002 формулируется как ОТСУТСТВИЕ эффекта (self-source.md не должен
# измениться). Пока инструмента нет, --fix --yes не мутирует НИЧЕГО — негативная проверка была
# бы тривиально верна без единой строчки кода Dev. Поэтому сначала — позитивная гарантия, что
# инструмент реально что-то сделал (смигрировал ИЗВЕСТНЫЙ NAV-кейс nav-source.md/nav-target.md
# из той же композитной фикстуры), и только затем — негативная проверка (self-source.md
# нетронут).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

BEFORE_SELF=$(cat "$WORKDIR/content/self-source.md")

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=2 2>&1)

# Позитивная гарантия: известный NAV-кейс реально смигрирован в этом же прогоне.
if ! grep -qE '\[[^]]+\]\([./]*nav-target\.md\)' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-002 (позитивная гарантия) — известный NAV-кейс nav-source.md не смигрирован; --fix --yes, похоже, не выполнил ничего (тест не может отличить «SELF защищён» от «инструмент вообще не запускался»)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

AFTER_SELF=$(cat "$WORKDIR/content/self-source.md")
if [ "$BEFORE_SELF" != "$AFTER_SELF" ]; then
  echo "  FAIL: AC-002 — self-source.md изменён миграцией: SELF-код-спан не должен ни удаляться, ни заменяться ссылкой (BR-001, FR-078)" >&2
  diff <(echo "$BEFORE_SELF") <(echo "$AFTER_SELF") >&2
  FAIL=$((FAIL + 1))
fi
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if ! grep -qF '`content/self-source.md`' "$WORKDIR/content/self-source.md"; then
  echo "  FAIL: AC-002 — код-спан self-source.md на саму себя исчез из текста" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: SELF-код-спан приоритетно защищён от миграции, несмотря на NAV-маркер вокруг"
