#!/usr/bin/env bash
# scripts/assemble-gate-evidence.sh — механическая сборка пакета доказательств человеческого
# гейта (ADR-137 Д4; capability lean-epic-initialization, «Gate evidence is assembled
# mechanically by one script»).
#
# Четыре секции пакета (находки `файл:строка`, прогоны «команда → exit code → хвост»,
# проверенные сценарии capability-спеки, что не проверено) собираются из ИМЕНОВАННЫХ входов
# и печатаются в stdout. Рекомендацию роли и вердикт скрипт не берёт и не пишет: пакет —
# вход `record_verdict` роли («The script writes no verdict»), никаких вызовов стора и
# никаких записей файлов — только чтение именованных входов (grep/cat/wc), runtime ≤ 5 с.
#
# Громкость (ADR-007 Д1): отсутствующий или ненайденный именованный вход — exit 2
# с именем ключа; пустой пакет (все входы без содержимого) с exit 0 запрещён.
#
# Совместимость: системный bash потребителя — на macOS это GNU bash 3.2.57, поэтому ни
# `declare -A`, ни `${var,,}` (конвенция bin/store.sh). Корень плагина резолвится от
# BASH_SOURCE — приём bin/store.sh; на работу скрипта корень не влияет: входы читаются
# как заданы.
#
# Usage:
#   bash scripts/assemble-gate-evidence.sh \
#     --findings <file> --runs <file> [--runs <file> …] \
#     --spec <capability/spec.md> --not-checked <file>
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FINDINGS=""
SPEC=""
NOT_CHECKED=""
RUNS=""   # пути файлов прогонов, по одному на строку (повторный --runs дописывает)

usage() {
  echo "usage: bash scripts/assemble-gate-evidence.sh --findings <file> --runs <file> [--runs <file> …] --spec <path> --not-checked <file>" >&2
  echo "  корень плагина: $ROOT" >&2
}

die2() {
  echo "ОШИБКА: $1" >&2
  exit 2
}

if [ "$#" -eq 0 ]; then
  usage
  die2 "ни одного именованного входа: нужны --findings, --runs, --spec, --not-checked"
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --findings)
      [ "$#" -ge 2 ] || die2 "--findings требует путь файла"
      FINDINGS="$2"; shift 2 ;;
    --spec)
      [ "$#" -ge 2 ] || die2 "--spec требует путь capability-спеки"
      SPEC="$2"; shift 2 ;;
    --not-checked)
      [ "$#" -ge 2 ] || die2 "--not-checked требует путь файла"
      NOT_CHECKED="$2"; shift 2 ;;
    --runs)
      [ "$#" -ge 2 ] || die2 "--runs требует путь файла прогона"
      if [ -n "$RUNS" ]; then RUNS="$RUNS
$2"; else RUNS="$2"; fi
      shift 2 ;;
    -h|--help)
      usage
      exit 0 ;;
    *)
      usage
      die2 "неизвестный аргумент '$1' — именованные входы: --findings, --runs, --spec, --not-checked" ;;
  esac
done

MISSING=""
[ -n "$FINDINGS" ]    || MISSING="$MISSING --findings"
[ -n "$RUNS" ]        || MISSING="$MISSING --runs"
[ -n "$SPEC" ]        || MISSING="$MISSING --spec"
[ -n "$NOT_CHECKED" ] || MISSING="$MISSING --not-checked"
if [ -n "$MISSING" ]; then
  die2 "отсутствует именованный вход:$MISSING — пакет без входа не собирается (пустой пакет с exit 0 запрещён, ADR-007 Д1)"
fi

[ -f "$FINDINGS" ]    || die2 "вход --findings не найден: $FINDINGS"
[ -f "$SPEC" ]        || die2 "вход --spec не найден: $SPEC"
[ -f "$NOT_CHECKED" ] || die2 "вход --not-checked не найден: $NOT_CHECKED"
RUNS_LIST=""
while IFS= read -r runs_file; do
  [ -n "$runs_file" ] || continue
  if [ ! -f "$runs_file" ]; then
    die2 "вход --runs не найден: $runs_file"
  fi
  if [ -n "$RUNS_LIST" ]; then RUNS_LIST="$RUNS_LIST
$runs_file"; else RUNS_LIST="$runs_file"; fi
done <<EOF
$RUNS
EOF

N_REQ=$(grep -c '^### Requirement:' "$SPEC")
N_SCN=$(grep -c '^#### Scenario:' "$SPEC")

# Пустой пакет запрещён: ни находок, ни прогонов, ни счётчиков, ни «не проверено».
TOTAL_BYTES=$(( $(wc -c < "$FINDINGS") + $(wc -c < "$NOT_CHECKED") + N_REQ + N_SCN ))
while IFS= read -r runs_file; do
  [ -n "$runs_file" ] || continue
  TOTAL_BYTES=$(( TOTAL_BYTES + $(wc -c < "$runs_file") ))
done <<EOF
$RUNS_LIST
EOF
if [ "$TOTAL_BYTES" -eq 0 ]; then
  die2 "пустой пакет запрещён: --findings, --runs, --spec, --not-checked не несут содержимого (ADR-007 Д1)"
fi

echo "## Gate evidence pack"
echo
echo "### Findings (file:line)"
cat "$FINDINGS"
echo
echo "### Runs (command - exit code - tail)"
while IFS= read -r runs_file; do
  [ -n "$runs_file" ] || continue
  echo "--- $runs_file"
  cat "$runs_file"
done <<EOF
$RUNS_LIST
EOF
echo
echo "### Capability scenarios checked"
echo "spec: $SPEC — requirements: $N_REQ, scenarios: $N_SCN"
echo
echo "### Not checked"
cat "$NOT_CHECKED"
