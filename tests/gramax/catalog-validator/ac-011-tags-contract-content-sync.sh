#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-011-tags-contract-content-sync.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-005 (FR-038, FR-039)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 3 (JSON — единый
#      источник; validate_structure.py ЧИТАЕТ его вместо хардкода PAIRED_TAGS/SELF_CLOSING —
#      целевое состояние стирает сами литералы кода).
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#
# Пересмотр после ревью PM (см. at-design.md → «Находка: неубиваемый тест», раздел AC-005):
# первая версия сравнивала JSON-контракт на РАВЕНСТВО с PAIRED_TAGS/SELF_CLOSING,
# извлечёнными регуляркой из исходника. Корректный DEV-001 по ADR-0012 Решение 3 удаляет
# эти литералы (код начинает читать JSON) — тест не смог бы позеленеть НИКОГДА, даже при
# идеальной реализации, и активно поощрял бы Dev оставлять хардкод ради зелёного CI —
# нарушение BR-002, которое тест должен ловить, а не провоцировать. Переписано на две
# независимые проверки:
#   (A) SUBSET — контракт обязан содержать ОЖИДАЕМЫЙ минимум тегов, зафиксированный
#       ЛИТЕРАЛЬНО в этом файле (не извлечённый из кода) — FR-038 «как минимум». Не
#       зависит от того, остался ли хардкод в коде: позеленеет от любой корректной
#       реализации DEV-001, включая ту, что полностью убирает PAIRED_TAGS/SELF_CLOSING.
#   (B) DRIFT (условная) — ТОЛЬКО пока литеральные PAIRED_TAGS/SELF_CLOSING ещё
#       обнаруживаются в исходнике (переходный период до завершения рефакторинга),
#       сверяет их с контрактом на равенство и падает при расхождении (сохраняет ценность
#       FR-039 на переходный период). Если констант уже нет (целевое состояние Решения 3)
#       — печатает N/A по каждому списку отдельно, не засчитывает как провал.
#
# Находка для DEV-001 (не чинится этим тестом — см. at-design.md, «Находки для DEV-001»):
# текущий SELF_CLOSING (validate_structure.py:17) не содержит `drawio`, хотя FR-038 прямо
# требует его в контракте — канонический тег плагина с версии 4.1.0
# (`<drawio path="..."/>`). `check_no_drawio` тут ни при чём — та проверка про конвертацию
# `.drawio`-файлов в `.svg`, не про тег. Поэтому ОЖИДАЕМЫЙ набор ниже — текущие константы
# ПЛЮС `drawio`: равенство с сегодняшним SELF_CLOSING дало бы ложный провал на корректном,
# полном контракте. DEV-001 также должен решить судьбу `legacy[]`-записи для старого
# синтаксиса `[drawio:...]` (поле уже отведено ADR-0012 Решение 3).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
VALIDATOR="$ROOT/plugins/gramax/scripts/validate_structure.py"
TAGS_FILE=$(find "$ROOT/plugins/gramax" -iname '*tag*' -iname '*.json' 2>/dev/null | head -1)

if [ -z "$TAGS_FILE" ]; then
  echo "  FAIL: AC-005 — машиночитаемый файл контракта тегов не найден, сверять нечего (зависит от AC-004; DEV-001 создаёт gramax-tags.json)" >&2
  FAIL=$((FAIL + 1))
else
  REPORT=$(python3 - "$TAGS_FILE" "$VALIDATOR" <<'PY'
import json
import re
import sys

tags_file, validator_file = sys.argv[1], sys.argv[2]

# (A) Литерально зафиксированный минимум — НЕ извлекается из кода, поэтому удаление
# хардкода корректным DEV-001 (ADR-0012 Решение 3) не убивает эту проверку.
# EXPECTED_SELF_CLOSING = текущий SELF_CLOSING (validate_structure.py:17) + "drawio"
# (FR-038 требует его явно; собственный код валидатора его не знает — находка для DEV-001).
EXPECTED_PAIRED = {"note", "tabs", "tab", "html", "comment", "color", "highlight"}
EXPECTED_SELF_CLOSING = {"view", "snippet", "openapi", "mermaid", "video", "icon", "image", "drawio"}

try:
    contract = json.load(open(tags_file, encoding="utf-8"))
except (json.JSONDecodeError, OSError) as e:
    print(f"PARSE_ERROR: {tags_file} — {e}")
    sys.exit(1)

if not isinstance(contract, dict):
    print(f"PARSE_ERROR: {tags_file} — верхний уровень JSON не объект")
    sys.exit(1)

contract_paired = set(contract.get("pairedTags") or [])
contract_self_closing = set(contract.get("selfClosingTags") or [])

ok = True

# --- (A) SUBSET: контракт обязан содержать как минимум ожидаемый набор (FR-038) ---
missing_paired = EXPECTED_PAIRED - contract_paired
if missing_paired:
    print(f"SUBSET_FAIL pairedTags: контракт не содержит {sorted(missing_paired)} (FR-038, минимум)")
    ok = False

missing_self_closing = EXPECTED_SELF_CLOSING - contract_self_closing
if missing_self_closing:
    print(f"SUBSET_FAIL selfClosingTags: контракт не содержит {sorted(missing_self_closing)} "
          f"(FR-038, минимум; включает drawio — см. заголовок ac-011)")
    ok = False

# --- (B) DRIFT (условная): только пока хардкод в коде ещё жив (переходный период) ---
src = open(validator_file, encoding="utf-8").read()


def extract_list(name):
    m = re.search(rf"{name}\s*=\s*\[([^\]]*)\]", src)
    if not m:
        return None
    return {t.strip().strip("\"'") for t in m.group(1).split(",") if t.strip()}


code_paired = extract_list("PAIRED_TAGS")
if code_paired is None:
    print("DRIFT_CHECK pairedTags: N/A — PAIRED_TAGS больше не найден как литерал в коде "
          "(целевое состояние ADR-0012 Решение 3 — код читает JSON)")
elif code_paired != contract_paired:
    missing = sorted(code_paired - contract_paired)
    extra = sorted(contract_paired - code_paired)
    print(f"DRIFT_FAIL pairedTags: контракт разошёлся с живым PAIRED_TAGS кода "
          f"(отсутствуют в контракте={missing} лишние в контракте={extra}) — FR-039, переходный период")
    ok = False

code_self_closing = extract_list("SELF_CLOSING")
if code_self_closing is None:
    print("DRIFT_CHECK selfClosingTags: N/A — SELF_CLOSING больше не найден как литерал в коде "
          "(целевое состояние ADR-0012 Решение 3 — код читает JSON)")
elif code_self_closing != contract_self_closing:
    missing = sorted(code_self_closing - contract_self_closing)
    extra = sorted(contract_self_closing - code_self_closing)
    print(f"DRIFT_FAIL selfClosingTags: контракт разошёлся с живым SELF_CLOSING кода "
          f"(отсутствуют в контракте={missing} лишние в контракте={extra}) — FR-039, переходный период")
    ok = False

sys.exit(0 if ok else 1)
PY
)
  REPORT_EXIT=$?
  if [ "$REPORT_EXIT" -ne 0 ]; then
    echo "  FAIL: AC-005 — контракт тегов ($TAGS_FILE) не удовлетворяет минимуму FR-038 и/или разошёлся с переходным хардкодом FR-039" >&2
    echo "$REPORT" >&2
    FAIL=$((FAIL + 1))
  else
    echo "$REPORT"
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011: контракт тегов содержит минимум FR-038 и синхронен с переходным хардкодом (если он ещё жив)"
