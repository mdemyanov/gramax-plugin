#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-170-shellcheck-changed-step.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-170 (FR-226)
# Решение: ADR-0029 «Состав гейта и сюит волны-4» (вне индекса на момент письма), Решение 1 —
#   шаг 2.7 `==> shellcheck-changed` пути --fast (после `==> render`, до --full-блока):
#   стаб с shellcheck-находкой ловится ДО передачи Dev (уроки журнала 2026-11-21 и 2026-11-23:
#   стабы дважды дошли до полного гейта с lint-долгом).
# Проверка (контракт, статические пины тела шага):
#   (a) в пути --fast есть шаг, печатающий метку исполняемой строкой `echo "==> shellcheck-changed"`
#       (scripts/check-gramax.sh:111), стоящий после шага render и до открытия --full-блока;
#   (b) список изменённых и новых .sh собран дословной командой ADR (untracked через
#       git ls-files --others + изменённые через git diff --diff-filter=d, минус
#       tests/gramax/archive/, sort -u);
#   (c) расщепление по базису: список из .nauta-scripts-basis.yaml зовётся с
#       `-e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR`, остальные файлы —
#       `shellcheck -x -P SCRIPTDIR` (второй вызов без кодов -e);
#   (d) пять исходов дословно: пустой список → `OK: no changed shell files`; shellcheck
#       отсутствует при непустом списке → `FAIL: shellcheck not installed`; ошибка git при
#       сборе списка → FAIL, называющий шаг; находки → `FAIL: shellcheck issues (changed files)`;
#       чисто → `OK: shellcheck clean`;
#   (e) всё, кроме двух OK, ставит FAILED=1 — в теле шага ≥ 3 присваивания.
# Цвет: ЗЕЛЁНЫЙ от рождения как гард состояния после реализации шага Dev'ом
#   (scripts/check-gramax.sh:107-155). Мутации к красному: снять шаг; изменить любой
#   пин тела — дословную команду списка, цепочку -e кодов базиса, одну из строк исходов,
#   убрать присваивание FAILED=1 из ветви отказа; шаг до render либо внутри --full-блока.
#   История матчера: v1 сравнивала строку гейта на РАВЕНСТВО «голой» метке (без слова
#   echo перед ней) и потому не видела живой шаг — в строке гейта метке предшествует
#   echo; дефект исправлен опознанием по исполняемой строке (дом ac-143). «Голая» метка
#   неисполнима (rc=127), пин такой формы был бы пином мёртвого кода.
# Граница: число «11 файлов базиса» не пришивается — список читается из
#   .nauta-scripts-basis.yaml и меняется синком nauta; стаб держит ПРАВИЛО расщепления.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-170: scripts/check-gramax.sh на месте"

# Быстрый путь: все строки до открытия --full-блока (if в нулевой колонке).
FAST_PART="$(awk '/^if \[ "\$MODE" = "--full" \]; then/ { exit } { print NR "\t" $0 }' "$CHECK_GRAMAX")"

# Метки гейта печатаются ИСПОЛНЯЕМОЙ строкой `echo "==> <label>"` (дом ac-143: шаг
# опознаётся по строке, которая его вызывает). «Голая» метка `==> <label>` неисполнима
# (bash -c 'set -euo pipefail; ==> render' → «==: command not found», rc=127) — пин
# такой формы требовал бы от гейта мёртвого кода. Дефект матчера v1: сравнение $2 на
# РАВЕНСТВО голой метке никогда не било — строка гейта несёт `echo ` перед меткой.
RENDER_LINE="$(printf '%s\n' "$FAST_PART" | awk -F '\t' '$2 ~ /^echo "==> render"$/ { print $1; exit }')"
STEP_LINE="$(printf '%s\n' "$FAST_PART" | awk -F '\t' '$2 ~ /^echo "==> shellcheck-changed"$/ { print $1; exit }')"

# --- (a): шаг есть, после render, до --full-блока (маркер найден в быстром пути) ---
if [ -z "$STEP_LINE" ]; then
  echo "  FAIL: AC-170 — в быстром пути check-gramax.sh нет шага «==> shellcheck-changed»:" >&2
  echo "  оболочка с shellcheck-находкой доходит до Dev незамеченной (уроки 2026-11-21/23;" >&2
  echo "  ADR-0029 Решение 1). Пин тела шага: (b) список дословно, (c) расщепление по базису," >&2
  echo "  (d) пять исходов, (e) FAILED=1 вне двух OK." >&2
  FAIL=$((FAIL + 1))
  fail_msg "ac-170: шаг shellcheck-changed отсутствует — $FAIL assertion(s) failed"
  exit 1
fi
if [ -z "$RENDER_LINE" ] || [ "$RENDER_LINE" -ge "$STEP_LINE" ]; then
  echo "  FAIL: AC-170 — шаг shellcheck-changed (строка ${STEP_LINE}) обязан стоять после" >&2
  echo "  шага render (строка ${RENDER_LINE:-отсутствует}) в пути --fast (ADR-0029 Решение 1)" >&2
  FAIL=$((FAIL + 1))
fi

# Тело шага: от метки до следующей метки «==>» (та же исполняемая форма echo),
# исполняемые строки (без комментариев).
STEP_BLOCK="$(printf '%s\n' "$FAST_PART" | awk -F '\t' -v s="$STEP_LINE" '
  $1 == s                { show = 1; next }
  show && $2 ~ /^echo "==>/ { exit }
  show {
    l = $2; sub(/^[ \t]+/, "", l)
    if (l !~ /^#/) print l
  }
')"

# --- (b): дословная команда списка ADR-0029 Решение 1 ---
for ANCHOR in \
  "git ls-files --others --exclude-standard -- '*.sh'" \
  "git diff --name-only --diff-filter=d HEAD -- '*.sh'" \
  "grep -v '^tests/gramax/archive/'" \
  "sort -u"; do
  if printf '%s\n' "$STEP_BLOCK" | grep -qF "$ANCHOR"; then
    :
  else
    echo "  FAIL: AC-170 — тело шага не несёт якорь команды списка «${ANCHOR}»" >&2
    echo "  (ADR-0029 Решение 1: список дословно — untracked + изменённые, минус архив, sort -u)" >&2
    FAIL=$((FAIL + 1))
  fi
done

# --- (c): расщепление по базису — -e коды только базису, остальным чистый вызов ---
if printf '%s\n' "$STEP_BLOCK" | grep -qF '.nauta-scripts-basis.yaml'; then
  :
else
  echo "  FAIL: AC-170 — шаг не называет .nauta-scripts-basis.yaml: правило расщепления" >&2
  echo "  «11 .sh базиса — с -e кодами, остальные — без» не читается из тела (ADR-0029 Решение 1)" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$STEP_BLOCK" | grep -qF -- '-e SC1125 -e SC2001 -e SC2016 -e SC2086'; then
  :
else
  echo "  FAIL: AC-170 — базис-вызов без кодов -e SC1125/SC2001/SC2016/SC2086" >&2
  echo "  (ADR-0029 Решение 1: до исправления issue №42 коды снимают находки payload-файлов)" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$STEP_BLOCK" | grep -E 'shellcheck .*-x -P SCRIPTDIR' | grep -v 'SC1125' | grep -q .; then
  :
else
  echo "  FAIL: AC-170 — нет второго вызова shellcheck без -e кодов (остальные файлы:" >&2
  echo "  «shellcheck -x -P SCRIPTDIR», их находки блокирующие; ADR-0029 Решение 1)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (d): пять исходов дословно ---
for OUTCOME in \
  "OK: no changed shell files" \
  "FAIL: shellcheck not installed" \
  "FAIL: shellcheck issues (changed files)" \
  "OK: shellcheck clean"; do
  if printf '%s\n' "$STEP_BLOCK" | grep -qF "$OUTCOME"; then
    :
  else
    echo "  FAIL: AC-170 — тело шага не несёт исход «${OUTCOME}» (ADR-0029 Решение 1)" >&2
    FAIL=$((FAIL + 1))
  fi
done
if printf '%s\n' "$STEP_BLOCK" | grep -qE 'FAIL.*shellcheck-changed'; then
  :
else
  echo "  FAIL: AC-170 — ошибка сбора списка (git) не даёт FAIL с именем шага" >&2
  echo "  (ADR-0029 Решение 1: список не собрался → FAIL с именем shellcheck-changed)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (e): всё, кроме двух OK, ставит FAILED=1 ---
FAILED_SETS="$(printf '%s\n' "$STEP_BLOCK" | grep -c 'FAILED=1' || true)"
if [ "$FAILED_SETS" -lt 3 ]; then
  echo "  FAIL: AC-170 — присваиваний FAILED=1 в теле шага ${FAILED_SETS} (< 3): три ветви" >&2
  echo "  отказа (нет shellcheck; ошибка git; находки) обязаны красить гейт (ADR-0029 Решение 1)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-170: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-170: шаг 2.7 shellcheck-changed в --fast (после render, до --full): список дословно, расщепление по базису, пять исходов, FAILED=1 вне двух OK"
