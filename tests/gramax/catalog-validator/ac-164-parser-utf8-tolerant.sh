#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-164-parser-utf8-tolerant.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-164 (FR-222)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.1 (scan_md_resources
# читает через lib/read_page.py и отдаёт (resources, errors); инвариант 1: файл с битым
# UTF-8 даёт один MdPageError и ни одного ресурса, обход доведён до конца в отсортированном
# порядке); ADR-0028 Решение 1; контракт QA-author — дизайн §6.1 (строка 1).
# Проверка: каталог с a.md (ссылки на битый broken.md и на здоровый c.md), c.md и broken.md
#   (оборванный байт 0xd0) → scan_md_resources возвращает пару: одна MdPageError с source
#   broken.md и фрагментом utf8_message, два ресурса (ссылки из a.md: c.md и broken.md),
#   ни одного исключения и traceback.
# Уровень: интеграционный прогон парсера (модуль stdlib-only, вызывается python3 -B
#   напрямую, без uv — pyyaml парсеру не нужен); ac-133 остаётся замком уровня CLI
#   (validate_structure), этот стаб судит сам парсер.
# Red on 6e2db04: scan_md_resources в lib/md_link_parser.py нет; parse_md_resources на
#   каталоге с битым UTF-8 роняет скрипт UnicodeDecodeError'ом (замер 2026-11-24 — дизайн
#   §2, карточка gramax-4jf.14): второго читателя и обёртки валидатора недостаточно, чтобы
#   публичный парсер стал безопасным.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-164-utf8-parser"
LIBDIR="$ROOT/plugins/gramax/scripts"
PROBE="$(mktemp "${TMPDIR:-/tmp}/ac-164.XXXXXX")"
PROBE_ERR="$(mktemp "${TMPDIR:-/tmp}/ac-164-err.XXXXXX")"
trap 'rm -f "$PROBE" "$PROBE_ERR"' EXIT

python3 -B - "$FIXTURE" "$LIBDIR" >"$PROBE" 2>"$PROBE_ERR" <<'PY'
import sys
from pathlib import Path

fixture = Path(sys.argv[1])
sys.path.insert(0, sys.argv[2])
import lib.md_link_parser as mlp  # noqa: E402

if not hasattr(mlp, "scan_md_resources"):
    print("MISSING scan_md_resources")
    # Наблюдаемое на красном дереве: parse_md_resources падает исключением на битом файле.
    try:
        mlp.parse_md_resources(fixture)
        print("PARSE-OK (неожиданно: парсер перестал падать без scan_md_resources)")
    except UnicodeDecodeError as exc:
        print(f"RAISED UnicodeDecodeError: {exc}")
    sys.exit(3)

resources, errors = mlp.scan_md_resources(fixture)
print(f"RES={len(resources)}")
print(f"ERRS={len(errors)}")
from lib.read_page import utf8_message  # noqa: E402

for err in errors:
    print(f"ERRSOURCE={err.source.name}")
    print(f"ERRMSG={utf8_message(err.error)}")
print("TARGETS=" + ",".join(sorted(r.resolved_path.name for r in resources)))
PY
RC=$?

if [ "$RC" -eq 3 ]; then
  echo "  FAIL: AC-164 RED — scan_md_resources отсутствует в lib/md_link_parser.py: парсер не читает через lib/read_page.py и не отдаёт ошибки чтения (ADR-0028 Решение 1, дизайн §3.1)" >&2
  grep -E '^(RAISED|PARSE-OK|MISSING)' "$PROBE" >&2
  echo "  --- доказательство красного дерева: строка RAISED выше — сегодняшний parse_md_resources роняет обход UnicodeDecodeError'ом" >&2
  FAIL=$((FAIL + 1))
  fail_msg "ac-164: AC-164 — $FAIL assertion(s) failed"
  exit 1
fi

assert_exit_zero "$RC" "AC-164: scan_md_resources выполняется без исключения на каталоге с битым UTF-8 (замер 2026-11-24: parse_md_resources на старом дереве падал UnicodeDecodeError)"

# Ни одного traceback — ни в stdout прибора, ни в stderr (дизайн §6.1, зелёная колонка).
if grep -q "Traceback" "$PROBE" || grep -q "Traceback" "$PROBE_ERR"; then
  echo "  FAIL: AC-164 — traceback в выводе пробы не допускается: чтение идёт через lib/read_page.py, ошибки отдаются наружу как MdPageError (ADR-0028 Решение 1)" >&2
  grep -m3 "Traceback" "$PROBE" "$PROBE_ERR" >&2
  FAIL=$((FAIL + 1))
fi

assert_grep_regex "$PROBE" "^ERRS=1$" "AC-164: ровно одна ошибка чтения — файл с битым UTF-8 даёт один MdPageError (BR-004, дизайн §3.1 инвариант 1)"
assert_grep_regex "$PROBE" "^ERRSOURCE=broken.md$" "AC-164: MdPageError называет источник broken.md"
assert_grep_regex "$PROBE" "^ERRMSG=файл не является валидным UTF-8" "AC-164: ошибка несёт фрагмент utf8_message из lib/read_page.py (дизайн §3.1)"

assert_grep_regex "$PROBE" "^RES=2$" "AC-164: оба ресурса на месте — ссылки из a.md на c.md и на broken.md (обход доведён до конца, не оборван битым файлом)"
assert_grep_regex "$PROBE" "^TARGETS=broken.md,c.md$" "AC-164: цели ресурсов — c.md и broken.md, отсортированный порядок обхода сохранён (дизайн §3.1 инвариант 1)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-164: AC-164 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-164: AC-164 — scan_md_resources: одна MdPageError (broken.md), оба ресурса на месте, без исключения"
