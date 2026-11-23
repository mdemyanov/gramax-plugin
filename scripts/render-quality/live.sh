#!/usr/bin/env bash
# scripts/render-quality/live.sh — именованный шаг живого замера рендер-проб
# (ADR-0027 docs/00-project/adr/0027-full-gate-composition.md, Решение 1: живая нога
# выведена из --full в именованный шаг релизного ритуала).
# Обёртка probe.sh с дефолтными путями прибора (конфиг цели
# scripts/render-quality/render-target.local.json, фикстуры сюиты, отчёт в results/);
# аргументы передаются насквозь (шов --config/--fixtures/--report -- для тестов).
# Гейт не зовёт этот скрипт ни в одном режиме (NFR-085: в --full нет сети, проб и токена);
# шаг ритуала: (1) --full зелёный на чистом дереве, (2) bash scripts/render-quality/live.sh —
# при выданных владельцем токене и санкции на публикацию проб, иначе в релизной заметке
# «не исполнен», (3) уборка проб. Сеть или цель недоступны — именованный отказ
# rc=2 (баннер REFUSAL <КОД>: <подсказка>, см. probe.sh/probe.py); автоматического
# офлайн-фолбэка нет (ADR-0027 Решение 2).

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec bash "$SCRIPT_DIR/probe.sh" "$@"
