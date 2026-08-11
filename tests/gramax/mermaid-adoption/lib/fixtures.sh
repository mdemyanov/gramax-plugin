#!/usr/bin/env bash
# tests/gramax/mermaid-adoption/lib/fixtures.sh
# Helpers shared by ac-*.sh scripts of this suite. Каждый ac-*.sh, который вызывает
# migrate_mermaid.py в мутирующем режиме (--fix --yes) или иным образом рискует записать в
# отсканированное дерево, ОБЯЗАН работать на копии в mktemp, никогда напрямую на
# fixtures/composite — иначе один прогон испортит git-working-tree и все последующие ac-*.sh
# в этой же сессии получат уже мутированную фикстуру.

# copy_composite_fixture <script_dir>
# Копирует fixtures/composite/ (content/ + outside/) в свежий mktemp-каталог и печатает его
# путь на stdout. Вызывающий обязан подчистить каталог через `trap 'rm -rf "$WORKDIR"' EXIT`.
copy_composite_fixture() {
  local script_dir="$1"
  local workdir
  workdir="$(mktemp -d)"
  cp -R "$script_dir/fixtures/composite/." "$workdir/"
  printf '%s\n' "$workdir"
}

# generate_at_scale_fixture <dir> [count=156]
# Генерирует фикстуру масштаба AC-004: <count> файлов с уже корректными тегами
# <mermaid path="…"/> под свежим .doc-root.yaml. Не коммитится в git как статичный набор
# файлов — 156×2 (md + .mermaid) почти идентичных файлов раздули бы репозиторий без
# содержательного выигрыша; генератор сам по себе — ревьюируемый, детерминированный
# артефакт (см. README.md, раздел «Фикстура масштаба (AC-004)»). Образец масштаба —
# naumen-smp-mcp, 156 корректных тегов (NFR-051, research G5).
generate_at_scale_fixture() {
  local dir="$1" count="${2:-156}"
  mkdir -p "$dir"
  cat > "$dir/.doc-root.yaml" <<'YAML'
code: mermaid-adoption-at-scale
title: "Сгенерированная фикстура масштаба (AC-004)"
description: >-
  156 корректных тегов <mermaid path="…"/> — образец naumen-smp-mcp (NFR-051). Генерируется
  на лету generate_at_scale_fixture() (lib/fixtures.sh), не коммитится в git.
language: ru
syntax: XML

properties:
  - name: Тип контента
    type: Enum
    values:
      - Требование

filterProperties: [Тип контента]
YAML

  local i=1
  while [ "$i" -le "$count" ]; do
    cat > "$dir/page-$i.md" <<EOF
---
order: $i
title: "Сгенерированная страница $i"
properties:
  - name: Тип контента
    value: [Требование]
---

# Сгенерированная страница $i

<mermaid path="./page-$i-diagram.mermaid" width="800px" height="450px"/>
EOF
    cat > "$dir/page-$i-diagram.mermaid" <<EOF
flowchart TB
    A[Узел $i] --> B[Следующий $i]
EOF
    i=$((i + 1))
  done
}
