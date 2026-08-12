#!/usr/bin/env bash
# scripts/check.sh — light pre-commit/pre-merge gate для gramax-marketplace.
# Без profile-валидаторов (профилей нет). Валидатор content/ — из nauta,
# доставлен через /nauta:sync-scripts, обновляется тем же каналом.
#
# Modes:
#   --fast   : whitespace + JSON validity + validate-content.py (uv обязателен; для pre-commit hook)
#   --full   : --fast + shellcheck (если установлен) + проверка submodule status +
#              tests/gramax/orphan-references + tests/gramax/nauta-integration +
#              tests/gramax/plugin-contract + tests/gramax/doc-paths +
#              tests/gramax/catalog-validator + tests/gramax/mermaid-adoption +
#              tests/gramax/writer-consumer-rules + tests/gramax/link-form-resolver +
#              tests/gramax/link-form-migration
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

# --- 2.5. Gramax content/ validation (валидатор nauta, PEP 723) ---
echo "==> content"
if [ -d content ]; then
  if command -v uv > /dev/null 2>&1; then
    if ! uv run scripts/validate-content.py; then
      echo "FAIL: content/ validation"
      FAILED=1
    else
      echo "OK: content validated"
    fi
  else
    echo "FAIL: uv not installed — content/ validation not performed (install: https://docs.astral.sh/uv/)"
    FAILED=1
  fi
else
  echo "OK: no content/ directory"
fi

# --- 3. (--full only) Shellcheck on tracked .sh files, if installed ---
if [ "$MODE" = "--full" ]; then
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
      # shellcheck disable=SC2086
      if ! shellcheck -x -P SCRIPTDIR $SH_FILES; then
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

  # --- 4. (--full only) Submodule status ---
  echo "==> submodule status"
  if git submodule status 2>&1 | grep -q '^[+-]'; then
    echo "WARN: submodule out of sync (not a hard fail)"
    git submodule status
  else
    echo "OK: submodules in sync"
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

  # --- 7. (--full only) plugin-contract: живые инварианты плагина ---
  echo "==> plugin-contract"
  if bash tests/gramax/plugin-contract/run.sh; then
    echo "OK: plugin-contract green"
  else
    echo "FAIL: plugin-contract"
    FAILED=1
  fi

  # --- 8. (--full only) doc-paths: нет нерабочих docs/-указателей в content/ ---
  echo "==> doc-paths"
  if bash tests/gramax/doc-paths/run.sh; then
    echo "OK: doc-paths clean"
  else
    echo "FAIL: doc-paths gate"
    FAILED=1
  fi

  # --- 9. (--full only) catalog-validator: контракт validate_structure.py, догфудинг ---
  echo "==> catalog-validator"
  if bash tests/gramax/catalog-validator/run.sh; then
    echo "OK: catalog-validator green"
  else
    echo "FAIL: catalog-validator"
    FAILED=1
  fi

  # --- 10. (--full only) mermaid-adoption: юрисдикция + обнаружение/миграция legacy mermaid ---
  echo "==> mermaid-adoption"
  if bash tests/gramax/mermaid-adoption/run.sh; then
    echo "OK: mermaid-adoption green"
  else
    echo "FAIL: mermaid-adoption"
    FAILED=1
  fi

  # --- 11. (--full only) writer-consumer-rules: триаж правил потребителей поверх writer ---
  echo "==> writer-consumer-rules"
  if bash tests/gramax/writer-consumer-rules/run.sh; then
    echo "OK: writer-consumer-rules green"
  else
    echo "FAIL: writer-consumer-rules"
    FAILED=1
  fi

  # --- 12. (--full only) link-form-resolver: инференс .md/_index.md в _collect_links ---
  echo "==> link-form-resolver"
  if bash tests/gramax/link-form-resolver/run.sh; then
    echo "OK: link-form-resolver green"
  else
    echo "FAIL: link-form-resolver"
    FAILED=1
  fi

  # --- 13. (--full only) link-form-migration: классификация NAV/SELF/SUBJECT + migrate_nav_codespans.py ---
  echo "==> link-form-migration"
  if bash tests/gramax/link-form-migration/run.sh; then
    echo "OK: link-form-migration green"
  else
    echo "FAIL: link-form-migration"
    FAILED=1
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "==> RESULT: FAIL"
  exit 1
fi

echo "==> RESULT: PASS"
