#!/usr/bin/env bash
# Проектный гейт gramax, профиль --full (projectGates.full, ADR-077).
exec bash "$(dirname "$0")/check-gramax.sh" --full
