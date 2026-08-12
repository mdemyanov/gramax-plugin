#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-003-disposition-and-source-untouched.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-003 (FR-097).
# ADR: content/00-project/adr/0017-cross-catalog-retraction.md, Решение 1 — коррекция отдельным
#      документом (этот ADR), БЕЗ правки тела/статуса/frontmatter диспозиции и исходного
#      требования.
#
# Диапазон коммитов (открытый вопрос №5 требования) — см. lib/baseline-commit.sh.
#
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания (HEAD == BASELINE_COMMIT, diff пуст по
# определению) и обязан ОСТАВАТЬСЯ зелёным весь TDD-цикл: Dev касается только
# plugins/gramax/skills/writer/**, content/40-architecture/_index.md (аннотация) — не
# тела/статуса/frontmatter диспозиции/исходного требования. Если этот тест покраснеет в
# процессе Dev-фазы — это САМО по себе дефект (BR-001), а не сигнал «функциональность ещё не
# реализована».

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/baseline-commit.sh"

FAIL=0
DISPOSITION="content/40-architecture/2026-08-11-writer-rules-disposition.md"
SOURCE_REQ="content/30-requirements/2026-08-11-writer-consumer-rules.md"

# Позитивное предусловие: оба файла обязаны существовать на BASELINE_COMMIT — иначе `git diff`
# на несуществующий путь тихо ничего не покажет (0 строк) ПО ПРИЧИНЕ отсутствия файла, не по
# факту «ничего не менялось». Пустой diff на несуществующий путь — та же ловушка «пустой ввод ⇒
# молчаливый PASS», что и в content/lessons-learned.md (2026-08-11, xargs на пустом stdin).
for f in "$DISPOSITION" "$SOURCE_REQ"; do
  if ! git -C "$ROOT" cat-file -e "$BASELINE_COMMIT:$f" 2>/dev/null; then
    echo "  FAIL: AC-003 — файл $f не существует на baseline $BASELINE_COMMIT — diff не может служить содержательной проверкой" >&2
    FAIL=$((FAIL + 1))
  fi
done

if [ "$FAIL" -eq 0 ]; then
  if ! git -C "$ROOT" diff --quiet "$BASELINE_COMMIT"..HEAD -- "$DISPOSITION" "$SOURCE_REQ"; then
    echo "  FAIL: AC-003 — диспозиция и/или исходное требование изменены после $BASELINE_COMMIT (нарушение BR-001/FR-097)" >&2
    git -C "$ROOT" diff --stat "$BASELINE_COMMIT"..HEAD -- "$DISPOSITION" "$SOURCE_REQ" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: диспозиция и исходное требование побайтово не тронуты с $BASELINE_COMMIT (regression guard)"
