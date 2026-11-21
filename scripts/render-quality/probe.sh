#!/usr/bin/env bash
# scripts/render-quality/probe.sh — единственный bash-вход прибора рендер-проб
# (дизайн docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решения 2/3/5).
# Вызов probe.py строго через uv: uv run --with playwright==<pin> (ADR-0025 — питон-биндинг
# без npm-поверхности; пин точной версии фиксируется Dev на дату реализации, одна строка
# ниже; дизайн номер сознательно не называет).
# Обёртка uv_named_refusal адаптирована с scripts/check.sh:615-639 (прецедент ADR-159):
# stderr вызова фильтруется по СУЖЕННОЙ сигнатуре офлайн-промаха кэша (ядро
# «found in the cache» И «disabled»); при совпадении к выводу добавляется рычаг
# bash scripts/render-quality/warm.sh; rc передаётся насквозь. Сигнатура не совпала
# (дрейф текста uv, чужой отказ) — вывод и rc нетронуты: fail-open по имени.
# Отличие от прецедента: рычаг здесь свой (warm.sh), не fixtures-update.sh.

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYWRIGHT_PIN="1.65.2"

uv_named_refusal() {
  local rc=0 _errf
  _errf="$(mktemp "${TMPDIR:-/tmp}/rq-uv-refusal.XXXXXX")" || { "$@"; return $?; }
  "$@" 2>"$_errf" || rc=$?
  if [ "$rc" -ne 0 ] \
     && grep -q 'found in the cache' "$_errf" 2> /dev/null \
     && grep -q 'disabled' "$_errf" 2> /dev/null; then
    # Форма сообщения — рычаг назван путём, без глагола-раннера (прецедент ADR-159 Д3).
    echo "  [offline] промах локального кэша uv: прогрей окружение явным рычагом" >&2
    echo "  «bash scripts/render-quality/warm.sh» — кэш uv + браузер chromium;" >&2
    echo "  отказ немедленный, rc передан насквозь (ADR-159; сигнатура uv 0.12.5)." >&2
  fi
  cat "$_errf" >&2 2> /dev/null
  rm -f "$_errf"
  return "$rc"
}

# --quiet: детерминизм вывода (NFR-077) — uv не пишет в stderr сообщения об установке,
# которые отличались бы между первым и последующими прогонами.
uv_named_refusal uv run --quiet --with "playwright==${PLAYWRIGHT_PIN}" \
  "$SCRIPT_DIR/probe.py" "$@"
