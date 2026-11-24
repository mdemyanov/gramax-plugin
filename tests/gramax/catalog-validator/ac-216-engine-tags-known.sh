#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-216-engine-tags-known.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-216
# (добавляется BA к §6.9, пункт 10 координатора; FR-222…FR-234 контур валидаторов).
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.10 (правило
# членства: реестр движка на пине — источник пополнения контракта; входят alert,
# block-field, block-property (pairedTags), db-diagram, db-table, include, term, module,
# issue, when, who, see (selfClosingTags, db-diagram также в diagramTags); не входят br,
# snippet-link, formula и внутренние ключи компонента), §6.9 (строка 1); ADR-0028
# Решение 10 (schemaVersion остаётся 3; W034 следует реестру движка — поправка к
# ADR-0024 Решение 4).
# Проверка (фикстура ac-216-engine-tags, пять статей): W034 снят на двенадцати именах;
#   W034 остаётся на br, snippet-link, formula и фиктивном теге; несбалансированный
#   <alert> — ERROR `unpaired <alert>` (баланс ведёт check_tags, в balanceTags они не
#   входят); <db-diagram path="./missing.yaml"/> — W031 (файловая цель диаграммы).
# Red on 6e2db04: двенадцать имён вне gramax-tags.json — W034 на всех; unpaired и W031
#   отсутствуют (замер 2026-11-24: W034 на 25 именах при нынешнем контракте, на 13 при
#   целевом).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-216-engine-tags"

if ! OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  echo "  FAIL: AC-216 — валидатор не исполнился на фикстуре реестра (крушение прибора, не ассерт)" >&2
  fail_msg "ac-216: AC-216 — прибор не исполнился"
  exit 1
fi

w034_on() { printf '%s\n' "$OUT" | grep "W034" | grep -F "$1" | grep -cF "<$2>"; }
w031_on() { printf '%s\n' "$OUT" | grep "W031" | grep -F "$1" | grep -cF "$2"; }

# --- двенадцать имён движка известны контракту: W034 снят ---
for name in dozen.md:db-table dozen.md:include dozen.md:term dozen.md:module dozen.md:issue dozen.md:when dozen.md:who dozen.md:see \
            paired-ok.md:alert paired-ok.md:block-field paired-ok.md:block-property \
            dbdiag.md:db-diagram; do
  article="${name%%:*}"; tag="${name##*:}"
  N=$(w034_on "$article" "$tag")
  if [ "$N" -ne 0 ]; then
    echo "  FAIL: AC-216 RED — W034 на <$tag> ($article, $N шт.): имя движка вне gramax-tags.json; по решению 10 W034 следует реестру движка, двенадцать имён входят в контракт (ADR-0028 Решение 10, дизайн §3.10)" >&2
    printf '%s\n' "$OUT" | grep "W034" | grep -F "$article" | grep -F "<$tag>" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- баланс трёх парных: несбалансированный alert — ERROR ---
if ! printf '%s\n' "$OUT" | grep -F "unbalanced.md" | grep -qF "unpaired <alert>"; then
  echo "  FAIL: AC-216 RED — несбалансированный <alert> не даёт ERROR «unpaired <alert>»: тег вне pairedTags, баланс его не ведёт (ADR-0028 Решение 10: «несбалансированная пара — ERROR unpaired <тег>»)" >&2
  printf '%s\n' "$OUT" | grep -F "unbalanced.md" >&2
  FAIL=$((FAIL + 1))
fi

# --- db-diagram в diagramTags: файловая цель проверяется ---
if [ "$(w031_on "dbdiag.md" './missing.yaml')" -lt 1 ]; then
  echo "  FAIL: AC-216 RED — <db-diagram path=\"./missing.yaml\"/> не даёт W031: тег вне diagramTags, цель не проверяется как файловая (ADR-0028 Решение 10; подмена контракта даёт находку W031)" >&2
  printf '%s\n' "$OUT" | grep -F "dbdiag.md" >&2
  FAIL=$((FAIL + 1))
fi

# --- приманки: W034 остаётся (leg-гард, зелёный и сегодня) ---
for name in baits.md:br baits.md:snippet-link baits.md:formula baits.md:fictional-tag; do
  article="${name%%:*}"; tag="${name##*:}"
  N=$(w034_on "$article" "$tag")
  if [ "$N" -lt 1 ]; then
    echo "  FAIL: AC-216 — W034 на <$tag> ($article) исчез: тег не входит в реестр движка по правилу членства (legacy-форма / внутреннее представление / фиктивный), W034 на нём — верный сигнал (ADR-0028 Решение 10, дизайн §3.10 таблица вердиктов)" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-216: AC-216 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-216: AC-216 — W034 снят на двенадцати именах движка, баланс alert ведёт check_tags, db-diagram проверяет цель, приманки репортятся"
