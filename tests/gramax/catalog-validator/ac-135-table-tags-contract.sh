#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-135-table-tags-contract.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-135 (FR-214)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.2, ADR-0026
# Решение 2 (TABLE_TAGS движка: tableTransform.ts:11; баланс — только validate_render, BR-027);
# Contract-строка в CHANGELOG — нога приёмки Dev, не стаба.
# Проверка:
#   (a) валидная XML-таблица (table/tr/td) → ноль W034 (замер 2026-11-23: W034 на каждый тег);
#   (b) незакрытый <td> → validate_structure НЕ балансирует (ноль «unpaired <td>»/баланса) —
#       баланс ведёт validate_render, один дефект — одна находка (BR-027; зелёная нога);
#   (c) genuinely неизвестный тег <mywidget> → W034 остаётся (known_tags не расширился сверх);
#   (d) контракт: schemaVersion 3, pairedTags содержат table, tr, td; th — по-прежнему нет.
# Red on 7553da1: в pairedTags gramax-tags.json нет table/tr/td (замер 2026-11-23:
#   три W034 на валидную таблицу; schemaVersion 2).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-135-table"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

# --- (a): W034 на table/tr/td уходят ---
if printf '%s\n' "$OUT" | grep "W034" | grep -qE '<(table|tr|td)>'; then
  echo "  FAIL: AC-135 — W034 на table/tr/td: теги обязаны войти в known_tags через pairedTags (TABLE_TAGS движка, FR-214)" >&2
  printf '%s\n' "$OUT" | grep "W034" | grep -E '<(table|tr|td)>' >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): баланс table/tr/td остаётся за validate_render (BR-027) ---
if printf '%s\n' "$OUT" | grep -qE 'unpaired <(table|tr|td)>'; then
  echo "  FAIL: AC-135 (BR-027) — validate_structure не должен балансировать table/tr/td: один дефект — одна находка от validate_render" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): неизвестный тег по-прежнему даёт W034 ---
if ! printf '%s\n' "$OUT" | grep "W034" | grep -qF '<mywidget>'; then
  echo "  FAIL: AC-135 — genuinely неизвестный тег <mywidget> обязан сохранить W034: known_tags не расширяется сверх контракта" >&2
  FAIL=$((FAIL + 1))
fi

assert_eq "$RC" "0" "AC-135: каталог с таблицами без прочих дефектов — чист по ERROR (rc=0)"

# --- (d): контракт тегов ---
assert_eq "$(python3 -c 'import json;print(json.load(open(sys.argv[1],encoding="utf-8")).get("schemaVersion"))' "$TAGS_JSON" 2>/dev/null)" "3" \
  "AC-135: schemaVersion gramax-tags.json = 3 (ADR-0026 Решение 2; замер 2026-11-23: 2)"

PAIRED=$(python3 -c 'import json,sys;print(",".join(json.load(open(sys.argv[1],encoding="utf-8")).get("pairedTags",[])))' "$TAGS_JSON" 2>/dev/null)
for tag in table tr td; do
  if ! printf '%s' "$PAIRED" | grep -qE "(^|,)$tag(,|$)"; then
    echo "  FAIL: AC-135 — $tag отсутствует в pairedTags gramax-tags.json (FR-214, ADR-0026 Решение 2)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if printf '%s' "$PAIRED" | grep -qE '(^|,)th(,|$)'; then
  echo "  FAIL: AC-135 — th не входит в pairedTags: его носитель gramax-render-rules.json (§2.2)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-135: AC-135 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-135: AC-135 — table/tr/td известны, баланс не дублируется, контракт schemaVersion 3"
