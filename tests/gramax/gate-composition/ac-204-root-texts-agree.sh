#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-204-root-texts-agree.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-204 (FR-253, карточка gramax-o0q.13, D10).
# Проверка (контракт): корневые тексты говорят одно —
#   (1) корневой CHANGELOG.md несёт архивное уведомление сразу под H1: архив записей
#       marketplace 1.0.0–3.0.0, последняя от 2026-05-11, действующий журнал —
#       plugins/gramax/CHANGELOG.md, поправка — (ADR-0030);
#   (2) раздел «Версии» корневого README.md называет тот же журнал («единственный действующий»)
#       и ту же заморозку — «архив записей marketplace 1.0.0–3.0.0, заморожен на 3.0.0
#       (2026-05-11)»;
#   (3) ADR-0030 несёт «Поправку к ADR-0006» с той же парой (журнал один; архив заморожен
#       на 3.0.0 (2026-05-11)).
#   Не дублирует ac-146-root-texts.sh (тот пиннит состав плагина в CLAUDE.md, число сюит,
#   порог C14 и якоря README drawio) — здесь предмет только пара «журнал/заморозка».
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — все три текста согласованы (замер роли).
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md): удаление
#   уведомления из копии CHANGELOG.md / строки заморозки из раздела «Версии» / поправки из
#   ADR-0030 — соответствующая нога теряет литерал.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
CHANGELOG="$ROOT/CHANGELOG.md"
README="$ROOT/README.md"
ADR30="$ROOT/docs/00-project/adr/0030-plugin-perimeter-deferred-capabilities.md"

assert_file_exists "$CHANGELOG" "AC-204: корневой CHANGELOG.md на месте"
assert_file_exists "$README" "AC-204: корневой README.md на месте"
assert_file_exists "$ADR30" "AC-204: ADR-0030 на месте"

# --- Нога 1: архивное уведомление сразу под H1 корневого CHANGELOG.md ---
# Уведомление — абзац из двух строк сразу после H1 (между ними одна пустая строка):
# начальные пустые строки пропускаются, сбор — до первой пустой строки после начала абзаца.
NOTICE="$(awk 'NR==1 && /^# /{h1=1; next} h1{ if (started && NF==0) exit; if (NF>0){started=1; print} }' "$CHANGELOG")"
for FRAGMENT in \
  'Архив: записи marketplace 1.0.0–3.0.0, последняя от 2026-05-11' \
  'plugins/gramax/CHANGELOG.md' \
  '(ADR-0030)'; do
  if printf '%s\n' "$NOTICE" | grep -qF "$FRAGMENT"; then
    :
  else
    echo "  FAIL: AC-204 — уведомление под H1 корневого CHANGELOG.md не несёт «${FRAGMENT}»" >&2
    echo "  (абзац под H1: «${NOTICE:-<пусто>}»; текст поправки —" >&2
    echo "  ADR-0030 «Поправка к ADR-0006», разделы заморозки не трогаются)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- Нога 2: раздел «Версии» README называет тот же журнал и ту же заморозку ---
VERSIONS="$(awk '/^## Версии/{v=1; next} v && /^## /{exit} v{print}' "$README")"
for FRAGMENT in \
  'plugins/gramax/CHANGELOG.md' \
  'единственный действующий' \
  'архив записей marketplace 1.0.0–3.0.0' \
  '3.0.0 (2026-05-11)'; do
  if printf '%s\n' "$VERSIONS" | grep -qF "$FRAGMENT"; then
    :
  else
    echo "  FAIL: AC-204 — раздел «Версии» README.md не несёт «${FRAGMENT}»" >&2
    echo "  (текст согласован с поправкой ADR-0006 внутри ADR-0030: журнал один, корневой" >&2
    echo "  CHANGELOG — архив, заморожен на 3.0.0 (2026-05-11))" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- Нога 3: ADR-0030 несёт поправку к ADR-0006 с той же парой ---
assert_grep "$ADR30" 'Поправка к ADR-0006' \
  "AC-204: ADR-0030 несёт строку-поправку к ADR-0006 (старые ADR не редактируются, BR-032)"
# shellcheck disable=SC2016  # бэктики — дословный литерал markdown из поправки ADR-0030
assert_grep "$ADR30" 'журнал релизов один — `plugins/gramax/CHANGELOG.md`' \
  "AC-204: поправка ADR-0030 называет единственный журнал — plugins/gramax/CHANGELOG.md"
assert_grep "$ADR30" 'заморожен на 3.0.0 (2026-05-11)' \
  "AC-204: поправка ADR-0030 называет ту же заморозку — 3.0.0 (2026-05-11)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-204: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-204: корневые тексты согласованы — архивный CHANGELOG под H1, «Версии» README и поправка ADR-0006 в ADR-0030 называют один журнал и одну заморозку 3.0.0 (2026-05-11)"
