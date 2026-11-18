#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-055-bpmn-camunda-xml-authored.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-055 (FR-143).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт
#   тегов (Q-4)» подраздел «<bpmn> — контракт docs, в движке на пине
#   отсутствует»: авторство по документированной форме (только файловая,
#   inline для bpmn не выдумывается), verify-before-include с релизным probe
#   (probe — вне suite'а этого репозитория, релизный чек-лист PM); файл-план:
#   references/plantuml-syntax.md несёт «каркас Camunda XML для .bpmn».
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Литеральна AC-055 (`head -1 | grep '<?xml'` + `bpmn:definitions|<definitions`)
# — на артефакт авторства (qa-runner); механика литералы доказывается на
# синтетическом минимальном Camunda XML во временном каталоге (mutation
# honesty по прецеденту rehearsal docs-migration: однострочность обязана быть
# исполнимой и зелёной на валидном входе). Фикстуры-образца .bpmn дизайн не
# требует (состав фикстур закрыт списком «Контракта с QA-author»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
REF_SYNTAX="$ROOT/plugins/gramax/skills/plantuml/references/plantuml-syntax.md"

# (2) Механика литералы AC-055 — ДО гейта существования: на синтетическом
# валидном Camunda XML однострочность обязана проходить (доказательство, что
# красный после гейта — отсутствие навыка, а не сломанный grep).
TMPDIR_AC55="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_AC55"' EXIT
cat > "$TMPDIR_AC55/sample.bpmn" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://bpmn.io/schema/bpmn" id="sample">
  <bpmn:process id="process-sample"/>
</bpmn:definitions>
XML
if ! head -1 "$TMPDIR_AC55/sample.bpmn" | grep -q '<?xml'; then
  echo "  FAIL: AC-055 (механика на синтетике) — первая строка .bpmn обязана быть <?xml (литераль AC-055)" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep -qiE 'bpmn:definitions|<definitions' "$TMPDIR_AC55/sample.bpmn"; then
  echo "  FAIL: AC-055 (механика на синтетике) — .bpmn обязан содержать bpmn:definitions|<definitions (литераль AC-055)" >&2
  FAIL=$((FAIL + 1))
fi

# Гейт существования предмета — красная причина stub'а.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-055: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — BPMN-авторство (Camunda XML) не реализовано (красная причина AC-055)"
  exit 1
fi

# (1) Контрактная половина: секция BPMN по документированной docs-форме (FR-143).
assert_grep_regex_i "$SKILL_MD" 'BPMN' \
  "AC-055/FR-143 — SKILL.md обязан нести секцию BPMN (скелет дизайна: «BPMN (Camunda XML)»)"
assert_grep_regex_i "$SKILL_MD" 'Camunda' \
  "AC-055/FR-143 — SKILL.md обязан называть Camunda XML (форм-фактор .bpmn)"
assert_grep_regex_i "$SKILL_MD" '\.bpmn' \
  "AC-055/FR-143 — SKILL.md обязан называть .bpmn-файл как артефакт авторства"
assert_no_grep_regex_i "$SKILL_MD" 'inline[ -]bpmn|bpmn-блок|```bpmn' \
  "AC-055/FR-143 — inline-вариант для bpmn не выдумывается (дизайн: «документированная форма — только файловая», RES-007 §3)"

# Справочник (NFR-062, файл-план дизайна): каркас Camunda XML живёт в references.
assert_file_exists "$REF_SYNTAX" \
  "AC-055/NFR-062 (файл-план дизайна) — references/plantuml-syntax.md обязан существовать (несёт каркас Camunda XML)"
assert_grep "$SKILL_MD" 'references/plantuml-syntax.md' \
  "AC-055/NFR-062 (файл-план дизайна) — SKILL.md обязан регистрировать references/plantuml-syntax.md (секция References)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-055: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-055: BPMN-контур документирован (Camunda XML, только файловая форма); механика литералы исполнена на синтетическом .bpmn"
