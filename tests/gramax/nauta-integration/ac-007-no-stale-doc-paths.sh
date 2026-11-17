#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
# Спека: спека волны nauta-integration (2026-08-07; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021) FR-10
# AC coverage:
#   AC-14 → нет ссылок на docs/adr, docs/qa-reports, docs/acceptance, docs/research
#   AC-14 → нет ссылок на четыре переехавшие спеки по мёртвым префиксам
#     docs/superpowers/specs/ (удалён FR-129, инверсия 2026-11-17, ADR-0021) и
#     content/30-requirements/ (инверсия 2026-11-17; живой адрес —
#     docs/30-requirements/). Паттерн — полные имена файлов.
#     Мёртвость обоих префиксов физическая: каталогов на дереве нет.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
PATTERN_DIRS='(docs|content)/(adr|qa-reports|acceptance|research)'
PATTERN_SPECS='(docs/superpowers/specs|content/30-requirements)/(2026-05-08-diagram-on-demand-design|2026-05-11-remove-diagram-skills|2026-05-11-routing-mermaid-drawio|2026-05-12-mermaid-file-based-design)\.md'

# scripts/ вне области: доставленные sync-scripts валидаторы — чужие файлы под управлением
# .nauta-scripts-basis.yaml (validate-content.py несёт "docs/adr/" в собственном комментарии),
# править их нельзя. Из tests/ исключены целиком suite'ы, чей предмет — сами устаревшие
# пути: они обязаны называть эти пути дословно (в ассертах их отсутствия, в README,
# в обучающих фикстурах), и находка там — не регрессия, а инструмент этого suite'а. Сейчас
# это tests/gramax/nauta-integration/ (собственные ассерты про устаревшие пути),
# tests/gramax/docs-migration/ (приёмка инверсии 2026-11-17 — её grep-паттерны легально
# несут литералы) и tests/gramax/archive/ (замороженные свидетельства приёмки прошлых
# релизов, ADR-0011 Решение 1 — шапки «Spec:» называют старые пути как предмет записи).
# Прежнее исключение tests/gramax/doc-paths/ снято: suite ретирирован
# (ADR-0021 Решение 4, FR-130). Новый такой suite добавляется в исключение по тому же
# принципу — по факту, что его предмет есть устаревшие пути, а не по факту, что он мешает
# прогону.
HITS_DIRS="$(grep -rnE "$PATTERN_DIRS" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -vE '^tests/gramax/(nauta-integration|docs-migration|archive)/' || true)"

if [ -n "$HITS_DIRS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие каталоги ((docs|content)/(adr|qa-reports|acceptance|research)):" >&2
  echo "$HITS_DIRS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

HITS_SPECS="$(grep -rnE "$PATTERN_SPECS" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -vE '^tests/gramax/(nauta-integration|docs-migration|archive)/' || true)"

if [ -n "$HITS_SPECS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие спеки (мёртвые префиксы docs/superpowers/specs/ или content/30-requirements/, инверсия 2026-11-17):" >&2
  echo "$HITS_SPECS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: ссылок на старые пути docs/ не осталось"
