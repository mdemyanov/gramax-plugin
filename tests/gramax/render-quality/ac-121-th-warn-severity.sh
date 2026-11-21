#!/usr/bin/env bash
# tests/gramax/render-quality/ac-121-th-warn-severity.sh
# Требование: docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md — AC-121 (FR-200)
# Дизайн: docs/40-architecture/2026-11-21-render-quality-wave2-design.md, Решение 4
#   (подтверждённый 200 -> понижение синхронно в двух носителях: атрибут
#   "severity": "warn" в записи killerTags тегов th + severity-aware киллерный проход
#   validate_render.py; warn баланс th НЕ подавляет; rc-контракт 0/1/2 не меняется).
# Проверка (контракт, офлайн — валидатор чисто stdlib, сети нет):
#   A) gramax-render-rules.json: запись th носит severity="warn", WARN-семантика
#      сообщения (без «HTTP 500»), подсказка замены <td> + header="row" сохранена;
#   B) прогон валидатора на фикстуре th-in-table: warn-строки, ERROR нет, «HTTP 500»
#      нет, rc=0 (WARN rc не красит — NFR-001);
#   C) несбалансированный <th> (временный дубль): балансовый ERROR «Несбалансированный
#      <th>» присутствует, киллер — warn, rc=1 (поглощение баланса только для
#      ERROR-киллера, NFR-083: понижение не ослабляет правило баланса);
#   D) инлайновый <note> (временный дубль): остаётся ERROR, rc=1 (дефолт severity
#      других носителей не меняется — подтверждённые киллеры не мягчеют).
# Цвет при создании: КРАСНЫЙ — оба носителя держат th в ERROR-семантике: severity-атрибута
#   нет, киллер даёт E() («Тег <th> … → HTTP 500»), th-баланс подавлен безусловно
#   (замер 2026-11-21: th-in-table -> ERROR L8/L9, rc=1; дубль с несбалансированным th ->
#   только киллер, балансовой строки нет). Закрывает Dev в цикле понижения (FR-202).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
RULES="$ROOT/plugins/gramax/gramax-render-rules.json"
VALIDATOR="$ROOT/plugins/gramax/scripts/validate_render.py"
FIXTURE="$ROOT/tests/gramax/render-quality/fixtures/th-in-table.md"
source "$SCRIPT_DIR/lib/assert.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/render-quality-ac-121.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAIL=0

run_validator() { # $1 = файл .md; выставляет V_OUT / V_RC
  if V_OUT="$(python3 "$VALIDATOR" "$1" 2>&1)"; then
    V_RC=0
  else
    V_RC=$?
  fi
}

# --- A) контрактный носитель: атрибут severity + WARN-семантика сообщения ---
PY_OUT="$(python3 -I - "$RULES" <<'PYEOF'
import json, sys
rules = json.load(open(sys.argv[1], encoding="utf-8"))
killers = [i for i in rules.get("killerTags", []) if isinstance(i, dict) and i.get("tag") == "th"]
if not killers:
    print("TH_ENTRY=absent")
else:
    entry = killers[0]
    msg = str(entry.get("message", ""))
    print("TH_ENTRY=present")
    print("SEVERITY=%s" % entry.get("severity", "<absent>"))
    print("MSG_HAS_TD=%s" % ("true" if "<td>" in msg else "false"))
    print("MSG_HAS_HEADER_ROW=%s" % ("true" if "header=\"row\"" in msg else "false"))
    print("MSG_HAS_HTTP500=%s" % ("true" if "HTTP 500" in msg else "false"))
PYEOF
)"
assert_grep "$RULES" "killerTags" "AC-121: контрактный носитель читаем (killerTags в дереве)"
if printf '%s\n' "$PY_OUT" | grep -qF "TH_ENTRY=absent"; then
  echo "  FAIL: AC-121 — запись th исчезла из killerTags (носитель severities сломан: membership th держит W034-подавление validate_structure, ADR-0019 Решение 3)" >&2
  FAIL=$((FAIL + 1))
else
  if ! printf '%s\n' "$PY_OUT" | grep -qE '^SEVERITY=warn$'; then
    echo "  FAIL: AC-121 — запись killerTags th обязана носить атрибут \"severity\": \"warn\" (Решение 4, носитель 1); сейчас:" >&2
    printf '%s\n' "$PY_OUT" | grep -E "SEVERITY=" >&2
    FAIL=$((FAIL + 1))
  fi
  assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'MSG_HAS_HTTP500=true' || true)" "0" "AC-121: сообщение th — WARN-семантика (рекомендация), без констатации сбоя «HTTP 500»"
  assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'MSG_HAS_TD=true' || true)" "1" "AC-121: подсказка замены <td> сохранена в сообщении th"
  assert_eq "$(printf '%s\n' "$PY_OUT" | grep -c 'MSG_HAS_HEADER_ROW=true' || true)" "1" "AC-121: подсказка header=\"row\" сохранена в сообщении th"
fi

# --- B) валидатор на th-in-table: warn, не ERROR; rc=0 ---
run_validator "$FIXTURE"
assert_eq "$V_RC" "0" "AC-121: th-WARN не красит exit — rc=0 (rc-контракт 0/1/2 не меняется, NFR-001)"
ERROR_COUNT_B="$(printf '%s\n' "$V_OUT" | grep -c 'ERROR L' || true)"
assert_eq "$ERROR_COUNT_B" "0" "AC-121: прогон на th-in-table без ERROR-строк (понижение оба носителя, не только json)"
WARN_COUNT_B="$(printf '%s\n' "$V_OUT" | grep -c 'warn  L' || true)"
assert_eq "$WARN_COUNT_B" "2" "AC-121: th-in-table даёт две warn-строки (th на L8 и L9)"
assert_eq "$(printf '%s\n' "$V_OUT" | grep -c 'HTTP 500' || true)" "0" "AC-121: WARN-семантика th без «HTTP 500» (рекомендация, не констатация сбоя рендера)"

# --- C) несбалансированный th: баланс НЕ подавлен warn-киллером ---
cat > "$TMP/unbalanced-th.md" <<'EOF'
---
title: "Дубль ac-121: несбалансированный th"
order: 1
---

<table>
  <tr>
    <th>Незакрытая шапка
    <td>Значение</td>
  </tr>
</table>
EOF
run_validator "$TMP/unbalanced-th.md"
assert_eq "$V_RC" "1" "AC-121: балансовый ERROR по несбалансированному th красит rc=1 (баланс не подавлен warn-киллером, NFR-083)"
if ! printf '%s\n' "$V_OUT" | grep -qF "Несбалансированный <th>"; then
  echo "  FAIL: AC-121 — несбалансированный <th> обязан давать ERROR баланса «Несбалансированный <th>»: warn-киллер не поглощает th-баланс (Решение 4, п. 2; NFR-083); сейчас баланс подавлен безусловно" >&2
  printf '%s\n' "$V_OUT" | head -8 >&2
  FAIL=$((FAIL + 1))
fi
assert_eq "$(printf '%s\n' "$V_OUT" | grep -c 'HTTP 500' || true)" "0" "AC-121: киллер th на дубле — warn без «HTTP 500»"

# --- D) дефолт severity других носителей не меняется ---
cat > "$TMP/inline-note.md" <<'EOF'
---
title: "Дубль ac-121: инлайновый note"
order: 1
---

<note>инлайн</note>
EOF
run_validator "$TMP/inline-note.md"
assert_eq "$V_RC" "1" "AC-121: подтверждённый киллер (инлайновый note) остаётся ERROR, rc=1 — дефолт severity=error не меняется"
if ! printf '%s\n' "$V_OUT" | grep -qF "Инлайновый <note>"; then
  echo "  FAIL: AC-121 — инлайновый <note> обязан оставаться ERROR (severity-aware проход не мягчит прочие носители)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-121: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-121: th = warn в обоих носителях, баланс th не подавлен, прочие киллеры ERROR, rc-контракт 0/1/2 сохранён"
