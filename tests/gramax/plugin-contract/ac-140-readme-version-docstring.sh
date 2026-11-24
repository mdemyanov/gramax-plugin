#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-140-readme-version-docstring.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-140 (FR-221a)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-140
# («проверка версии README сравнивает её с plugin.json»); beads gramax-4jf.12.
# Проверка:
#   (a) версия в plugins/gramax/README.md (раздел «Версия») равна version из
#       plugins/gramax/.claude-plugin/plugin.json;
#   (b) докстринг validate_render согласован с gramax-render-rules.json: th носит
#       severity warn — докстринг не подаёт th как ERROR-киллер «HTTP 500» в
#       перечислении «Обнаруживает конструкции…», и несёт th+WARN вместе
#       (якорь тега: <th>[^.]*warn / warn[^.]*<th> — ADR-0029 Решение 5, строка 3;
#       наживка без тега «Without any doubt the linter may warn here» не проходит);
#   (c) запасной ERROR-текст не подаётся как действующий: литерала
#       «Тег <th> не поддерживается Gramax → HTTP 500.» нет в README и докстринге
#       (регресс-нога, зелёная от рождения).
# Red on 7553da1 (2026-11-23): README называет 4.8.0, plugin.json — 4.9.0;
#   докстринг validate_render.py:5-6 перечисляет <th> среди «роняют рендерер GES
#   (HTTP 500)», тогда как контракт несёт th severity warn с 4.9.0.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"
README="$ROOT/plugins/gramax/README.md"
RULES_JSON="$ROOT/plugins/gramax/gramax-render-rules.json"
RENDER_PY="$ROOT/plugins/gramax/scripts/validate_render.py"

# --- (a): версия README == version plugin.json ---
PV=$(python3 -c "import json;print(json.load(open('$PLUGIN_JSON')).get('version','MISSING'))" 2>/dev/null || echo PARSE_ERROR)
RV=$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+ — см\. \[CHANGELOG' "$README" 2>/dev/null | head -1 | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || echo MISSING)

if [ "$PV" = "MISSING" ] || [ "$PV" = "PARSE_ERROR" ]; then
  echo "  FAIL: AC-140 — версия plugin.json не читается ($PV)" >&2
  FAIL=$((FAIL + 1))
elif [ "$RV" = "MISSING" ]; then
  echo "  FAIL: AC-140 — раздел «Версия» README.md не несёт строки «X.Y.Z — см. [CHANGELOG.md]»" >&2
  FAIL=$((FAIL + 1))
else
  assert_eq "$RV" "$PV" "AC-140 — версия README ($RV) равна версии plugin.json ($PV; красный на 7553da1: README 4.8.0 против plugin.json 4.9.0)"
fi

# --- (b): докстринг согласован с контрактом (th — WARN) ---
TH_SEVERITY=$(python3 -c "
import json, sys
rules = json.load(open('$RULES_JSON', encoding='utf-8'))
sev = 'absent'
for item in rules.get('killerTags', []):
    if isinstance(item, dict) and item.get('tag') == 'th':
        sev = str(item.get('severity') or 'error')
print(sev)
" 2>/dev/null || echo PARSE_ERROR)
assert_eq "$TH_SEVERITY" "warn" "AC-140 — предпосылка контракта: th в killerTags несёт severity warn (замер носителя 2026-11-21; красный здесь = порча контракта, триаж)"

DOCSTRING=$(python3 -c "
import ast
tree = ast.parse(open('$RENDER_PY', encoding='utf-8').read())
print(ast.get_docstring(tree) or '')
" 2>/dev/null)

FIRST_SENTENCE=$(python3 -c "
import ast, re
tree = ast.parse(open('$RENDER_PY', encoding='utf-8').read())
doc = ast.get_docstring(tree) or ''
flat = ' '.join(doc.split())
m = re.search(r'Обнаруживает конструкции[^.]*\.', flat)
print(m.group(0) if m else '')
" 2>/dev/null)

if [ -n "$FIRST_SENTENCE" ] && printf '%s\n' "$FIRST_SENTENCE" | grep -qF '<th>'; then
  echo "  FAIL: AC-140 — докстринг подаёт <th> в перечислении конструкций, «роняющих рендерер GES (HTTP 500)»: контракт несёт th severity warn (с 4.9.0)" >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$DOCSTRING" | grep -qiE '<th>[^.]*warn|warn[^.]*<th>'; then
  echo "  FAIL: AC-140 — докстринг обязан называть th WARN-семантику (согласованность с gramax-render-rules.json)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b2): регекс заякорен на литерал тега (ADR-0029 Решение 5, строка 3):
# th[^.]*warn проходило предложение без тега («Without any doubt the linter may warn
# here» — «With**out** … may **warn**»); усиленный <th>[^.]*warn / warn[^.]*<th> — нет.
# Наживка — самопроверка якоря: зелёная нога только при тег-заякоренном регексе.
BAIT="Without any doubt the linter may warn here"
if printf '%s\n' "$BAIT" | grep -qiE '<th>[^.]*warn|warn[^.]*<th>'; then
  echo "  FAIL: AC-140 — регекс нога (b) не заякорен на литерал <th>: наживка без тега" >&2
  echo "  проходит (ADR-0029 Решение 5, строка 3: <th>[^.]*warn или warn[^.]*<th>)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): запасной ERROR-текст не подаётся как действующий ---
FALLBACK="Тег <th> не поддерживается Gramax → HTTP 500."
assert_no_grep "$README" "$FALLBACK" "AC-140 — запасной ERROR-текст не подаётся в README как действующий"
if printf '%s\n' "$DOCSTRING" | grep -qF "$FALLBACK"; then
  echo "  FAIL: AC-140 — запасной ERROR-текст не подаётся в докстринге как действующий" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-140: AC-140 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-140: AC-140 — версия README = plugin.json, докстринг согласован с контрактом (th — WARN)"
