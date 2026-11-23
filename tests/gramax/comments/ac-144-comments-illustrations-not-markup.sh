#!/usr/bin/env bash
# tests/gramax/comments/ac-144-comments-illustrations-not-markup.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md —
#             FR-216/AC-137 в контуре комментариев; номер AC-144 — гейт-порог «0 ERROR на
#             docs/» (FR-220), которому это питает comments-ногу; сам шаг гейта — ADR-0027,
#             владелец не QA-author. Комментарии — beads gramax-4jf.13 (ложные «invalid
#             comment id format» на иллюстрациях синтаксиса).
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.5
# (validate_comments.py — маска общим примитивом _mask_code до извлечения якорей,
# пробелы тега — одной строкой).
# Проверка:
#   (a) примеры синтаксиса в inline-коде и fenced-блоке не дают находок (rc=0, пустой вывод);
#   (b) тег, разорванный переносом строки между <comment и id=, даёт находку «тег разорван»,
#       а не ложный ID: ни «invalid comment id format», ни «yaml missing key for md id».
# Red on 7553da1: INLINE_RE с re.DOTALL мостит через переносы строк, код не маскируется
#   (замер 2026-11-23: rc=1, ложные «yaml missing key for md id» на обеих фикстурах).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-144-illustrations"

# --- (a): иллюстрации в коде — не разметка ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/page.md" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "FR-216 (комментарии): примеры <comment id> в inline-коде и fenced-блоке — не находки, rc=0"

if printf '%s\n' "$OUT" | grep -qE 'invalid comment id format|yaml missing key|md missing tag'; then
  echo "  FAIL: FR-216 (комментарии) — иллюстрация синтаксиса в коде прочитана как разметка (ложный ID): код обязан маскироваться до извлечения якорей (gramax-4jf.13)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (b): разорванный тег — находка «тег разорван», не ложный ID ---
if OUT_BROKEN=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_comments.py "$FIXTURE/broken-tag.md" 2>&1); then
  RC_BROKEN=0
else
  RC_BROKEN=$?
fi

if printf '%s\n' "$OUT_BROKEN" | grep -qF 'invalid comment id format'; then
  echo "  FAIL: FR-216 (комментарии) — разорванный переносом тег не должен рождать «invalid comment id format» с ложным ID" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT_BROKEN" | grep -qF 'yaml missing key for md id'; then
  echo "  FAIL: FR-216 (комментарии) — разорванный переносом тег не должен рождать ложный «yaml missing key for md id»" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT_BROKEN" | grep -qi "разорв"; then
  echo "  FAIL: FR-216 (комментарии) — тег, разорванный переносом строки между <comment и id=, обязан давать находку «тег разорван» (критерий gramax-4jf.13), а не тишину" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-144: FR-216 (комментарии) — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-144: иллюстрации в коде не находки; разорванный тег — находка «тег разорван», не ложный ID"
