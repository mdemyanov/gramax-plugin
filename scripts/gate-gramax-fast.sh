#!/usr/bin/env bash
# Проектный гейт gramax, профиль --fast (projectGates.fast, ADR-077).
exec bash "$(dirname "$0")/check-gramax.sh" --fast
