#!/usr/bin/env bash
# check.sh — single entry-point для всех валидаций.
#
# Usage:
#   bash scripts/check.sh [--fast | --full | --secret-scan-only | --delivery-composition-only]
#
# --fast (default): validate-content.py + validate-profile.py + check-adr-line-limit.py
#         (ADR-013) + check-test-subject-governs.py (ADR-070; код 1 мягкий — ADR-072 Д3/Д4)
#         + check-content-actuality.py (ADR-076 Д7; код 1 мягкий, замер спутника §6) +
#         check-subprocess-encoding.py (BA-118, NA-EPIC-150: born-red запрет text=True без
#         encoding=, AC-002c спеки subprocess-utf8-determinism — быстрый ярус) +
#         check-network-roster.py (BA-119, NA-EPIC-151: свип сетевого класса, ADR-159 Д2).
#         Quick gate.
# --full: + check-backlog-closure.py (ADR-012 Д4) + id-check.sh (ADR-038, решение владельца
#         Р22; перевод ступени в --fast по ADR-072 Д7 ОСТАНОВЛЕН DEV-111 — см. отчёт задачи:
#         он расходится с ADR-030 Д6(2), требующим зелёный --fast у потребителя сразу после
#         payload'а, где .nauta-ids.yaml ещё не заведён) + self-test harness
#         (test-check-adr-line-limit.sh, test-check-backlog-closure.sh,
#         test-check-breaking-change-section.sh, test-check-id.sh, test-validate-content.sh —
#         две последние доставляются payload'ом; test-check-id зарегистрирована DEV-022,
#         test-validate-content заведена и зарегистрирована DEV-125 тем же коммитом).
#
# ADR-037 (docs/30-architecture/adr/ADR-037-gate-roster-from-delivery-basis.md +
# docs/30-architecture/ADR-037-gate-roster-from-delivery-basis-spec.md): перечень вызовов
# ниже — намерение («какие гейты этот раннер знает вообще»), НЕ факт обязательности. Факт —
# .nauta-scripts-basis.yaml (ADR-030 Д3), единственная запись дерева-потребителя о том, что
# ему привезли. Дерево-источник payload'а (само это дерево, опознаётся по подписи
# bin/deliver.sh) — исключение: там обязателен весь перечень целиком, найденный рядом базис
# на это не влияет (ADR-037 Д3).

set -euo pipefail

# uv-guard: обязательная зависимость
if ! command -v uv >/dev/null 2>&1; then
  echo "ERROR: 'uv' не найден в PATH. Установите: https://docs.astral.sh/uv/getting-started/installation/" >&2
  exit 1
fi

MODE="${1:---fast}"

case "$MODE" in
  --fast|--full|--secret-scan-only|--delivery-composition-only|-h|--help) ;;
  *)
    echo "Usage: $0 [--fast | --full | --secret-scan-only | --delivery-composition-only]" >&2
    exit 2
    ;;
esac

if [[ "$MODE" == "-h" ]] || [[ "$MODE" == "--help" ]]; then
  cat <<EOF
Usage: $0 [--fast | --full | --secret-scan-only | --delivery-composition-only]

Modes:
  --fast (default)  Run validators (validate-content.py + validate-profile.py +
                    check-adr-line-limit.py + check-subprocess-encoding.py). Quick gate.
                    Suitable for pre-commit hook.
  --full            Run --fast checks + check-backlog-closure.py (ADR-012 Д4 — lives in
                    --full, not --fast) + id-check.sh (ADR-038 identifier registry audit;
                    --full by owner ruling Р22) + self-test harness (test-check-adr-line-
                    limit.sh, test-check-backlog-closure.sh,
                    test-check-breaking-change-section.sh, test-check-id.sh,
                    test-validate-content.sh). Suitable for CI / pre-merge gate.
  --secret-scan-only
                    Run ONLY the secret-scan-tree gate — the same block --fast runs,
                    not a copy of it. Meant for the release path (ADR-073 Д4, spec
                    §4.3): on the filtered delivery tree the other gates have no
                    subject, and secret-scan-tree is the only applicable one.
  --delivery-composition-only
                    Run ONLY the delivery-composition guard — again the same block,
                    not a copy. Step 4 of the release procedure (ADR-073-spec §4.1)
                    needs the guard alone on the filtered tree, where --fast is red
                    for four gates that have no subject there.

Obligation (ADR-037): which of the gates above MUST exist in this tree is resolved from
.nauta-scripts-basis.yaml (delivery record), not hardcoded — see ADR-037-spec §2.

Exit codes:
  0  All checks passed
  1  Validator, gate, suite failed, or the delivery basis could not be read
  2  Invalid usage
EOF
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# CHECK_SELF — путь к ЭТОМУ файлу (ADR-085 Д6). Объявления невхождения §3.2 живут в его же
# тексте: носитель утверждения «позиция не доставляется» выбран так, чтобы он ехал вместе с
# ростером и разъехаться с ним не мог. Второго носителя (case-таблицы рядом с комментарием)
# намеренно нет — он и был бы тем самым местом расхождения.
CHECK_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# ---------------------------------------------------------------------------
# ADR-123 Д4 (NA-EPIC-72) — журнал инструментированного прогона: TSV, строка =
# `step <имя> <исход> starts <N> wall_<s|ms> <N>`. Путь — env NAUTA_CHECK_JOURNAL
# (детерминизм для замка tests/test_adr123_check_fast_spawn_lock.py) либо файл с меткой
# времени в .git/nauta-quiet/check-fast-journal/ (паттерн run-quiet); вне git-дерева
# журнал не пишется — прогон от этого не меняется. Запись — bookkeeping, не гейт
# (прецедент full-run-record, DEV-454): сбой дописывания не краснит прогон. НИ ОДНОЙ
# новой строки в stdout прогона журнал не производит — путь живёт в файле и env, окно
# чужих ассертов (§3.3 ADR-085) не сдвигается.
# ---------------------------------------------------------------------------
CHECK_JOURNAL=""
JOURNAL_EPOCH="$(date +%s)"
if [[ -n "${NAUTA_CHECK_JOURNAL:-}" ]]; then
  CHECK_JOURNAL="$NAUTA_CHECK_JOURNAL"
else
  _journal_git_dir="$(git rev-parse --git-common-dir 2>/dev/null || true)"
  if [[ -n "$_journal_git_dir" ]]; then
    CHECK_JOURNAL="$_journal_git_dir/nauta-quiet/check-fast-journal/${JOURNAL_EPOCH}-$$-${MODE#--}.tsv"
  fi
fi
if [[ -n "$CHECK_JOURNAL" ]]; then
  if mkdir -p "${CHECK_JOURNAL%/*}" 2>/dev/null; then
    CHECK_JOURNAL="$(cd "${CHECK_JOURNAL%/*}" && pwd)/$(basename "$CHECK_JOURNAL")"
  else
    CHECK_JOURNAL=""
  fi
fi

# _journal <имя> <исход> <старты> <стена> <единица s|ms> — дописать строку TSV; no-op при
# пустом пути. Каждая строка флашится сразу (форензика Д3: прерывание прогона называет
# исполненные ступени и молчит о незавершённых).
_journal() {
  [[ -n "$CHECK_JOURNAL" ]] || return 0
  printf 'step %s %s starts %s wall_%s %s\n' "$1" "$2" "$3" "$5" "$4" >> "$CHECK_JOURNAL" 2>/dev/null || true
}

# Шапка журнала — первая строка файла, `run <mode> <epoch>` (ADR-123-spec §4).
_journal_run_header() {
  [[ -n "$CHECK_JOURNAL" ]] || return 0
  printf 'run %s %s\n' "$MODE" "$JOURNAL_EPOCH" >> "$CHECK_JOURNAL" 2>/dev/null || true
}

# _journal_okfail <имя> <t0> <failed-на-входе> <старты> — исход по дельте failed:
# отказ соседа не называется своим (маркер принадлежит одному исходу, ADR-042 Д3).
# Единица — секунды (`SECONDS`, встроенная, без форка); стены bash-ступеней в журнале
# несут суффикс wall_s, стены внутри батча — wall_ms (spec §4).
_journal_okfail() {
  local outcome=ok
  if [[ "$failed" -ne "$3" ]]; then outcome=fail; fi
  _journal "$1" "$outcome" "$4" "$(( SECONDS - $2 ))" s
}

# _journal_infofail — то же, но немятый прогон ступени даёт info: ступени с объявленным
# молчанием (projectGates absent/configured — ADR-077 Д3), чей отказ остаётся отказом.
_journal_infofail() {
  local outcome=info
  if [[ "$failed" -ne "$3" ]]; then outcome=fail; fi
  _journal "$1" "$outcome" 0 "$(( SECONDS - $2 ))" s
}

# Итоговая строка прибора — дописывает _finish (единственный решатель exit-кода, сам он
# не меняется): `run <mode> starts_total <N> wall_s <N> start_share <0.NN>` (spec §4/§5).
# Доля стартов — ступенчатая атрибуция Д5: сумма стен ступеней со стартом интерпретатора
# (wall_ms нормируются к секундам) к стене прогона, по меткам журнала, не секундомером.
# awk — инструмент счёта, не старт. Сбой записи прогон не краснит (best-effort).
_journal_summary() {
  [[ -n "$CHECK_JOURNAL" && -f "$CHECK_JOURNAL" ]] || return 0
  local line
  line="$(awk -v mode="$MODE" -v runwall="$SECONDS" '
    $1 == "step" {
      starts = 0; wall = 0; unit = "s"
      for (i = 2; i <= NF; i++) {
        if ($i == "starts") { starts = $(i + 1) + 0 }
        if ($i == "wall_ms") { unit = "ms"; wall = $(i + 1) + 0 }
        if ($i == "wall_s") { unit = "s"; wall = $(i + 1) + 0 }
      }
      total += starts
      if (starts >= 1) { startw += (unit == "ms" ? wall / 1000 : wall) }
    }
    END {
      share = 0
      if (runwall > 0) { share = startw / runwall }
      if (share < 0) { share = 0 }
      if (share > 1) { share = 1 }
      printf "run %s starts_total %d wall_s %d start_share %.2f\n", mode, total, runwall, share
    }
  ' "$CHECK_JOURNAL")" || line=""
  if [[ -n "$line" ]]; then
    printf '%s\n' "$line" >> "$CHECK_JOURNAL" 2>/dev/null || true
  fi
}

_journal_run_header
_journal "uv-guard" "ok" 0 "$SECONDS" s

# ---------------------------------------------------------------------------
# ADR-037 §2 — разрешение режима обязательности. Выполняется РОВНО один раз, здесь, ДО
# первого вызова гейта — вердикт о том, обязана ли каждая позиция перечня существовать,
# принимается прежде, чем побежит хоть один шаг.
# ---------------------------------------------------------------------------
BASIS_FILE="$REPO_ROOT/.nauta-scripts-basis.yaml"
ORIGIN_INSTALLER="$REPO_ROOT/bin/deliver.sh"

# Признак источника — СОДЕРЖИМОЕ, не имя файла (ADR-037-spec §2): bin/deliver.sh — родовой
# путь, у потребителя может лежать одноимённый чужой скрипт выкладки. Подпись — литерал имени
# базиса (".nauta-scripts-basis.yaml", несущая строка BASIS_NAME= в самом bin/deliver.sh:31)
# в тексте установщика: писатель базиса обязан называть файл, который пишет.
ORIGIN=0
if [[ -f "$ORIGIN_INSTALLER" ]] && grep -Fq -- ".nauta-scripts-basis.yaml" "$ORIGIN_INSTALLER"; then
  ORIGIN=1
fi

# Форма доставки (ADR-161 Д3, NA-EPIC-158) — ТРЕТИЙ различитель дерева рядом с ORIGIN:
# подпись установщика ЕСТЬ, а корпусного маркера docs/00-vision/glossary.md НЕТ. Ветка
# раздачи (ADR-073) исключает docs/ из состава по построению, поэтому форма доставки —
# не гипотеза, а машинный факт состава: инверсия списка исключений закоммичена в ветке и
# охраняется delivery-composition. Промежуточных форм нет: маркер один, частичный docs/
# без глоссария — та же форма доставки (SA-423 «Крайние случаи»). Флаг НЕ сужает
# ORIGIN-гейты (delivery-composition, roster-declaration, payload-callers исполняются в
# форме доставки как прежде — это доставочные проверки); его читает ровно одна ветвь —
# объявленное молчание заявленной ступени в _run_if_declared ниже.
DELIVERY_FORM=0
if [[ "$ORIGIN" -eq 1 ]] && [[ ! -f "$REPO_ROOT/docs/00-vision/glossary.md" ]]; then
  DELIVERY_FORM=1
fi

OBLIGATION_MODE="STRICT"   # STRICT | DELIVERED
DECLARED_FILES=""          # \n-разделённый список путей files: (заполняется в DELIVERED)
SKIPPED_FILES=""           # \n-разделённый список путей skip: (заполняется в DELIVERED)
CONFLICTED_FILES=""        # \n-разделённый список путей conflicts: (ADR-079 Д1/Д2)
BASIS_NAUTA_VERSION=""
BASIS_NAUTA_REF_SHA=""
BASIS_SYNCED_AT=""
BASIS_FILES_COUNT=""

# --- §4 ADR-037-spec: читатели базиса — блочный awk, та же форма, что уже разбирает базис
#     bin/deliver.sh (секция 3 того файла): вход в блок по заголовку без отступа, выход — на
#     первой строке без отступа. Каждый читатель обязан ВСЕГДА возвращать 0 (см. заметку в
#     bin/deliver.sh про set -euo pipefail и command substitution внутри присваивания —
#     "не нашёл" не ошибка выполнения самого читателя, различие видно по ПУСТОТЕ вывода).

_basis_files_paths() {
  awk '
    /^files:[ \t]*(#.*)?$/ { infiles=1; next }
    infiles && $0 ~ /^[^ \t]/ { infiles=0 }
    infiles {
      line=$0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      colon = index(line, ":")
      if (colon == 0) next
      key = substr(line, 1, colon-1)
      gsub(/[ \t]+$/, "", key)
      print key
    }
  ' "$BASIS_FILE"
}

_basis_skip_paths() {
  awk '
    /^skip:[ \t]*(#.*)?$/ { inskip=1; next }
    inskip && $0 ~ /^[^ \t]/ { inskip=0 }
    inskip {
      line=$0
      sub(/^[ \t]*-[ \t]*/, "", line)
      gsub(/^[ \t]+/, "", line); gsub(/[ \t]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      print line
    }
  ' "$BASIS_FILE"
}

# _basis_conflict_paths — ADR-079 Д2/§5 п.1 спутника: копия формы _basis_files_paths с
# заголовком `conflicts:`. Секция несёт ФАКТИЧЕСКИЙ sha диска на момент синка (Д1), тогда
# как `files:` — базу sha-дискриминатора ADR-030 Д4; путать их и было дефектом ишью #13.
_basis_conflict_paths() {
  awk '
    /^conflicts:[ \t]*(#.*)?$/ { inconf=1; next }
    inconf && $0 ~ /^[^ \t]/ { inconf=0 }
    inconf {
      line=$0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      colon = index(line, ":")
      if (colon == 0) next
      key = substr(line, 1, colon-1)
      gsub(/[ \t]+$/, "", key)
      print key
    }
  ' "$BASIS_FILE"
}

# _basis_entry_value <заголовок-блока> <путь> — значение записи внутри блочного маппинга
# (`files:` или `conflicts:`). Нужен ровно одному вызывающему — тексту шестого исхода,
# который обязан назвать ОБА sha: заявленный базисом и найденный на диске (§4 спутника).
# Хешера это не заводит: значения ЧИТАЮТСЯ из базиса, ничего не считается (Д3).
_basis_entry_value() {
  local header="$1" want="$2"
  awk -v header="$header" -v want="$want" '
    $0 ~ ("^" header ":[ \t]*(#.*)?$") { inblock=1; next }
    inblock && $0 ~ /^[^ \t]/ { inblock=0 }
    inblock {
      line=$0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      colon = index(line, ":")
      if (colon == 0) next
      key = substr(line, 1, colon-1)
      val = substr(line, colon+1)
      gsub(/[ \t]+$/, "", key)
      gsub(/^[ \t]+/, "", val); gsub(/[ \t]+$/, "", val)
      gsub(/^"/, "", val); gsub(/"$/, "", val)
      if (key == want) { print val; exit }
    }
  ' "$BASIS_FILE"
}

# _basis_adopted_value <путь> — значение записи секции `adopted:` (форма Д2 ADR-080:
# `foreign` | `unverifiable`) либо пустота — секции/записи нет, позиция доставлена писателем
# и провенанса не имеет (В4 ADR-122). Читатель строки провенанса, не хешер и не писатель:
# значения читаются, ничего не классифицируется заново (Д3 ADR-080).
_basis_adopted_value() {
  local want="$1"
  [[ -f "$BASIS_FILE" ]] || return 0
  awk -v want="$want" '
    /^adopted:[ \t]*(#.*)?$/ { inblk=1; next }
    inblk && $0 ~ /^[^ \t]/ { inblk=0 }
    inblk {
      line=$0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      colon = index(line, ":")
      if (colon == 0) next
      key = substr(line, 1, colon-1)
      val = substr(line, colon+1)
      gsub(/[ \t]+$/, "", key)
      gsub(/^[ \t]+/, "", val); gsub(/[ \t]+$/, "", val)
      gsub(/^"/, "", val); gsub(/"$/, "", val)
      if (key == want) { print val; exit }
    }
  ' "$BASIS_FILE" 2>/dev/null || true
}

_basis_has_conflicts_block() {
  grep -qE '^conflicts:[[:space:]]*(#.*)?$' "$BASIS_FILE"
}

_basis_has_files_block() {
  grep -qE '^files:[[:space:]]*(#.*)?$' "$BASIS_FILE"
}

_basis_top_level_scalar() {
  # $1 = ключ (nauta_version|nauta_ref_sha|synced_at|files_count). Печатает значение с
  # обрезанными кавычками, либо ничего, если ключ отсутствует — awk без явного `exit 1` в
  # END всегда завершается нулём независимо от того, нашлось совпадение или нет.
  local key="$1"
  awk -v key="$key" '
    index($0, key ":") == 1 {
      line = $0
      sub("^" key ":[ \t]*", "", line)
      gsub(/[ \t]+$/, "", line)
      gsub(/^"/, "", line); gsub(/"$/, "", line)
      print line
      exit
    }
  ' "$BASIS_FILE"
}

_basis_delivery_complete() {
  # §4: терпит кавычки вокруг булева значения ("true"/"false") — единственное место, где
  # терпимость дешевле строгости (закавыченный руками true иначе дал бы неверную причину —
  # "версия до ADR-037" вместо отказа по существу). Пусто — «ключа нет», не «false»: разницу
  # между LEGACY и PARTIAL несёт ПУСТОТА против буквального "false", не отсутствие вывода.
  grep -E '^delivery_complete:[[:space:]]*"?(true|false)"?[[:space:]]*$' "$BASIS_FILE" 2>/dev/null \
    | sed -E 's/^delivery_complete:[[:space:]]*"?(true|false)"?[[:space:]]*$/\1/' \
    | head -n1 || true
}

_count_nonempty_lines() {
  # $1 = \n-разделённая строка (может быть пустой). grep -c без совпадений выходит 1 —
  # гасится здесь один раз, а не у каждого вызывающего.
  local text="$1"
  if [[ -z "$text" ]]; then
    echo 0
    return 0
  fi
  printf '%s\n' "$text" | grep -c . || true
}

_in_newline_list() {
  # $1 = искомый путь, $2 = \n-разделённый список (может быть пустой строкой).
  local needle="$1" haystack="$2"
  [[ -n "$haystack" ]] && printf '%s\n' "$haystack" | grep -Fxq -- "$needle"
}

# basis-resolution (ADR-123-spec §1): ступень = блок ADR-037 §2 ниже; отказные exit-ветки
# печатают текст ДО журнала и в него строку не пишут (журнал обрывается на шапке — форензика).
_basis_t0=$SECONDS
if [[ "$ORIGIN" -eq 1 ]]; then
  # Д3/Д4: признак источника проверяется ПЕРВЫМ и только УЖЕСТОЧАЕТ — найденный рядом базис
  # обязательств дерева-источника не сужает.
  OBLIGATION_MODE="STRICT"
  if [[ -f "$BASIS_FILE" ]]; then
    echo "[INFO] в дереве-источнике payload'а найден .nauta-scripts-basis.yaml — на обязательства он не"
    echo "       влияет: здесь обязателен весь перечень гейтов (ADR-037 Д3)."
  fi
elif [[ -f "$BASIS_FILE" ]]; then
  # Порядок вердиктов обязателен (§2/§4 ADR-037-spec): завершённость — РАНЬШЕ структурных.
  # Обрыв на первой же записи даёт базис с нулём записей И complete=false — назвать его
  # "нечитаемым" значило бы соврать про причину (Д5).
  BASIS_DELIVERY_COMPLETE="$(_basis_delivery_complete)"
  if [[ -z "$BASIS_DELIVERY_COMPLETE" ]]; then
    echo "ERROR: в .nauta-scripts-basis.yaml нет ключа delivery_complete — завершённость доставки по этому" >&2
    echo "базису неизвестна. Две гипотезы, механизм их не различает: базис написан версией nauta до ADR-037" >&2
    echo "либо блок метаданных правился руками. Ни один гейт не запущен. Почини: повтори" >&2
    echo "/nauta:sync-scripts — команда перепишет базис целиком, новый несёт ключ." >&2
    exit 1
  fi
  if [[ "$BASIS_DELIVERY_COMPLETE" == "false" ]]; then
    echo "ERROR: .nauta-scripts-basis.yaml объявляет незавершённую доставку (delivery_complete: false) —" >&2
    echo "синк был прерван, дерево укомплектовано частично. Считать \"мне столько и привезли\" нельзя: гейты," >&2
    echo "отсутствующие из-за обрыва, молчали бы законно (ADR-037 Д5). Ни один гейт не запущен. Почини:" >&2
    echo "повтори /nauta:sync-scripts — доставка докопирует недостающее (ADR-030 Д7)." >&2
    exit 1
  fi
  if ! _basis_has_files_block; then
    echo "ERROR: .nauta-scripts-basis.yaml в корне дерева есть, но прочитать его не удалось: блока files: нет." >&2
    echo "check.sh не может определить, что ему доставлено, и не станет молча считать, что не доставлено" >&2
    echo "ничего (ADR-007 Д1; ADR-031 Д3: \"не смог прочитать\" ≠ \"нарушений нет\"). Ни один гейт не" >&2
    echo "запущен. Почини: повтори /nauta:sync-scripts — команда перепишет базис целиком; если файл" >&2
    echo "правился руками, верни форму из ADR-030-spec §5." >&2
    exit 1
  fi
  DECLARED_FILES="$(_basis_files_paths)"
  DECLARED_COUNT="$(_count_nonempty_lines "$DECLARED_FILES")"
  if [[ "$DECLARED_COUNT" -eq 0 ]]; then
    echo "ERROR: .nauta-scripts-basis.yaml в корне дерева есть, но прочитать его не удалось: ни одной записи" >&2
    echo "в files:. check.sh не может определить, что ему доставлено, и не станет молча считать, что не" >&2
    echo "доставлено ничего (ADR-007 Д1; ADR-031 Д3: \"не смог прочитать\" ≠ \"нарушений нет\"). Ни один" >&2
    echo "гейт не запущен. Почини: повтори /nauta:sync-scripts — команда перепишет базис целиком; если файл" >&2
    echo "правился руками, верни форму из ADR-030-spec §5." >&2
    exit 1
  fi
  BASIS_FILES_COUNT="$(_basis_top_level_scalar files_count)"
  if [[ -z "$BASIS_FILES_COUNT" ]] || [[ "$BASIS_FILES_COUNT" != "$DECLARED_COUNT" ]]; then
    echo "ERROR: .nauta-scripts-basis.yaml обрезан: files_count объявляет ${BASIS_FILES_COUNT:-<нет>} записей," >&2
    echo "разобрать удалось ${DECLARED_COUNT}. Часть заявленного пропала бы бесшумно — гейты потерянных" >&2
    echo "строк выглядели бы как недоставленные, а не как порча (ADR-037 Д5). Ни один гейт не запущен." >&2
    echo "Почини: повтори /nauta:sync-scripts — команда перепишет базис целиком." >&2
    exit 1
  fi

  # ---------------------------------------------------------------------
  # conflicts_count / conflicts: — ADR-079 Д1, §5 п.2 спутника. Место — СРАЗУ за вердиктом
  # files_count: структурные контрольные числа идут группой, до вердикта SELF-UNDECLARED.
  #
  # Пару "счётчик + блок" писатель печатает ВСЕГДА вместе, в том числе на здоровом дереве
  # (там conflicts_count: 0 и пустой блок). Поэтому отсутствие пары — не «конфликтов нет», а
  # состояние, о котором базис молчит; молчание здесь опаснее отказа: посторонний файл на
  # payload-пути исполнился бы под именем гейта nauta (ровно дефект ишью #13). Прецедент
  # формы вердикта — delivery_complete выше (ADR-037 Д5): ERROR до запуска гейтов, две
  # гипотезы названы, лечение — повторный синк.
  # ---------------------------------------------------------------------
  BASIS_CONFLICTS_COUNT="$(_basis_top_level_scalar conflicts_count)"
  _conflicts_block_present=0
  if _basis_has_conflicts_block; then _conflicts_block_present=1; fi
  if [[ -z "$BASIS_CONFLICTS_COUNT" && "$_conflicts_block_present" -eq 0 ]]; then
    echo "ERROR: в .nauta-scripts-basis.yaml нет секции conflicts: — ни ключа conflicts_count, ни блока." >&2
    echo "Заявлена ли хоть одна позиция конфликтной, по этому базису неизвестно. Две гипотезы, механизм" >&2
    echo "их не различает: базис написан версией nauta до ADR-079 либо секция удалена руками. Считать" >&2
    echo "\"конфликтов нет\" нельзя: посторонний файл на payload-пути исполнился бы под именем гейта nauta" >&2
    echo "(ADR-079 Д2; ADR-031 Д3: \"не смог прочитать\" ≠ \"нарушений нет\"). Ни один гейт не запущен." >&2
    echo "Почини: повтори /nauta:sync-scripts — команда перепишет базис целиком, новый несёт секцию." >&2
    exit 1
  fi
  if [[ -z "$BASIS_CONFLICTS_COUNT" || "$_conflicts_block_present" -eq 0 ]]; then
    if [[ -z "$BASIS_CONFLICTS_COUNT" ]]; then
      _conflicts_present_half="блок conflicts:"; _conflicts_missing_half="ключ conflicts_count"
    else
      _conflicts_present_half="ключ conflicts_count"; _conflicts_missing_half="блок conflicts:"
    fi
    echo "ERROR: .nauta-scripts-basis.yaml несёт секцию conflicts: наполовину: ${_conflicts_present_half} на месте," >&2
    echo "${_conflicts_missing_half} отсутствует. Писатель печатает счётчик и блок всегда вместе (ADR-079 Д1)," >&2
    echo "поэтому половина пары означает обрез файла или ручную правку, а не отсутствие конфликтов — а по" >&2
    echo "половине судить, занята ли позиция посторонним файлом, нельзя. Ни один гейт не запущен." >&2
    echo "Почини: повтори /nauta:sync-scripts — команда перепишет базис целиком." >&2
    exit 1
  fi
  CONFLICTED_FILES="$(_basis_conflict_paths)"
  CONFLICTED_COUNT="$(_count_nonempty_lines "$CONFLICTED_FILES")"
  # Строгий `!=`, симметрично files_count и НЕ симметрично skip_count (Д1): секцию пишет
  # ТОЛЬКО писатель ("Не редактируйте руками значения" — шапка базиса), санкционированной
  # ручной правки у неё нет, поэтому расхождение в ЛЮБУЮ сторону — порча.
  if [[ ! "$BASIS_CONFLICTS_COUNT" =~ ^[0-9]+$ ]] || [[ "$BASIS_CONFLICTS_COUNT" != "$CONFLICTED_COUNT" ]]; then
    echo "ERROR: .nauta-scripts-basis.yaml обрезан: conflicts_count объявляет ${BASIS_CONFLICTS_COUNT:-<нет>} записей," >&2
    echo "разобрать удалось ${CONFLICTED_COUNT} в conflicts:. Метка конфликта — единственное, что мешает" >&2
    echo "раннеру исполнить посторонний файл под именем гейта nauta (ADR-079 Д2); потерянная метка сняла бы" >&2
    echo "защиту бесшумно. Секцию правит только писатель, поэтому расхождение в любую сторону — порча, а не" >&2
    echo "санкционированная правка (в отличие от skip:). Ни один гейт не запущен. Почини: повтори" >&2
    echo "/nauta:sync-scripts — команда перепишет базис целиком." >&2
    exit 1
  fi
  # skip_count — контрольное число секции skip:, но НЕ симметрично files_count: files:
  # правится ТОЛЬКО писателем ("Не редактируйте руками значения" — шапка базиса), а skip:
  # явно и санкционированно правится потребителем руками (та же шапка: "секцию skip: —
  # можно"; §3 ADR-037-spec). Симметричная проверка (`!=`, как у files_count) ловила бы ОБЕ
  # стороны расхождения — и обрез (`разобрано < объявлено`, порча), и САНКЦИОНИРОВАННОЕ
  # ручное добавление строки (`разобрано > объявлено`, ожидаемое поведение) — как одну и ту
  # же ошибку, блокируя каждый прогон/коммит до повторного синка за действие, которое базис
  # сам разрешает без синка. Направленное сравнение (`-lt`) ловит ТОЛЬКО обрез: если строк
  # оказалось МЕНЬШЕ заявленного — часть заявленного пропала бы бесшумно, путь, заявленный
  # ТОЛЬКО через skip: (§3), тихо перестал бы считаться заявленным — ровно та дыра, ради
  # закрытия которой заведена сама skip-клауза правила declared.
  # Если строк оказалось БОЛЬШЕ — это ручное добавление, санкционировано, не ошибка.
  SKIPPED_FILES="$(_basis_skip_paths)"
  SKIPPED_COUNT="$(_count_nonempty_lines "$SKIPPED_FILES")"
  BASIS_SKIP_COUNT="$(_basis_top_level_scalar skip_count)"
  if [[ -z "$BASIS_SKIP_COUNT" ]] \
      || ! [[ "$BASIS_SKIP_COUNT" =~ ^[0-9]+$ ]] \
      || [[ "$SKIPPED_COUNT" -lt "$BASIS_SKIP_COUNT" ]]; then
    echo "ERROR: .nauta-scripts-basis.yaml обрезан: skip_count объявляет ${BASIS_SKIP_COUNT:-<нет>} записей," >&2
    echo "разобрать удалось ${SKIPPED_COUNT} в skip:. Часть заявленного через skip: пропала бы бесшумно —" >&2
    echo "путь, добавленный в skip: до первого синка, перестал бы считаться заявленным (§3 ADR-037-spec)," >&2
    echo "и его гейт выключился бы тихо и навсегда (ADR-037 Д5). Ни один гейт не запущен. Почини: повтори" >&2
    echo "/nauta:sync-scripts — команда перепишет базис целиком." >&2
    exit 1
  fi

  # Базис обязан заявлять САМ scripts/check.sh — раннер, которым он читается. Защита в
  # глубину поверх писателя в bin/deliver.sh: базис без этой записи, даже при непустом
  # files: и сошедшемся files_count, — признак свернувшегося состава, не полноценное
  # описание доставки (§4 ADR-037-spec: "check.sh девятая позиция payload'а, к моменту его
  # появления в дереве базис заявляет минимум девять файлов").
  if ! { _in_newline_list "scripts/check.sh" "$DECLARED_FILES" \
      || _in_newline_list "scripts/check.sh" "$SKIPPED_FILES"; }; then
    echo "ERROR: .nauta-scripts-basis.yaml не заявляет сам scripts/check.sh — раннер, которым он читается." >&2
    echo "Базис, управляющий check.sh, обязан называть check.sh в files: или в skip: (§4 ADR-037-spec:" >&2
    echo "check.sh — девятая позиция payload'а, к моменту его появления в дереве базис заявляет минимум" >&2
    echo "девять файлов). Отсутствие этой записи — признак свернувшегося базиса (например, обрыв сразу" >&2
    echo "после предварительной записи писателя, до переобработки состава), а не полноценное описание" >&2
    echo "доставки этого дерева. Ни один гейт не запущен. Почини: повтори /nauta:sync-scripts — команда" >&2
    echo "перепишет базис целиком." >&2
    exit 1
  fi

  # Раннер обязан отвергнуть САМ СЕБЯ, если базис объявил его позицию конфликтной (edge case
  # §7 спутника ADR-079). Через _run_if_declared это не выражается: scripts/check.sh — не
  # ступень ростера, он и есть исполняющийся процесс. SELF-UNDECLARED выше не срабатывает —
  # запись в files: на месте (Д1), причина другая, и вердикт печатается ровно один раз.
  # `skip:` побеждает метку той же логикой, что и в _conflicted ниже: санкционированное
  # владение потребителя метка отменить не может.
  if _in_newline_list "scripts/check.sh" "$CONFLICTED_FILES" \
      && ! _in_newline_list "scripts/check.sh" "$SKIPPED_FILES"; then
    echo "ERROR: раннер не исполняет сам себя: .nauta-scripts-basis.yaml заявляет позицию scripts/check.sh" >&2
    echo "конфликтной — на диске лежит не то, что доставлено (базис: $(_basis_entry_value files scripts/check.sh)," >&2
    echo "диск на момент синка: $(_basis_entry_value conflicts scripts/check.sh)). Продолжить значило бы" >&2
    echo "выдать чужой сценарий за прогон гейтов nauta, причём под именем этого файла (ADR-079 Д2)." >&2
    echo "Ни один гейт не запущен. Почини: разреши конфликт (bin/deliver.sh печатает варианты) и повтори" >&2
    echo "/nauta:sync-scripts." >&2
    exit 1
  fi

  BASIS_NAUTA_VERSION="$(_basis_top_level_scalar nauta_version)"
  BASIS_NAUTA_REF_SHA="$(_basis_top_level_scalar nauta_ref_sha)"
  BASIS_SYNCED_AT="$(_basis_top_level_scalar synced_at)"
  OBLIGATION_MODE="DELIVERED"
  echo "[INFO] базис доставки .nauta-scripts-basis.yaml: nauta ${BASIS_NAUTA_VERSION}, ref ${BASIS_NAUTA_REF_SHA}, синк ${BASIS_SYNCED_AT},"
  echo "       заявлено файлов: ${BASIS_FILES_COUNT}. Обязательными считаются только заявленные (ADR-037 Д1)."
else
  # Д4: строгое умолчание — отсутствие базиса не значит "ничего не доставлено". Право на
  # молчание выдаёт исключительно прочитанный и завершённый базис.
  OBLIGATION_MODE="STRICT"
fi
_journal "basis-resolution" "ok" 0 "$(( SECONDS - _basis_t0 ))" s

failed=0
# Флаг окна collect (ADR-123-spec §2) и носители батча: открытие — после payload-callers
# и только в --fast, закрытие — flush'ем; PY_BATCH копит пары `имя:мягкие` собранных
# гейтов, PY_BATCH_RC хранит код выхода драйвера батча, BATCH_DRIVER_OUT — его вывод.
FAST_PY_BATCH=0
PY_BATCH=""
PY_BATCH_RC=0
BATCH_DRIVER_OUT=""

# _finish — эпилог прогона: единственное место, где решается exit-код. Вынесен в функцию
# ради режима --secret-scan-only (§4.3 спутника ADR-073), который завершается раньше
# остального перечня: копия эпилога была бы вторым прибором и разошлась бы с первым.
# Дописывает итоговую строку журнала (starts_total/start_share, Д4/Д5 ADR-123) — решатель
# exit-кода при этом не меняется.
_finish() {
  _journal_summary
  if [[ "$failed" -ne 0 ]]; then
    echo "" >&2
    echo "✗ check.sh $MODE — FAILED" >&2
    exit 1
  fi
  echo ""
  echo "✓ check.sh $MODE — passed"
  exit 0
}
# run_check <name> <cmd> [soft-codes] — третий аргумент (ADR-072 Д4) необязателен: список
# кодов, разделённых пробелом, которые для ЭТОГО вызова означают не отказ, а расхождение
# класса «soft» таксономии ADR-007 Д1. На таком коде печатается строка `⚠` и `failed` НЕ
# поднимается. Маркер ошибки (`ERROR:`/`[ERROR]`/`[error]`) в неё не входит намеренно:
# счётчик исходов ADR-042 считает маркеры, и предупреждение не смеет выглядеть отказом.
# Освобождаются ТОЛЬКО перечисленные коды — амнистия не сплошная (замок:
# tests/test_dev111_warden_detectors_on_the_path.py::test_run_check_soft_list_is_not_a_
# blanket_amnesty). Вызов без третьего аргумента ведёт себя ровно как прежде.
# uv_named_refusal — обёртка именованного отказа uv-драйверов (ADR-159 Д3, SA-162 §4.5;
# NA-EPIC-151 волна 1, DEV-560). stderr вызова фильтруется по СУЖЕННОЙ сигнатуре
# офлайн-промаха кэша — общее ядро ОБЕИХ замеренных форм uv 0.12.5: стадия download
# (замер SA 2026-11-19: «Network connectivity is disabled, but the requested data wasn't
# found in the cache») и стадия resolve (замер qa198 того же дня: «…was not found in the
# cache» + «hint: Packages were unavailable because the network was disabled») — ядро:
# «found in the cache» И «disabled». При совпадении к выводу добавляется строка, называющая
# рычаг и ADR-159; rc — насквозь (Д3: мягкий rc 3 прибора стоимости не переписывается,
# прецедент NA-EPIC-131:48). Сигнатура не совпала (дрейф текста uv, чужой отказ) — вывод и
# rc нетронуты: fail-open по имени, немедленность сохраняет сам uv (~0.1 с); пропажу имени
# ловит замок qa198 ac4a — это и есть ловец дрейфа сигнатуры. Вызова рычага здесь НЕТ
# (норма 2 спеки: рычаг невидим из нормы) — имя в диагностике, не вызов (замок ac2a судит
# строку вызова, не вхождение имени).
uv_named_refusal() {
  local rc=0 _errf
  _errf="$(mktemp "${TMPDIR:-/tmp}/uv-named-refusal.XXXXXX")" || { "$@"; return $?; }
  "$@" 2>"$_errf" || rc=$?
  if [[ "$rc" -ne 0 ]] \
     && grep -q 'found in the cache' "$_errf" 2>/dev/null \
     && grep -q 'disabled' "$_errf" 2>/dev/null; then
    # Форма сообщения: рычаг назван путём, без глагола-раннера — строка-сообщение не есть
    # вызов (ac2a судит строку вызова), а сторона ростера-объявлений не должна увидеть
    # фантомное имя вызова (стороб roster-declaration читает исполняемые строки).
    echo "  [offline UV_OFFLINE=1] промах локального кэша uv: прогрей кэш явным рычагом" >&2
    echo "  «scripts/fixtures-update.sh» — единственный сетевой рычаг сьюты; вызов руками," >&2
    echo "  форма в блоке «Test run.» AGENTS.md (ADR-159 Д2/Д3; сигнатура uv 0.12.5," >&2
    echo "  замер 2026-11-19); отказ немедленный, rc передан насквозь." >&2
  fi
  cat "$_errf" >&2 2>/dev/null
  rm -f "$_errf"
  return "$rc"
}

run_check() {
  local name="$1" cmd="$2" soft="${3:-}" rc=0
  echo "▶ $name"
  # uv-вызовы идут через обёртку именованного отказа (ADR-159 Д3, SA-162 §4.5): имя рычага
  # добавляется к офлайн-промаху кэша, rc насквозь; вердиктные литералы ниже не меняются.
  if [[ "$cmd" == *"uv run"* ]]; then
    eval "${cmd/"uv run"/uv_named_refusal uv run}" || rc=$?
  else
    eval "$cmd" || rc=$?
  fi
  if [[ "$rc" -eq 0 ]]; then
    echo "  ✓ $name"
  elif [[ -n "$soft" && " $soft " == *" $rc "* ]]; then
    echo "  ⚠ $name — код $rc объявлен мягким для этого вызова (расхождение класса soft,"
    echo "    ADR-007 Д1): проверка ВЫПОЛНЕНА, её исход не блокирует коммит."
  else
    echo "  ✗ $name FAILED" >&2
    failed=1
  fi
}

# _declared <rel> — §3 ADR-037-spec: позиция заявлена, если режим STRICT (весь перечень
# заявлен по умолчанию), либо путь есть в files: базиса, либо путь есть в skip: базиса —
# skip: заявляет НАРАВНЕ с files: (иначе путь, добавленный в skip: до первого синка, не
# получает записи в files: никогда, и гейт выключился бы тихо и навсегда).
_declared() {
  local rel="$1"
  [[ "$OBLIGATION_MODE" == "STRICT" ]] && return 0
  _in_newline_list "$rel" "$DECLARED_FILES" && return 0
  _in_newline_list "$rel" "$SKIPPED_FILES" && return 0
  return 1
}

# _conflicted <rel> — ADR-079 Д2: базис заявил, что на позиции лежит НЕ доставленное.
# `skip:` побеждает метку (edge case §7 спутника): путь в skip: — санкционированное владение
# потребителя ("не перезаписывай мою копию"), и метка, унаследованная от прогона ДО этой
# правки, не имеет права его отменять; писатель снимет её следующим синком (Д4).
_conflicted() {
  local rel="$1"
  [[ -n "$CONFLICTED_FILES" ]] || return 1
  _in_newline_list "$rel" "$SKIPPED_FILES" && return 1
  _in_newline_list "$rel" "$CONFLICTED_FILES"
}

# --- ADR-085 Д6, спутник §3.2 — объявление невхождения в поставку -------------------------
# Форма записи (одна строка комментария рядом с вызовом ростера):
#
#     # NOT-DELIVERED: <имя-ростера> — <метка причины>
#
# Метка — одна из ПЯТИ дословных (§3.2 + ADR-087 Д3): её читают сторож дополнения ниже и
# второй текст `[INFO]` в _run_if_declared. Свободная проза рядом остаётся и метки не
# заменяет: прозу читает человек, метку — прибор.
#
# Пятая — `предмет необязателен у потребителя` (ADR-087 Д3, DEV-138): у позиции, чей предмет
# у потребителя не производится НИ каналом доставки, НИ `bin/init.sh` (уточнение Д2 к
# критерию ADR-085 Д1(1)). Порядок в строке не косметика: срез метки КРАТЧАЙШИЙ
# (`${line#*" — "}` ниже), поэтому метка, сама несущая тире, обязана оставаться последней.
NOT_DELIVERED_LABELS=$'нашитая константа\nтихий ноль\nпредмет не доставляется\nпредмет необязателен у потребителя\nпредмет — репозиторий nauta'

# _not_delivered_label <base> — метка причины из объявления §3.2 либо пустая строка.
_not_delivered_label() {
  local line=""
  line="$(grep -m1 -E "^# NOT-DELIVERED: $1 " "$CHECK_SELF" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 0
  # `#*" — "` — КРАТЧАЙШЕЕ совпадение: метка `предмет — репозиторий nauta` сама несёт тире,
  # и жадный срез вернул бы «репозиторий nauta».
  printf '%s' "${line#*" — "}"
}

# _delivery_form_label <base> — метка объявления ФОРМЫ ДОСТАВКИ (ADR-161 Д3) либо пустая
# строка. Форма `# DELIVERY-FORM: <имя-ростера> — <метка>` — отдельное объявление рядом с
# вызовом ростера, НЕ §3.2: её носитель — ступень, ДОСТАВЛЯЕМАЯ потребителю (в PAYLOAD_FILES
# стоит, и §3.2-объявление у неё запрещено сторожем выше как противоречие), но чей предмет
# формой доставки не производится вовсе (замер qa201: validate-content — единственный такой
# класс структурной красности формы). Тот же срез кратчайшего « — », метка последней.
_delivery_form_label() {
  local line=""
  line="$(grep -m1 -E "^# DELIVERY-FORM: $1 " "$CHECK_SELF" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 0
  printf '%s' "${line#*" — "}"
}

# _run_if_declared <base> <ext> <runner> <kind> <kind-genitive> <func-name> — общая функция
# для гейтов (.py, uv run) и сьютов (.sh, bash); §3 ADR-037-spec: "два безусловных вызова
# идут через ту же функцию, исключений в правиле нет" — распространено на ВСЕ вызовы ниже,
# не только validate-content.py/validate-profile.py. Семь исходов (§3 псевдокод + ADR-079 Д2
# + ADR-161 Д3):
#   conflicted && present → ERROR-CONFLICTED-PRESENT (проверяется ПЕРВЫМ, §5 п.4 ADR-079-spec)
#   delivery-form && declared → INFO-DECLARED-SILENCE (ADR-161 Д3: заявленная ступень формы
#                             доставки молчит вместо исполнения; незаявленные исполняются)
#   present            → исполняет (присутствие исполняет, не запись)
#   declared && origin → ERROR-MISSING-AT-ORIGIN
#   declared && STRICT → ERROR-MISSING-NO-BASIS
#   rel in skip:       → ERROR-MISSING-SKIPPED
#   declared (прочее)  → ERROR-MISSING-DELIVERED
#   иначе              → INFO-NOT-DELIVERED, exit-код не меняется
_run_if_declared() {
  local base="$1" ext="$2" runner="$3" kind="$4" kind_gen="$5" func_name="$6"
  # Седьмой аргумент (ADR-072 Д4) — необязательный список мягких кодов, доезжающий до
  # run_check. Пять исходов выше НЕ меняются: мягкий код относится к исполненной проверке,
  # а не к её отсутствию — отсутствие заявленного файла остаётся ошибкой во всех четырёх
  # своих формах.
  local soft="${7:-}"
  local _jr_t0=$SECONDS
  local rel="scripts/${base}.${ext}"
  local name="${base}.${ext}"

  # Шестой исход — ПЕРЕД веткой присутствия (ADR-079 Д2). "Присутствие исполняет" (ADR-037
  # Д2) не отменяется, а сужается одним санкционированным условием: присутствие исполняет,
  # пока базис не заявил, что присутствует НЕ доставленное. Право на молчание по-прежнему
  # выдаёт только базис — здесь он выдаёт противоположное, прямой запрет.
  # Файла нет при живой метке — метка НЕ применяется, работают прежние пять исходов
  # (отсутствие заявленного остаётся ERROR по ADR-037 Д2).
  if _conflicted "$rel" && [[ -f "$rel" ]]; then
    echo "ERROR: ${kind} \"$name\" не исполнен: .nauta-scripts-basis.yaml заявляет позицию $rel" >&2
    echo "  конфликтной — на диске лежит не то, что доставлено (базис: $(_basis_entry_value files "$rel")," >&2
    echo "  диск на момент синка: $(_basis_entry_value conflicts "$rel")). Исполнить файл значило бы выдать" >&2
    echo "  чужую шкалу за проверку nauta (ADR-079 Д2; ADR-007 Д1: гейт возвращает 0, только если выполнил" >&2
    echo "  проверку и она прошла). Почини: разреши конфликт (bin/deliver.sh печатает три варианта) и" >&2
    echo "  повтори /nauta:sync-scripts." >&2
    exit 1
  fi

  # Форма доставки (ADR-161 Д3, NA-EPIC-158) — седьмой исход, ПЕРЕД веткой присутствия:
  # заявленная ступень берёт объявленное молчание ВМЕСТО исполнения. В форме доставки
  # скрипты присутствуют (ветка раздачи несёт scripts/ целиком), а предметы заявленных
  # ступеней формой не производятся — исполнение давало структурную красность на КАЖДОМ
  # прогоне (замер TPL :1817, деревья v2.7.0/v2.8.0). Носитель права — то же объявление,
  # что у потребителя: §3.2-метка ступени, а для доставляемой позиции с пустой популяцией
  # формы — объявление DELIVERY-FORM (замер qa201: validate-content). Незаявленные ступени
  # исполняются как прежде — дельта присутствующего файла не глушится никогда
  # (спека not-delivered-absent-only AC-001b).
  if [[ "$DELIVERY_FORM" -eq 1 ]]; then
    local df_label
    df_label="$(_not_delivered_label "$base")"
    if [[ -z "$df_label" ]]; then
      df_label="$(_delivery_form_label "$base")"
    fi
    if [[ -n "$df_label" ]]; then
      echo "[INFO] $name в форме доставки берёт объявленное молчание: ${df_label}. Проверка не"
      echo "       выполняется, exit-код не меняется: скрипт присутствует в ветке раздачи, а предмет"
      echo "       проверки формой доставки не производится (ADR-161 Д3; метка — объявление, читающее"
      echo "       право на молчание, как у потребителя — ADR-085 §3.2)."
      _journal "$name" info 0 "$(( SECONDS - _jr_t0 ))" s
      return
    fi
  fi

  if [[ -f "$rel" ]]; then
    # Ветвь провенанса (В4 ADR-122, Д4 ADR-080): перед исполнением файла, которого nauta
    # не писала, раннер называет это ОДНОЙ строкой — позиция в `adopted:`, либо в `skip:`
    # при файле на месте. Имя гейта и исход присутствия не меняются (ADR-037 Д2 в силе);
    # на чистом дереве строке нет места — она сдвинула бы окно чужих ассертов (§3.3).
    local adopted_value
    adopted_value="$(_basis_adopted_value "$rel")"
    if [[ -n "$adopted_value" ]]; then
      echo "[INFO] $rel усыновлена базисом (adopted: $adopted_value) — файл писала не nauta; исполнение санкционировано, провенанс назван (ADR-080 Д4)."
    elif _in_newline_list "$rel" "$SKIPPED_FILES"; then
      echo "[INFO] $rel назван в skip: базиса — доставка сюда отключена, файл писала не nauta; исполнение санкционировано, провенанс назван (ADR-080 Д4)."
    fi
    # Окно collect (ADR-123-spec §2, Д1/Д2): в --fast присутствующий гейт хвостовых
    # вызовов собирается в PY_BATCH парой `имя:мягкие` и исполняется run_py_batch ОДНИМ
    # стартом интерпретатора; журнальную строку ступени тогда пишет драйвер батча (исход
    # ok/soft/fail по rc и мягкому списку данного вызова) — здесь строка не пишется, иначе
    # ступень получила бы две. Отсутствующий/конфликтный гейт сюда не доходит: свои исходы
    # ADR-037 он получил выше, немедленно и без старта. Вне окна исполнение прежнее.
    if [[ "$FAST_PY_BATCH" -eq 1 ]]; then
      PY_BATCH+="${name}:${soft}"$'\n'
      return
    fi
    local _jr_f0=$failed _jr_starts=0
    if [[ "$runner" == "uv run" ]]; then _jr_starts=1; fi
    run_check "$name" "$runner $rel" "$soft"
    # Журнал ступени: исход по дельте failed (своё имя — своему отказу, ADR-042 Д3);
    # старты считает runner — `uv run` стартует интерпретатор, `bash` — нет (пин состава
    # ADR-123 Д1 считает только interpreter-spawn'ы). Мягкий код немедленного вызова
    # различим только внутри run_check, потому в журнале немедленного вызова мягкий класс
    # неотличим от ok: шаги с мягкими списками в --fast исполняет батч, чей драйвер пишет
    # исход soft погейтно (ADR-072 Д4 переживает батч).
    _journal_okfail "$name" "$_jr_t0" "$_jr_f0" "$_jr_starts"
    return
  fi

  if _declared "$rel"; then
    if [[ "$ORIGIN" -eq 1 ]]; then
      echo "▶ $name"
      echo "  ✗ $name FAILED" >&2
      echo "  ERROR: ${kind} \"$name\" объявлен в check.sh (${func_name} \"$base\"), но файла" >&2
      echo "  $rel в этом дереве нет. Дерево опознано как источник payload'а (bin/deliver.sh" >&2
      echo "  на месте и несёт подпись установщика) — здесь обязателен весь перечень (ADR-037 Д3), сужать" >&2
      echo "  его нечем. ADR-007 Д1: гейт возвращает 0 только если выполнил проверку и она прошла. Почини:" >&2
      echo "  верни файл на место либо убери \"$base\" из вызовов в check.sh, если этого предмета здесь" >&2
      echo "  больше не должно быть." >&2
      _journal "$name" fail 0 "$(( SECONDS - _jr_t0 ))" s
      failed=1
      return
    fi
    if [[ "$OBLIGATION_MODE" == "STRICT" ]]; then
      echo "▶ $name"
      echo "  ✗ $name FAILED" >&2
      echo "  ERROR: ${kind} \"$name\" объявлен в check.sh, файла $rel нет, и сузить обязательства" >&2
      echo "  нечем: .nauta-scripts-basis.yaml в корне дерева отсутствует. Отсутствие базиса не значит" >&2
      echo "  \"ничего не доставлено\" (ADR-037 Д4). Две гипотезы, механизм их не различает: (1) это дерево" >&2
      echo "  получило scripts/ через /nauta:sync-scripts, а базис потерян — повтори команду, она перепишет" >&2
      echo "  базис; (2) это дерево-источник с повреждённым bin/ — верни bin/deliver.sh и файл ${kind_gen}." >&2
      _journal "$name" fail 0 "$(( SECONDS - _jr_t0 ))" s
      failed=1
      return
    fi
    if _in_newline_list "$rel" "$SKIPPED_FILES"; then
      echo "▶ $name"
      echo "  ✗ $name FAILED" >&2
      echo "  ERROR: ${kind} \"$name\" стоит в секции skip: базиса .nauta-scripts-basis.yaml, но файла" >&2
      echo "  $rel в дереве нет. skip: означает \"не перезаписывай мою копию\", а не \"у меня" >&2
      echo "  этого нет\" (ADR-030-spec §5) — заявка есть, предмета нет, и это противоречие, а не отказ." >&2
      echo "  Почини: либо верни файл (повтори /nauta:sync-scripts, предварительно убрав путь из skip:)," >&2
      echo "  либо убери путь из skip:, если этот ${kind} вам не нужен, — тогда базис перестанет его заявлять." >&2
      _journal "$name" fail 0 "$(( SECONDS - _jr_t0 ))" s
      failed=1
      return
    fi
    echo "▶ $name"
    echo "  ✗ $name FAILED" >&2
    echo "  ERROR: ${kind} \"$name\" заявлен доставленным (.nauta-scripts-basis.yaml, files: →" >&2
    echo "  $rel, nauta ${BASIS_NAUTA_VERSION}, синк ${BASIS_SYNCED_AT}), но файла в дереве нет — доставка" >&2
    echo "  повреждена. ADR-007 Д1: \"не смог проверить\" ≠ \"нечего проверять\". Почини: повтори" >&2
    echo "  /nauta:sync-scripts — отсутствующий файл создаётся заново и конфликтом не считается" >&2
    echo "  (ADR-030 Д4)." >&2
    _journal "$name" fail 0 "$(( SECONDS - _jr_t0 ))" s
    failed=1
    return
  fi

  # Не заявлен и отсутствует — объявленное молчание (Д2/Д6): называет источник своего права,
  # не тихий [INFO] skip (Д7 — этот токен здесь не используется вовсе).
  #
  # Текстов ДВА (ADR-085 Д7, спутник §4), и различает их объявление §3.2, а не режим прогона.
  # Прежний текст кончается «обнови плагин и повтори /nauta:sync-scripts» — он опирается на
  # ADR-037 Д6 («потребитель не виноват, что гейт добавили после его синка») и предполагает,
  # что позиция когда-нибудь придёт. Для позиций классов B/C/Д5 это ЛОЖНО: обновление плагина
  # не внесёт их в payload никогда — ровно жалоба ишью #14. Инварианты у обоих текстов общие:
  # строка `▶` не печатается (шаг не исполнялся), exit-код 0, токен `[INFO] skip` не
  # используется. Отличие ровно одно и оно содержательное: первый называет лечение, второй
  # называет, что лечения нет, и куда идти вместо него.
  local nd_label
  nd_label="$(_not_delivered_label "$base")"
  if [[ -n "$nd_label" ]]; then
    echo "[INFO] $name не доставляется в деревья-потребители: ${nd_label}. Проверка не"
    echo "       выполняется, exit-код не меняется. Обновление плагина этого не изменит — позиция вне"
    echo "       состава поставки по решению ADR-085; если проверка нужна вашему проекту, подключите"
    echo "       её своим гейтом (projectGates, ADR-077)."
    _journal "$name" info 0 "$(( SECONDS - _jr_t0 ))" s
    return
  fi

  echo "[INFO] $name не доставлен в это дерево: базис (nauta ${BASIS_NAUTA_VERSION}, синк ${BASIS_SYNCED_AT}) его не"
  echo "       заявляет — проверка не выполняется, exit-код не меняется. Чтобы ${kind} появился: обнови"
  echo "       плагин и повтори /nauta:sync-scripts; как только ${kind} войдёт в payload, базис его заявит,"
  echo "       и с этого момента его отсутствие станет ошибкой."
  _journal "$name" info 0 "$(( SECONDS - _jr_t0 ))" s
}

# run_gate_if_declared <gate-basename> — прогнать `uv run scripts/<basename>.py`. Имя
# заменяет исторический остаток `run_gate_if_present`/`run_suite_if_present` («_if_present»,
# докстрока-предшественник отмечала это как остаток эпохи двух курируемых снапшотов, ADR-006
# §Q1) — неверно называл предикат: обязательность решает ЗАЯВКА базиса, не голое присутствие
# файла (ADR-037-spec §3). Имена функций не проверяются ассертами нигде (ADR-037-spec §3);
# упоминания старых имён в прозе уже закрытых артефактов (CHANGELOG.md,
# docs/60-operations/postmortems/lessons-learned.md, docs/20-requirements/**) не правятся — состояние на момент
# написания.
run_gate_if_declared() {
  _run_if_declared "$1" "py" "uv run" "гейт" "гейта" "run_gate_if_declared" "${2:-}"
}

# run_suite_if_declared <suite-basename> — прогнать scripts/<basename>.sh. Симметрична
# run_gate_if_declared (см. её докстроку).
run_suite_if_declared() {
  _run_if_declared "$1" "sh" "bash" "сьют" "сьюта" "run_suite_if_declared" "${2:-}"
}

# run_gate_sh_if_declared <gate-basename> — прогнать `bash scripts/<basename>.sh` КАК ГЕЙТ
# (Д7 ADR-040): третья обёртка _run_if_declared — runner bash (как у сьюта), но род сообщения
# "гейт" (как у .py-гейтов) — `check-hooks-path.sh` и `id-check.sh` не .sh-регрессия
# self-test harness, а содержательная проверка дерева. Протокол обязательности (пять исходов
# ADR-037) не меняется — меняется только текст рода.
run_gate_sh_if_declared() {
  _run_if_declared "$1" "sh" "bash" "гейт" "гейта" "run_gate_sh_if_declared" "${2:-}"
}

# ---------------------------------------------------------------------------
# run_py_batch (ADR-123 Д1–Д3, NA-EPIC-72) — ОДИН старт интерпретатора на хвостовую группу
# py-гейтов --fast. Форма — heredoc-драйвер `uv run -` В ТЕЛЕ check.sh (прецедент —
# infra-identifiers/link-integrity: ступени, обязанные работать у потребителя и на стенде
# QA-081 из одного check.sh, не выносятся в файл — ADR-083/issue #24, ADR-103: поставка
# без pyproject). Собранные окном collect пары `имя:мягкие` передаются argv'ем (мягкие —
# одним токеном, пустая строка, если мягких нет). Драйвер исполняет гейты через
# runpy.run_path с перехватом: изоляция погейтная (SystemExit фиксируется кодом,
# прочее исключение — код 250 «CRASH», гейт падает, следующие исполняются — Д3);
# sys.argv/cwd/потоки восстанавливаются между гейтами; захваченный stdout/stderr
# реплеятся построчно (порядок детерминирован, PYTHONUNBUFFERED). Машинная строка
# BATCH_RSLT <имя> <rc> — канал пары (имя, rc) к вердиктному блоку flush: она читается
# из захваченного вывода и в stdout прогона НЕ попадает (Д4 — ни одной новой строки).
# Журнальные строки ступеней и конверт `step py-batch starts 1 wall_ms <Σ>` пишет сам
# драйвер погейтно (стены в миллисекундах time.monotonic()).
# ---------------------------------------------------------------------------
run_py_batch() {
  [[ -n "$PY_BATCH" ]] || return 0
  local batch_rc=0
  PY_BATCH_RC=0
  BATCH_DRIVER_OUT=""
  local _batch_arg _batch_name _batch_soft
  set --
  while IFS= read -r _batch_arg; do
    [[ -n "$_batch_arg" ]] || continue
    _batch_name="${_batch_arg%%:*}"
    _batch_soft="${_batch_arg#*:}"
    if [[ "$_batch_soft" == "$_batch_arg" ]]; then _batch_soft=""; fi
    set -- "$@" "$_batch_name" "$_batch_soft"
  done <<< "$PY_BATCH"
  BATCH_DRIVER_OUT="$(uv_named_refusal env PYTHONUNBUFFERED=1 uv run - "$REPO_ROOT" "$CHECK_JOURNAL" "$@" <<'PYEOF'
# /// script
# dependencies = ["pyyaml"]
# ///
import contextlib
import io
import os
import runpy
import sys
import time
import traceback

REPO_ROOT = sys.argv[1]
JOURNAL = sys.argv[2]
_rest = sys.argv[3:]
PAIRS = [(_rest[i], _rest[i + 1]) for i in range(0, len(_rest), 2)]

sys.path.insert(0, "scripts")


def journal_line(text):
    """Построчная запись с немедленным флашем — форензика Д3: прерванный батч называет
    исполненные ступени и молчит о незавершённых. Без журнала — no-op."""
    if not JOURNAL:
        return
    try:
        with open(JOURNAL, "a", encoding="utf-8") as fh:
            fh.write(text + "\n")
            fh.flush()
    except OSError:
        pass


total_ms = 0
for name, soft in PAIRS:
    print("▶ " + name, flush=True)
    argv_backup = list(sys.argv)
    cwd_backup = os.getcwd()
    old_stdout, old_stderr = sys.stdout, sys.stderr
    out_buf, err_buf = io.StringIO(), io.StringIO()
    wall0 = time.monotonic()
    rc = 0
    try:
        sys.argv = ["scripts/" + name]
        with contextlib.redirect_stdout(out_buf), contextlib.redirect_stderr(err_buf):
            runpy.run_path("scripts/" + name, run_name="__main__")
    except SystemExit as exc:
        code = exc.code
        if code is None:
            rc = 0
        elif isinstance(code, int):
            rc = code
        else:
            rc = 1
    except BaseException:
        rc = 250
        err_buf.write("CRASH: гейт завершился вне SystemExit — следующие гейты исполнены (Д3 ADR-123)\n")
        traceback.print_exc(file=err_buf)
    finally:
        wall_ms = int(round((time.monotonic() - wall0) * 1000))
        sys.argv = argv_backup
        os.chdir(cwd_backup)
        sys.stdout, sys.stderr = old_stdout, old_stderr
    sys.stdout.write(out_buf.getvalue())
    sys.stdout.flush()
    sys.stderr.write(err_buf.getvalue())
    sys.stderr.flush()
    outcome = "ok"
    if rc != 0:
        outcome = "soft" if str(rc) in soft.split() else "fail"
    print("BATCH_RSLT " + name + " " + str(rc), flush=True)
    journal_line("step %s %s starts 0 wall_ms %d" % (name, outcome, wall_ms))
    total_ms += wall_ms

journal_line("step py-batch starts 1 wall_ms %d" % total_ms)
sys.exit(0)
PYEOF
)" || batch_rc=$?
  # Реплей захваченного stdout драйвера (▶ заголовки и вывод гейтов) — те же строки, что
  # печатали бы немедленные вызовы, НИ ОДНОЙ новой; машинные строки BATCH_RSLT вывода не
  # достигают (фильтр ниже) и уходят только вердиктному блоку flush. stderr драйвера
  # (stderr гейтов) проходит мимо захвата вживую. awk читает до конца — SIGPIPE исключён.
  if [[ -n "$BATCH_DRIVER_OUT" ]]; then
    printf '%s\n' "$BATCH_DRIVER_OUT" | awk '$0 !~ /^BATCH_RSLT /'
  fi
  PY_BATCH_RC=$batch_rc
}

# check-hooks-path (ADR-040 Д2/Д7, ADR-040-spec §4) — маршрут хуков сверяется В --fast, ДО
# гейтов содержимого: расхождение маршрута отключает .githooks/pre-commit целиком (замер §1.2
# ADR-040-spec) — сообщить об этом раньше остального дерева, а не после.
case "$MODE" in
  --secret-scan-only|--delivery-composition-only) ;;
  *) run_gate_sh_if_declared "check-hooks-path" ;;
esac

# check-branch-discipline (ADR-081 Д2/Д7) — читатель объявления профиля дисциплины ветвления
# и сторож шва §4.4 (имя ветки рабочей копии роли — адрес задачи). Место — рядом с
# check-hooks-path: обе проверки судят не содержимое дерева, а условия, в которых дерево
# вообще проверяется, и обе обязаны сказать своё раньше гейтов содержимого. У дерева без
# объявления профиля исход — [INFO] и exit 0: молчание разрешением ни одного профиля не
# является, но и отказом на непринятую дисциплину гейт не краснеет.
case "$MODE" in
  --secret-scan-only|--delivery-composition-only) ;;
  *) run_gate_if_declared "check-branch-discipline" ;;
esac

# secret-scan-tree (ADR-040 Д1, secret-hygiene-gate) — обход РАБОЧЕГО дерева gitleaks'ом в
# --fast (симметрично --staged в .githooks/pre-commit, замер §1.4: 0.33с при 2.13с текущего
# --fast). Конфигурация: secretScan.enabled/secretScan.binary из .nauta-gates.yaml (§6),
# умолчание — включено, бинарь gitleaks. Отсутствие бинаря — громкая ошибка (uv-guard
# check.sh:23 прецедент), не тихий skip (secret-hygiene-gate: "unavailable scanner is a loud
# failure").
# Строгое значение (ADR-072 Д6, решение владельца Р3) — ВТОРОЙ читатель того же ключа:
# строгость в одном (`.githooks/pre-commit`) оставила бы этот тихим, и `check.sh --fast`,
# запускаемый из CI и вручную, продолжал бы молча пропускать скан на `True`/`yes`/`flase`.
# awk печатает строку-признак `enabled=<значение>` всегда, когда ключ НАЙДЕН: без неё
# «ключа нет» (умолчание из кода, ADR-031 Д3) и «ключ задан, значение пустое» (нечитаемо)
# неразличимы. Функция возвращает 1 на нечитаемом значении, печатая его на stdout, — разбор
# делает вызывающий код: `exit` внутри `$( )` убил бы только подоболочку.
_gates_secret_scan_enabled() {
  local gates="$REPO_ROOT/.nauta-gates.yaml" v
  [[ -f "$gates" ]] || { echo true; return 0; }
  v="$(awk '
    /^secretScan:[ \t]*(#.*)?$/ { inblk=1; next }
    inblk && $0 ~ /^[^ \t]/ { inblk=0 }
    inblk && $0 ~ /^[ \t]*enabled:/ {
      line=$0
      sub(/^[ \t]*enabled:[ \t]*/, "", line)
      gsub(/[ \t]+$/, "", line); gsub(/^"/, "", line); gsub(/"$/, "", line)
      print "enabled=" line
      exit
    }
  ' "$gates")"
  [[ -z "$v" ]] && { echo true; return 0; }
  v="${v#enabled=}"
  echo "$v"
  [[ "$v" == "true" || "$v" == "false" ]]
}
_gates_secret_scan_binary() {
  local gates="$REPO_ROOT/.nauta-gates.yaml" v
  [[ -f "$gates" ]] || { echo gitleaks; return 0; }
  v="$(awk '
    /^secretScan:[ \t]*(#.*)?$/ { inblk=1; next }
    inblk && $0 ~ /^[^ \t]/ { inblk=0 }
    inblk && $0 ~ /^[ \t]*binary:/ {
      line=$0
      sub(/^[ \t]*binary:[ \t]*/, "", line)
      gsub(/[ \t]+$/, "", line); gsub(/^"/, "", line); gsub(/"$/, "", line)
      print line
      exit
    }
  ' "$gates")"
  [[ -z "$v" ]] && v=gitleaks
  echo "$v"
}
# _secret_scan_verify_scope <scope-toml> — Д6 ADR-062: громкая сверка заявленной области
# (allowlist paths конфига) с реализованной (`git ls-files`). Отслеживаемый файл, попавший
# под вычитающий паттерн, выводится на stdout — непустой вывод means сверка провалена.
# Стоимость — сотые доли секунды против ~20 с скана (замер §1.7 ADR-062-spec).
_secret_scan_verify_scope() {
  local scope="$1" patterns combined
  patterns="$(grep -oE "'''[^']*'''" "$scope" | sed -E "s/^'''(.*)'''\$/\1/")"
  [[ -z "$patterns" ]] && return 0
  combined="$(printf '%s\n' "$patterns" | paste -sd'|' -)"
  git -C "$REPO_ROOT" ls-files 2>/dev/null | grep -E "$combined" || true
}

# run_secret_scan_tree_gate — тот же и единственный блок скана для ДВУХ режимов: --fast
# (путь коммита) и --secret-scan-only (путь релиза, §4.3 спутника ADR-073). Копии кода в
# релизном скрипте нет намеренно: копия — второй прибор, и первый же дрейф развёл бы их
# молча (У8 §7 спутника — мутация внутри этого блока обязана красить оба режима разом).
run_secret_scan_tree_gate() {
  local _ss_t0=$SECONDS _ss_f0=$failed
  # Присвоение стоит УСЛОВИЕМ `if !`, а не отдельной строкой: под `set -e` голое
  # `x="$(cmd)"` абортировало бы весь скрипт раньше, чем код успеет прочесть причину (тот же
  # регресс, что описан ниже у secret_scan_ok).
  if ! SECRET_SCAN_ENABLED="$(_gates_secret_scan_enabled)"; then
    # Заголовок записи исхода намеренно НЕ совпадает дословно с заголовком секции скана
    # ниже (там суффикса в скобках нет): tests/test_qa062_adr062_secret_scan_scope.py
    # ::test_d2_2_check_sh_invokes_gitleaks_with_explicit_scope_config режет файл по ПЕРВОМУ
    # вхождению того заголовка и смотрит следующие 800 символов — совпадение сдвинуло бы окно
    # на текст этого отказа и покрасило чужой замок Д2 ADR-062. По той же причине сам литерал
    # заголовка не цитируется и в этом комментарии.
    echo "▶ secret-scan-tree (чтение конфигурации)"
    echo "  ✗ secret-scan-tree FAILED" >&2
    echo "  ERROR: secretScan.enabled в .nauta-gates.yaml задан значением" >&2
    echo "  '$SECRET_SCAN_ENABLED' — признаются ровно 'true' и 'false'. Сканирование рабочего" >&2
    echo "  дерева НЕ выполнено; это не \"0 находок\" (ADR-007 Д1, ADR-072 Д6). YAML-истины" >&2
    echo "  'True'/'yes'/'on' синонимами 'true' здесь НЕ являются, а пустое значение при" >&2
    echo "  заданном ключе не даёт права на умолчание из кода — оно принадлежит только" >&2
    echo "  отсутствующему ключу. Почини: впиши 'enabled: true' либо 'enabled: false', либо" >&2
    echo "  убери ключ secretScan целиком." >&2
    exit 1
  fi
  if [[ "$SECRET_SCAN_ENABLED" == "true" ]]; then
    SECRET_SCAN_BINARY="$(_gates_secret_scan_binary)"
    echo "▶ secret-scan-tree"
    # Область — коммитируемое множество минус игнорируемый балласт (ADR-062 Д1/Д2): конфиг
    # НЕавтоподхватываемого имени передаётся явным -c "$REPO_ROOT/.gitleaks-scope.toml"
    # (У1 SEC-041, §2.1 ADR-062-spec) — автоподхват `.gitleaks.toml` разоружил бы pre-commit
    # хук тем же allowlist'ом.
    # Цель обхода — "." ПОСЛЕ cd в $REPO_ROOT (подоболочка ниже), не абсолютный $REPO_ROOT:
    # gitleaks сверяет allowlist-паттерны с путём, КАКИМ он ему передан (§1.6/§2.1
    # ADR-062-spec), и абсолютная цель делает кандидатом на совпадение весь путь целиком,
    # включая ancestor-каталоги выше $REPO_ROOT. Ролевые копии живут ПОД местом копий
    # (`.claude/worktrees/<id>` — платформа, ADR-081 Д3; `.worktrees/<имя>` — прежний ручной
    # ритуал), поэтому при абсолютной цели неякорный паттерн этого места совпал бы с
    # ПРЕФИКСОМ собственного $REPO_ROOT такой копии и молча схлопнул бы область до 0 байт
    # (поймано Д7 при реализации DEV-088). Относительная цель снимает это без правки
    # паттернов — не менять (ADR-081 §7, «что не делать»).
    SECRET_SCAN_SCOPE_CONFIG="$REPO_ROOT/.gitleaks-scope.toml"
    SECRET_SCAN_SOURCE="absent"
    [[ -f "$SECRET_SCAN_SCOPE_CONFIG" ]] && SECRET_SCAN_SOURCE="present"
    if ! command -v "$SECRET_SCAN_BINARY" >/dev/null 2>&1; then
      echo "  ✗ secret-scan-tree FAILED" >&2
      echo "  ERROR: '$SECRET_SCAN_BINARY' не найден в PATH — сканирование секретов рабочего" >&2
      echo "  дерева не выполнено (secretScan.enabled=true, .nauta-gates.yaml). Это НЕ \"0" >&2
      echo "  находок\" (ADR-007 Д1). Установи: brew install gitleaks (замер §1.1 ADR-040-spec)." >&2
      failed=1
    elif [[ "$SECRET_SCAN_SOURCE" == "present" ]] \
         && secret_scan_d6_hits="$(_secret_scan_verify_scope "$SECRET_SCAN_SCOPE_CONFIG")" \
         && [[ -n "$secret_scan_d6_hits" ]]; then
      echo "  ✗ secret-scan-tree FAILED" >&2
      echo "  ERROR: .gitleaks-scope.toml вычитает ОТСЛЕЖИВАЕМЫЕ файлы из области (Д6 ADR-062)," >&2
      echo "  а не только игнорируемые — заявленная область (git ls-files) разошлась с" >&2
      echo "  реализованной (allowlist). Файлы:" >&2
      echo "$secret_scan_d6_hits" | sed 's/^/    /' >&2
      failed=1
    else
      # bash 3.2 (macOS system bash) даёт "unbound variable" на `"${empty_array[@]}"` под
      # `set -u` — вместо опционального элемента массива два явных вызова, оба с "dir"
      # буквально рядом с $SECRET_SCAN_BINARY (регресс DEV-088: array-форма ловилась только
      # локально на bash 5, ломала fresh sibling-consumer теста ADR-030 на системном bash).
      # Каждый вызов — условие `if`, не присвоение переменной: под `set -e` присвоение вида
      # `x="$(cmd)"` абортирует скрипт целиком при ненулевом `cmd`, даже раньше чем код
      # успевает прочитать `$?` (регресс, найденный тем же прогоном).
      if [[ "$SECRET_SCAN_SOURCE" == "present" ]]; then
        secret_scan_ok=0
        (cd "$REPO_ROOT" && "$SECRET_SCAN_BINARY" dir -c "$SECRET_SCAN_SCOPE_CONFIG" --no-banner --no-color --redact -v .) >/tmp/nauta-secret-scan-tree.$$ 2>&1 || secret_scan_ok=1
      else
        secret_scan_ok=0
        (cd "$REPO_ROOT" && "$SECRET_SCAN_BINARY" dir --no-banner --no-color --redact -v .) >/tmp/nauta-secret-scan-tree.$$ 2>&1 || secret_scan_ok=1
      fi
      if [[ "$secret_scan_ok" -eq 0 ]]; then
        SECRET_SCAN_BYTES="$(grep -oE 'scanned ~[0-9]+' /tmp/nauta-secret-scan-tree.$$ | head -1 | grep -oE '[0-9]+')"
        [[ -z "$SECRET_SCAN_BYTES" ]] && SECRET_SCAN_BYTES=0
        SECRET_SCAN_SCOPE_COUNT="$( { git -C "$REPO_ROOT" ls-files 2>/dev/null || true; git -C "$REPO_ROOT" ls-files --others --exclude-standard 2>/dev/null || true; } | sort -u | wc -l | tr -d ' ')"
        if [[ "$SECRET_SCAN_BYTES" -eq 0 && "$SECRET_SCAN_SCOPE_COUNT" -gt 0 ]]; then
          echo "  ✗ secret-scan-tree FAILED" >&2
          echo "  ERROR: scanned ~0 bytes при непустом коммитируемом множестве" >&2
          echo "  ($SECRET_SCAN_SCOPE_COUNT файлов) — область скана полностью схлопнута (Д7" >&2
          echo "  ADR-062, ADR-007 Д1: это не \"0 находок\", а отсутствие проверки)." >&2
          failed=1
        else
          echo "  ✓ secret-scan-tree (scanned ~${SECRET_SCAN_BYTES} bytes, область: ${SECRET_SCAN_SCOPE_COUNT} файлов, .gitleaks-scope.toml: ${SECRET_SCAN_SOURCE})"
        fi
        rm -f /tmp/nauta-secret-scan-tree.$$
      else
        cat /tmp/nauta-secret-scan-tree.$$ >&2
        rm -f /tmp/nauta-secret-scan-tree.$$
        echo "  ✗ secret-scan-tree FAILED" >&2
        failed=1
      fi
    fi
  else
    echo "[INFO] secret-scan-tree выключен (.nauta-gates.yaml secretScan.enabled: false) — проверка не"
    echo "       выполняется, exit-код не меняется."
    _journal "secret-scan-tree" info 0 "$(( SECONDS - _ss_t0 ))" s
    return 0
  fi
  # Журнал ступени — здесь, а не на вызывающей стороне: у функции два точечных исхода
  # (выключенный скан — info выше) и один общий для ветки включённого скана (ок/отказ по
  # дельте failed — binary-missing, сверка Д6, схлопнутая область, находки). Конфигурационный
  # отказ выше завершается exit 1 до журнала (спека ADR-123-spec §1).
  _journal_okfail "secret-scan-tree" "$_ss_t0" "$_ss_f0" 0
}

# ---------------------------------------------------------------------------
# infra-identifiers (issue #24, DEV-466) — ступень РЯДОМ с secret-scan-tree, не внутри неё:
# gitleaks ловит секреты по сигнатуре, а IP-литерал/hostname тестового стенда секретом не
# является и вне области gitleaks по построению (прецедент issue #24: hostname прожил в пяти
# файлах опубликованной ветки, IP прошёл бы без ручной проверки ревьюера — оба класса нашла
# только пара глаз человека на гейте publish).
#
# Реализация — бэш-функция + ОДНОФАЙЛОВЫЙ embedded-python (heredoc, `uv run -`, тот же приём,
# что `run_link_integrity_delivery_gate` ниже), НЕ отдельный scripts/*.py и НЕ
# run_gate_if_declared: ступень обязана исполняться у ПОТРЕБИТЕЛЯ (в отличие от
# link-integrity-delivery, у неё нет `[[ "$ORIGIN" -eq 1 ]] || return 0`), а payload
# `bin/deliver.sh` копирует только явно перечисленные PAYLOAD_FILES — новый файл вне этого
# перечня потребителю не приехал бы вовсе. `check.sh` целиком уже входит в PAYLOAD_FILES
# (ADR-030 Д2/Д6), поэтому код внутри него доставляется без правки bin/deliver.sh. Питон
# внутри heredoc — ради `ipaddress` (валидация IPv4/IPv6, включая диапазоны/компрессию) и
# `re`, которые бэш/awk воспроизвели бы менее надёжно; сторонних зависимостей (PyYAML) НЕТ
# сознательно — `pyproject.toml`/`uv.lock` не доставляются потребителю (ADR-103 Decision),
# и heredoc, требующий стороннего пакета, упал бы там, где `uv run -` резолвит окружение без
# доступного `pyproject.toml`. Ключ `infraIdentifiers` разбирается собственным построчным
# мини-парсером (тот же приём, что уже несёт bash-`awk` секции `secretScan`/`hooksPath` этого
# файла), не `yaml.safe_load`.
#
# Тихий skip БЕЗ КЛЮЧА (issue #24, симметрично тому, как `sizeBudgets` не производит строки
# для необъявленного типа) — grep ниже решает ДО спуска в python: ключ верхнего уровня не
# найден → `return 0` без единой строки вывода и БЕЗ запуска процесса `uv run` вовсе (дёшево
# для потребителя без тестового стенда). Ключ найден, но тело блока пусто (`infraIdentifiers:`
# без единого под-ключа) — тот же тихий исход, решаемый уже внутри python (см. ниже).
#
# Область скана — РАБОЧЕЕ ДЕРЕВО (`git ls-files` + неигнорируемый untracked, тот же принцип
# популяции, что байт-счётчик `secret-scan-tree` выше), НЕ история: находка, уже когда-то
# опубликованная прежним коммитом, не даёт амнистии повторному вхождению на текущем дереве
# (issue #24, «прежняя публикация не амнистирует») — гейт судит по ТЕКУЩЕМУ состоянию дерева
# и `git log`/`git blame` не читает никогда.
run_infra_identifiers_gate() {
  local gates="$REPO_ROOT/.nauta-gates.yaml"
  local _ii_t0=$SECONDS _ii_f0=$failed
  # Тихий skip ДО старта процесса (issue #24) — в журнале исход skip без старта (спека
  # ADR-123-spec §1); вот почему пин состава ADR-123 Д1 не считает infra-identifiers.
  [[ -f "$gates" ]] || { _journal "infra-identifiers" skip 0 0 s; return 0; }
  grep -qE '^infraIdentifiers:[ \t]*(#.*)?$' "$gates" || { _journal "infra-identifiers" skip 0 "$(( SECONDS - _ii_t0 ))" s; return 0; }

  local rc=0
  uv_named_refusal env PYTHONUNBUFFERED=1 uv run - "$REPO_ROOT" "$gates" <<'PYEOF' || rc=$?
# /// script
# dependencies = ["pyyaml"]
# ///
import ipaddress
import re
import subprocess
import sys
from pathlib import Path

SECTION = "infra-identifiers"
REPO_ROOT = Path(sys.argv[1]).resolve()
GATES = Path(sys.argv[2]).resolve()

raw = GATES.read_text(encoding="utf-8")


def _extract_block(text: str, key: str) -> list[str]:
    """Тело блока `key:` -- строки СТРОГО с отступом до первой строки без отступа (тот же
    приём, что bash-awk секции secretScan/hooksPath: заголовок без отступа обрывает блок)."""
    lines = text.split("\n")
    body: list[str] = []
    in_block = False
    for ln in lines:
        if not in_block:
            if re.match(rf'^{re.escape(key)}:[ \t]*(#.*)?$', ln):
                in_block = True
            continue
        if ln and ln[0] not in (" ", "\t"):
            break
        body.append(ln)
    return body


def _scalar(body: list[str], key: str) -> str | None:
    for ln in body:
        m = re.match(rf'^[ \t]+{re.escape(key)}:[ \t]*(.*)$', ln)
        if m:
            v = re.sub(r'[ \t]*#.*$', '', m.group(1)).strip()
            return v.strip('"\'')
    return None


def _list_value(body: list[str], key: str) -> list[str]:
    for i, ln in enumerate(body):
        m = re.match(rf'^[ \t]+{re.escape(key)}:[ \t]*(.*)$', ln)
        if not m:
            continue
        rest = re.sub(r'[ \t]*#.*$', '', m.group(1)).strip()
        if rest.startswith('['):
            inner = rest.strip('[]')
            return [x.strip().strip('"\'') for x in inner.split(',') if x.strip()]
        if rest:
            return [rest.strip('"\'')]
        items: list[str] = []
        key_indent = len(ln) - len(ln.lstrip())
        for nxt in body[i + 1:]:
            if not nxt.strip():
                continue
            if (len(nxt) - len(nxt.lstrip())) <= key_indent:
                break
            s = nxt.strip()
            if s.startswith('- '):
                items.append(s[2:].strip().strip('"\''))
        return items
    return []


body = _extract_block(raw, "infraIdentifiers")

# Пустой блок -- ТИХИЙ skip (issue #24): ни одной непустой строки под заголовком.
if not any(ln.strip() for ln in body):
    sys.exit(0)

enabled_raw = _scalar(body, "enabled")
if enabled_raw is None:
    enabled = True
elif enabled_raw == "true":
    enabled = True
elif enabled_raw == "false":
    enabled = False
else:
    print(f"▶ {SECTION}")
    print(f"  ✗ {SECTION} FAILED", file=sys.stderr)
    print(f"  ERROR: infraIdentifiers.enabled в .nauta-gates.yaml задан значением "
          f"'{enabled_raw}' — признаются ровно 'true' и 'false' (симметрия с "
          f"secretScan.enabled, ADR-072 Д6).", file=sys.stderr)
    sys.exit(1)

print(f"▶ {SECTION}")
if not enabled:
    print(f"  [INFO] {SECTION} выключен (.nauta-gates.yaml infraIdentifiers.enabled: false) — "
          f"проверка не выполняется, exit-код не меняется.")
    sys.exit(0)

probe = subprocess.run(
    ["git", "-C", str(REPO_ROOT), "rev-parse", "--is-inside-work-tree"],
    capture_output=True, text=True, encoding="utf-8", errors="replace",
)
if probe.returncode != 0:
    print(f"  OK: не git-репозиторий — предмета проверки нет (структурно, симметрично "
          f"check-hooks-path.sh).")
    sys.exit(0)

deny_hosts = [h for h in _list_value(body, "denyHosts") if h]
allow_ips_raw = [a for a in _list_value(body, "allowIPs") if a]

DEFAULT_ALLOW = [
    "0.0.0.0/32", "127.0.0.0/8", "::1/128",
    "192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24", "2001:db8::/32",
]
allow_networks = []
for lit in DEFAULT_ALLOW + allow_ips_raw:
    try:
        allow_networks.append(ipaddress.ip_network(lit, strict=False))
    except ValueError:
        pass  # запись allowIPs нечитаема -- игнорируется как несуществующая, не фатально

_IPV4_CAND = re.compile(r'\b\d{1,3}(?:\.\d{1,3}){3}\b')
_IPV6_CAND = re.compile(r'\b(?:[0-9A-Fa-f]{0,4}:){2,7}[0-9A-Fa-f]{0,4}\b')
_WORD_CHAR = re.compile(r'[0-9A-Za-z_]')


def _ip_hits(line: str):
    """Замер на реальном дереве (смоук DEV-466, не входит в замки) вскрыл два класса шума,
    оба снимаются здесь конструкцией, а не проектным allowIPs (issue #24 отводит allowlist
    ПОД проектно-зависимые случаи, не под структурный шум формата):
      1. "::" без единого hex-символа — валидный IPv6 (unspecified address) по `ipaddress`,
         но не несёт ни бита адресной информации; исключается literal'ом, не диапазоном
         (диапазон `::/0` разрешил бы вообще все IPv6).
      2. `path/to/test.py::test_name` (node-id прогона сьюты) и любой `<слово>::<слово>` —
         разделитель, не адрес; кандидат, приклеенный к предшествующему word-символу без
         разделителя, отбрасывается (реальный литерал в прозе отделён пробелом/пунктуацией)."""
    hits = []
    for pat, cat in ((_IPV4_CAND, "ipv4"), (_IPV6_CAND, "ipv6")):
        for m in pat.finditer(line):
            literal = m.group(0)
            if cat == "ipv6" and literal.strip(":") == "":
                continue  # "::"/"":" -- unspecified address, ноль информации
            start = m.start()
            if start > 0 and _WORD_CHAR.match(line[start - 1]):
                continue  # приклеен к предыдущему токену -- разделитель, не адрес
            try:
                addr = ipaddress.ip_address(literal)
            except ValueError:
                continue
            if not any(addr in net for net in allow_networks):
                hits.append((cat, literal))
    return hits


def _git_ls(*args: str) -> list[str]:
    r = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files", *args], capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    return [ln for ln in r.stdout.split("\n") if ln]


files = sorted(set(_git_ls() + _git_ls("--others", "--exclude-standard")))

# .nauta-gates.yaml исключён из скана СОЗНАТЕЛЬНО: он ОБЯЗАН нести денилист буквально
# (denyHosts/allowIPs) — без исключения объявление своего собственного запрета всегда
# краснело бы на строке, которая его и объявляет (тот же класс, что allowlist-паттерны
# .gitleaks-scope.toml исключены из скана gitleaks им же).
GATES_REL = None
try:
    GATES_REL = str(GATES.relative_to(REPO_ROOT))
except ValueError:
    pass

findings = []
for rel in files:
    if rel == GATES_REL:
        continue
    p = REPO_ROOT / rel
    try:
        text = p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError, IsADirectoryError):
        continue
    for lineno, line in enumerate(text.split("\n"), start=1):
        for host in deny_hosts:
            if host in line:
                findings.append((rel, lineno, "denyHost", host))
        for cat, lit in _ip_hits(line):
            findings.append((rel, lineno, cat, lit))

if findings:
    for rel, lineno, cat, lit in findings:
        print(
            f'  ERROR: {rel}:{lineno}: {cat} "{lit}" — инфраструктурный идентификатор в '
            f"рабочем дереве (issue #24: секретом не является, gitleaks его не ловит; "
            f"прежняя публикация не амнистирует повторное вхождение).",
            file=sys.stderr,
        )
    print(f"  ✗ {SECTION} FAILED", file=sys.stderr)
    sys.exit(1)

print(
    f"  ✓ {SECTION} (файлов: {len(files)}, denyHosts: {len(deny_hosts)}, "
    f"allowIPs доп.: {len(allow_ips_raw)})"
)
sys.exit(0)
PYEOF
  if [[ "$rc" -ne 0 ]]; then
    failed=1
  fi
  # Журнал ступени: скан исполнен — старт интерпретатора состоялся (uv run -), исход по
  # дельте failed (rc гейта дошёл своим именем, ADR-042 Д3).
  _journal_okfail "infra-identifiers" "$_ii_t0" "$_ii_f0" 1
}


# ---------------------------------------------------------------------------
# delivery-composition (ADR-073 Д2/Д3, спутник §2/§3) — сторож ДОПОЛНЕНИЯ состава поставки.
# Правило Д3: каждая верхнеуровневая запись `git ls-files` (каталог; для корня — файл)
# принадлежит РОВНО ОДНОМУ из двух объявленных списков носителя `.nauta-delivery.yaml`;
# третьего не дано. Мощность НЕ проверяется (Д3): устаревшее исключение молчит намеренно.
# Место вызова — §3.4: после check-hooks-path и ДО secret-scan-tree, то есть на пути
# pre-commit в stable, где нарушение и вносится (RES-053, ADR-073 Д3).
# ---------------------------------------------------------------------------
DELIVERY_CARRIER_NAME=".nauta-delivery.yaml"
DELIVERY_CARRIER="$REPO_ROOT/$DELIVERY_CARRIER_NAME"

# _delivery_carrier_records — разбор носителя по схеме §2.2 в плоские записи, разделённые
# табом: `VERSION <значение>` и `ENTRY <список> <path> <есть reason> <есть provenance>`.
# Форма разбора та же блочная awk-конструкция, что уже читает базис доставки выше в этом
# файле и `.nauta-gates.yaml`: вход в блок по заголовку без отступа, выход — на первой
# строке без отступа. Наличие полей возвращается признаком, а не значением: решение
# «полон ли носитель» принимает вызывающий код, у которого есть право печатать и краснеть.
_delivery_carrier_records() {
  awk '
    function flush() {
      if (has_entry) printf "ENTRY\t%s\t%s\t%d\t%d\n", list, epath, has_reason, has_prov
      has_entry=0; epath=""; has_reason=0; has_prov=0
    }
    /^version:/ {
      flush(); list=""
      v=$0; sub(/^version:[ \t]*/, "", v)
      gsub(/[ \t]+$/, "", v); gsub(/^"/, "", v); gsub(/"$/, "", v)
      print "VERSION\t" v; next
    }
    /^excluded:[ \t]*(#.*)?$/  { flush(); list="excluded";  next }
    /^delivered:[ \t]*(#.*)?$/ { flush(); list="delivered"; next }
    /^[^ \t]/ { flush(); list=""; next }
    list != "" {
      line=$0
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line ~ /^-[ \t]*path:/) {
        flush(); has_entry=1
        p=line; sub(/^-[ \t]*path:[ \t]*/, "", p)
        gsub(/[ \t]+$/, "", p); gsub(/^"/, "", p); gsub(/"$/, "", p)
        epath=p; next
      }
      if (line ~ /^reason:[ \t]*[^ \t]/)     { has_reason=1; next }
      if (line ~ /^provenance:[ \t]*[^ \t]/) { has_prov=1;   next }
    }
    END { flush() }
  ' "$DELIVERY_CARRIER"
}

# _delivery_unreadable <причина> <строки-подробности> — единственная форма исхода «не смог
# проверить» (ADR-007 Д1): носителя нет, схема незнакома, запись неполна или её путь не той
# грануляции. Отдельной от «нарушение состава» она обязана быть потому, что лечение разное:
# там правится состав дерева или объявление, здесь — форма самого носителя.
_delivery_unreadable() {
  local why="$1" detail="${2:-}"
  echo "  ✗ delivery-composition FAILED" >&2
  echo "  ERROR: $DELIVERY_CARRIER_NAME прочитать по схеме не удалось: $why." >&2
  [[ -n "$detail" ]] && printf '%s\n' "$detail" >&2
  echo "  Состав поставки НЕ проверен — это не «нарушений нет» (ADR-007 Д1). Почини форму" >&2
  echo "  носителя по схеме ADR-073-spec §2.2: version: 1, два списка excluded: и delivered:," >&2
  echo "  у каждой записи три обязательных поля path/reason/provenance, путь — верхнеуровневый" >&2
  echo "  каталог со слэшем на конце либо корневой файл." >&2
  failed=1
}

_dc_entry_in_list() {
  # $1 = искомая верхнеуровневая запись, $2 = \n-разделённый список; чистый bash, ноль
  # спавнов интерпретаторов — пин состава ADR-123 Д6 П-1/П-2 не расширяют.
  local needle="$1" line
  [[ -n "$2" ]] || return 1
  while IFS= read -r line; do
    [[ "$line" == "$needle" ]] && return 0
  done <<< "$2"
  return 1
}

run_delivery_composition_gate() {
  # §2.3: у потребителя сторож не зовётся ВОВСЕ — ни строки вывода, exit-код не меняется.
  # Различитель тот же, которым check.sh уже отличает два дерева (ORIGIN, строки 80-87):
  # у потребителя носителей объявления нет и быть не должно, а `--fast` обязан быть зелёным
  # сразу после payload'а (ADR-030 Д6(2), ADR-031 Д3).
  [[ "$ORIGIN" -eq 1 ]] || return 0

  # Дерево без собственной истории — НЕ нарушение границы, а отсутствие ПРЕДМЕТА, и
  # различается это тем же приёмом, что уже применён строкой выше к ORIGIN: там сторож не
  # зовётся у потребителя, здесь — не зовётся там, где источника выборки не существует.
  # Довод не в удобстве прогона, а в §3.1 спутника дословно: «Источник выборки — git
  # ls-files, то есть коммитируемое множество… поставка родится из истории». У дерева без
  # истории поставке родиться не из чего: это «нечего проверять», а не «не смог проверить»,
  # и ADR-007 Д1 различает их именно так. Случай наблюдаем не гипотетически — его дают
  # фикстуры `git archive HEAD | tar -x` (tests/test_check_sh_loud_gate_degradation.py,
  # tests/test_dev023_one_marker_per_outcome.py, tests/test_check_sh_obligation_from_basis.py):
  # плоская копия закоммиченного дерева без `.git`.
  #
  # Проверяется НЕ только «под git ли мы», но и «наш ли это корень»: материализованная копия,
  # положенная внутрь чужого репозитория, иначе получила бы выборку из ЧУЖОГО индекса и
  # судила бы состав поставки по нему. Сравнение идёт по inode (`-ef`), а не по строкам путей
  # — на macOS `pwd` и `rev-parse --show-toplevel` расходятся на `/var` против `/private/var`,
  # и строковое сравнение молча выключило бы сторож на настоящем дереве.
  #
  # Молчание ОБЪЯВЛЕННОЕ, не тихое: форма — та же строка `[INFO] … проверка не выполняется,
  # exit-код не меняется`, которой check.sh уже пользуется для недоставленного гейта и для
  # выключенного secret-scan-tree. Маркера отказа она не несёт намеренно: счётчик исходов
  # ADR-042 считает маркеры, и «нечего проверять» не смеет выглядеть отказом.
  local git_top=""
  git_top="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$git_top" ]] || ! [[ "$git_top" -ef "$REPO_ROOT" ]]; then
    echo "[INFO] delivery-composition не выполняется: у этого дерева нет своей истории git, а"
    echo "       источник выборки — git ls-files (§3.1 спутника ADR-073). Поставка родится из"
    echo "       истории, значит состава поставки здесь нет — это \"нечего проверять\", не \"не"
    echo "       смог проверить\" (ADR-007 Д1). Exit-код не меняется. Чтобы сторож заработал:"
    echo "       прогоняй его в дереве-репозитории (git init / клон), а не в плоской копии."
    return 0
  fi

  echo "▶ delivery-composition"

  if [[ ! -f "$DELIVERY_CARRIER" ]]; then
    echo "  ✗ delivery-composition FAILED" >&2
    echo "  ERROR: носитель $DELIVERY_CARRIER_NAME в корне дерева отсутствует, а дерево опознано" >&2
    echo "  как источник (bin/deliver.sh на месте и несёт подпись установщика) — здесь объявление" >&2
    echo "  границы поставки обязано быть (спутник ADR-073 §2.3). Состав поставки не проверен, и" >&2
    echo "  это не «нарушений нет» (ADR-007 Д1). Почини: заведи $DELIVERY_CARRIER_NAME по схеме" >&2
    echo "  ADR-073-spec §2.2 либо смержи ветку на коммит, где носитель уже есть." >&2
    failed=1
    return
  fi

  local records=""
  records="$(_delivery_carrier_records)" || true

  local version
  version="$(printf '%s\n' "$records" | awk -F'\t' '$1=="VERSION" {print $2; exit}')"
  if [[ "$version" != "1" ]]; then
    _delivery_unreadable "версия схемы '${version:-<ключа version нет>}' незнакома, признаётся ровно 1" \
      "  Читатель, встретивший незнакомое значение, краснеет, а не догадывается (§2.2)."
    return
  fi

  local excluded_paths="" delivered_paths="" declared_paths="" problems=""
  local kind list epath has_reason has_prov stripped
  while IFS=$'\t' read -r kind list epath has_reason has_prov; do
    [[ "$kind" == "ENTRY" ]] || continue
    if [[ -z "$epath" ]]; then
      problems+="    - запись списка $list: поле path пусто"$'\n'
      continue
    fi
    stripped="${epath%/}"
    if [[ "$epath" == ./* || "$epath" == /* || "$stripped" == */* || -z "$stripped" ]]; then
      problems+="    - '$epath' ($list): грануляция Д2 — верхнеуровневый каталог со слэшем на конце либо корневой файл; второй уровень и ведущий './' формой не являются"$'\n'
    fi
    [[ "$has_reason" == "1" ]] || problems+="    - '$epath' ($list): нет обязательного поля reason"$'\n'
    [[ "$has_prov" == "1" ]] || problems+="    - '$epath' ($list): нет обязательного поля provenance"$'\n'
    if [[ "$list" == "excluded" ]]; then
      excluded_paths+="$epath"$'\n'
    else
      delivered_paths+="$epath"$'\n'
    fi
    declared_paths+="$epath"$'\n'
  done <<< "$records"

  # §3.2 дословно: «проверяется принадлежность записи РОВНО ОДНОМУ из них». Запись в обоих
  # списках — противоречивое объявление: фильтр релиза читает только excluded (§4.1 шаг 2) и
  # выкинет её, сторож увидит её объявленной с обеих сторон и промолчит. Расхождение решается
  # автором, не механизмом.
  local both=""
  while IFS= read -r epath; do
    [[ -n "$epath" ]] || continue
    _in_newline_list "$epath" "$delivered_paths" && both+="    - '$epath'"$'\n'
  done <<< "$excluded_paths"
  if [[ -n "$both" ]]; then
    problems+="    запись названа И в excluded, И в delivered — «ровно одному» (§3.2) нарушено:"$'\n'"$both"
  fi

  if [[ -n "$problems" ]]; then
    _delivery_unreadable "объявление не по схеме" "${problems%$'\n'}"
    return
  fi

  # Выборка §3.1 — коммитируемое множество, не рабочий каталог: неотслеживаемый каталог
  # сторожа не будит, потому что поставка родится из истории. Каталог получает слэш на
  # конце, корневой файл — нет: без этого различия объявление `internal` (форма корневого
  # файла) молча закрывало бы каталог `internal/`, то есть опечатка проходила бы как
  # объявление.
  local sample entry unknown="" sample_count excluded_count
  sample="$(git -C "$REPO_ROOT" ls-files | awk -F/ '{ if (NF==1) print $0; else print $1 "/" }' | sort -u)"
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    _in_newline_list "$entry" "$declared_paths" || unknown+="$entry"$'\n'
  done <<< "$sample"

  if [[ -n "$unknown" ]]; then
    echo "  ✗ delivery-composition FAILED" >&2
    while IFS= read -r entry; do
      [[ -n "$entry" ]] || continue
      echo "  ERROR: верхнеуровневая запись '$entry' не объявлена: она не названа исключением в" >&2
      echo "  $DELIVERY_CARRIER_NAME, а значит по умолчанию уезжает на ветку delivery всему" >&2
      echo "  потребителю (ADR-073 Д2/Д3). Механизм не знает, поставка это или внутренний" >&2
      echo "  артефакт, и не станет решать за автора. Почини одним из двух — в обоих случаях" >&2
      echo "  правится $DELIVERY_CARRIER_NAME:" >&2
      echo "    1) запись — часть плагина и должна уезжать потребителю: добавь её в список" >&2
      echo "       delivered: строкой \`- path: $entry\` с полями reason и provenance;" >&2
      echo "    2) запись внутренняя и уезжать не должна: добавь её в список excluded: той же" >&2
      echo "       формой." >&2
      echo "  Схема обоих списков — ADR-073-spec §2.2." >&2
    done <<< "$unknown"
    failed=1
    return
  fi

  # ---------------------------------------------------------------------------
  # П-1/П-2 (ADR-156 Д5, SA-159 §6) — пара механической сходимости границ состава.
  # Граница КОПИИ (PAYLOAD_FILES) читается ИЗ ТЕКСТА bin/deliver.sh (прецедент
  # bin/upgrade.sh:77-81 — состав не дублируется руками; чтение файла циклом без
  # спавнов — пин состава ADR-123 Д6 не расширяется); граница РЕЛИЗА — исключённые
  # каталоги носителя, разобранные выше. Позиция под исключённым каталогом доезжает
  # на релизное дерево громкой инъекцией шага 2.5 (bin/release-delivery.sh) — класс
  # reinjected делает акт инъекции видимым; остальные — direct. Позиция, которой нет
  # в дереве файлом, класса не получает — громкий ERROR: на дереве-источнике это
  # фильтр-лик (инъекции шага 2.5 не из чего делать), на подготовленном релизном
  # дереве тот же отказ именует дрейф фильтра/инъекции — зубы П-2 (AC-006b/c).
  # Перечень печатается классификацией, БЕЗ счётчиков: пара классифицирует, а не
  # считает — семантика числа 24 и его пять зеркал (RES-106 §1.1.3) не меняются
  # (AC-006d). Третий перечень состава session-start код-путь не заводит: хук
  # сравнивает записи базиса, который пишется синком из PAYLOAD_FILES.
  # ---------------------------------------------------------------------------
  local _pf_pos="" _pf_top="" _pf_line=""
  local _pf_direct="" _pf_reinjected="" _pf_missing=""
  local _pf_in=0
  while IFS= read -r _pf_line || [[ -n "$_pf_line" ]]; do
    if [[ "$_pf_line" == "PAYLOAD_FILES=(" ]]; then
      _pf_in=1
      continue
    fi
    [[ "$_pf_in" == 1 ]] || continue
    if [[ "$_pf_line" == ")" ]]; then
      break
    fi
    _pf_pos="${_pf_line#"${_pf_line%%[![:space:]]*}"}"
    _pf_pos="${_pf_pos%\"}"
    _pf_pos="${_pf_pos#\"}"
    [[ -n "$_pf_pos" ]] || continue
    if [[ ! -f "$REPO_ROOT/$_pf_pos" ]]; then
      _pf_missing+="$_pf_pos"$'\n'
      continue
    fi
    _pf_top="${_pf_pos%%/*}/"
    if _dc_entry_in_list "$_pf_top" "$excluded_paths"; then
      _pf_reinjected+="  reinjected: $_pf_pos (под исключённым каталогом ${_pf_top} — на релизное дерево доезжает громкой инъекцией шага 2.5)"$'\n'
    else
      _pf_direct+="  direct: $_pf_pos"$'\n'
    fi
  done < "$REPO_ROOT/bin/deliver.sh"

  if [[ -z "${_pf_direct}${_pf_reinjected}${_pf_missing}" ]]; then
    _delivery_unreadable "PAYLOAD_FILES не прочитан из bin/deliver.sh: срез массива в тексте доставщика не нашёлся" ""
    return
  fi

  if [[ -n "$_pf_missing" ]]; then
    echo "  ✗ delivery-composition FAILED" >&2
    while IFS= read -r _pf_pos; do
      [[ -n "$_pf_pos" ]] || continue
      echo "  ERROR: позиция PAYLOAD_FILES '$_pf_pos' отсутствует в дереве файлом и класса" >&2
      echo "  не получает (П-1/П-2, ADR-156 Д5). На дереве-источнике фильтр релиза её вырежет," >&2
      echo "  а громкой инъекции шага 2.5 не из чего делать — фильтр-лик; на подготовленном" >&2
      echo "  релизном дереве это отказ П-2: дрейф фильтра/инъекции назван, не замолчан." >&2
      echo "  Почини: верни файл в дерево либо сними позицию с границы копии" >&2
      echo "  (PAYLOAD_FILES в bin/deliver.sh)." >&2
    done <<< "$_pf_missing"
    failed=1
    return
  fi

  echo "  П-1 классификация PAYLOAD_FILES (состав читается из текста bin/deliver.sh):"
  printf '%s' "$_pf_direct"
  printf '%s' "$_pf_reinjected"
  echo "  П-2: каждая позиция PAYLOAD_FILES присутствует в дереве файлом — на подготовленном релизном дереве дрейф фильтра/инъекции ловится фактом отсутствия."

  sample_count="$(printf '%s\n' "$sample" | grep -c . || true)"
  excluded_count="$(printf '%s\n' "$excluded_paths" | grep -c . || true)"
  echo "  ✓ delivery-composition (${sample_count} верхнеуровневых записей, ${excluded_count} объявленных исключений)"
}

if [[ "$MODE" != "--secret-scan-only" ]]; then
  _dc_t0=$SECONDS
  _dc_f0=$failed
  run_delivery_composition_gate
  _journal_okfail "delivery-composition" "$_dc_t0" "$_dc_f0" 0
fi

# Симметрично --secret-scan-only (§4.3): шаг 4 релиза (§4.1) зовёт ТОТ ЖЕ блок сторожа, а не
# свою копию правила. Отдельный режим здесь потому, что `--fast` на отфильтрованном дереве
# красен четырьмя гейтами без предмета (замер §4.3), а разбирать его вывод грепом значило бы
# завести второй, менее строгий разборщик исхода.
if [[ "$MODE" == "--delivery-composition-only" ]]; then
  _finish
fi

# ---------------------------------------------------------------------------
# link-integrity-delivery (ADR-083 Д1-Д3/Д7, спутник §2/§3/§4.1) — субъект проверки ссылочной
# целостности онбординг-текста ЭТОГО дерева обязан быть СОСТАВОМ ПОСТАВКИ (`git ls-files`
# минус `excluded:`), а не диском дерева разработки, где ADR-014/C9 уже проверяет то же самое
# и молчит на ссылках в `docs/` — область там другая (Д1/Д2 ADR-083). Место вызова — сразу
# после delivery-composition и до secret-scan-tree (§3 спутника): тот же предмет («сначала
# читаемость носителя, потом суждение о дереве»), тот же порядок.
#
# Реализация — бэш-функция плюс ОДНОФАЙЛОВЫЙ embedded-python (heredoc, не отдельный
# scripts/*.py) намеренно, а не через run_gate_if_declared: контрактный тестовый стенд QA-081
# (tests/test_link_integrity_delivery_gate.py, докстрока) копирует в дерево-фикстуру РОВНО
# `scripts/check.sh` (плюс bin/deliver.sh) — ни `scripts/_validate_common.py`, ни
# `scripts/validate-content.py` там нет. Гейт, объявленный через run_gate_if_declared,
# получил бы там ERROR-MISSING-AT-ORIGIN на КАЖДОМ прогоне вместо содержательной проверки —
# как и delivery-composition/secret-scan-tree, этот гейт — часть самого раннера, а не
# отдельно поставляемый файл. Питон внутри heredoc — ради регулярных выражений и множеств
# (резолвер/маска/таблица конструкций), которые бэш/awk воспроизвёл бы менее надёжно; такой
# же алгоритм и та же таблица `_LINK_PATTERNS`, что у дискового резолвера C9
# (scripts/validate-content.py::_resolve_link_target) и у второго прохода против канала
# (scripts/check-link-integrity-channel.py) — физическая копия неизбежна по той же причине
# самодостаточности; менять форму ссылки — значит менять все три места разом.
LINK_INTEGRITY_SECTION="link-integrity-delivery"

run_link_integrity_delivery_gate() {
  # §2.3 (тот же приём, что ORIGIN уже применяет к delivery-composition, строки 244+): у
  # потребителя сторож не зовётся ВООБЩЕ — ни строки вывода, exit-код не меняется.
  local _li_t0=$SECONDS _li_f0=$failed
  if [[ "$ORIGIN" -ne 1 ]]; then
    _journal "link-integrity-delivery" info 0 0 s
    return 0
  fi

  # uv, не голый python3 (единственная внешняя зависимость check.sh — uv-guard в шапке
  # файла; голый python3 её обошёл бы молча на среде, где интерпретатор ставит только uv).
  # PYTHONUNBUFFERED — иначе stdout буферизуется блоками при перенаправлении в пайп и строки
  # ERROR (stderr, небуферизован) обгоняют заголовок "▶ …" (stdout) в объединённом выводе —
  # секция читается тестами по ПЕРВОЙ строке с литералом, порядок должен быть детерминирован.
  local rc=0
  uv_named_refusal env PYTHONUNBUFFERED=1 uv run - "$REPO_ROOT" "$DELIVERY_CARRIER_NAME" "$LINK_INTEGRITY_SECTION" <<'PYEOF' || rc=$?
# /// script
# dependencies = ["pyyaml"]
# ///
import posixpath
import re
import subprocess
import sys
from pathlib import Path

SECTION = sys.argv[3] if len(sys.argv) > 3 else "link-integrity-delivery"
REPO_ROOT = Path(sys.argv[1]).resolve()
CARRIER_NAME = sys.argv[2]
CARRIER = REPO_ROOT / CARRIER_NAME

PLACEHOLDER_RE = re.compile(r"\{\{[A-Z_]+\}\}")


def has_placeholder(path: Path) -> bool:
    """Копия scripts/_validate_common.py::has_placeholder (ADR-014 Д2/ADR-007 Д5) —
    физическая копия неизбежна: этот процесс не смеет импортировать соседние scripts/*.py
    (см. докстроку над функцией run_link_integrity_delivery_gate)."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return False
    parts = text.split("---", 2)
    if len(parts) < 3:
        return False
    return bool(PLACEHOLDER_RE.search(parts[1]))


_FENCE_RE = re.compile(r'^ {0,3}(`{3,}|~{3,})(.*)$')
_INLINE_CODE_RE = re.compile(r'(`+)([^\n]+?)\1')


def mask_code(text: str) -> str:
    """Копия scripts/_validate_common.py::_mask_code."""
    out = []
    fence_char = None
    fence_len = 0
    for line in text.split("\n"):
        m = _FENCE_RE.match(line)
        if fence_char is None:
            if m:
                fence_char, fence_len = m.group(1)[0], len(m.group(1))
                out.append(" " * len(line))
            else:
                out.append(line)
            continue
        if m and m.group(1)[0] == fence_char and len(m.group(1)) >= fence_len \
                and not m.group(2).strip():
            fence_char, fence_len = None, 0
        out.append(" " * len(line))
    return _INLINE_CODE_RE.sub(lambda m: " " * len(m.group(0)), "\n".join(out))


# Та же таблица, что ADR-014 Д1 / scripts/validate-content.py::_LINK_PATTERNS, кроме
# snippet_id — форма резолвится относительно docs/.gramax/snippets/, которого в составе
# поставки нет (§2 ADR-083-spec: вне области, помечается строкой, не молчанием).
_LINK_PATTERNS = [
    ("path", re.compile(r'!?\[[^\]\n]*\]\(([^)\n]+)\)')),
    ("path", re.compile(r'<mermaid\s+[^>]*?path="([^"]+)"')),
    ("path", re.compile(r'<image\s+[^>]*?src="([^"]+)"')),
    ("path", re.compile(r'<openapi\s+[^>]*?src="([^"]+)"')),
    ("snippet", re.compile(r'<snippet\s+[^>]*?id="([^"]+)"')),
    ("path", re.compile(r'\[drawio:([^:\]]+):[^\]]*\]')),
]
_EXTERNAL_RE = re.compile(r'^(?:[a-z][a-z0-9+.\-]*:|//)', re.IGNORECASE)


def ls_files(repo_root: Path) -> list[str]:
    proc = subprocess.run(["git", "-C", str(repo_root), "ls-files"],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60)
    if proc.returncode != 0:
        return []
    return [l for l in proc.stdout.splitlines() if l]


def parse_carrier(path: Path):
    """Мини-парсер .nauta-delivery.yaml — семантика та же, что у bash
    _delivery_carrier_records() выше в этом файле (та же блочная форма: вход в блок по
    заголовку без отступа, выход — на первой строке без отступа). Не PyYAML: процесс не
    смеет тянуть внешние зависимости (см. докстроку над run_link_integrity_delivery_gate)."""
    lines = path.read_text(encoding="utf-8").splitlines()
    version = None
    excluded: list[dict] = []
    delivered: list[dict] = []
    cur_list = None
    cur_entry = None

    def flush():
        nonlocal cur_entry
        if cur_entry is not None:
            (excluded if cur_entry["list"] == "excluded" else delivered).append(cur_entry)
        cur_entry = None

    for raw in lines:
        if raw.startswith("version:"):
            flush(); cur_list = None
            version = raw.split(":", 1)[1].strip().strip('"')
            continue
        if re.match(r'^excluded:\s*(#.*)?$', raw):
            flush(); cur_list = "excluded"; continue
        if re.match(r'^delivered:\s*(#.*)?$', raw):
            flush(); cur_list = "delivered"; continue
        if re.match(r'^\S', raw):
            flush(); cur_list = None; continue
        if cur_list is None:
            continue
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if re.match(r'^-\s*path:', stripped):
            flush()
            p = re.sub(r'^-\s*path:\s*', '', stripped).strip().strip('"')
            cur_entry = {"list": cur_list, "path": p, "reason": False, "provenance": False}
            continue
        if re.match(r'^reason:\s*\S', stripped) and cur_entry is not None:
            cur_entry["reason"] = True; continue
        if re.match(r'^provenance:\s*\S', stripped) and cur_entry is not None:
            cur_entry["provenance"] = True; continue
    flush()
    return version, excluded, delivered


def compute_kept(all_files: list[str], excluded_entries: list[dict]):
    """§2 шаг 2: KEPT — git ls-files минус excluded (якорение: точное совпадение для
    корневого файла, startswith для каталога со слэшем — templates/root-prompt-layer/
    CLAUDE.md обязан ОСТАТЬСЯ, если исключён только корневой CLAUDE.md, ADR-083 §1.2).
    KEPT_DIRS — все каталоги-префиксы путей KEPT, не только непосредственный родитель."""
    excl_dirs = [e["path"] for e in excluded_entries if e["path"].endswith("/")]
    excl_files = {e["path"] for e in excluded_entries if not e["path"].endswith("/")}
    kept = []
    for f in all_files:
        if f in excl_files:
            continue
        if any(f.startswith(d) for d in excl_dirs):
            continue
        kept.append(f)
    kept_set = set(kept)
    kept_dirs = set()
    for f in kept:
        parts = f.split("/")[:-1]
        prefix = ""
        for part in parts:
            prefix += part + "/"
            kept_dirs.add(prefix)
    return kept_set, kept_dirs


def resolve(base_dir: str, target: str, kept_set: set, kept_dirs: set):
    """§2 шаг 6: lit ∈ KEPT, либо lit ∈ KEPT_DIRS, либо lit+'.md' ∈ KEPT, либо (без
    завершающего слэша) lit+'/_index.md' ∈ KEPT. Порядок/семантика — как у
    scripts/validate-content.py::_resolve_link_target, только цель ищется в СОСТАВЕ, не на
    диске (Д2)."""
    ends_slash = target.endswith("/")
    combined = target if base_dir in ("", ".") else f"{base_dir}/{target}"
    lit = posixpath.normpath(combined)
    if lit in kept_set:
        return True, lit
    if (lit + "/") in kept_dirs:
        return True, lit
    if (lit + ".md") in kept_set:
        return True, lit
    if not ends_slash and (lit + "/_index.md") in kept_set:
        return True, lit
    return False, lit


def main() -> int:
    # §2 шаг 1: дерево без своей истории git — «нечего проверять», не «не смог проверить»
    # (ADR-007 Д1), форма — как у delivery-composition (сравнение через realpath, не строки:
    # macOS расходится на /var против /private/var).
    git_top_proc = subprocess.run(["git", "-C", str(REPO_ROOT), "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30)
    git_top = git_top_proc.stdout.strip()
    same_tree = False
    if git_top:
        try:
            same_tree = Path(git_top).resolve() == REPO_ROOT
        except OSError:
            same_tree = False
    if git_top_proc.returncode != 0 or not git_top or not same_tree:
        print(f"[INFO] {SECTION} не выполняется: у этого дерева нет своей истории git — источник")
        print("       выборки git ls-files, поставка родится из истории (ADR-083 Д1/Д2). Это")
        print('       "нечего проверять", не "не смог проверить" (ADR-007 Д1). Exit-код не меняется.')
        return 0

    if not CARRIER.is_file():
        print(f"▶ {SECTION}")
        print(f"  ✗ {SECTION} FAILED", file=sys.stderr)
        print(f"  ERROR: носитель {CARRIER_NAME} отсутствует — состав поставки не прочитан, это не", file=sys.stderr)
        print('  "нарушений нет" (ADR-007 Д1). Гейт delivery-composition сообщает об этом отдельно;', file=sys.stderr)
        print(f"  здесь тот же факт назван для собственной секции {SECTION}.", file=sys.stderr)
        return 1

    version, excluded, delivered = parse_carrier(CARRIER)
    if version != "1":
        print(f"▶ {SECTION}")
        print(f"  ✗ {SECTION} FAILED", file=sys.stderr)
        print(f"  ERROR: {CARRIER_NAME} не прочитан по схеме — версия '{version}' незнакома,", file=sys.stderr)
        print("  признаётся ровно 1 (ADR-073-spec §2.2). Состав поставки не проверен.", file=sys.stderr)
        return 1

    all_files = ls_files(REPO_ROOT)
    kept_set, kept_dirs = compute_kept(all_files, excluded)

    # Источники — онбординг-текст СОСТАВА (ADR-083 Д1): та же тройка, что SCAN_FILES сканера
    # свежести (README + гайды getting-started/upgrading — в корне поставки с акта О3
    # NA-EPIC-83: директива владельца 2026-10-17 исключила docs/ и вернула гайды в корень),
    # плюс docs/**.md, пока docs/ числится в поставке (у потребителя с docs/ правило то же).
    # CHANGELOG корнем не сканируется: предмет — онбординг-текст, не история разработки.
    # Ревью раунда 1 окна О3: буквальное «README ИЛИ docs/**» после исключения docs/
    # оставило гайды поставки вне скана — сужение предмета гейта, устранено тем же актом.
    sources = sorted(
        f for f in kept_set
        if f in ("README.md", "getting-started.md", "upgrading-the-plugin.md")
        or (f.startswith("docs/") and f.endswith(".md"))
    )

    print(f"▶ {SECTION}")
    print(f"  проверена РАЗРЕШИМОСТЬ ссылок относительно состава поставки, а не истина текста")
    print(f"  (ADR-076 Д3) — необходимый признак, не достаточный.")
    if not excluded:
        # Краевое условие §10 ADR-083-spec: пустой excluded: — «не смог проверить», НЕ
        # «нечего исключать, всё резолвится» (замаскированный ложный зелёный). Печатается
        # КАВЕАТОМ, а не отказом: гейт продолжает читать НОСИТЕЛЬ (а не константу) — реальное
        # снятие исключения (delivered: пополняется явной записью) обязано оставаться
        # наблюдаемо-зелёным, если после этого всё резолвится по существу.
        print(f"  [INFO] excluded: пуст — форма прочитана по схеме, но границу подтвердить нечем")
        print(f"  (пустой список не прочитан как \"всё в составе\", ADR-083-spec §10 краевое условие).")

    errors: list[str] = []
    scanned = 0
    target_count = 0
    snippet_seen = False
    for source in sources:
        full = REPO_ROOT / source
        try:
            text = full.read_text(encoding="utf-8")
        except OSError:
            continue
        if has_placeholder(full):
            # §2 шаг 4 / §4.1: объявленное исключение — ИМЕНОВАННАЯ строка [INFO], не
            # молчаливый skip (AC-059-02: «объявленно не проверяется» ≠ «совпало с битым»).
            print(f"  [INFO] {source} — исходящие ссылки не проверяются: объявленный шаблон (Д3)")
            continue
        scanned += 1
        masked = mask_code(text)
        base_dir = posixpath.dirname(source)
        for kind, pattern in _LINK_PATTERNS:
            for m in pattern.finditer(masked):
                if kind == "snippet":
                    snippet_seen = True
                    continue
                raw_target = m.group(1)
                target = raw_target.split("#", 1)[0].strip("<>")
                if not target:
                    continue
                if _EXTERNAL_RE.match(target):
                    continue
                target_count += 1
                ok, lit = resolve(base_dir, target, kept_set, kept_dirs)
                if not ok:
                    errors.append(f'  ERROR: {source}: ссылка "{raw_target}" не входит в состав поставки — {lit}')

    if snippet_seen:
        print(f"  [INFO] {SECTION}: форма snippet вне области — .gramax/ не входит в поставку (§2)")

    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        print(f"  ✗ {SECTION} FAILED", file=sys.stderr)
        return 1

    print(f"  ✓ {SECTION} (состав {len(kept_set)}, источников {scanned}, целей {target_count})")
    return 0


sys.exit(main())
PYEOF
  if [[ "$rc" -ne 0 ]]; then
    failed=1
  fi
  # Журнал ступени (spec §1): heredoc-гейт с собственным стартом интерпретатора — единственный
  # из двух heredoc'ов, входящий в состав --fast дерева-источника и в пин стартов ADR-123 Д1.
  _journal_okfail "link-integrity-delivery" "$_li_t0" "$_li_f0" 1
}

if [[ "$MODE" != "--secret-scan-only" ]]; then
  run_link_integrity_delivery_gate
fi

if [[ "$MODE" != "--delivery-composition-only" ]]; then
  run_secret_scan_tree_gate
fi

# infra-identifiers НЕ исполняется в --secret-scan-only (§4.3 ADR-073: тот режим — РОВНО один
# гейт, secret-scan-tree, и ничего больше, замер §4.3 — четыре красных из пяти без предмета).
if [[ "$MODE" != "--delivery-composition-only" && "$MODE" != "--secret-scan-only" ]]; then
  run_infra_identifiers_gate
fi

# §4.3 спутника ADR-073: режим релиза исполняет РОВНО один гейт и ничего больше — на
# отфильтрованном дереве у остальных предмета нет (замер §4.3: четыре красных из пяти).
# Выход идёт через тот же _finish, что и полный прогон: второго решателя exit-кода нет.
if [[ "$MODE" == "--secret-scan-only" ]]; then
  _finish
fi
# ---------------------------------------------------------------------------
# roster-declaration (ADR-085 Д6, спутник §3.3) — сторож ДОПОЛНЕНИЯ ростера, не его мощности.
# Правило одно: каждое имя ростера принадлежит либо PAYLOAD_FILES, либо объявлению
# невхождения §3.2 с меткой причины; третьего не дано (форма — прецедент ADR-073 Д3).
#
# Почему дополнение, а не число: `assert len(PAYLOAD_FILES) == N` в четырёх
# tests/test_sync_scripts_*.py ловит «позиция пропала», но слеп к «позицию забыли добавить» —
# на базе b916433 вне поставки стояли ВОСЕМЬ имён ростера и ни одно из них не было объявлено
# (ишью #14 потребителя). Оба прибора остаются: они ловят разные дефекты.
#
# Половина ORIGIN=1 — по тому же основанию, что у delivery-composition (§2.3 ADR-073): у
# потребителя предмета нет вовсе, bin/deliver.sh ему не едет.
#
# Область — ростер (15 имён), а не весь scripts/: среди файлов вне поставки живёт внутренний
# инструментарий (execution_store*, measure-*), у которого вопроса о поставке нет.
run_roster_declaration_gate() {
  [[ "$ORIGIN" -eq 1 ]] || return 0

  echo "▶ roster-declaration"

  # Собственный флаг исхода: `failed` к этому моменту мог быть поднят СОСЕДНИМ гейтом, и
  # `✗ roster-declaration FAILED` тогда назвал бы чужой отказ своим (ADR-042 Д3 — маркер
  # принадлежит одному исходу).
  local rd_failed=0

  # Якорь начала строки СНЯТ намеренно: check-hooks-path и check-branch-discipline стоят в
  # ветках `case … esac`, и с якорем ростер даёт 13 имён вместо 15 — сторож молча сузил бы
  # собственный предмет (отрицательный контроль прибора — спутник ADR-085 §1.1).
  # ЛОВУШКА САМОЧТЕНИЯ, а не украшение: заголовок цикла сьют собирается из кусков и целиком
  # в тексте этого файла не встречается. Второй прибор ростера
  # (tests/test_qa083_gate_delivery_by_subject.py::_roster) берёт блок цикла НЕЖАДНЫМ
  # регекспом от заголовка до ближайшего `done` — по ПЕРВОМУ вхождению в файле. Написанный
  # здесь целиком, заголовок стал бы этим первым вхождением, и оба прибора увидели бы вместо
  # цикла ростера тело функции ниже: замер падал с 15 имён до 10 (наблюдалось при заведении
  # сторожа, до правки).
  local loop_anchor="for suite"
  # Третья компонента ростера (ADR-117 Д1): базовые имена ПРЯМЫХ вызовов
  # `(uv run|python3|bash) scripts/<имя>.(py|sh)` вне трёх обёрток и цикла сьют — тот же
  # прибор, что строка перемера §0 ADR-117-spec (комментарии исключены: хвост несёт
  # объявление невхождения, чьё имя совпадает с именем прибора). Прямой вызов без обёртки —
  # тоже вызов: его предмет у потребителя решается тем же правилом «в поставке либо
  # объявлен», иначе орфан ростера невидим сторожу (issue #35: вызов есть, поставки нет).
  local roster payload_bases decl_lines
  roster="$( { grep -oE '(run_gate_if_declared|run_gate_sh_if_declared|run_suite_if_declared) "[a-z-]+"' "$CHECK_SELF" \
                 | grep -oE '"[a-z-]+"' | tr -d '"' || true
               sed -n "/${loop_anchor} in/,/done/p" "$CHECK_SELF" | grep -oE 'test-[a-z-]+' || true
               grep -vE '^[[:space:]]*#' "$CHECK_SELF" \
                 | grep -oE '(uv run|python3|bash)[[:space:]]+"?[^"[:space:]]*scripts/[a-z0-9._-]+\.(py|sh)' \
                 | grep -oE 'scripts/[a-z0-9._-]+\.(py|sh)' | sed -e 's#.*/##' -e 's#\.[^.]*$##' || true; } | sort -u)"
  payload_bases="$(sed -n '/^PAYLOAD_FILES=(/,/^)/p' "$ORIGIN_INSTALLER" \
                     | grep -oE '"[^"]+"' | tr -d '"' | sed -e 's#.*/##' -e 's#\.[^.]*$##' | sort -u || true)"
  decl_lines="$(grep -E '^# NOT-DELIVERED: ' "$CHECK_SELF" || true)"

  local roster_n decl_n
  roster_n="$(printf '%s\n' "$roster" | grep -c . || true)"
  decl_n="$(printf '%s\n' "$decl_lines" | grep -c . || true)"

  local name label in_payload has_decl
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    in_payload=0
    printf '%s\n' "$payload_bases" | grep -Fxq -- "$name" && in_payload=1 || true
    label="$(_not_delivered_label "$name")"
    has_decl=0
    [[ -n "$label" ]] && has_decl=1 || true

    if [[ "$in_payload" -eq 1 && "$has_decl" -eq 1 ]]; then
      echo "  ERROR: \"$name\" доставляется и объявлено недоставляемым одновременно —" >&2
      echo "  позиция стоит в PAYLOAD_FILES (bin/deliver.sh) и несёт объявление" >&2
      echo "  \"# NOT-DELIVERED: $name — $label\" в scripts/check.sh. Это противоречие, а не" >&2
      echo "  двойная страховка (§3.3 ADR-085): потребитель получит файл и прочитает, что его" >&2
      echo "  не получит. Почини: сними одно из двух." >&2
      rd_failed=1
    elif [[ "$in_payload" -eq 0 && "$has_decl" -eq 0 ]]; then
      echo "  ERROR: \"$name\" не доставляется и невхождение не объявлено — имя стоит в ростере" >&2
      echo "  scripts/check.sh, но его нет ни в PAYLOAD_FILES (bin/deliver.sh), ни в объявлениях" >&2
      echo "  §3.2. Потребитель получит [INFO] с лечением, которого нет (ишью #14). Почини:" >&2
      echo "  внеси позицию в PAYLOAD_FILES, если её предмет есть у потребителя (критерий" >&2
      echo "  ADR-085 Д1), либо объяви невхождение строкой" >&2
      echo "  \"# NOT-DELIVERED: $name — <метка>\" рядом с вызовом; метки — ADR-085 §3.2." >&2
      rd_failed=1
    fi
  done <<< "$roster"

  # Метка вне дословной пятёрки (§3.2 + ADR-087 Д3) — отказ, а не тихое принятие: свободную
  # прозу читает человек, метку — этот сторож и текст [INFO]. Проверяются ВСЕ объявления, а не
  # только найденные обходом ростера: объявление с опечаткой в имени иначе не прозвучало бы
  # нигде.
  local decl_label
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    decl_label="${name#*" — "}"
    if ! printf '%s\n' "$NOT_DELIVERED_LABELS" | grep -Fxq -- "$decl_label"; then
      echo "  ERROR: метка причины вне дословной пятёрки ADR-085 §3.2 (пятая — ADR-087 Д3):" >&2
      echo "  \"$decl_label\" (строка: \"$name\"). Метка — не проза: её читают этот сторож и" >&2
      echo "  второй текст [INFO]. Допустимы ровно пять: нашитая константа | тихий ноль |" >&2
      echo "  предмет не доставляется | предмет необязателен у потребителя | предмет —" >&2
      echo "  репозиторий nauta." >&2
      rd_failed=1
    fi
  done <<< "$decl_lines"

  if [[ "$rd_failed" -eq 0 ]]; then
    echo "  ✓ roster-declaration (${roster_n} имён ростера, ${decl_n} объявлений невхождения)"
  else
    echo "  ✗ roster-declaration FAILED" >&2
    failed=1
  fi
}

_rd_t0=$SECONDS
_rd_f0=$failed
run_roster_declaration_gate
_journal_okfail "roster-declaration" "$_rd_t0" "$_rd_f0" 0

# ---------------------------------------------------------------------------
# payload-callers (ADR-111 Д1/Д2/Д4, спутник §4) — сторож ДОПОЛНЕНИЯ белого списка состава.
# Правило одно: каждая позиция перечня состава принадлежит либо ростеру выше, либо записи
# `# CALLER: <позиция> — <метка>` в bin/deliver.sh; третьего не дано. Форма — прецедент
# roster-declaration соседней функцией, и это не симметрия ради симметрии: обратный перекос
# (имя ростера вне поставки) закрыт ею, встречный (позиция без названного вызывающего) — нет.
#
# Что этот сторож НЕ делает (спутник §4, рубрика «Не делает»): он не перепроверяет, что
# названный вызывающий физически существует в дереве. Эта половина живёт в
# tests/test_payload_caller_provenance.py, где есть прибор с тремя границами (раннер ПЕРЕД
# путём; `tests/` не читается; печатаемая строка не есть вызов) и укоренением цепочки. Порознь
# оба слепы: сторож пропустит запись, чей вызывающий умер; тест не увидит позицию, о которой
# записи нет вовсе. Цена ступени здесь — два чтения файла, и она названа в решении условием.
#
# Половина ORIGIN=1 — по тому же основанию, что у delivery-composition и roster-declaration
# (§2.3 ADR-073): у потребителя предмета нет вовсе, bin/deliver.sh ему не едет. Ступень —
# --fast, довод ADR-073 Д3 дословно: «нарушение вносится коммитом в stable… сторож не на пути
# нарушения — не сторож». Р22 не переоткрывается: предмет ступени — ДВА ФАЙЛА, а не состояние
# корпуса, и перенос корпусных проверок в --fast (остановленный DEV-111, строки 11-12) здесь
# не предлагается.
CALLER_LABELS=$'ростер check.sh\nглагол промт-слоя\nвызов живой позиции\nимпорт живой позиции\nисполнитель платформы\nинструкция потребителю\nвызывающего нет'

run_payload_callers_gate() {
  [[ "$ORIGIN" -eq 1 ]] || return 0

  echo "▶ payload-callers"

  # Собственный флаг исхода: `failed` мог быть поднят соседом, и `✗ payload-callers FAILED`
  # тогда назвал бы чужой отказ своим (ADR-042 Д3).
  local pc_failed=0
  # Тот же якорь-из-кусков, что у соседа: заголовок цикла сьют, написанный целиком, стал бы
  # ПЕРВЫМ его вхождением в файл и сдвинул бы оба прибора ростера с 15 имён до 10.
  local loop_anchor="for suite"
  # Третья компонента — та же, что у соседа roster-declaration (ADR-117 Д1): прямые вызовы
  # `scripts/*.(py|sh)` вне обёрток и цикла. Прибор один и тот же в обоих сторожах — иначе
  # «позиция в ростере» значила бы разное в двух местах одного файла.
  local roster positions rec_lines
  roster="$( { grep -oE '(run_gate_if_declared|run_gate_sh_if_declared|run_suite_if_declared) "[a-z-]+"' "$CHECK_SELF" \
                 | grep -oE '"[a-z-]+"' | tr -d '"' || true
               sed -n "/${loop_anchor} in/,/done/p" "$CHECK_SELF" | grep -oE 'test-[a-z-]+' || true
               grep -vE '^[[:space:]]*#' "$CHECK_SELF" \
                 | grep -oE '(uv run|python3|bash)[[:space:]]+"?[^"[:space:]]*scripts/[a-z0-9._-]+\.(py|sh)' \
                 | grep -oE 'scripts/[a-z0-9._-]+\.(py|sh)' | sed -e 's#.*/##' -e 's#\.[^.]*$##' || true; } | sort -u)"
  positions="$(sed -n '/^PAYLOAD_FILES=(/,/^)/p' "$ORIGIN_INSTALLER" \
                 | grep -oE '"[^"]+"' | tr -d '"' || true)"
  rec_lines="$(grep -E '^# CALLER: ' "$ORIGIN_INSTALLER" || true)"

  local pos_n rec_n dead_n
  pos_n="$(printf '%s\n' "$positions" | grep -c . || true)"
  rec_n="$(printf '%s\n' "$rec_lines" | grep -c . || true)"
  dead_n="$(printf '%s\n' "$rec_lines" | grep -c -- ' — вызывающего нет$' || true)"

  # Три перечня сводятся в строки-с-обрамлением и дальше ищутся ЧИСТО СРЕДСТВАМИ bash: замер
  # DEV-469 на этом дереве дал 336 мс у редакции с `grep` на каждую из 26 позиций (52 форка) —
  # больше цены соседа `--delivery-composition-only` (304 мс), то есть условие спутника §8 п. 3
  # («прирост больше цены соседа — остановка») срабатывало на самой реализации, а не на решении.
  local roster_all rec_all labels_all pos_all
  roster_all=$'\n'"$roster"$'\n'
  rec_all=$'\n'"$rec_lines"$'\n'
  labels_all=$'\n'"$CALLER_LABELS"$'\n'
  pos_all=$'\n'"$positions"$'\n'

  local pos base rec label tail in_roster has_rec
  while IFS= read -r pos; do
    [[ -n "$pos" ]] || continue
    base="${pos##*/}"
    base="${base%.*}"
    in_roster=0
    [[ "$roster_all" == *$'\n'"$base"$'\n'* ]] && in_roster=1
    has_rec=0
    label=""
    rec=""
    if [[ "$rec_all" == *$'\n'"# CALLER: $pos — "* ]]; then
      has_rec=1
      tail="${rec_all#*$'\n'"# CALLER: $pos — "}"
      # КРАТЧАЙШЕЕ совпадение: метка, сама несущая тире, иначе потеряла бы начало.
      label="${tail%%$'\n'*}"
      rec="# CALLER: $pos — $label"
    fi

    if [[ "$in_roster" -eq 1 && "$has_rec" -eq 1 ]]; then
      echo "  ERROR: \"$pos\" несёт и имя ростера, и запись # CALLER: — это два источника" >&2
      echo "  правды об одной позиции, а не двойная страховка (ADR-111-spec §3). Имя ростера" >&2
      echo "  уже стережёт roster-declaration выше. Почини: сними строку" >&2
      echo "  \"# CALLER: $pos — $label\" из bin/deliver.sh." >&2
      pc_failed=1
    elif [[ "$in_roster" -eq 0 && "$has_rec" -eq 0 ]]; then
      echo "  ERROR: \"$pos\" доставляется, но вызывающий у неё не назван — имени в ростере" >&2
      echo "  scripts/check.sh нет, записи # CALLER: в bin/deliver.sh нет (ADR-111 Д2:" >&2
      echo "  позиция входит в состав тогда и только тогда, когда у неё НАЗВАН вызывающий)." >&2
      echo "  Почини: назови вызывающего строкой \"# CALLER: $pos — <метка>\" рядом с" >&2
      echo "  перечнем — метки ниже; либо, если вызывающего нет и это установлено замером," >&2
      echo "  поставь метку \"вызывающего нет\", и снятие позиции решит владелец (ADR-111 Д5)." >&2
      pc_failed=1
    fi
  done <<< "$positions"

  # Метка вне закрытого набора — отказ. Проверяются ВСЕ записи, а не только встреченные
  # обходом перечня: запись с опечаткой в пути иначе не прозвучала бы нигде (тот же довод,
  # что у соседа строкой 1706).
  local rec_label rec_path
  while IFS= read -r rec; do
    [[ -n "$rec" ]] || continue
    rec_label="${rec#*" — "}"
    rec_path="${rec#'# CALLER: '}"
    rec_path="${rec_path%%' — '*}"
    if [[ "$labels_all" != *$'\n'"$rec_label"$'\n'* ]]; then
      echo "  ERROR: метка вызывающего вне закрытого набора ADR-111-spec §3:" >&2
      echo "  \"$rec_label\" (строка: \"$rec\"). Метка — не проза: её читает этот сторож." >&2
      echo "  Допустимы ровно семь: ростер check.sh | глагол промт-слоя | вызов живой" >&2
      echo "  позиции | импорт живой позиции | исполнитель платформы | инструкция" >&2
      echo "  потребителю | вызывающего нет." >&2
      pc_failed=1
    fi
    if [[ "$pos_all" != *$'\n'"$rec_path"$'\n'* ]]; then
      echo "  ERROR: запись # CALLER: адресует \"$rec_path\" — такой позиции в перечне" >&2
      echo "  состава (bin/deliver.sh) нет. Это опечатка в пути либо запись, пережившая" >&2
      echo "  снятие позиции. Почини: выправи путь или сними строку \"$rec\"." >&2
      pc_failed=1
    fi
  done <<< "$rec_lines"

  if [[ "$pc_failed" -eq 0 ]]; then
    echo "  ✓ payload-callers (${pos_n} позиций, ${rec_n} записей, ${dead_n} из них «вызывающего нет»)"
  else
    echo "  ✗ payload-callers FAILED" >&2
    failed=1
  fi
}

_pc_t0=$SECONDS
_pc_f0=$failed
run_payload_callers_gate
_journal_okfail "payload-callers" "$_pc_t0" "$_pc_f0" 0

# Окно collect (ADR-123-spec §2): открыт здесь и только в --fast, закрыт flush'ем ниже.
# Внутри окна _run_if_declared собирает присутствующие гейты хвостовых вызовов в
# PY_BATCH вместо немедленного исполнения; ранее окна (check-branch-discipline) и в --full
# гейты идут немедленно, как прежде (Д7). Пустому батчу окна не мешают: дерево-потребитель
# получает свои исходы ADR-037 немедленно, PY_BATCH остаётся пустым, run_py_batch выходит
# без единого старта (стенд QA-081 — только check.sh, --fast остаётся зелёным).
if [[ "$MODE" == "--fast" ]]; then
  FAST_PY_BATCH=1
fi

# Два безусловных вызова (§3 ADR-037-spec: "исключений в правиле нет") — идут через ТУ ЖЕ
# функцию, что и остальной перечень: в реальном payload'е они всегда заявлены и присутствуют,
# наблюдаемое поведение не меняется; расходится только текст, если они когда-нибудь пропадут.
# Объявление ФОРМЫ ДОСТАВКИ (ADR-161 Д3, находка среза qa201) — позиция ДОСТАВЛЯЕТСЯ
# потребителю (PAYLOAD_FILES, у git-потребителя с заведённым контуром исполняется штатно),
# поэтому §3.2-объявление ей запрещено сторожем roster-declaration как противоречие; но
# документарный контур формой доставки не производится вовсе (инверсия ADR-073 вырезает
# docs/ из ветки раздачи), и на форме доставки валидатор обязан молчать объявленно, а не
# краснить S2 («контур Д не заведён») на каждом прогоне — пятая структурная ступень замера
# qa201. Метка несёт тире и потому последняя в строке (срез кратчайшего « — »).
# DELIVERY-FORM: validate-content — предмет — документарный контур потребителя
run_gate_if_declared "validate-content"
run_gate_if_declared "validate-profile"
# Объявление невхождения §3.2 — позиция ВНЕ поставки по решению ADR-087 (Д1/Д3/Д4), которое
# закрыло остановку DEV-135. ADR-085 Д2 назвал этот гейт классом A по критерию Д1(3);
# ADR-087 Д1 переклассифицировал: позиция покидает класс A по провалу Д1(1) («предмет есть у
# потребителя»), а не Д1(3), и мощность `PAYLOAD_FILES` остаётся 21 (перечень класса A и
# число `20 → 23` ADR-085 Д2 замещены ADR-087 Д5; текст ADR-085 не правится).
# ADR-085 Д2 назвал этот гейт классом A («доставляется этой волной») на основании Д1(3) —
# «на дереве без предмета печатает ГРОМКИЙ ноль». Замер, которым это обосновано (спутник §2.1),
# снят на стенде, где каталог-предмет СОЗДАН РУКАМИ: `mkdir -p $S/docs/30-architecture/adr/`.
# У настоящего потребителя каталога нет: ни `bin/deliver.sh`, ни
# `templates/content-scaffold/00-project/` его не заводят («`adr/` — создаёт
# `/nauta:sa adr <решение>`»). На таком входе гейт по СВОЕМУ принятому решению ADR-013 Д4
# («`docs/adr/` не существует/нечитаем — «не смог» ≠ «нет нарушений», ADR-007 Д1») печатает
# `ERROR: … not found or not a directory — gate did not run.` и возвращает 1, то есть Д1(3)
# НЕ выполнено, а `check.sh --fast` у потребителя краснеет — вопреки ADR-030 Д6(2). Замер
# DEV-135 на sibling-потребителе, собранном `bin/deliver.sh`: с позицией в payload —
# `✗ check.sh --fast — FAILED`; на базе 66d7c91 тот же стенд — `✓ check.sh --fast — passed`.
# Прецедент остановки ступени по тому же ADR-030 Д6(2) — DEV-111 (перевод id-check.sh в --fast).
# Метка — ПЯТАЯ (ADR-087 Д3), заведённая этой позицией: предмет проверки у потребителя
# необязателен. `нашитая константа` для неё ЛОЖНА — `DEFAULT_ADR_DIR`
# (`scripts/check-adr-line-limit.py:53`) константа, но называет она обычный путь ПОТРЕБИТЕЛЯ,
# а не артефакт nauta, и потребителю, у которого ADR есть, второй `[INFO]` напечатал бы
# неправду: тот же класс дефекта, что снимало ишью #14. Развилка («править exit-таксономию
# ADR-013 Д4 / заводить каталог в скаффолде / структурный маркер из `bin/deliver.sh`») закрыта
# ADR-087 целиком — все три ветви отклонены с основанием (§Alternatives). Условие входа
# позиции в payload названо и проверяемо (Д4): каталог `docs/30-architecture/adr/` начинает
# производиться для ОБЕИХ популяций ADR-030 Д6(2) без нарушения ADR-041 Д1; до того
# потребителю, ведущему ADR, адресован `projectGates` (ADR-077) — его называет второй
# `[INFO]` ниже. Объявление СЬЮТЫ (`test-check-adr-line-limit`) метку НЕ меняет: она не едет
# потому, что не едет её предмет-скрипт.
# NOT-DELIVERED: check-adr-line-limit — предмет необязателен у потребителя
run_gate_if_declared "check-adr-line-limit"

# check-test-subject-governs (ADR-070; вызов — ADR-072 Д3/Д4). До DEV-111 гейт не звался
# НИОТКУДА: `grep -rn check-test-subject-governs .githooks/pre-commit scripts/check.sh
# bin/deliver.sh .gitlab-ci.yml` на базе 11d1fd4 давал пусто (rc=1) — снятие строки
# `Governs:` не меняло вывода ни одного обязательного прогона.
#
# Код 1 объявлен МЯГКИМ (второй аргумент): по контракту ADR-070 это «неполнота охвата»
# (есть SIGNAL, нет VIOLATION) — расхождение класса soft таксономии ADR-007 Д1, а не «не
# смог проверить». Число SIGNAL меняется каждой волной (capability без объявляющего теста
# заводит BA), и блокировать по нему значило бы красить рабочую ветку чужой волной.
# Хард-блок — код 3 (VIOLATION), он мягким не объявлен и остаётся отказом.
#
# Сам гейт при этом НЕ правится: его exit-контракт (0/1/2/3) объявлен ADR-070 и заперт
# `tests/test_qa073_adr070_governs_marker_gate.py`; переоткрывать принятое решение критерий
# BA-056 запрещает. Разбирает исход раннер — здесь. Состав поставки этой волной не меняется
# (ADR-072 Д5): вызов и поставка — разные вопросы (ADR-037 Д1).
# Объявление невхождения §3.2 ADR-085 (Д4). Основание — ЗАМЕР на дереве формы потребителя:
# гейт печатает 0 БАЙТ и возвращает 0, то есть его ноль неотличим от незапущенного прогона
# (ADR-007 Д1). Доставить его значило бы воспроизвести у потребителя класс ишью #11/#12.
# Условие входа в поставку названо и проверяемо: строка вида `INFO: scanned 0 test file(s)`
# (форма соседа по Д2), после чего позиция вносится обычной правкой числа. Exit-контракт
# ADR-070 при этом НЕ трогается — правится только громкость пустого входа.
# NOT-DELIVERED: check-test-subject-governs — тихий ноль
run_gate_if_declared "check-test-subject-governs" "1"

# check-content-actuality (ADR-076 Д5/Д7, DEV-118). Предмет — разрешимость ОБЪЯВЛЕННЫХ
# статьёй опор в `git ls-files`, не дата правки: соседний check-status-drift.py мерит дату и
# «Статус» (ADR-008), и ни один прибор дерева до этого не мерил соответствие статьи дереву.
#
# Ступень --fast, а не --full: замер спутника §6 — 0,14 с на всё дерево (396 файлов, три
# прогона 0.14/0.14/0.13), один `git ls-files` на прогон, не на файл. Соседний гейт того же
# класса (маркер в шапке файла по корпусу) уже стоит здесь же строкой выше.
#
# Код 1 объявлен МЯГКИМ вторым аргументом по тому же основанию, что у соседа, и оно названо
# в Д5 дословно: «сегодня без маркера весь корпус области — заявленная цена перехода, не
# авария»; корпус входит в норму волнами, и блокировать коммит по числу «неопределим»
# значило бы красить рабочую ветку чужой волной. Хард-блок — код 3 («устарел»): там суждения
# нет ни грамма, статья сама назвала путь опорой, и пути в дереве нет. Мягким он не
# объявлен и остаётся отказом.
#
# Дерево без своей истории git (плоская копия `git archive HEAD | tar -x`) гейт НЕ красит: он
# печатает объявленное молчание и возвращает 0 — та же форма и то же основание, что у
# delivery-composition выше (ADR-073 §3.1): источника разрешения (`git ls-files`) здесь нет
# вовсе, значит нет и предмета — «нечего проверять», не «не смог проверить» (ADR-007 Д1).
run_gate_if_declared "check-content-actuality" "1"

# check-prompt-layer-cyrillic (ADR-118 Д2, DEV-487). Предмет — кириллические строки пяти
# поверхностей промт-слоя (agents/, commands/, корневая пара, .claude/skills/, пара шаблонов)
# против классового реестра в самом приборе: дрейф (строка вне классов) — exit 1 жёстко,
# протухлость (класс/фрагмент без живого носителя) — warn, exit 0. Спека ADR-118 шаг check.sh
# не называет — ступень выбрана --fast: замер живого дерева < 0,2 с (чистый Python, stdlib),
# и дрейф языка — свойство КОММИТА, а не агрегат волны; ждать --full значило бы дать
# untranslated-строке дожить до закрытия волны, что спека запрещает дословно («SHALL NOT
# survive the wave untranslated or unclassed»).
#
# Предмет — этот же репозиторий: реестр классов держит держатели nauta (глоссарий, SA-031,
# шаблоны), у потребителя этих поверхностей нет вовсе — прибор печатает объявленное молчание
# («поверхностей промт-слоя в этом дереве нет») и выходит 0. Объявление невхождения §3.2
# ADR-085, метка — та же, что у check-onboarding-staleness ниже.
# NOT-DELIVERED: check-prompt-layer-cyrillic — предмет — репозиторий nauta
run_gate_if_declared "check-prompt-layer-cyrillic"

# check-subprocess-encoding (BA-118, NA-EPIC-150 срез 1, gitsd issue #1). Предмет — места
# вызова subprocess в текстовом режиме (`text=True`) без явного `encoding=` в scripts/ и
# hooks/ ЭТОГО дерева: без encoding= вывод ребёнка декодируется ANSI-страницей платформы
# (cp1251 на Windows), кириллический UTF-8 байт роняет reader-thread, stdout становится
# None — класс невидим на POSIX, поэтому запрет — гейт, не ревью. Гранулярность — место
# вызова (AST): многострочный вызов с encoding= на соседней строке и упоминание литерала
# в комментарии — не находки (FR-3); маркеры-подавители и реестры исключений находку не
# глушат, hooks/ под тем же правилом (FR-4). Находка — строка `file:line`; чистый прогон
# печатает именованный нулевой счётчик (норма спеки «reported count»).
# Ступень --fast — норма спеки AC-002c (перенос в --full-only — нарушение нормы); входит
# в окно collect ADR-123 седьмым хвостовым вызовом, батч держит пин стартов --fast == 3.
# Доставляется потребителю (класс A ADR-085 Д1: предмет — его же scripts/ и hooks/;
# «детектор обязан работать на потребительском дереве» — BA-118), объявления невхождения
# норма не допускает.
run_gate_if_declared "check-subprocess-encoding"

# check-network-roster (ADR-159 Д2, SA-162 §4.4, NA-EPIC-151 волна 1, DEV-560). Предмет —
# сетевой класс сьюты: каждый хит детекторов (исполняемые спавны uv/uvx/pip, инсталляции
# пакетов, живые fetch-вызовы, транзитные спавны scripts/check.sh) в tests/ и на верхнем
# уровне scripts/ разрешается строкой tests/_suite-network-roster.yaml или приложением
# beyond_suite; origin-конструкция команды прогона сьюты (`uv run … tests/`) без
# «UV_OFFLINE=1 » — именованный дефект нормы прогона (AC-001c); неразрешённый хит —
# именованная находка (AC-003b), молчаливое поглощение запрещено. Текстовый свип дёшев
# (чистый stdlib, один AST-проход по файлу) — ступень --fast, окно collect ADR-123
# (восьмой хвостовой вызов, конверт py-batch starts 1 и пин стартов не двигает). Семантика
# отсутствующего ростера — именованный skip (ADR-007 Д1: «нечего проверять» ≠ «не смог»):
# деревья-потребители и пробные раскладки qa197/qa198 реестра не несут, их --fast остаётся
# зелёным с INFO-строкой (at-design BA-119, «Допущения верхних ролей» №2). Ростер живёт
# только в репозитории nauta — у потребителя предмета нет.
# NOT-DELIVERED: check-network-roster — предмет — репозиторий nauta
run_gate_if_declared "check-network-roster"

# --- ADR-123 Д1/Д2 (NA-EPIC-72) — батч хвостовых py-гейтов и его flush -------------------
# Вызов сразу за последним из хвостовых (spec §2, якорь ADR-123-spec: check.sh:2000 на дате
# решения; состав хвостовых — семь с BA-118, см. check-subprocess-encoding выше). Конверт `step py-batch starts 1 wall_ms <Σ>` и погейтные строки журнала пишет
# сам драйвер; вердикты по каждому собранному гейту печатает bash ниже — по паре (имя, rc)
# из машинных строк драйвера и мягкому списку ДАННОГО вызова, литералы равны литералам
# run_check (дрейф-замок). Машинные строки BATCH_RSLT в stdout прогона не попадают:
# они читаются из захваченного вывода драйвера, человек видит только ▶/вывод/вердикт.
run_py_batch
FAST_PY_BATCH=0
if [[ "$PY_BATCH_RC" -ne 0 ]]; then
  name="py-batch"
  echo "  ✗ $name FAILED" >&2
  failed=1
fi
if [[ -n "$PY_BATCH" ]]; then
  while IFS= read -r _batch_pair; do
    [[ -n "$_batch_pair" ]] || continue
    name="${_batch_pair%%:*}"
    soft="${_batch_pair#*:}"
    if [[ "$soft" == "$_batch_pair" ]]; then
      soft=""
    fi
    rc="$(printf '%s\n' "$BATCH_DRIVER_OUT" | awk -v n="$name" '$1 == "BATCH_RSLT" && $2 == n { print $3 }')"
    case "$rc" in
      ""|*[!0-9]*) rc=250 ;;
    esac
    if [[ "$rc" -eq 0 ]]; then
      echo "  ✓ $name"
    elif [[ -n "$soft" && " $soft " == *" $rc "* ]]; then
      echo "  ⚠ $name — код $rc объявлен мягким для этого вызова (расхождение класса soft,"
      echo "    ADR-007 Д1): проверка ВЫПОЛНЕНА, её исход не блокирует коммит."
    else
      echo "  ✗ $name FAILED" >&2
      failed=1
    fi
  done <<< "$PY_BATCH"
fi


if [[ "$MODE" == "--full" ]]; then
  # check-backlog-closure (ADR-012 Д4, Ruling D задачи 8/S7-DEV-003): гейт живёт в --full,
  # не --fast — Д4 буквально: между тем, как тест Dev'а позеленел, и тем, как PM перенёс
  # пункт в «Won't», проходят коммиты; в --fast гейт бил бы по каждому из них, то есть по
  # нормальному ходу TDD внутри эпика, а не по расхождению между эпиками. Заработал только
  # после починки разбора заголовков бэклога (### и ####, scripts/check-backlog-closure.py,
  # эта же задача) — на реальном дереве даёт `OK: 0 нарушений`, не молчал раньше по причине
  # отсутствия вызова, а падал бы `ERROR: не найдены секции` до фикса.
  # Объявление невхождения §3.2 ADR-085 (Д3). Стоит в НУЛЕВОЙ колонке намеренно: форма
  # объявления машиночитаема и якорена на начало строки — отступ блока `--full` сделал бы
  # запись невидимой и для сторожа roster-declaration, и для текста [INFO].
  # Основание — замер: путь бэклога нашит константой `scripts/check-backlog-closure.py:63`
  # с ИМЕНЕМ АРТЕФАКТА nauta (2026-07-24-template-improvements-backlog.md), и на дереве
  # потребителя гейт даёт rc=1 на файле, которого у того быть не может. Параметризация пути
  # этой волной НЕ поручена (Д3): «что считать бэклогом у потребителя» — вопрос BA.
# NOT-DELIVERED: check-backlog-closure — нашитая константа
  run_gate_if_declared "check-backlog-closure"

  # check-onboarding-staleness (ADR-083 Д4, спутник §4.2/§1.4; DEV-133 по находке ревью
  # DEV-132 — «сторож без вызывающего»: `grep -rn check-onboarding-staleness --include=*.sh
  # --include=*.py .` за пределами tests/ и своего же файла давал пусто до этой правки).
  # Живёт в --full, не --fast, по тому же основанию, что check-backlog-closure выше: предмет —
  # версия ПЛАГИНА (`.claude-plugin/plugin.json`) против онбординг-текста README.md/docs/**,
  # а не отдельный коммит — между правкой текста и бампом version в норме проходят коммиты
  # эпика, и --fast бил бы по каждому из них.
  #
  # Вызывается БЕЗ аргументов (`run_gate_if_declared`, ADR-037-spec §3) — гейт получил
  # умолчание `--root` от `__file__` этой же правкой, иначе первый же прогон падал бы на
  # разборе argparse (`--root` был `required=True`).
  #
  # Предмет — этот же репозиторий (README.md и корневые гайды getting-started/upgrading —
  # поставка с акта О3 NA-EPIC-83), не поставка потребителю: `bin/deliver.sh` эту
  # позицию НЕ доставляет (PAYLOAD_FILES её не несёт), онбординг-текст потребителя — не
  # nauta'шный README. Дерево-потребитель получит объявленное молчание (INFO-NOT-DELIVERED,
  # ADR-037 §3) и exit-код не изменится.
  # Объявление невхождения §3.2 ADR-085. Решение принято раньше (ADR-083) и было записано
  # прозой абзацем выше — читателя-прибора у той записи не было ни одного, поэтому ишью #14
  # назвало семь имён из восьми: восьмое просто не прозвучало у потребителя.
# NOT-DELIVERED: check-onboarding-staleness — предмет — репозиторий nauta
  run_gate_if_declared "check-onboarding-staleness"

  # check-hook-declaration-projection (ADR-133 З-2, DEV-519) — режим ростера прибора-
  # проекции объявления хуков: каждая копия объявления (hooks*.json, кроме манифеста) в
  # коммитируемом множестве дерева сверяется с секцией hooks манифеста; расхождение —
  # поимённый отказ ДО установки (норма спеки harness-neutral-core «Объявление хуков имеет
  # единственный носитель»); копий нет — «единственный носитель манифест». Позиция стоит
  # здесь, в --full, а не в --fast: состав --fast заморожен ADR-123-spec (15 ступеней, замок
  # QA-118), а предмет ступени — состояние дерева поставки целиком, не отдельный коммит —
  # то же основание, что у соседей ниже. Точка ГЕНЕРАЦИИ копии для моста — ритуал релиза
  # (bin/release-delivery.sh, at-design qa-144 граница 4: «точку его вызова выбирает акт
  # Dev»); этот вызов — зовущий прибора в контуре разработки (ADR-101 Д3) и сверка копий,
  # появившихся в дереве вне прибора.
  #
  # Предмет — этот же репозиторий (манифест .claude-plugin/plugin.json): bin/deliver.sh
  # позицию не доставляет (PAYLOAD_FILES её не несёт), у потребителя своего манифеста
  # плагина nauta нет. Дерево-потребитель получит объявленное молчание (INFO-NOT-DELIVERED,
  # ADR-037 §3), exit-код не изменится. Объявление невхождения §3.2 ADR-085, нулевая
  # колонка — по тому же основанию, что у check-backlog-closure и check-onboarding-staleness
  # выше: форма машиночитаема и якорена на начало строки, отступ блока --full сделал бы
  # запись невидимой обоим её читателям.
# NOT-DELIVERED: check-hook-declaration-projection — предмет — репозиторий nauta
  run_gate_if_declared "check-hook-declaration-projection"

  # check-spec-language (ADR-136 Д5, DEV-526) — классы исключений А–Ж правила языка спек:
  # кириллическая строка АНГЛИЙСКОЙ спеки (доля ≤ 5 % пофайловым вызовом вердиктора доли)
  # вне реестра классов — дрейф, exit 1 жёстко; класс без живых фрагментов — протухлость,
  # warn при exit 0. Scope-фильтр пофайловый (спека spec-authoring-language, требование
  # «The Cyrillic share is decided per file by one instrument»: батч — не замер), русские
  # спеки старого корпуса прибор не разбирает — проспективная сила правила ADR-136 Д1
  # механична до решения Д6. Спека ADR-136 шаг check.sh не называет — ступень выбрана
  # --full, не --fast: состав --fast заморожен ADR-123-spec (замок QA-118), а предмет
  # ступени — состояние КОРПУСА спек целиком (45 пофайловых замеров доли ≈ 2,5 с), не
  # отдельный коммит, — то же основание, что у соседей ниже. Дрейф блокирующе, а не мягко:
  # классы механические (ARGUMENT ADR-118 §3), коридор 41–68 % — про NLP-детекторы.
  #
  # Предмет — этот же репозиторий (реестр держит держатели nauta: глоссарий, .doc-root.yaml,
  # спеки role-prompt-contracts и spec-authoring-language); у потребителя openspec/specs нет —
  # прибор печатает объявленное молчание («спек openspec/specs/ в этом дереве нет») и выходит
  # 0. bin/deliver.sh позицию не доставляет (PAYLOAD_FILES её не несёт). Объявление
  # невхождения §3.2 ADR-085, нулевая колонка — по тому же основанию, что у трёх соседей
  # выше: форма машиночитаема и якорена на начало строки.
# NOT-DELIVERED: check-spec-language — предмет — репозиторий nauta
  run_gate_if_declared "check-spec-language"

  # check-ratchet (ADR-106 Д6/Д7, спутник §3/§4) — храповик ВОЛНЫ: ряд «волна → величина», чей
  # порог есть ПРОШЛОЕ измерение ряда, а не рукописная константа. Живёт в --full, не в --fast,
  # по тому же основанию, что три соседа выше: предмет — агрегат ДЕРЕВА на закрытии волны, а не
  # отдельный коммит; в --fast он бил бы по каждому шагу TDD внутри волны.
  #
  # Второй аргумент — перечень МЯГКИХ кодов, и он ровно один: `3` (нарушение ряда). Дословное
  # основание — ADR-102 Д2: «мягким на вызове объявляется ТОЛЬКО 3 — превышение есть измерение,
  # а не провал прогона». Коды 1 (НЕ СМОГ ПРОВЕРИТЬ) и 2 (конфигурация) жёстки здесь и на втором
  # зовущем. У ВТОРОГО зовущего — предусловия `close_route` в commands/pm.md — мягких кодов нет
  # вовсе: там ухудшение уже необратимо, и момент истины принадлежит ему (ADR-106 Д6, AC-010).
  #
  # Объявления невхождения `# NOT-DELIVERED:` здесь НЕТ намеренно, и это проверяемое решение,
  # а не пропуск: позиция доставляется (ADR-106 Д7 — три условия ADR-085 Д1 проверены по
  # отдельности, констант nauta в приборе нет, набор метрик читается из носителя). Появление
  # имени в ростере без записи в `PAYLOAD_FILES` ловит сторож roster-declaration выше.
  run_gate_if_declared "check-ratchet" "3"

  # check-verdict-signatures (ADR-139 Д4, спутник SA-146 §3, DEV-538) — прибор дрейфа
  # подписи вердикта: биды-гейты (оба носителя ADR-052 Д1, закрытые включительно) с
  # `verdict=approve` и пином `approved` — пересчёт sha256 запиненных путей. STALE/
  # MISSING/MALFORMED — exit 1 (мягких кодов нет: stale — дефект, не измерение), LEGACY-
  # строка «байты не утверждались» — exit 0 (Д6), bd недоступен — объявленное молчание,
  # сломанный запрос — exit 1. Живёт в --full, не в --fast, по тем же основаниям, что
  # соседи выше: состав --fast заморожен ADR-123-spec (замок QA-118), а предмет ступени —
  # СТОР ЦЕЛИКОМ (все гейты всех эпиков), не отдельный коммит; в --fast он бил бы по
  # каждому шагу TDD внутри волны.
  #
  # Предмет — стор контура исполнения nauta, которого у потребителя нет; дерево-потребитель
  # получит объявленное молчание (ADR-037 §3). Объявление невхождения §3.2 ADR-085 в
  # нулевой колонке, метка — дословно из перечня замка QA-083 («предмет — репозиторий nauta»,
  # как у check-warden-callers и check-suite-cost-pin ниже: иллюстративная метка спутника
  # SA-146 §3 «предмет — стор контура исполнения nauta» вне дословного перечня — замер
  # DEV-538), форма якорена на начало строки: отступ блока --full сделал бы запись
  # невидимой обоим её читателям.
# NOT-DELIVERED: check-verdict-signatures — предмет — репозиторий nauta
  run_gate_if_declared "check-verdict-signatures"


  # check-based-on-freshness (ADR-140 Д5, спутник SA-147 §3/§4, DEV-539) — прибор дрейфа
  # привязок based_on: реестр openspec/specs/based-on-bindings.yaml (запись keyed by путь
  # производного артефакта, полные sha256 источников, потолка нет) против ТЕКУЩИХ байт
  # источников; перечисление охвата v1 — декларации **Capability:** документов docs/,
  # тот же домен, что C15/C16. STALE/MISSING/UNPINNED/UNDECLARED/ORPHAN/MALFORMED —
  # exit 1 (мягких кодов нет: просроченная связь — дефект, не измерение), OK — exit 0,
  # реестра нет — ERROR exit 1 (ADR-007 Д1); LEGACY-класса нет — посев базы (режим --seed
  # прибора, акт вступления этой волны) делает «до нормы» и «мимо нормы» различимыми
  # записью, baseline re-pin (R1-4). bd не вызывается; отдельного состояния просроченности
  # нет — вердикт выводится каждым прогоном (R2-3), дерево прибор не пишет.
  #
  # Позиция: --full, НЕ --fast — состав --fast заморожен (ADR-123-spec, замок QA-118),
  # а предмет ступени — корпус привязок ЦЕЛИКОМ (все пары всех спек), не отдельный коммит;
  # в --fast он бил бы по каждому шагу TDD внутри волны. Стоит СРАЗУ за
  # check-verdict-signatures (замок QA-152 ac2a) — соседняя ступень того же класса
  # «байтовые идентичности против дерева».
  #
  # Предмет — репозиторий nauta: реестр и пары C15 этого дерева; дерево-потребитель
  # получит объявленное молчание (ADR-037 §3). Объявление невхождения §3.2 ADR-085
  # в нулевой колонке, метка — дословно из перечня замка QA-083, форма якорена на начало
  # строки: отступ блока --full сделал бы запись невидимой обоим её читателям.
# NOT-DELIVERED: check-based-on-freshness — предмет — репозиторий nauta
  run_gate_if_declared "check-based-on-freshness"

  # measure-specs-strict (NA-EPIC-141 qa186, бусина kui5) — advisory-счётчик strict-проходов
  # корпуса спек: сколько каталогов openspec/specs/* проходят `openspec validate --specs
  # --strict`. Ряд `specs-strict-pass` в .nauta-ratchet.yaml рождён СЛЕДЯЩИМ, без потолка:
  # решение владельца — strict НЕ становится обязательным гейтом. Блокирующее сравнение
  # строки ряда делает ступень check-ratchet (мягкий код 3, существующая механика P2/P3);
  # сам прибор всегда rc 0 — исходы TOTAL/SKIP/NOT-MEASURED, каждый назван словами
  # (УТР-образец BA-116: advisory-отчёт не фьюз). Пин версии CLI читается у ЕДИНСТВЕННОГО
  # носителя scripts/spec-validate.sh (ADR-149 Д2), второй литерал пина не заводится.
  #
  # Позиция в ростере: блок стоит ПОСЛЕ check-verdict-signatures и check-based-on-freshness,
  # НЕ сразу за check-ratchet: смежность check-ratchet ↔ check-verdict-signatures зафиксирована
  # замком QA-151 ac3c (ADR-139 Д4), а check-verdict-signatures ↔ check-based-on-freshness —
  # замком QA-152 ac2a (ADR-140 Д5); advisory-прибор места у храповика не требует — его
  # блокирует только сравнение строки ряда у читателя (перестановка NA-EPIC-141, 2026-11-14;
  # прежнее место — сразу за check-ratchet, провенанс акта qa186).
  #
  # Позиция: --full, НЕ --fast — состав --fast заморожен (ADR-123-spec, замок QA-118), а
  # предмет ступени — состояние КОРПУСА спек целиком, не отдельный коммит; в --fast он бил бы
  # по каждому шагу TDD внутри волны.
  #
  # NOT-DELIVERED ниже — классификация доставки акта qa186: манифесты (PAYLOAD_FILES) акт не
  # трогает, классификацию объявляет координатор; без объявления сторож roster-declaration
  # был бы красным на имя без поставки (ишью #14).
# NOT-DELIVERED: measure-specs-strict — предмет не доставляется
  run_gate_if_declared "measure-specs-strict"

  # text-clarity-check (NA-EPIC-141, qa188; capability text-clarity-ratchet; вердикт gate-ba
  # approve с условиями, BA-116) — прибор понятности текстов по двум объявленным
  # поверхностям, сплит по ПУТИ: docs/**/*.md — UTR-норма (вендор erwinete/asd-ste100-ru,
  # режим strict), openspec/specs/**/spec.md — ASD-STE100 (вендор danyuchn/asd-ste100-skill).
  # Отчёт ADVISORY (требование 2 спеки): exit 0 при любом числе находок; exit 2 —
  # использование/IO/кросс-применение рулсета вне своей поверхности (AC-001a). Блокирует
  # только сравнение строк храповика (.nauta-ratchet.yaml: utr-docs-hard-findings,
  # ste-specs-hard-findings; check-ratchet.py, код 3) — новых блокирующих гейтов прибор не
  # вводит. Вендорные копии — пинованные (provenance в шапке), stdlib-only, без сети, без
  # автообновления; запуск python3 -I.
  # Позиция: --full, НЕ --fast — состав --fast заморожен ADR-123-spec (замок QA-118), а
  # предмет ступени — состояние КОРПУСОВ целиком (959 md + 60 spec.md, замер прибора на
  # живом дереве qa188 ~7 с суммарно), не отдельный коммит; то же основание, что у соседей
  # выше.
  # Предмет — этот же репозиторий (корпуса docs/ и openspec/specs этого дерева); дерево-
  # потребитель получит объявленное молчание (INFO-NOT-DELIVERED, ADR-037 §3), exit-код
  # не изменится. PAYLOAD-классификацию объявляет координатор (прибор разработки, ожидание —
  # NOT-DELIVERED). Объявление невхождения §3.2 ADR-085 в нулевой колонке, метка дословно
  # из перечня замка QA-083, форма якорена на начало строки.
# NOT-DELIVERED: text-clarity-check — предмет — репозиторий nauta
  run_gate_if_declared "text-clarity-check"
  # check-stall (NA-EPIC-110 В2, BA-113, capability route-stall-watcher; донор aida
  # check stall @5e89617, RES-100 §B) — сторож немых рабочих стадий маршрута: эпики на
  # стадиях test-design..acceptance, чей новейший state-change старше окна
  # .nauta-gates.yaml::stallWatch.windowDays. ADVISORY-ступень --full (без --strict в
  # ростере): стопор чужого эпика не блокирует выпуск чужого релижа — будильник, не гейт;
  # координатор зовёт с --strict в ритуале волны. Живёт в --full по тем же основаниям, что
  # соседи выше: предмет — СТОР ЦЕЛИКОМ, состав --fast заморожен ADR-123-spec (QA-118).
  # У потребителя стора нет: объявленное молчание прибора + NOT-DELIVERED ниже.
# NOT-DELIVERED: check-stall — предмет — репозиторий nauta
  run_gate_if_declared "check-stall"

  # id-check (ADR-038 Д3/Д8, ADR-038-spec §4.3/§5; решение владельца Р22, roadmap 2026-08-18)
  # — коллизии, невозврат отменённого номера, расхождение реестра .nauta-ids.yaml с корпусом.
  # Живёт в --full, не в --fast, по тексту Р22 дословно: профиль назван решением. Обоснование
  # то же, что у check-backlog-closure выше, — гейт судит СОСТОЯНИЕ КОРПУСА целиком (полный
  # обход дерева), а не отдельный коммит; в --fast (вход .githooks/pre-commit) он бил бы по
  # каждому шагу TDD внутри эпика.
  #
  # ЦЕНА ПОДКЛЮЧЕНИЯ, записанная здесь, а не только в roadmap, — чтобы следующий читатель не
  # принял её за недосмотр и не «починил»: область поиска ступени 3 («определение вне всех
  # объявленных home», scripts/id-check.sh) сознательно СУЖЕНА до формы `filename-prefix` и
  # дополнительно исключает companion-файлы `-spec.md` (санкционированный прецедент ADR-013
  # Д2 — companion законно несёт номер решения). То есть гейт видит меньше, чем мог бы. Без
  # сужения однобуквенный префикс `Д` пространства decision-clause матчит обычную русскую
  # прозу («Дата», «Две», «Держать») — замер на живом дереве DEV-010: ~90 ложных ERROR, из них
  # ~29 на companion-файлах docs/30-architecture/. Расширение области до честного маркера
  # определения — ОТДЕЛЬНАЯ задача (требует более строгого матчера и покрывающего теста), а не
  # условие включения этого вызова.
  #
  # `next-id.sh` в этом перечне не появляется НИКОГДА (Д5 ADR-040, подтверждено Р22):
  # аллокатор мутирует реестр, раннер обязан оставаться читателем.
  run_gate_sh_if_declared "id-check"

  # check-warden-callers (ADR-101 Д3, спутник §1.5/§4) — у каждого `scripts/check-*` есть
  # зовущий вне `tests/`, а отсутствие зовущего объявлено записью, не молчанием. Живёт в
  # --full, не в --fast, по тому же основанию, что три соседа выше: предмет — СОСТОЯНИЕ
  # ДЕРЕВА целиком (перечень всех сторожей против шести носителей вызова), а не отдельный
  # коммит; красный на рубеже слияния, а не на каждом шаге TDD.
  #
  # Почему гейт не на буквальном grep, и почему это не украшение: `check.sh` зовёт сторожей
  # ОБЪЯВЛЕННЫМ ИМЕНЕМ РОСТЕРА, а не путём (`grep -c -F scripts/check-onboarding-staleness.py`
  # по этому файлу даёт 0 при живом вызове строкой 1598). Прибор на буквальном пути назвал бы
  # без зовущего пять файлов из двенадцати — замер §1.5. Разрешение имени в
  # `scripts/<имя>.py|.sh` живёт в самом гейте (`_roster_callers`).
  #
  # Предмет — этот же репозиторий: перечень носителей вызова (`bin/deliver.sh`,
  # `bin/release-delivery.sh`, `agents/*.md`, `commands/*.md`, ростер этого файла) — контур
  # разработки nauta, а не дерево потребителя; у потребителя своя раскладка вызовов и свой
  # состав сторожей. Дерево-потребитель получит объявленное молчание (INFO-NOT-DELIVERED,
  # ADR-037 §3), exit-код не изменится.
  # Объявление невхождения §3.2 ADR-085, нулевая колонка — по тому же основанию, что у
  # check-backlog-closure и check-onboarding-staleness выше: форма машиночитаема и якорена на
  # начало строки, отступ блока --full сделал бы запись невидимой обоим её читателям.
# NOT-DELIVERED: check-warden-callers — предмет — репозиторий nauta
  run_gate_if_declared "check-warden-callers"

  # check-materialization (RES-085 §К2, at-design qa-142, DEV-515) — инварианты
  # материализации поставки: непустой description у каждого поставляемого SKILL.md
  # (платформа скилл без него дропает молча), компилируемость hooks/*.py и
  # .githooks/*.py («битый хук молча не срабатывает, а не падает»), парсящесть
  # JSON-манифестов, отсутствие мёртвого груза — скилла, на который не ссылается ни
  # один текст полосы. Живёт в --full, не в --fast: состав --fast заморожен
  # ADR-123-spec (15 ступеней, замок QA-118), а предмет ступени — состояние поставки
  # ДЕРЕВА целиком (GO-1 плана волны NA-EPIC-85: живое дерево накрывается той же
  # ступенью, что и фиксстуры замков test_qa142), красный на рубеже слияния, не на
  # каждом шаге TDD. Класс «вызываемый скрипт в дереве» НЕ дублируется — он заперт
  # payload-callers (ADR-111).
  #
  # Предмет — этот же репозиторий: замки прибора зовут его с ЯВНЫМ корнем дерева
  # (tmp_path-фикстуры, дом DEV-065); без аргумента прибор материализует дерево, в
  # котором лежит сам. Дерево-потребитель получит объявленное молчание
  # (INFO-NOT-DELIVERED, ADR-037 §3), exit-код не изменится. Объявление невхождения
  # §3.2 ADR-085, нулевая колонка — по тому же основанию, что у check-warden-callers
  # выше: форма машиночитаема и якорена на начало строки, отступ блока --full сделал
  # бы запись невидимой обоим её читателям.
# NOT-DELIVERED: check-materialization — предмет — репозиторий nauta
  run_gate_if_declared "check-materialization"

  # check-suite-cost-pin (ADR-104 Д3, спутник §5/§7) — число сьюты в абзаце «Test run»
  # AGENTS.md проверяется двумя предикатами РАЗНЫХ субъектов против коммита, который оно
  # называет: правдивость записи в её собственной точке (материализация названного коммита
  # `git archive`, не `git worktree add` — ADR-081 Д3) и её актуальность (свежий сбор рабочего
  # дерева). Живёт в --full, не в --fast, по тому же основанию, что соседи выше: предмет —
  # СОСТОЯНИЕ ДЕРЕВА относительно постоянного документа, а не отдельный шаг TDD.
  #
  # Ни один код не мягкий, КРОМЕ объявленного здесь (ADR-117 Д3, issue #34): код 4 — ТОЛЬКО
  # дрейф свежести (запись честна на названном коммите, HEAD ушёл) — мягкий, вторым
  # аргументом вызова, по прецеденту ADR-072 Д4 у check-ratchet. Ложь о названном коммите
  # (1) и «не смог воспроизвести» (3) красят обязательную ступень своими текстами (ADR-007
  # Д1); оба предиката разошлись — жёсткий старше (код 1).
  #
  # Предмет — этот же репозиторий: проверяемый документ — `AGENTS.md` дерева разработки nauta,
  # а не онбординг-текст потребителя; у потребителя своя копия и свой состав чисел. Дерево-
  # потребитель получит объявленное молчание (INFO-NOT-DELIVERED, ADR-037 §3), exit-код не
  # изменится. Объявление невхождения §3.2 ADR-085, нулевая колонка — по тому же основанию,
  # что у check-warden-callers и check-onboarding-staleness выше: форма машиночитаема и
  # якорена на начало строки, отступ блока --full сделал бы запись невидимой обоим её
  # читателям.
# NOT-DELIVERED: check-suite-cost-pin — предмет — репозиторий nauta
  run_gate_if_declared "check-suite-cost-pin" "4"

  # check-tier2-profile-pin (ADR-146 Д2/Д3, SA-152 §4) — структурная секция пина профиля
  # цены яруса 2 (tests/_wave-gate-profile-pin.yaml: размер ростера + счёт МЕСТ вызовов
  # check.sh/материализаций) проверяется против коммита, который она называет, формой
  # соседа слева: ложь на названном — жёсткий rc 1 с ОБОИМИ числами, дрейф HEAD при
  # честном названном — мягкий rc 4 (вторым аргументом, ADR-117 Д3), «не смог» — rc 3,
  # «нечего проверять» вне своего репозитория — [INFO] rc 0. Пересчёт — статический
  # AST-разбор файлов членов (`uv run scripts/tier2-profile.py --recount`), ярус он НЕ
  # исполняет: measured-числа перевыводит только инструментированный ярус-2 прогон
  # каденции волнового гейта — НИКОГДА «на каждый --full» (13 минут, напряжение BA-109
  # №2). Живёт в --full, не в --fast: предмет — состояние ДЕРЕВА относительно носителя
  # пина, а не отдельный шаг TDD.
  #
  # Предмет — этот же репозиторий: носитель пина — tests/_ дерева-ИСТОЧНИКА, у
  # потребителя своего пина нет; объявление невхождения §3.2 ADR-085 — метка из
  # дословного перечня Д6 ADR-085.
# NOT-DELIVERED: check-tier2-profile-pin — предмет — репозиторий nauta
  run_gate_if_declared "check-tier2-profile-pin" "4"

  # measure-session-cost (ADR-102 Д1/Д2, спутник §3/§5/§10) — прибор цены сессии и вердикт по
  # ключу `sessionCostBudget` (.nauta-gates.yaml). Живёт в --full, не в --fast, по тому же
  # основанию, что четыре соседа выше, и это основание записано решением дословно: предмет
  # ступени — состояние ЦЕЛОЙ СЕССИИ (все её акторы, весь её транскрипт), а не отдельный
  # коммит; в --fast (вход .githooks/pre-commit) она била бы по каждому шагу нормального хода
  # TDD величиной, которая внутри шага не меняется.
  #
  # Три исхода ступени, и каждый объявлен, а не выведен: транскрипта нет (в CI каталога
  # ~/.claude/projects/ не существует вовсе) — строка `NOT-MEASURED:` и мягкий код 3
  # (п.11 ADR-121: неизмеренное останавливает бюджетную проверку, а не проходит за успех;
  # прежде был exit 0 — форма снята QA-116 T2b), штатное состояние прогона, не поломка
  # окружения (ADR-007 Д1); ключа нет (дерево-потомок) — тихий
  # проход отчётом-измерением (ADR-031 Д3); размерность превышена — красный с четвёркой
  # «имя / измеренное / порог / база». Прибор доставляется (PAYLOAD_FILES, bin/deliver.sh),
  # ключ — нет: числа базы принадлежат ЭТОМУ дереву, и доставленные чужие пороги были бы
  # вердиктом о чужой сессии.
  #
  # Мягким объявлен РОВНО код 3 — «измерил, размерность превышена» (ADR-102, §13.2 спутника),
  # а с п.11 ADR-121 — также НЕИЗМЕРЕННОЕ (NOT-MEASURED: транскрипта нет либо единицы счёта
  # нет ни в одной записи), и с В1 ADR-122 (D1) — исходы ветки «сессия не названа»: носитель
  # платформы ведения волн опознан → ИЗМЕРЕННЫЙ отчёт по его правилу счёта (0 либо 3 —
  # по бюджету, refusal-ветки больше нет); носителя нет либо он не разобран → NOT-MEASURED
  # rc 3 с именем неуспевшего шага. Мягкость живёт ЗДЕСЬ, на вызове, а не внутри прибора:
  # прибор несёт честный код, ростер решает, блокирует ли этот исход. Коды 1 («не смог»:
  # конфигурация неполна, профили правил разошлись) и 2 (использование) остаются ЖЁСТКИМИ —
  # иначе мягкость заглушила бы сторожа собственного ключа; «сессия не названа» выведена
  # из кода 1 решением D1 ADR-122, а не смягчена глобально. Основание мягкости: сессия,
  # которую ступень мерит сегодня, бо́льшую часть жизни прожила БЕЗ механизмов, чью цену
  # показывает, — это смесь «до» и «после», а §7 уже сказал словами «недостижимый порог
  # есть находка приёмки, а не провал». Ужесточение однотокенное и видимое: снять "3"
  # со строки ниже. Условие названо решением — первая сессия, прожившая стадию целиком
  # под механизмами, и перевывод базы по Д2.
  run_gate_if_declared "measure-session-cost" "3"

  # check-status-drift (ADR-105 Д1, спутник §1/§4/§7; DEV-458) — прибор существовал в дереве
  # (`scripts/check-status-drift.py`) и до этой правки не звучал НИОТКУДА: `git grep -n
  # "status-drift" -- scripts/check.sh` давал три вхождения, все — комментарии (строки 1538,
  # 1726-1727 до правки). Это первая исполняемая строка его вызова. Живёт в --full, не в
  # --fast, по тому же основанию, что соседи выше: предмет размерности 4 — состояние ВСЕЙ
  # истории коммитов `release(...)` против даты создания ADR-файла, а не отдельный коммит.
  #
  # Размерность 4 безусловна (не opt-in) — четыре ADR этого репозитория были выпущены
  # потребителю, стоя в `Статус: Review` (098/099/100/102, план 1.0.0 §П10), и признак
  # «дата последнего коммита» этого не поймал бы: ADR-102 датирован 2026-09-10, выпущен
  # 2026-09-11, свежим — 14-дневный `--stale-days` его бы не тронул.
  #
  # Второго аргумента НЕТ — код 3 не объявлен мягким: находка «ADR уже выпущен релизом и
  # сегодня не Approved» блокирующая по построению (ADR-105 Д1), а не «неполнота охвата»,
  # как у соседей с мягким кодом выше. Размерности A/B/S1-S3 прибора (advisory-дрейф,
  # читаемость, контур Д) этой правкой не тронуты — экзит-контракт 0/1/2 тот же.
  #
  # `scripts/check-status-drift.py` доставляется PAYLOAD_FILES (`bin/deliver.sh`) — запись
  # NOT-DELIVERED здесь не заводится: позиция ЕСТЬ у потребителя, и объявление невхождения
  # рядом с вызовом доставляемой позиции читалось бы roster-declaration-сторожем (строка
  # ~1456) как противоречие «доставляется и объявлено недоставляемым одновременно» и красило
  # бы прогон само по себе.
  run_gate_if_declared "check-status-drift"

  # wave-brief (ADR-108 Д6/Д7, спутник §4/§7; DEV-461) — сторож непокрытых упоминаний: блок
  # источника, называющий метку волны и НЕ объявивший принадлежности, выпадает из выдержки
  # молча. Прибор зовётся БЕЗ аргументов (ADR-037-spec §3) и в этой форме собирает не
  # выдержку, а только перечень кандидатов по всем меткам сразу. Второго читателя формата
  # плана не заводится (ADR-108 Д1): сторож живёт в том же приборе, режимом.
  #
  # Мягким объявлен РОВНО код 3 — «ИЗМЕРИЛ непокрытые» (четвёрка ADR-102 Д2), и мягкость
  # живёт ЗДЕСЬ, на вызове, а не внутри прибора: прибор несёт честный код, ростер решает,
  # блокирует ли исход. Основание мягкости названо числом: разметка источника — работа его
  # автора, а не Dev (§13 спутника), и на неразмеченном источнике перечень непуст по
  # построению (замер DEV-461: непусты все семь меток). Коды 1 («источник не прочитан») и 2
  # (использование) остаются ЖЁСТКИМИ — иначе мягкость заглушила бы сторожа собственного
  # входа. Ужесточение однотокенное и видимое: снять "3" со строки ниже; условие названо —
  # источник размечен целиком, и перечень кандидатов пуст.
  #
  # Предмет — план выпуска 1.0.0 ЭТОГО репозитория: у потребителя его нет, а `DEFAULT_PLAN`
  # прибора есть литеральный путь дерева-источника. Дерево-потребитель получит объявленное
  # молчание (INFO-NOT-DELIVERED, ADR-037 §3), exit-код не изменится.
# NOT-DELIVERED: wave-brief — предмет — репозиторий nauta
  run_gate_if_declared "wave-brief" "3"

  # check-content-classification (Ruling C задачи 8/S7-DEV-003, ADR-033 Д2) — вызов НЕ
  # восстанавливается, это не забытый файл. Гейт требует `.publishignore`; модель «рабочая
  # ветка + производная публикуемая», для которой он писался, в nauta не существует (ADR-033
  # Д2) — семантика гейта у потомка инвертирована: он красил бы КАЖДЫЙ файл docs/ как
  # неклассифицированный (живой прогон архивной копии — отчёт задачи 7). Предмета здесь нет
  # по принятому решению — громким этот вызов не делается, он просто отсутствует.

  # check-breaking-change-section (Ruling E задачи 8/S7-DEV-003, ADR-021 Д2/Д4) — гейт-
  # СКРИПТ из check.sh не вызывается: требует обязательный позиционный `<range>`, несовместимый
  # с run_gate_if_declared (зовёт без аргументов). Второе основание невызова (отсутствующий
  # `.publishignore`) снято ADR-071 Д1 (Р6): область теперь читается ключом `breakingChangeScope.
  # exclude` в `.nauta-gates.yaml` с умолчанием в коде — входа, который мог бы отсутствовать,
  # больше нет. Неприменимость документируется здесь, а не молчит — сам гейт остаётся
  # advisory-инструментом для `ba-agent.md --mode=acceptance` (диапазон эпика передаётся
  # вручную). Его bash-СЬЮТ (регрессия на синтетике) при этом зарегистрирован ниже — ADR-017
  # требует регистрацию раннера отдельно от применимости самого гейта.

  # Ruling F (задача 8/S7-DEV-003): список сьютов приведён к тому, что реально есть в
  # дереве («объявлено — значит обязано существовать», ADR-007 Д1 распространяется и на
  # self-test harness). Из 18 архивных имён остаются три — N1 (задача 7) перенёс их py/sh-
  # предметы в scripts/, задача 8 регистрирует третье (test-check-breaking-change-section
  # ранее нигде не упоминался, ADR-017). Остальные 15 удалены по ДВУМ разным причинам —
  # полная разбивка построчно в task-8-report.md, здесь — категории:
  #   (a) предмета здесь нет по принятому решению, не «не успели перенести»: test-publish-
  #       public, test-examples-sync, test-repo-zone-map (публикация/витрина examples/,
  #       ADR-033 Д2 убрал модель «рабочая ветка + производная публикуемая»); test-template
  #       (смоук rename/idempotency локальной directory-копии шаблона — ADR-009-plugin-
  #       centralization-migration-spec.md Д7 п.3: «становится бессмысленным... удалять, не
  #       переписывать», как только источник стал удалённой git-ссылкой); test-check-
  #       content-classification (Ruling C выше); test-central-plugin-checkout (ADR-009-spec
  #       п.5 — «новая тестовая поверхность БЕЗ АНАЛОГА», проверяет consumer-сторону
  #       установки nauta как ЧУЖОГО плагина; внутри самого nauta второй стороны, которую
  #       можно поставить потребителем, нет).
  #   (b) предмет здесь есть (код существует в scripts/ или agents/), но сам файл сьюта не
  #       перенесён — отложенная задача N3 роадмапа (owner-решение Р10), не код: test-
  #       validate-profile, test-resolve-agents, test-check-status-drift, test-apply-overlay
  #       (предметы — validate-profile.py, _resolve_agents.py, check-status-drift.py,
  #       apply-overlay.sh, все в scripts/). DEV-125 (NA-EPIC-38) вывел из этой категории
  #       test-validate-content: сьюта не перенесена из донора, а НАПИСАНА заново под другой
  #       предмет — самопроверку гейта на синтетических фикстурах (четыре группы входов,
  #       ишью потребителей #11/#12), не перенос ~23 сценариев донорского контракта. Она
  #       доставляется payload'ом и зарегистрирована в перечне ниже;
  #       test-loud-gates (_validate_common.py/_drift_check.py); test-gate-debt (debt-батч
  #       PT-EPIC-13, большей частью тот же _drift_check.py/apply-overlay.sh); test-spdd-
  #       integration (two-way sync CLAUDE.md, PM-review drift-check, manifest drift_pairs —
  #       все три живут в этом дереве); test-backlog-cleanup (ownership-бухгалтерия PT-EPIC-16
  #       поверх check-backlog-closure.py/check-adr-line-limit.py); test-prompt-layer
  #       (ADR-016 промт-слой 11 ролей — agents/*.md, собственный домен nauta; 5 из 8
  #       исходных предметов уже переехали сюда напрямую вне этой задачи).
  #
  # test-check-id (DEV-022, NA-EPIC-11) — регистрируется тем же механизмом, что три соседа
  # выше, и это ЧЕТВЁРТОЕ имя перечня, а не исключение. Основание — то же правило ADR-017,
  # уже записанное абзацем выше про test-check-breaking-change-section: регистрация раннера
  # решается отдельно от применимости самого гейта. Разница с соседями по перечню одна и
  # ничего в протоколе не меняет: `scripts/test-check-id.sh` входит в PAYLOAD_FILES
  # (bin/deliver.sh) — то есть доставляется каждому потребителю, — тогда как три соседних
  # сьюты живут только здесь. Именно поэтому её отсутствие в перечне было вакуумом, а не
  # безобидным упущением: 19 мутационных проверок M1–M9 ехали в каждое дерево и не бежали ни
  # в одном профиле (находка DEV-019, «Осознанные границы» его отчёта).
  #
  # Обязательность НЕ ужесточается регистрацией: run_suite_if_declared соблюдает те же пять
  # исходов ADR-037, что и остальной перечень. У потребителя, синкнувшегося payload'ом БЕЗ
  # этой позиции, базис её не заявляет — он получит объявленное молчание (INFO-NOT-DELIVERED)
  # и exit 0, а не ложный красный. Красным она станет ровно тогда, когда базис её заявит.
  # test-validate-content (DEV-125, NA-EPIC-38) — ПЯТОЕ имя перечня, на том же основании и по
  # тому же протоколу, что и четвёртое. Отличие от соседей — только в предмете: это
  # самопроверка `validate-content.py` (самого большого гейта поставки, 19 проверок), которой
  # не было ни одной, тогда как у четырёх меньших гейтов она есть с ADR-025. Профилактика
  # ровно того класса, что дали ишью #11/#12: проверка признавалась работающей по признаку,
  # снятому с СОБСТВЕННОГО дерева. Сьюта входит в PAYLOAD_FILES — без регистрации здесь она
  # ехала бы к каждому потребителю и не бежала ни в одном профиле (вакуум DEV-019/DEV-022).
  # Объявления невхождения §3.2 ADR-085 (Д5), нулевая колонка — по тому же основанию, что у
  # check-backlog-closure выше. Сьюта едет только со своим предметом: test-check-backlog-
  # closure следует за гейтом класса B (Д3), а test-check-breaking-change-section не
  # доставляется никогда — её предмет `check-breaking-change-section.py` не доставляется и не
  # зовётся по Ruling E. Регистрация обеих в ростере сохраняется: ADR-017 отделяет
  # регистрацию раннера от применимости предмета, снятие вернуло бы вакуум DEV-019/DEV-022.
# Сьюта гейта, чья доставка ОСТАНОВЛЕНА выше, — по тому же правилу Д5 «сьюта едет только со
# своим предметом», которым Д2 её и вносил («едет за предметом»).
# NOT-DELIVERED: test-check-adr-line-limit — предмет не доставляется
# NOT-DELIVERED: test-check-backlog-closure — предмет не доставляется
# NOT-DELIVERED: test-check-breaking-change-section — предмет не доставляется
  for suite in test-check-adr-line-limit test-check-backlog-closure \
               test-check-breaking-change-section test-check-id \
               test-validate-content; do
    run_suite_if_declared "$suite"
  done
fi

# ---------------------------------------------------------------------------
# projectGates (ADR-077) — точка подключения ПРОЕКТНОГО гейта: проверки, которую написал
# потребитель доставки и которой в ростере выше нет и не будет.
#
# Носитель объявления — ключ `projectGates` в `.nauta-gates.yaml`, и выбран он по ВЛАДЕНИЮ
# файлом (Д1), не по удобству: это единственный из трёх кандидатов ВНЕ PAYLOAD_FILES
# (bin/deliver.sh), то есть единственный, который доставщик не перезаписывает каноном. Сам
# этот файл и `.githooks/pre-commit` заморожены per-file sha256 (ADR-030 Д3/Д4) — правка
# любого из них у потребителя даёт конфликт синка либо запись в skip:.
#
# Обязательность проектного гейта решает ЕГО ОБЪЯВЛЕНИЕ, не базис доставки (Д2): базис
# отвечает на вопрос «что мне привезли» и по построению не может ответить о непривезённом
# (`files:` пишется циклом ровно по PAYLOAD_FILES). Множества путей не пересекаются, поэтому
# приоритета между двумя источниками обязательности не требуется — но каждое сообщение
# обязано называть СВОЙ носитель дословно, иначе чинящего отправят не в тот файл (§4 спутника
# ADR-077; тот же класс дефекта, что закрывает ADR-037 Д5 пятью раздельными сообщениями).
# ---------------------------------------------------------------------------

# _project_gates_records — разбор ключа в плоские записи, разделённые табом: `KEY` (ключ
# найден; печатается ВСЕГДА при входе в блок, иначе «ключа нет» и «ключ есть, списки пусты»
# были бы неразличимы — тот же приём, что у признака `enabled=` в _gates_secret_scan_enabled)
# и `<fast|full>\t<путь>`. Форма — та же блочная awk-идиома, которой этот файл уже читает
# secretScan и носитель поставки: вход в блок по заголовку без отступа, выход — на первой
# строке без отступа. Отличие одно: значение подключа — список `- <путь>`, а не скаляр.
_project_gates_records() {
  local gates="$REPO_ROOT/.nauta-gates.yaml"
  [[ -f "$gates" ]] || return 0
  awk '
    /^projectGates:[ \t]*(#.*)?$/ { inblk=1; lst=""; print "KEY"; next }
    inblk && $0 ~ /^[^ \t]/ { inblk=0 }
    inblk {
      line=$0
      sub(/^[ \t]+/, "", line); gsub(/[ \t]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      if (line ~ /^fast:[ \t]*(#.*)?$/) { lst="fast"; next }
      if (line ~ /^full:[ \t]*(#.*)?$/) { lst="full"; next }
      if (lst != "" && line ~ /^-[ \t]*/) {
        p=line
        sub(/^-[ \t]*/, "", p)
        gsub(/^"/, "", p); gsub(/"$/, "", p)
        if (p != "") print lst "\t" p
      }
    }
  ' "$gates"
}

# run_project_gates <fast|full> — шесть исходов Д3 ADR-077, ни одного тихого. Два молчания
# ОБЪЯВЛЕННЫЕ (ADR-040 Д8: у потребителя отсутствие конфигурации законно и громкой ошибкой не
# делается) и exit-кода не меняют; четыре отказа — ERROR и failed=1. Мягкие коды проектным
# гейтам НЕ выдаются (Д8): выдача была бы дырой — потребитель объявил бы мягким собственный
# отказ. Таймаут чужому гейту не вводится: времени прогона проектных гейтов не измерено ни в
# одном дереве, порог был бы выдуманным числом (Consequences ADR-077, приём ADR-037 Д6).
run_project_gates() {
  local profile="$1" records lst rel runner paths="" passes="$1" pass n
  records="$(_project_gates_records)"
  if [[ -z "$records" ]]; then
    echo "[INFO] projectGates: absent (.nauta-gates.yaml) — проверка не выполняется, exit-код не"
    echo "       меняется (ADR-077 Д3, ADR-040 Д8). Точка подключения СВОЕГО гейта существует:"
    echo "       заведи ключ projectGates с подсписками fast:/full: — объявленные пути будут"
    echo "       исполнены здесь, в хвосте прогона (fast: в обоих режимах, full: только в --full)."
    return 0
  fi

  # Порядок §4 спутника: сначала список профиля, затем fast: (он идёт в обоих режимах, Д5).
  # Дубль исполняется РОВНО один раз: путь, объявленный и в fast:, и в full:, в --full не
  # должен бежать дважды (граничное условие §10 спутника).
  if [[ "$profile" == "full" ]]; then passes="full fast"; fi
  for pass in $passes; do
    while IFS=$'\t' read -r lst rel; do
      [[ "$lst" == "$pass" && -n "$rel" ]] || continue
      _in_newline_list "$rel" "$paths" && continue
      paths+="$rel"$'\n'
    done <<< "$records"
  done

  n="$(printf '%s' "$paths" | grep -c . || true)"
  echo "[INFO] projectGates: configured (${n} позиций) — носитель объявления .nauta-gates.yaml,"
  echo "       профиль ${profile}. Источник обязательности этих гейтов — их объявление в ключе,"
  echo "       а не базис доставки (ADR-077 Д2): базис заявляет только привезённое."
  # `return 0`, а не голый `return`: голый вернул бы статус ПОСЛЕДНЕЙ команды — то есть 1 от
  # самого `[[ -n "$paths" ]]`, — и под `set -e` инертный ключ ронял бы весь прогон ещё до
  # _finish. Поймано красным `test_d3_row2_present_but_empty_key_is_configured_zero`.
  [[ -n "$paths" ]] || return 0

  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue

    # Путь вне дерева отвергается ДО запуска. Проверка грубая намеренно: любое вхождение ".."
    # достаточно, чтобы отказать — механизм не разрешает символические ссылки и не считает
    # уровни, а объявление о собственном гейте таких форм не требует.
    if [[ "$rel" == /* || "$rel" == *".."* ]]; then
      echo "▶ $rel"
      echo "  ✗ $rel FAILED" >&2
      echo "  ERROR: путь \"$rel\" объявлен в projectGates (.nauta-gates.yaml) абсолютным либо содержит \"..\"" >&2
      echo "  — объявление не даёт права исполнить код вне дерева (ADR-077 Д3), гейт НЕ запускался." >&2
      echo "  Почини: назови путь от корня репозитория либо убери его из projectGates." >&2
      failed=1
      continue
    fi

    # Д4: раннер выводится из расширения, бит x не спрашивается (git переносит его одной
    # единственной сущностью и в носители объявления не годится).
    case "$rel" in
      *.sh) runner="bash" ;;
      *.py) runner="uv run" ;;
      *)
        echo "▶ $rel"
        echo "  ✗ $rel FAILED" >&2
        echo "  ERROR: гейт \"$rel\" объявлен в projectGates (.nauta-gates.yaml), а раннер не выводится из пути:" >&2
        echo "  признаются ровно два расширения — .sh (bash) и .py (uv run), ADR-077 Д4. Гейт НЕ" >&2
        echo "  запускался. Почини: дай файлу одно из двух расширений либо убери путь из projectGates." >&2
        failed=1
        continue
        ;;
    esac

    # Граница, ради которой существует решение: «заявлен и отсутствует» — противоречие, а не
    # отказ от проверки. Сообщение называет ИМЕННО projectGates: базис доставки этот путь не
    # заявляет и заявить не может, и посылать чинящего в .nauta-scripts-basis.yaml значило бы
    # отправить его не в тот файл.
    if [[ ! -f "$rel" ]]; then
      echo "▶ $rel"
      echo "  ✗ $rel FAILED" >&2
      echo "  ERROR: гейт объявлен в projectGates (.nauta-gates.yaml), но файла $rel в дереве нет —" >&2
      echo "  заявка есть, предмета нет. ADR-007 Д1: \"не смог проверить\" ≠ \"нечего проверять\"," >&2
      echo "  и источник обязательности здесь — объявление в ключе, не доставка (ADR-077 Д2)." >&2
      echo "  Почини: верни файл либо убери путь из projectGates." >&2
      failed=1
      continue
    fi

    run_check "$rel" "$runner $rel"
  done <<< "$paths"
}

# Место вызова — хвост прогона (Д6): после всего доставленного ростера и до _finish, чтобы
# красный ДОСТАВЛЕННЫЙ гейт был виден раньше чужого. Односьютные режимы (--secret-scan-only,
# --delivery-composition-only) сюда не доезжают — они завершаются своим _finish выше, и это
# то же правило «режим релиза исполняет РОВНО один гейт и ничего больше» (§4.3 спутника
# ADR-073). Признак дерева-источника (ORIGIN) здесь не спрашивается: у проектных гейтов
# перечня по умолчанию нет, объявление всегда явное, и поведение в дереве-источнике и у
# потребителя одинаково (Д7).
if [[ "$MODE" == "--full" ]]; then
  run_project_gates "full"
else
  _pg_t0=$SECONDS
  _pg_f0=$failed
  run_project_gates "fast"
  # Исход info при немятом прогоне — состав ADR-123-spec §1: absent/configured, оба
  # объявления, не отказ; отказ проектного гейта остаётся отказом (дельта failed).
  _journal_infofail "projectGates" "$_pg_t0" "$_pg_f0"
fi

# --- DEV-454 (NA-EPIC-51, AC-8) — запись sha прогона, ЗА run_project_gates и ДО _finish ------
# Пишущий вызов ТОЛЬКО: scripts/full-run-record.py --record не читает и не сверяет прежнюю
# запись, поэтому дерево, коммитившее между двумя `--full`, не красит этот шаг — читающий режим
# того же файла нигде в обязательном пути не встроен ровно по этой причине (докстрока файла,
# раздел Recursion). Условия: MODE=--full (запись о `--fast` не утверждает того же объёма
# проверок) и failed=0 (запись — доказательство ПРОШЕДШЕГО прогона, не попытки). Исход шага не
# заведён в failed: сама запись — bookkeeping, а не гейт, и её отказ не смеет ронять уже
# зелёный `--full` (best-effort, докстрока прибора).
# ADR-117 Д1 (issue #35): прибор записи — прямой вызов (вне обёрток ростера) и НЕ
# доставляется потребителю (вне PAYLOAD_FILES). Вызов — только под `[[ -f ]]`: на дереве
# потребителя неограждённый `uv run` падал бы `error: Failed to spawn` внутри зелёного
# `--full`. Ветке отсутствия ЗАПРЕЩЕНО молчать (ADR-085 §3): невхождение объявляется
# строкой [INFO] с меткой `_not_delivered_label` — молчание выглядело бы исполненным шагом.
# NOT-DELIVERED: full-run-record — предмет — репозиторий nauta
if [[ "$MODE" == "--full" && "$failed" -eq 0 ]]; then
  if [[ -f scripts/full-run-record.py ]]; then
    uv_named_refusal uv run scripts/full-run-record.py --record || true
  else
    echo "[INFO] full-run-record: $(_not_delivered_label full-run-record) — запись зелёного --full не выполнена"
  fi
fi

_finish
