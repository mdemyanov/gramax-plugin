#!/usr/bin/env bash
# tests/gramax/export-skill/ac-041-skill-surface-and-triggers.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-041 (FR-131).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт триггеров
#   (description)», «Контракт с QA-author» (хук AC-041, edge cases: негативная
#   демаркация, структурный кейс FR-132, кросс-ссылка из writer).
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: предмет проверки plugins/gramax/skills/export/SKILL.md
#   отсутствует. Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011; дизайн: unit неприменим — исполняемого кода в навыке нет).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/export/SKILL.md"
WRITER_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"
REF_TEMPLATES="$ROOT/plugins/gramax/skills/export/references/templates.md"
REF_RECIPES="$ROOT/plugins/gramax/skills/export/references/recipes.md"

# Гейт существования — до контентных грейпов: пока предмета нет, падение обязано
# называть ровно одну причину (навык не создан), а не россыпь «паттерн не найден».
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-041: SKILL.md навыка export отсутствует ($SKILL_MD) — guidance-поверхность экспорта не создана (красная причина AC-041)"
  exit 1
fi

# --- AC-041, литеральные грейпы требования ---
assert_grep_regex "$SKILL_MD" '^name: export' \
  "AC-041 — frontmatter обязан объявлять name: export (FR-131)"
assert_grep_regex_i "$SKILL_MD" 'экспорт' \
  "AC-041 — SKILL.md обязан называть «экспорт» (триггер FR-131)"
assert_grep_regex_i "$SKILL_MD" 'docx' \
  "AC-041 — SKILL.md обязан называть DOCX (триггер FR-131)"
assert_grep_regex_i "$SKILL_MD" 'pdf' \
  "AC-041 — SKILL.md обязан называть PDF (триггер FR-131)"

# --- FR-131, хук дизайна: все шесть триггерных слов обязаны жить в description ---
# (литерала AC грепает файл целиком; контракт FR-131 — именно description, целевой
# текст — дизайн §«Контракт триггеров»).
DESC="$(sed -n 's/^description:[[:space:]]*//p' "$SKILL_MD")"
if [ -z "$DESC" ]; then
  echo "  FAIL: AC-041 — во frontmatter обязана быть однострочная description (контракт триггеров, дизайн §«Контракт триггеров»)" >&2
  FAIL=$((FAIL + 1))
else
  # ${trigger} в скобках обязательно: системный bash 3.2 (macOS) сближает имя переменной
  # с первым байтом многомбайтной кавычки «» — «$trigger» парсится как несуществующая
  # переменная и под set -u роняет тест мимо ассерта (замер: /tmp/repro.sh, 2026-11-18).
  for trigger in 'экспорт' 'docx' 'pdf' 'шаблон экспорта' 'CI/CD' 'статическ'; do
    if ! printf '%s' "$DESC" | grep -qiE "$trigger"; then
      echo "  FAIL: AC-041/FR-131 — description обязан называть триггер «${trigger}»" >&2
      FAIL=$((FAIL + 1))
    fi
  done
  # Негативная демаркация (edge case дизайна): авторинг-триггеры writer в description
  # export дают ложный маршрутинг.
  if printf '%s' "$DESC" | grep -qiE 'создаёт статьи|редактирует статьи'; then
    echo "  FAIL: AC-041 (edge case дизайна) — description export не должен нести авторинг-триггеры writer («создаёт/редактирует статьи»)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Q-1 дизайна, warden: description writer не расширяется экспортными триггерами ---
# Зелёный на 9355b69 — охранная, не forced red; защищает контракт «шесть слов FR-131
# живут только в description export».
if [ -f "$WRITER_MD" ]; then
  WDESC="$(sed -n 's/^description:[[:space:]]*//p' "$WRITER_MD")"
  if [ -n "$WDESC" ] && printf '%s' "$WDESC" | grep -qiE 'экспорт|docx|pdf'; then
    echo "  FAIL: AC-041 (Q-1 дизайна, warden) — description writer не должен расширяться экспортными триггерами («экспорт/docx/pdf»)" >&2
    FAIL=$((FAIL + 1))
  fi
  # Кросс-ссылка writer → export: ровно одна строка «gramax:export» (план файлов дизайна).
  XCOUNT="$(grep -c 'gramax:export' "$WRITER_MD" 2>/dev/null || true)"
  assert_eq "$XCOUNT" "1" \
    "AC-041/FR-131 (план файлов дизайна) — writer SKILL.md обязан звать gramax:export ровно одной строкой (раздел «Ресурсы»)"
else
  assert_file_exists "$WRITER_MD" \
    "AC-041 (кросс-связка FR-131) — writer/SKILL.md обязан существовать для кросс-ссылки"
fi

# --- FR-132, структурный кейс (edge case дизайна): references/ существуют и названы ---
assert_file_exists "$REF_TEMPLATES" \
  "FR-132 (edge case дизайна) — references/templates.md обязан существовать"
assert_file_exists "$REF_RECIPES" \
  "FR-132 (edge case дизайна) — references/recipes.md обязан существовать"
assert_grep "$SKILL_MD" 'references/templates.md' \
  "FR-132 (edge case дизайна) — SKILL.md обязан регистрировать references/templates.md (секция References)"
assert_grep "$SKILL_MD" 'references/recipes.md' \
  "FR-132 (edge case дизайна) — SKILL.md обязан регистрировать references/recipes.md (секция References)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-041: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-041: skill export существует, триггеры и демаркация в description, references зарегистрированы, кросс-ссылка writer на месте"
