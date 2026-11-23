#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-136-lucide-registry-boundary.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-136 (FR-215)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.3/§3, §6
# границы (регистр — реестр по code.lower(), файл по коду дословно; пустой код — W035);
# ADR-0026 Решение 3 (реестр как контракт; W035 = нет файла И нет в реестре).
# Проверка (каталог с фиксированным набором кодов):
#   (a) голые коды Lucide check/ban/aperture/info → W035 нет (замер 2026-11-23: 4 W035);
#   (b) пользовательский my-custom-x без файла → W035 остаётся (зелёная нога);
#   (c) lucide-zap без файла → W035 С подсказкой убрать префикс (замер 2026-11-23: тишина);
#   (d) xlucide-zap → W035 остаётся (префикс только в начале; зелёная нога);
#   (e) CHECK (реестр по нижнему регистру) → W035 нет (замер 2026-11-23: W035);
#   (f) zap-with-file — файл есть → находки нет даже вне реестра (файл приоритетнее; зелёная);
#   (g) контракт: gramax-lucide-icons.json существует, schemaVersion 1, source
#       lucideReact 0.525.0 / enginePin 48592b36.
# Red on 7553da1: реестра нет, условие code.startswith("lucide-") (validate_structure.py:779)
#   — ноги (a), (c), (e), (g) красные.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-136-icons"
REGISTRY="$ROOT/plugins/gramax/gramax-lucide-icons.json"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-136 — W035 остаётся предупреждением: без --strict валидатор обязан закончить с rc=0" >&2
  FAIL=$((FAIL + 1))
fi

w035_for() {
  printf '%s\n' "$OUT" | grep "W035" | grep -cF "код \"$1\"" || true
}

# --- (a): встроенные коды Lucide — W035 нет ---
for code in check ban aperture info; do
  COUNT=$(w035_for "$code")
  if [ "$COUNT" -gt 0 ]; then
    echo "  FAIL: AC-136 — W035 на встроенном коде Lucide \"$code\": код обязан быть в реестре (lucide-react 0.525.0; пикер пишет голый kebab-case)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- (b): пользовательский код без файла — W035 остаётся ---
COUNT=$(w035_for "my-custom-x")
if [ "$COUNT" -eq 0 ]; then
  echo "  FAIL: AC-136 регрессия — пользовательский код my-custom-x без .icons/my-custom-x.svg обязан давать W035" >&2
  FAIL=$((FAIL + 1))
fi

# --- (c): lucide-префикс без файла — W035 с подсказкой ---
COUNT=$(w035_for "lucide-zap")
if [ "$COUNT" -eq 0 ]; then
  echo "  FAIL: AC-136 — код lucide-zap без файла обязан давать W035 с подсказкой убрать префикс (формы lucide- движок не знает)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep "W035" | grep -F 'lucide-zap' | grep -qi "префикс"; then
  echo "  FAIL: AC-136 — W035 на lucide-zap обязан нести подсказку про префикс (дизайн §2.4, сообщение дословно)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): xlucide-zap — префикс не в начале, пользовательский ---
COUNT=$(w035_for "xlucide-zap")
if [ "$COUNT" -eq 0 ]; then
  echo "  FAIL: AC-136 регрессия — xlucide-zap (префикс не в начале) обязан оставаться пользовательским кодом с W035" >&2
  FAIL=$((FAIL + 1))
fi

# --- (e): регистр — членство в реестре по code.lower() ---
COUNT=$(w035_for "CHECK")
if [ "$COUNT" -gt 0 ]; then
  echo "  FAIL: AC-136 — CHECK обязан резолвиться в реестре по нижнему регистру (движок toCamelCase без приведения файла; дизайн §6)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (f): файл есть — находки нет даже вне реестра ---
COUNT=$(w035_for "zap-with-file")
if [ "$COUNT" -gt 0 ]; then
  echo "  FAIL: AC-136 регрессия — файл .icons/zap-with-file.svg существует: W035 запрещён (файл при рендере приоритетнее)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (g): реестр как контракт ---
assert_file_exists "$REGISTRY" "AC-136 — gramax-lucide-icons.json обязан существовать (ADR-0026 Решение 3; красный на 7553da1 — файла нет)"
if [ -f "$REGISTRY" ]; then
  assert_eq "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("schemaVersion"))' "$REGISTRY" 2>/dev/null)" "1" \
    "AC-136 — schemaVersion реестра = 1"
  assert_eq "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("source",{}).get("lucideReact"))' "$REGISTRY" 2>/dev/null)" "0.525.0" \
    "AC-136 — source.lucideReact = 0.525.0 (bun.lock:3155 движка)"
  assert_eq "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8")).get("source",{}).get("enginePin"))' "$REGISTRY" 2>/dev/null)" "48592b36" \
    "AC-136 — source.enginePin = 48592b36"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-136: AC-136 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-136: AC-136 — голые коды Lucide и реестр молчат, префикс с подсказкой, пользовательский код ловится"
