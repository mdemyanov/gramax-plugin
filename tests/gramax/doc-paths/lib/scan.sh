#!/usr/bin/env bash
# tests/gramax/doc-paths/lib/scan.sh
# Ядро гейта doc-paths (FR-024, FR-026, FR-027). Вынесено в функцию, чтобы одна и та же
# логика проверялась и на живом content/, и на фикстуре рассинхрона — иначе тест на
# поведение при рассинхроне пришлось бы делать мутацией рабочего дерева.
#
# Форматы записи allowlist:
#   path/to/file.md:123 — docs/expected/path.md — причина
#     точечная: конкретная строка есть историческая запись. Freshness пинит ИМЕННО этот
#     путь на этой строке, а не факт наличия какого-то docs/-пути вообще: если строку
#     переписали и на её место попал другой, реально нерабочий указатель, случайно
#     совпадающий с тем же паттерном, — запись обязана заметить подмену, а не смолчать.
#   path/to/file.md — причина
#     whole-file: весь документ посвящён самой миграции. Пинить нечего — весь документ
#     и есть исключение, точечная защита строк ему не нужна (ADR-0011 Решение 4).
#
# Разбор устойчив к тому, что причина сама может содержать « — » несколько раз, и к
# записи без причины: ожидаемый путь — это текст между ПЕРВЫМ и ВТОРЫМ « — »; всё, что
# после второго, свободный текст причины и в разбор не идёт (а если второго « — » нет —
# ожидаемый путь это весь остаток строки, причины попросту нет).

# Каталоги-прокси (docs/adr, docs/qa-reports, docs/acceptance, docs/research,
# docs/lessons-learned.md) переехали целиком — префикс безопасен. `docs/superpowers/specs/`
# — нет: там остаются два легитимных, никуда не переезжавших спека
# (2026-05-08-apply-project-template-design.md, 2026-08-07-nauta-integration-design.md,
# FR-029). Префиксный паттерн ловил бы рабочие ссылки на них как нерабочие указатели —
# поэтому здесь, как и в соседнем tests/gramax/nauta-integration/ac-007, только точные
# имена четырёх переехавших спек, не префикс каталога.
DOC_PATHS_PATTERN='docs/(adr|qa-reports|acceptance|research|lessons-learned)|docs/superpowers/specs/(2026-05-08-diagram-on-demand-design|2026-05-11-remove-diagram-skills|2026-05-11-routing-mermaid-drawio|2026-05-12-mermaid-file-based-design)\.md'

# scan_doc_paths <content-root> <allowlist-path>
scan_doc_paths() {
  local root="$1" allowlist="$2"
  local violations=0 stale_entries=0

  if [ ! -f "$allowlist" ]; then
    echo "  FAIL: allowlist не найден: $allowlist" >&2
    return 1
  fi

  # Разбор allowlist в три параллельных списка: позиции точечных записей, ожидаемый
  # путь для каждой (тот же индекс — оба массива растут синхронно, только в ветке
  # точечной записи) и whole-file пути.
  local -a wholefile_paths=() line_keys=() line_expected=()
  local line entry rest expected
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    entry="${line%% — *}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    if printf '%s' "$entry" | grep -qE ':[0-9]+$'; then
      rest="${line#*" — "}"
      expected="${rest%% — *}"
      line_keys+=("$entry")
      line_expected+=("$expected")
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

  # 2. Свежесть allowlist: каждая точечная запись обязана указывать на строку, которая
  #    всё ещё содержит ИМЕННО ожидаемый путь. Проверка «есть ли на строке хоть какой-то
  #    docs/-путь» не годится: строку могли переписать так, что старый путь исчез, а на
  #    его место попал другой, реально нерабочий указатель, совпадающий с тем же
  #    паттерном, — по паттерну запись осталась бы «свежей» и молча прикрыла бы новую
  #    находку (FR-027, находка ревью).
  local idx=0 f n content
  for k in ${line_keys[@]+"${line_keys[@]}"}; do
    expected="${line_expected[$idx]}"
    idx=$((idx + 1))
    f="${k%:*}"; n="${k##*:}"
    if [ ! -f "$f" ]; then
      echo "  FAIL: allowlist устарел: файл $f не существует (запись $k)" >&2
      stale_entries=$((stale_entries + 1))
      continue
    fi
    content="$(sed -n "${n}p" "$f")"
    if [ -z "$expected" ] || ! printf '%s' "$content" | grep -qF "$expected"; then
      echo "  FAIL: allowlist устарел: строка $n в файле $f больше не содержит ожидаемый путь" >&2
      echo "        ожидалось: ${expected:-<путь не указан в allowlist>}" >&2
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
