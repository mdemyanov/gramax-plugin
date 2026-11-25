#!/usr/bin/env bash
# scripts/check-gramax.sh — проектный гейт gramax-marketplace (бывший scripts/check.sh; зовётся из check.sh nauta через projectGates).
# Без profile-валидаторов (профилей нет). Валидатор каталога docs/ — из nauta,
# доставлен через /nauta:sync-scripts, обновляется тем же каналом.
#
# Modes:
#   --fast   : whitespace + JSON validity + validate-content.py + validate_render.py +
#              шаг shellcheck-changed: lint изменённых и новых .sh (ADR-0029 Решение 1)
#              (uv обязателен; shellcheck обязателен, когда в дереве есть изменённые
#              или новые .sh — без него шаг 2.7 красит оба режима; для pre-commit hook)
#   --full   : --fast + догфудинг своих валидаторов docs/ (validate_structure.py и
#              validate_comments.py, порог 0 ERROR — ADR-0027 Решение 4) +
#              полный lint отслеживаемых .sh (если shellcheck не установлен — шаг
#              пропускается с предупреждением; предусловие для изменённых .sh уже
#              предъявил шаг 2.7 состава --fast; -e коды — только файлам базиса,
#              ADR-0029 Решение 1) +
#              tests/gramax/orphan-references + tests/gramax/nauta-integration +
#              tests/gramax/docs-layout-invariants +
#              tests/gramax/plugin-contract +
#              tests/gramax/catalog-validator + tests/gramax/comments +
#              tests/gramax/mermaid-adoption +
#              tests/gramax/writer-consumer-rules + tests/gramax/link-form-resolver +
#              tests/gramax/link-form-migration + tests/gramax/export-skill +
#              tests/gramax/plantuml-bpmn + tests/gramax/writer-sync-470 +
#              tests/gramax/writer-tail-480 + tests/gramax/render-linter +
#              tests/gramax/render-quality (только офлайн-стабы, ADR-0027 Решение 1) +
#              tests/gramax/cross-catalog-retraction + tests/gramax/gate-composition
#              (18 сюит; состав — ADR-0027 «Целевой состав --full» с поправкой PM,
#              волна-4 добавляет docs-layout-invariants — ADR-0029 Решение 2;
#              gate-composition — последним шагом)
#
# Exit codes:
#   0 — all checks passed
#   1 — at least one check failed

set -euo pipefail

MODE="${1:---fast}"
FAILED=0

echo "==> mode: $MODE"

# --- 1. Whitespace check on staged/all files ---
echo "==> whitespace"
if git diff --check HEAD -- 2>&1 | grep -q .; then
  git diff --check HEAD --
  echo "FAIL: trailing whitespace or mixed indent detected"
  FAILED=1
else
  echo "OK: no whitespace issues"
fi

# --- 2. JSON validity for tracked .json files ---
echo "==> json"
JSON_FILES=$(git ls-files '*.json' 2>/dev/null || true)
if [ -n "$JSON_FILES" ]; then
  JSON_FAILED=0
  for f in $JSON_FILES; do
    if ! python3 -m json.tool "$f" > /dev/null 2>&1; then
      echo "FAIL: invalid JSON: $f"
      FAILED=1
      JSON_FAILED=1
    fi
  done
  if [ "$JSON_FAILED" -eq 0 ]; then
    echo "OK: JSON validated"
  fi
else
  echo "OK: no JSON files tracked"
fi

# --- 2.5. Gramax docs/ validation (валидатор nauta, PEP 723) ---
echo "==> content"
if [ -d docs ]; then
  if command -v uv > /dev/null 2>&1; then
    if ! uv run scripts/validate-content.py; then
      echo "FAIL: docs/ validation"
      FAILED=1
    else
      echo "OK: docs validated"
    fi
  else
    echo "FAIL: uv not installed — docs/ validation not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi
else
  echo "OK: no docs/ directory"
fi

# --- 2.6. Gramax docs/ render-linter (рендер-киллеры, ADR-0019 Решение 4) ---
# Киллер рендера (HTTP 500 на GES) блокирует pre-commit: exit 1/2 → FAILED=1.
# --errors-only: принятый H1-WARN-шум по docs/ не спамит pre-commit, exit-контракт тот же.
echo "==> render"
if [ -d docs ]; then
  if command -v uv > /dev/null 2>&1; then
    if ! uv run plugins/gramax/scripts/validate_render.py docs --errors-only; then
      echo "FAIL: render-linter — киллер рендера в docs/"
      FAILED=1
    else
      echo "OK: render-linter clean"
    fi
  else
    echo "FAIL: uv not installed — render-linter not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi
else
  echo "OK: no docs/ directory"
fi

# --- 2.7. shellcheck изменённых и новых .sh (ADR-0029 Решение 1) ---
# Стаб с shellcheck-находкой ловится на пути qa-author → Dev (уроки журнала
# 2026-11-21 и 2026-11-23: стабы дважды дошли до полного гейта с lint-долгом),
# не дожидаясь --full. Цена на чистом дереве: 0 вызовов shellcheck, 2 вызова git.
echo "==> shellcheck-changed"
LIST_RC=0
CHANGED_SH="$(
  { git ls-files --others --exclude-standard -- '*.sh';
    git diff --name-only --diff-filter=d HEAD -- '*.sh'; } \
    | { grep -v '^tests/gramax/archive/' || true; } \
    | sort -u
)" || LIST_RC=1
if [ "$LIST_RC" -ne 0 ]; then
  echo "FAIL: shellcheck-changed — список изменённых .sh не собрался (ошибка git)"
  FAILED=1
elif [ -z "$CHANGED_SH" ]; then
  echo "OK: no changed shell files"
elif ! command -v shellcheck > /dev/null 2>&1; then
  CHANGED_COUNT="$(printf '%s\n' "$CHANGED_SH" | grep -c .)" || CHANGED_COUNT=0
  echo "FAIL: shellcheck not installed — ${CHANGED_COUNT} изменённых .sh не проверены"
  FAILED=1
else
  CHANGED_COUNT="$(printf '%s\n' "$CHANGED_SH" | grep -c .)" || CHANGED_COUNT=0
  # Расщепление по базису (ADR-0029 Решение 1): 11 .sh базиса (.nauta-scripts-basis.yaml,
  # до исправления issue №42) — с -e кодами; остальные файлы — чистый вызов, их находки
  # блокирующие. Список базиса меняется синком nauta — число «11» здесь не пришито.
  BASIS_SH="$(sed -n 's/^  \([^:]*\.sh\): "sha256:.*/\1/p' .nauta-scripts-basis.yaml)"
  BASIS_CHANGED="$(printf '%s\n' "$CHANGED_SH" | grep -Fxf <(printf '%s\n' "$BASIS_SH") || true)"
  OTHER_CHANGED="$(printf '%s\n' "$CHANGED_SH" | grep -Fxvf <(printf '%s\n' "$BASIS_SH") || true)"
  CHANGED_BAD=0
  if [ -n "$BASIS_CHANGED" ]; then
    # shellcheck disable=SC2086
    if ! shellcheck -e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR $BASIS_CHANGED; then
      CHANGED_BAD=1
    fi
  fi
  if [ -n "$OTHER_CHANGED" ]; then
    # shellcheck disable=SC2086
    if ! shellcheck -x -P SCRIPTDIR $OTHER_CHANGED; then
      CHANGED_BAD=1
    fi
  fi
  if [ "$CHANGED_BAD" -ne 0 ]; then
    echo "FAIL: shellcheck issues (changed files)"
    FAILED=1
  else
    echo "OK: shellcheck clean (${CHANGED_COUNT} changed)"
  fi
fi

# --- 3. (--full only) Полный блок --full: догфудинг валидаторов → shellcheck → сюиты ---
if [ "$MODE" = "--full" ]; then
  # --- 3.0 (--full only) Догфудинг своих валидаторов на docs/ (FR-220б, ADR-0027
  # Решение 4): два шага первыми внутри --full-блока, подряд с быстрыми валидаторами
  # docs/ (шаги 2.5-2.6, остаются в --fast). Порог 0 ERROR — rc-контракт валидатора
  # без --strict: rc≠0 даёт FAIL; предупреждения печатаются полностью и гейт не красят
  # (флаги подавления не вводятся). В --fast не переносится (ADR-0027 Решение 4).
  echo "==> validate-structure"
  if command -v uv > /dev/null 2>&1; then
    if ! uv run plugins/gramax/scripts/validate_structure.py docs; then
      echo "FAIL: validate-structure — ERROR на docs/ (порог 0 ERROR, FR-220б)"
      FAILED=1
    else
      echo "OK: validate-structure: 0 ERROR (WARNING печатаются и не красят)"
    fi
  else
    echo "FAIL: uv not installed — validate-structure not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi

  echo "==> validate-comments"
  if command -v uv > /dev/null 2>&1; then
    if ! uv run plugins/gramax/scripts/validate_comments.py docs; then
      echo "FAIL: validate-comments — ERROR на docs/ (порог 0 ERROR, FR-220б)"
      FAILED=1
    else
      echo "OK: validate-comments: 0 ERROR (WARNING печатаются и не красят)"
    fi
  else
    echo "FAIL: uv not installed — validate-comments not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi

  echo "==> shellcheck"
  if command -v shellcheck > /dev/null 2>&1; then
    # tests/gramax/archive/ — замороженные свидетельства приёмки прошлых релизов
    # (BR-001, ADR-0011 Решение 1): их не редактируют, поэтому замечания shellcheck
    # там не чинимы и не значимы — исключаем каталог из проверки, а не подавляем
    # находки. grep -v не должен молча выесть весь список: если после фильтрации
    # не осталось файлов, живых .sh в репозитории не найдено — это отдельный факт,
    # с ним разбираются отдельно от "архив исключён штатно".
    ALL_SH_FILES=$(git ls-files '*.sh' 2>/dev/null || true)
    if [ -n "$ALL_SH_FILES" ]; then
      SH_FILES=$(printf '%s\n' "$ALL_SH_FILES" | grep -v '^tests/gramax/archive/' || true)
    else
      SH_FILES=""
    fi
    if [ -n "$SH_FILES" ]; then
      # -x -P SCRIPTDIR: не подавление, а починка вызова. Без них shellcheck ищет
      # `source`-цели относительно текущего каталога (тут — repo root), а не
      # каталога проверяемого скрипта, и почти каждый `source "$SCRIPT_DIR/lib/…"`
      # даёт ложный SC1091 "Not following". С флагами shellcheck идёт по source
      # и резолвит путь от файла скрипта — так, как это реально исполняется.
      # -e SC1125,SC2001,SC2016,SC2086 (qa-057 F1; с волны-4 — только файлам базиса,
      # ADR-0029 Решение 1): все четыре кода живут ТОЛЬКО в
      # базис-пиновых payload-файлах nauta (role-postflight.sh, role-preflight.sh,
      # check.sh, check-readiness.sh — замер на ad7f1a4+; файлы не редактируются,
      # «payload не трогается», ADR-0021). SC1125 — русский текст после директивы
      # disable (намеренный стиль payload-файлов); SC2001/SC2016/SC2086 — стиль/info
      # в тех же файлах, shellcheck даёт rc=1 на любую находку. Фикс вынесен вверх
      # по потоку: issue tools-ai/nauta#42 (внутренний GitLab) —
      # «payload-скрипты: битые shellcheck-директивы (SC1125 — disable не работает) +
      # стиль SC2001/SC2016/SC2086». Исключение снимается тем же коммитом синка
      # payload после релиза nauta с фиксом: убрать коды из -e ниже и прогнать
      # --full. Проектные .sh (scripts/check-gramax.sh, tests/gramax/**) зовутся
      # отдельным вызовом без -e — их находки блокирующие.
      BASIS_SH="$(sed -n 's/^  \([^:]*\.sh\): "sha256:.*/\1/p' .nauta-scripts-basis.yaml)"
      BASIS_TRACKED="$(printf '%s\n' "$SH_FILES" | grep -Fxf <(printf '%s\n' "$BASIS_SH") || true)"
      PROJECT_TRACKED="$(printf '%s\n' "$SH_FILES" | grep -Fxvf <(printf '%s\n' "$BASIS_SH") || true)"
      SHELL_BAD=0
      if [ -n "$BASIS_TRACKED" ]; then
        # shellcheck disable=SC2086
        if ! shellcheck -e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR $BASIS_TRACKED; then
          SHELL_BAD=1
        fi
      fi
      if [ -n "$PROJECT_TRACKED" ]; then
        # shellcheck disable=SC2086
        if ! shellcheck -x -P SCRIPTDIR $PROJECT_TRACKED; then
          SHELL_BAD=1
        fi
      fi
      if [ "$SHELL_BAD" -ne 0 ]; then
        echo "FAIL: shellcheck issues"
        FAILED=1
      else
        echo "OK: shellcheck clean"
      fi
    else
      echo "OK: no shell files tracked"
    fi
  else
    echo "WARN: shellcheck not installed — skipping"
  fi

  # --- 5. (--full only) orphan-references gate ---
  echo "==> orphan-references"
  if bash tests/gramax/orphan-references/run.sh; then
    echo "OK: orphan-references clean"
  else
    echo "FAIL: orphan-references gate"
    FAILED=1
  fi

  # --- 6. (--full only) nauta-integration AC suite ---
  echo "==> nauta-integration"
  if bash tests/gramax/nauta-integration/run.sh; then
    echo "OK: nauta-integration AC suite green"
  else
    echo "FAIL: nauta-integration AC suite"
    FAILED=1
  fi

  # --- 6.5. (--full only) docs-layout-invariants: живые инварианты раскладки docs/
  # (ADR-0029 Решение 2: выделенные ассерты архивной сюиты docs-migration; сразу
  # после nauta-integration, хвост cross-catalog-retraction → gate-composition
  # не трогается)
  echo "==> docs-layout-invariants"
  if bash tests/gramax/docs-layout-invariants/run.sh; then
    echo "OK: docs-layout-invariants green"
  else
    echo "FAIL: docs-layout-invariants"
    FAILED=1
  fi

  # --- 7. (--full only) plugin-contract: живые инварианты плагина ---
  echo "==> plugin-contract"
  if bash tests/gramax/plugin-contract/run.sh; then
    echo "OK: plugin-contract green"
  else
    echo "FAIL: plugin-contract"
    FAILED=1
  fi

  # --- 8. (--full only) catalog-validator: контракт validate_structure.py, догфудинг ---
  echo "==> catalog-validator"
  if bash tests/gramax/catalog-validator/run.sh; then
    echo "OK: catalog-validator green"
  else
    echo "FAIL: catalog-validator"
    FAILED=1
  fi

  # --- 8.5. (--full only) comments: контракт скриптов комментариев (ADR-0027 Решение 5;
  # validate_comments.py/parse_comments.py/gen_comment_id.py/slugify.py) ---
  echo "==> comments"
  if bash tests/gramax/comments/run.sh; then
    echo "OK: comments green"
  else
    echo "FAIL: comments"
    FAILED=1
  fi

  # --- 9. (--full only) mermaid-adoption: юрисдикция + обнаружение/миграция legacy mermaid ---
  echo "==> mermaid-adoption"
  if bash tests/gramax/mermaid-adoption/run.sh; then
    echo "OK: mermaid-adoption green"
  else
    echo "FAIL: mermaid-adoption"
    FAILED=1
  fi

  # --- 10. (--full only) writer-consumer-rules: триаж правил потребителей поверх writer ---
  echo "==> writer-consumer-rules"
  if bash tests/gramax/writer-consumer-rules/run.sh; then
    echo "OK: writer-consumer-rules green"
  else
    echo "FAIL: writer-consumer-rules"
    FAILED=1
  fi

  # --- 11. (--full only) link-form-resolver: инференс .md/_index.md в _collect_links ---
  echo "==> link-form-resolver"
  if bash tests/gramax/link-form-resolver/run.sh; then
    echo "OK: link-form-resolver green"
  else
    echo "FAIL: link-form-resolver"
    FAILED=1
  fi

  # --- 12. (--full only) link-form-migration: классификация NAV/SELF/SUBJECT + migrate_nav_codespans.py ---
  echo "==> link-form-migration"
  if bash tests/gramax/link-form-migration/run.sh; then
    echo "OK: link-form-migration green"
  else
    echo "FAIL: link-form-migration"
    FAILED=1
  fi

  # --- 13. (--full only) export-skill: контракт навыка export (ADR-0022, AC-041…AC-050) ---
  echo "==> export-skill"
  if bash tests/gramax/export-skill/run.sh; then
    echo "OK: export-skill green"
  else
    echo "FAIL: export-skill"
    FAILED=1
  fi

  # --- 14. (--full only) plantuml-bpmn: контракт навыка plantuml (ADR-0023, AC-051…AC-062) ---
  echo "==> plantuml-bpmn"
  if bash tests/gramax/plantuml-bpmn/run.sh; then
    echo "OK: plantuml-bpmn green"
  else
    echo "FAIL: plantuml-bpmn"
    FAILED=1
  fi

  # --- 15. (--full only) writer-sync-470: контракт writer 4.7.0 (AC-073…AC-096) ---
  echo "==> writer-sync-470"
  if bash tests/gramax/writer-sync-470/run.sh; then
    echo "OK: writer-sync-470 green"
  else
    echo "FAIL: writer-sync-470"
    FAILED=1
  fi

  # --- 16. (--full only) writer-tail-480: хвосты writer 4.8.0 (AC-097…AC-103) ---
  # Без run.sh по брифу изоляции потока (семь скриптов + README) — агрегация циклом
  # по glob, как в README suite'а: все скрипты прогоняются, rc — «хоть один красный».
  echo "==> writer-tail-480"
  tail480_rc=0
  for f in tests/gramax/writer-tail-480/ac-*.sh; do
    bash "$f" || tail480_rc=1
  done
  if [ "$tail480_rc" -eq 0 ]; then
    echo "OK: writer-tail-480 green"
  else
    echo "FAIL: writer-tail-480"
    FAILED=1
  fi

  # --- 17. (--full only) render-linter: киллеры рендера docs/, контракт AC-001…AC-021 ---
  echo "==> render-linter"
  if bash tests/gramax/render-linter/run.sh; then
    echo "OK: render-linter green"
  else
    echo "FAIL: render-linter suite"
    FAILED=1
  fi

  # --- 18. (--full only) render-quality: офлайн-стабы сюиты (FR-194, AC-113; ADR-0027
  # Решение 1 — живой прогон прибора вне гейта: именованный шаг
  # scripts/render-quality/live.sh релизного ритуала) ---
  echo "==> render-quality"
  if bash tests/gramax/render-quality/run.sh; then
    echo "OK: render-quality green (офлайн-стабы)"
  else
    echo "FAIL: render-quality suite"
    FAILED=1
  fi

  # --- 19. (--full only) cross-catalog-retraction: ретракция code:-рецепта 4.2.1,
  # статический контракт (ADR-0027 Решение 3: подключена к --full, офлайн, ~16 с) ---
  echo "==> cross-catalog-retraction"
  if bash tests/gramax/cross-catalog-retraction/run.sh; then
    echo "OK: cross-catalog-retraction green"
  else
    echo "FAIL: cross-catalog-retraction"
    FAILED=1
  fi

  # --- 20. (--full only) gate-composition: сторож состава гейта и текстов репозитория
  # (поправка PM к списку ADR-0027 — последним шагом, 18-я сюита) ---
  echo "==> gate-composition"
  if bash tests/gramax/gate-composition/run.sh; then
    echo "OK: gate-composition green"
  else
    echo "FAIL: gate-composition"
    FAILED=1
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "==> RESULT: FAIL"
  exit 1
fi

echo "==> RESULT: PASS"
