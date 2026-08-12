#!/usr/bin/env bash
# tests/gramax/link-form-migration/ac-005-migration-form.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-005 (FR-080, FR-081,
#   BR-002).
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 2 — временный протокол:
#   собственный корпус пишет НОВЫЕ ссылки с явным `.md`-суффиксом, пока апстрим nauta не
#   починен. Это НЕ буквальная формулировка FR-080 «без расширения» — фактический проверяемый
#   контракт для ЭТОГО репозитория, см. заголовок задачи QA-author.
# Природа: живой контракт — КРАСНЫЙ на момент создания (migrate_nav_codespans.py не существует).
#
# Форма — построчное сравнение (AC-005 буквально требует «не визуальным ревью»): три
# раздельных grep-ассерта, не единый широкий паттерн: (1) текст ссылки = title цели из
# frontmatter (механический дефолт, «Бриф для Dev» п. 5); (2) href = относительный путь С
# ЯВНЫМ `.md`-суффиксом (временный протокол ADR-0016 Решение 2); (3) href НЕ содержит префикс
# имени doc-root-каталога (FR-081/BR-002).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"

FAIL=0
WORKDIR="$(copy_composite_fixture "$SCRIPT_DIR")"
trap 'rm -rf "$WORKDIR"' EXIT

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/migrate_nav_codespans.py "$WORKDIR/content" --fix --yes --expect-count=2 2>&1)

# (1) + (2): текст ссылки = title цели ("Цель миграции NAV"), href оканчивается на .md явно,
# путь относителен (без ../ здесь — оба файла в одном каталоге).
if ! grep -qE '\[Цель миграции NAV\]\([./]*nav-target\.md\)' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-005 — nav-source.md не содержит ожидаемую markdown-ссылку '[Цель миграции NAV](nav-target.md)' (текст = title цели, href с явным .md — ADR-0016 Решение 2)" >&2
  echo "  --- фактическое содержимое nav-source.md ---" >&2
  cat "$WORKDIR/content/nav-source.md" >&2
  echo "  --- вывод миграции ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# (3): href НЕ несёт префикс имени doc-root-каталога (FR-081/BR-002) — антипаттерн
# `content/nav-target.md` внутри href запрещён инвариантно.
if grep -qE '\]\([./]*content/nav-target\.md\)' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-005 — href содержит запрещённый префикс имени doc-root-каталога ('content/nav-target.md') — антипаттерн FR-081/BR-002" >&2
  FAIL=$((FAIL + 1))
fi

# Исходный код-спан заменён, не задублирован рядом с новой ссылкой.
# shellcheck disable=SC2016  # литеральный код-спан markdown (обратные кавычки), не command substitution
if grep -qF '`content/nav-target.md`' "$WORKDIR/content/nav-source.md"; then
  echo "  FAIL: AC-005 — исходный код-спан 'content/nav-target.md' всё ещё присутствует буквально рядом с новой ссылкой (не заменён, задублирован)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: форма результата миграции — markdown-ссылка с явным .md-суффиксом, без префикса doc-root-каталога"
