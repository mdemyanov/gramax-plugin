#!/usr/bin/env bash
# role-preflight.sh <task-id> — срез дерева, который роль получает ОДНИМ вызовом.
#
# ЗАЧЕМ (план волны NA-EPIC-52 Т4; спека `session-context-economy`, требование «A role
# receives the slice of the tree its task needs in one call»). Замер §7 плана: 6–7 тыс.
# токенов × ~100 обращений на роль уходило на РЕКОНСТРУКЦИЮ одной и той же картины поиском —
# ветка, база, чистота дерева, задача, требование, сценарии, файлы предмета, чужие гейты.
# Срез собирает ровно это и печатает СВОЙ размер: механизм, снимающий цену реконструкции и
# кладущий ту же цену одним куском, ничего не снимает (диверсионный анализ плана §8).
#
# ЧЕГО СРЕЗ НЕ ДЕЛАЕТ. Не пишет в стор (`bd` зовётся только на чтение: пишущие вызовы
# абсолютизируют `core.hooksPath` посреди работы), не решает за роль и не открывает эпик.
#
# ОТКАЗ ГРОМКИЙ. Идентификатор, не разрешающийся в задачу, даёт rc≠0 с названным вводом, а НЕ
# правдоподобный срез общей части: срез не о своей задаче роль читает до конца и работает по
# нему всю задачу.
#
# Usage: bash scripts/role-preflight.sh <task-id> | --no-task (бриф не назвал задачу)
#   NAUTA_SLICE_LIMIT — предел среза в байтах (по умолчанию 9216; окно О7 NA-EPIC-83:
#   8192 → 9216 — срез финального окна вырос списками гейтов/спек ветки aida-миграции,
#   секция потолков выпадала из усечённого среза (замок qa097 AC-12); значение живёт
#   в одном месте — здесь, замки читают печать прибора)
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIMIT="${NAUTA_SLICE_LIMIT:-9216}"
MAIN_BRANCH="${NAUTA_MAIN_BRANCH:-delivery}"
cd "$REPO" || exit 2

die() { printf 'ОШИБКА: %s\n' "$1" >&2; shift; for l in "$@"; do printf '  %s\n' "$l" >&2; done; exit 2; }

task="${1-}"
[ "$#" -ge 1 ] || die "задача не названа" "Usage: bash scripts/role-preflight.sh <task-id> | --no-task"
# `--no-task` — ЯВНЫЙ выбор брифа без задачи (разовый вызов команды, дерево без bd): общая часть
# среза, задача не разрешается. Отсутствие аргумента им НЕ является — забытый номер остаётся отказом.
bead=""
if [ "$task" != "--no-task" ]; then
  case "$task" in
    -*) die "идентификатор задачи '$task' начинается с дефиса — это опция, а не задача" \
            "единственная опция среза — --no-task (бриф не назвал задачу)" ;;
  esac
  trimmed="$(printf '%s' "$task" | tr -d '[:space:]')"
  [ -n "$trimmed" ] || die "идентификатор задачи пуст ('$task') — разрешать нечего"
  command -v bd >/dev/null 2>&1 || die "бинаря bd нет — контур И недоступен, задача '$task' не разрешается" \
      "бриф без задачи — bash scripts/role-preflight.sh --no-task"
  bead="$(bd show "$task" --json 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ] || [ -z "$bead" ]; then
    die "идентификатор '$task' не разрешается ни в одну задачу контура И (bd show → rc=$rc)" \
        "проверьте написание: срез, напечатанный по чужой задаче, выглядит исправным"
  fi
fi

body="$(mktemp "${TMPDIR:-/tmp}/role-preflight-XXXXXX")"
trap 'rm -f "$body"' EXIT
exec 3>&1 1>"$body"

# ===== задача ==============================================================================
if [ -z "$bead" ]; then
  printf '===== СРЕЗ РОЛИ — без задачи (--no-task) =====\n'
  printf 'задача: бриф её не назвал — предмет объявлен брифом координатора; ниже общая часть дерева\n'
else
printf '===== СРЕЗ РОЛИ — задача %s =====\n' "$task"
# В3 ADR-122 (backlog:882 + 1365): класс среза называет сам ПРИБОР — носитель класса, второй
# ключ гейтов не заводится. Различитель — префикс идентификатора (замер QA-117 L5): бид эпика
# живёт с префикса `epic-`, одноразовая задача контура И — без него.
case "$task" in
  epic-*) klass="эпик" ;;
  *)      klass="лист" ;;
esac
printf 'класс среза: %s (epic-* — эпик, иначе — лист; ADR-122 В3)\n' "$klass"
printf '%s' "$bead" | python3 -c '
import json, re, sys
from datetime import date
b = json.load(sys.stdin)
b = b[0] if isinstance(b, list) else b
print("задача: %s" % (b.get("title") or "<без заголовка>")[:200])
print("статус: %s; тип: %s; метки: %s" % (b.get("status"), b.get("issue_type"),
                                          ", ".join(b.get("labels") or []) or "<нет>"))
notes = (b.get("notes") or b.get("description") or "").strip()
print("заметки бида: %s" % (" ".join(notes.split())[:600] if notes else
      "<пусто> — предмет задачи объявлен брифом координатора, не биддом"))
# Срез состояния (ADR-138 Д2, SA-145 §2): живой срез — ПОСЛЕДНЯЯ строка заметок бида канонической
# формы `STATE <ГГГГ-ММ-ДД>: ` («последний маркированный победил», прежние — история того же
# журнала); дата — КАЛЕНДАРНАЯ (2026-13-40 не срез), форма строчными/без пробела — не маркер.
# Печать ≤ 300 символов строки — граница дизайна; отсутствие маркированной строки печатается
# ЯВНО («срез состояния: нет») — молчание запрещено; rc не меняется, `--no-task` сюда не доходит.
state = None
for line in notes.splitlines():
    m = re.match(r"^STATE (\d{4})-(\d{2})-(\d{2}): ", line)
    if not m:
        continue
    try:
        date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        continue
    state = line
print("срез состояния: %s" % (state[:300] if state else "нет"))
for label in b.get("labels") or []:
    if label.startswith("branch:"):
        print("ветка эпика по метке бида: %s" % label.split(":", 1)[1])
'
fi

# ===== ветка, база, чистота дерева =========================================================
printf '\n----- ветка, база, дерево -----\n'
cur="$(git branch --show-current 2>/dev/null)"
epic="$(printf '%s' "$bead" | sed -n 's/.*"branch:\([^"]*\)".*/\1/p' | head -1)"
[ -n "$epic" ] || epic="$MAIN_BRANCH"
# База — БЛИЖАЙШАЯ из разрешившихся веток-кандидатов, а не первая по списку: у дерева их
# несколько (ветка эпика из метки бида, интеграционная, канал раздачи), и merge-base с каналом
# раздачи здесь на 1072 файла старше merge-base с интеграционной. Первая-по-списку выдала бы
# «файлами предмета» весь корпус — правдоподобный срез не о своей задаче.
base=""; base_ref=""
for cand in "$epic" "$MAIN_BRANCH" "origin/$MAIN_BRANCH" stable origin/stable; do
  [ -n "$cand" ] && [ "$cand" != "$cur" ] || continue
  git rev-parse --verify --quiet "$cand" >/dev/null 2>&1 || continue
  mb="$(git merge-base HEAD "$cand" 2>/dev/null)" || continue
  [ -n "$mb" ] || continue
  if [ -z "$base" ] || [ "$(git log -1 --format=%ct "$mb")" -gt "$(git log -1 --format=%ct "$base")" ]; then
    base="$mb"; base_ref="$cand"
  fi
done
printf 'ветка: %s; сравнение с: %s\n' "${cur:-<detached>}" "${base_ref:-<ни одна база не разрешилась>}"
if [ -n "$base" ]; then
  counts="$(git rev-list --left-right --count "$base_ref"...HEAD 2>/dev/null)"
  printf 'база: %s (%s); позади/впереди %s\n' "${base:0:9}" \
    "$(git log -1 --format=%s "$base" 2>/dev/null | cut -c1-70)" "${counts:-?}"
else
  printf 'база: НЕ ВЫЧИСЛЕНА — ветки %s в дереве нет (это не «расхождений нет»)\n' "$base_ref"
fi
dirty="$(git status --short | wc -l | tr -d ' ')"
printf 'дерево: %s\n' "$([ "$dirty" = 0 ] && echo 'чисто' || echo "$dirty изменённых файлов")"

# ===== файлы предмета ======================================================================
files="$(git diff --name-only "${base:-HEAD}"..HEAD 2>/dev/null; git status --short | awk '{print $NF}')"
files="$(printf '%s\n' "$files" | sed '/^$/d' | sort -u)"
nfiles="$(printf '%s\n' "$files" | sed '/^$/d' | wc -l | tr -d ' ')"
printf '\n----- файлы предмета (%s; ветка против базы плюс несохранённое) -----\n' "$nfiles"
printf '%s\n' "$files" | head -12 | sed 's/^/  /'
[ "$nfiles" -gt 12 ] && printf '  …и ещё %s — `git diff --name-only %s..HEAD`\n' "$((nfiles-12))" "${base:0:9}"

# ===== требование, Capability, сценарии ====================================================
printf '\n----- требование и сценарии предмета -----\n'
req="$(printf '%s\n' "$files" | grep '^docs/20-requirements/.*\.md$' | grep -v -e '_index.md' -e 'README.md' | head -1)"
if [ -z "$req" ]; then
  printf 'требование: в файлах предмета не найдено — Capability не выведен\n'
else
  printf 'требование: %s\n' "$req"
  # Capability берётся СО СТРОКИ `**Capability:**`, а не первым вхождением пути по файлу:
  # требование цитирует чужие спеки в опорах, и первое вхождение дало бы чужой контракт
  # (замер на этом дереве: `run-token-budget` вместо `session-context-economy`).
  cap="$(grep -m1 -F '**Capability:**' "$req" 2>/dev/null | grep -o 'openspec/specs/[a-z0-9-]*/spec\.md' | head -1)"
  if [ -z "$cap" ] || [ ! -f "$cap" ]; then
    printf 'Capability: строка `**Capability:**` в требовании не найдена либо спека отсутствует\n'
  else
    printf 'Capability: %s (норм: %s, сценариев: %s)\n' "$cap" \
      "$(grep -c '^### Requirement:' "$cap")" "$(grep -c '^#### Scenario:' "$cap")"
    grep '^### Requirement:\|^#### Scenario:' "$cap" | cut -c1-110 | head -14 | sed 's/^/  /'
  fi
fi

# ===== окрестность предмета и обязанность прогона ==========================================
# ADR-107 Д4: первый акт роли печатает адреса, имена и ГОТОВЫЙ вызов последнего акта. Прибор
# зовётся БЕЗ `--run` и получает уже посчитанные здесь значения — вторым разрешением базы срез
# назвал бы другие файлы предмета, чем разделы выше. Печать усечена — тот же предел LIMIT.
printf '\n----- окрестность предмета и обязанность прогона -----\n'
hood="$REPO/scripts/subject-neighbourhood.py"
if [ ! -f "$hood" ]; then
  printf 'окрестность: прибора scripts/subject-neighbourhood.py в этом дереве нет — шаг не исполнен\n'
else
  hood_subject=""
  for s in ${NAUTA_TASK_SUBJECT:-}; do hood_subject="$hood_subject --subject $s"; done
  # shellcheck disable=SC2086 — разбиение на слова здесь предмет, а не оплошность
  printf '%s\n' "$files" | python3 "$hood" --base "${base:-HEAD}" --files-from - $hood_subject 2>&1 \
    | head -14 | sed 's/^/  /'
  printf 'последний акт: bash scripts/role-postflight.sh <свои тесты> — шаг [4/4] прогонит эту окрестность\n'
fi

# ===== гейты и спеки целевых каталогов =====================================================
printf '\n----- гейты и спеки, владеющие целевыми каталогами -----\n'
dirs="$(printf '%s\n' "$files" | sed -n 's|^\([^/]*/[^/]*\)/.*|\1|p; s|^\([^/]*\)/[^/]*$|\1|p' | sort -u | head -6)"
printf 'целевые каталоги: %s\n' "$(printf '%s ' $dirs)"
for d in $dirs; do
  gl="$(grep -l -F -- "$d/" scripts/check-*.py scripts/check-*.sh scripts/validate-content.py 2>/dev/null | xargs -n1 basename 2>/dev/null)"
  sl="$(grep -l -F -- "$d/" openspec/specs/*/spec.md 2>/dev/null | sed 's|openspec/specs/||; s|/spec.md||')"
  gn="$(printf '%s\n' "$gl" | sed '/^$/d' | wc -l | tr -d ' ')"
  sn="$(printf '%s\n' "$sl" | sed '/^$/d' | wc -l | tr -d ' ')"
  printf '  %s → гейты (%s): %s| спеки (%s): %s\n' "$d" "$gn" \
    "$(printf '%s\n' "$gl" | sed '/^$/d' | head -3 | tr '\n' ' ')" "$sn" \
    "$(printf '%s\n' "$sl" | sed '/^$/d' | head -3 | tr '\n' ' ')"
done

# ===== потолки файлов предмета =============================================================
printf '\n----- потолки файлов предмета (.nauta-gates.yaml) -----\n'
printf '%s\n' "$files" | head -40 | python3 -c '
import re, sys, pathlib
# Носитель порогов может отсутствовать: срез доставляется потребителю (PAYLOAD_FILES), а у
# свежего дерева `.nauta-gates.yaml` заводится bin/init.sh и до него файла нет. Отсутствие —
# НАЗВАННЫЙ исход, а не traceback посреди среза.
_gates = pathlib.Path(".nauta-gates.yaml")
if not _gates.is_file():
    print("  порогов не прочитать — .nauta-gates.yaml в этом дереве нет (заводится "
          "bin/init.sh); это не «потолков не назначено»")
    sys.exit(0)
gates = _gates.read_text(encoding="utf-8")
gf = dict(re.findall(r"^\s*-\s*path:\s*\"?([^\"\n]+?)\"?\s*\n\s*ceiling:\s*(\d+)", gates, re.M))
def num(block, key="thresholdLines"):
    m = re.search(rf"^{block}:(?:.|\n)*?^\s*{key}:\s*(\d+)", gates, re.M)
    return int(m.group(1)) if m else None
prompt_t = num("rolePromptSizeBudget")
code = [int(x) for x in re.findall(r"^\s*-\s*extension:\s*\.py\n\s*kind:\s*\w+\n\s*thresholdLines:\s*(\d+)", gates, re.M)]
prod_t, test_t = (code + [600, 650])[:2]
shown = 0
for line in sys.stdin.read().splitlines():
    p = pathlib.Path(line.strip())
    if not line.strip() or not p.is_file():
        continue
    if line in gf:
        ceiling, why = int(gf[line]), "грандфазер"
    elif re.match(r"^(agents|commands)/.*\.md$", line) and prompt_t:
        ceiling, why = prompt_t, "C18 промт-слоя"
    elif line.endswith(".py"):
        ceiling, why = (test_t, "C13 test") if "/test" in line or line.startswith("tests/") else (prod_t, "C13 prod")
    else:
        continue
    n = p.read_text(encoding="utf-8", errors="replace").count("\n")
    mark = "ПРЕВЫШЕН" if n > ceiling else "запас %d" % (ceiling - n)
    print("  %s: %d при потолке %d (%s, %s)" % (line, n, ceiling, why, mark))
    shown += 1
    if shown >= 8:
        print("  …перечень усечён восемью — потолки остальных: тот же ключ .nauta-gates.yaml")
        break
if not shown:
    print("  ни один файл предмета под измеряемые потолки не подпадает (.sh и docs/ — иные ключи)")
'

exec 1>&3 3>&-
size="$(wc -c <"$body" | tr -d ' ')"
if [ "$size" -gt "$((LIMIT - 120))" ]; then
  # УСЕЧЕНИЕ ПО ГРАНИЦЕ СИМВОЛА, не байта (окно О3 NA-EPIC-83): срез — текст, читаемый
  # потребителем в text=True; `head -c` резал многосимвольный UTF-8 пополам, и любой
  # декодирующий читатель падал UnicodeDecodeError на ровном месте (замер qa097: позиция
  # 7991, 0xd1). python3 уже обязателен дереву (uv-guard).
  python3 - "$body" "$((LIMIT - 200))" <<'PYCUT'
import sys
raw = open(sys.argv[1], "rb").read(int(sys.argv[2]))
sys.stdout.buffer.write(raw.decode("utf-8", errors="ignore").encode("utf-8"))
PYCUT
  printf '\n… срез УСЕЧЁН пределом: полный состав — по командам разделов выше\n'
  size="$((LIMIT - 200))"
else
  cat "$body"
fi
printf -- '----- размер среза: %s байт при пределе %s -----\n' "$size" "$LIMIT"
exit 0
