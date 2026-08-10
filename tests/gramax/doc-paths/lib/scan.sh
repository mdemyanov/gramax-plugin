#!/usr/bin/env bash
# tests/gramax/doc-paths/lib/scan.sh
# Ядро гейта doc-paths (FR-024, FR-026, FR-027). Вынесено в функцию, чтобы одна и та же
# логика проверялась и на живом content/, и на фикстуре рассинхрона — иначе тест на
# поведение при рассинхроне пришлось бы делать мутацией рабочего дерева.
#
# Форматы записи allowlist:
#   path/to/file.md:123 — причина    точечная: конкретная строка есть историческая запись
#   path/to/file.md — причина        whole-file: весь документ посвящён самой миграции
#
# Whole-file форма не дыра: такой документ не содержит указателей, по которым читателя
# приглашают перейти, — он содержит таблицу соответствия старого и нового (ADR-0011 Решение 4).

DOC_PATHS_PATTERN='docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)'

# scan_doc_paths <content-root> <allowlist-path>
scan_doc_paths() {
  local root="$1" allowlist="$2"
  local violations=0 stale_entries=0

  if [ ! -f "$allowlist" ]; then
    echo "  FAIL: allowlist не найден: $allowlist" >&2
    return 1
  fi

  # Разбор allowlist в две таблицы
  local -a wholefile_paths=() line_keys=()
  local line entry
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    entry="${line%% — *}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    if printf '%s' "$entry" | grep -qE ':[0-9]+$'; then
      line_keys+=("$entry")
    else
      wholefile_paths+=("$entry")
    fi
  done < "$allowlist"

  # 1. Находки в корпусе, не покрытые allowlist — нерабочие указатели
  local hit file lineno key covered
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    file="${hit%%:*}"
    lineno="$(printf '%s' "$hit" | cut -d: -f2)"
    key="$file:$lineno"

    covered=0
    for p in ${wholefile_paths[@]+"${wholefile_paths[@]}"}; do
      [ "$p" = "$file" ] && covered=1 && break
    done
    if [ "$covered" -eq 0 ]; then
      for k in ${line_keys[@]+"${line_keys[@]}"}; do
        [ "$k" = "$key" ] && covered=1 && break
      done
    fi

    if [ "$covered" -eq 0 ]; then
      echo "  FAIL: нерабочий указатель на docs/: $hit" >&2
      violations=$((violations + 1))
    fi
  done <<< "$(grep -rnE "$DOC_PATHS_PATTERN" "$root" 2>/dev/null || true)"

  # 2. Свежесть allowlist: каждая точечная запись обязана указывать на строку,
  #    которая всё ещё содержит docs/-путь. Иначе запись устарела и молча
  #    прикрывает строку, которой там больше нет (FR-027).
  local f n content
  for k in ${line_keys[@]+"${line_keys[@]}"}; do
    f="${k%:*}"; n="${k##*:}"
    if [ ! -f "$f" ]; then
      echo "  FAIL: allowlist устарел: файл $f не существует (запись $k)" >&2
      stale_entries=$((stale_entries + 1))
      continue
    fi
    content="$(sed -n "${n}p" "$f")"
    if ! printf '%s' "$content" | grep -qE "$DOC_PATHS_PATTERN"; then
      echo "  FAIL: allowlist устарел: строка $n в файле $f больше не содержит ожидаемого паттерна" >&2
      echo "        фактическое содержимое: ${content:-<пустая строка>}" >&2
      stale_entries=$((stale_entries + 1))
    fi
  done

  if [ "$violations" -gt 0 ] || [ "$stale_entries" -gt 0 ]; then
    echo "  Итого: $violations нерабочих указателей, $stale_entries устаревших записей allowlist" >&2
    return 1
  fi
  return 0
}
