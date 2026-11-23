#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-029-icon-custom-present.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-156 (FR-153)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (та же фикстура icons-missing
# с добавленным .icons/my-custom-icon.svg — находка исчезает; ADR-0024 Решения 1/2)
# Проверка: та же фикстура + существующий .icons/my-custom-icon.svg → вывод НЕ называет код
# Warden (зелёный при рождении, 99201c0): проверки иконок нет, поэтому упоминаний ноль уже
# сегодня; ассерт защищает от ЛОЖНЫХ находок W035 на СУЩЕСТВУЮЩЕМ файле иконки после реализации.
# Фикстура копируется во временный каталог и дополняется .icons/my-custom-icon.svg — единственная
# дельта между прогонами AC-155 и AC-156 гарантированно один файл.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/icons-missing"

TMP="$(mktemp -d)" || { echo "  FAIL: AC-156 — mktemp недоступен" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

cp -R "$FIXTURE" "$TMP/"
mkdir -p "$TMP/icons-missing/.icons"
printf '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"/>\n' > "$TMP/icons-missing/.icons/my-custom-icon.svg"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$TMP/icons-missing" 2>&1) || true

if echo "$OUT" | grep -qF 'my-custom-icon'; then
  echo "  FAIL: AC-156 — при существующем .icons/my-custom-icon.svg валидатор НЕ должен упоминать код 'my-custom-icon' (FR-153)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-029: AC-156 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-029: AC-156 — существующая .icons-иконка находки не даёт"
