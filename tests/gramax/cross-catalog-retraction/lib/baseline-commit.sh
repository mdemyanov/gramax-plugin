#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/lib/baseline-commit.sh
#
# Общий базовый коммит для git-diff-проверок AC-003 и AC-008(ветка а) этого suite'а — закрывает
# открытый вопрос №5 требования (content/30-requirements/2026-08-13-cross-catalog-retraction.md):
# "Точный базовый коммит — тот, на котором создано это требование ... QA-runner обязан
# зафиксировать его явно перед стартом реализации, не выводить из догадки постфактум."
# Зафиксировано QA-author'ом (эта задача, 2026-08-13) при создании suite'а — не QA-runner
# постфактум, но по тому же принципу: явная фиксация ДО начала правок Dev/Tech-writer, не вывод
# из догадки после факта.
#
# BASELINE_COMMIT = ce4228d — единственный коммит, которым созданы содержательные материалы
# этой волны: оба требования этой волны (2026-08-13-cross-catalog-retraction.md,
# 2026-08-13-link-form-contract.md), оба ADR (0016, 0017), research-находки RES-004/005/006 и
# правка content/00-project/adr/_index.md, добавившая строку реестра для ADR-0017.
# Подтверждено `git show --stat ce4228d` (список изменённых файлов — только content/**, ни
# одного файла plugins/gramax/**) и `git log --oneline -1 -- content/30-requirements/
# 2026-08-13-cross-catalog-retraction.md` (единственный коммит истории файла). HEAD совпадал с
# ce4228d на момент написания этого suite'а (2026-08-13), до всякой правки Dev/Tech-writer —
# поэтому AC-003 и ветка (а) AC-008 сегодня зелёные тривиально (diff по определению пуст).
# shellcheck disable=SC2034  # не "забытая" переменная: этот файл — библиотека, только для source; переменная читается вызывающими ac-003/ac-008 после `source lib/baseline-commit.sh`, не в этом файле
BASELINE_COMMIT="ce4228d"
