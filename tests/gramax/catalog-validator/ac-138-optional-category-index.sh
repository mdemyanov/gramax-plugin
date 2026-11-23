#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-138-optional-category-index.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-138 (FR-217)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.1 (ключ
# indexPolicy.subfolderOptionalFlag), §2.4 (сообщение дословно), §6 границы (снимает только
# строго YAML true); ADR-0026 Решение 4; beads gramax-4jf.10.
# Проверка (вариант .doc-root.yaml подставляется во временную копию каталога с подпапкой
# без _index.md):
#   (a) optionalCategoryIndex: true → ошибки нет;
#   (b) "true" строкой / false / без флага → ERROR остаётся с новой формулировкой
#       (префикс missing _index.md сохранён, текст «раздела в дереве нет, статьи подняты
#       выше»);
#   (c) контракт: indexPolicy.subfolderOptionalFlag == "optionalCategoryIndex".
# Red on 7553da1: флаг не читается (validate_structure.py:312-313) — все четыре варианта
#   дают ERROR со старой формулировкой «Gramax не покажет раздел в навигации»
#   (замер 2026-11-23); ключа subfolderOptionalFlag в контракте нет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-138-optional-index"
RULES_JSON="$ROOT/plugins/gramax/gramax-catalog-rules.json"

run_variant() {
  local variant="$1"
  local tmp
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/ac-138.XXXXXX")
  cp -R "$FIXTURE/" "$tmp/"
  cp "$FIXTURE/variants/$variant.doc-root.yaml" "$tmp/.doc-root.yaml"
  (cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$tmp" 2>&1)
  rm -rf "$tmp"
}

# --- (a): флаг true снимает ошибку ---
if OUT_TRUE=$(run_variant flag-true); then
  RC_TRUE=0
else
  RC_TRUE=$?
fi
if printf '%s\n' "$OUT_TRUE" | grep -qF 'missing _index.md'; then
  echo "  FAIL: AC-138 — optionalCategoryIndex: true обязан снять ERROR «missing _index.md» у подпапки (движок строит раздел сам)" >&2
  FAIL=$((FAIL + 1))
fi
assert_exit_zero "$RC_TRUE" "AC-138: каталог с флагом true и подпапкой без _index.md — rc=0 (замер 2026-11-23: rc=1)"

# --- (b): строка "true", false и отсутствие флага — ERROR остаётся с новой формулировкой ---
for variant in flag-string flag-false no-flag; do
  OUT_V=$(run_variant "$variant")
  if ! printf '%s\n' "$OUT_V" | grep -qF 'missing _index.md'; then
    echo "  FAIL: AC-138 — вариант $variant: ERROR «missing _index.md» обязан остаться (снимает только строго YAML true)" >&2
    FAIL=$((FAIL + 1))
  fi
  if printf '%s\n' "$OUT_V" | grep -qF 'Gramax не покажет раздел в навигации'; then
    echo "  FAIL: AC-138 — вариант $variant: старая формулировка «Gramax не покажет раздел в навигации» обязана уйти (неверно описывает эффект)" >&2
    FAIL=$((FAIL + 1))
  fi
  if ! printf '%s\n' "$OUT_V" | grep 'missing _index.md' | grep -qF 'подняты выше'; then
    echo "  FAIL: AC-138 — вариант $variant: новая формулировка обязана называть «раздела в дереве нет, статьи подняты выше» (дизайн §2.4 дословно)" >&2
    FAIL=$((FAIL + 1))
  fi
  if ! printf '%s\n' "$OUT_V" | grep 'missing _index.md' | grep -qF 'optionalCategoryIndex'; then
    echo "  FAIL: AC-138 — вариант $variant: формулировка обязана упоминать optionalCategoryIndex (дизайн §2.4 дословно)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- (c): контракт — имя флага переехало из кода в контракт ---
FLAG=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("indexPolicy",{}).get("subfolderOptionalFlag",""))' "$RULES_JSON" 2>/dev/null)
assert_eq "$FLAG" "optionalCategoryIndex" "AC-138: indexPolicy.subfolderOptionalFlag = optionalCategoryIndex в контракте (BR-002; красный на 7553da1 — ключа нет)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-138: AC-138 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-138: AC-138 — флаг снимает ошибку строго true, формулировка новая, флаг объявлен в контракте"
