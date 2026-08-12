#!/usr/bin/env bash
# tests/gramax/link-form-migration/lib/fixtures.sh
# Helpers shared by ac-*.sh scripts of this suite. Каждый ac-*.sh, который вызывает
# migrate_nav_codespans.py в мутирующем режиме (--fix --yes) или иным образом рискует записать
# в отсканированное дерево, ОБЯЗАН работать на копии в mktemp, никогда напрямую на
# fixtures/composite/ — иначе один прогон испортит git-working-tree и все последующие ac-*.sh
# в этой же сессии получат уже мутированную фикстуру (по прецеденту
# tests/gramax/mermaid-adoption/lib/fixtures.sh).

# copy_composite_fixture <script_dir>
# Копирует fixtures/composite/ (content/) в свежий mktemp-каталог и печатает его путь на
# stdout. Вызывающий обязан подчистить каталог через `trap 'rm -rf "$WORKDIR"' EXIT`.
copy_composite_fixture() {
  local script_dir="$1"
  local workdir
  workdir="$(mktemp -d)"
  cp -R "$script_dir/fixtures/composite/." "$workdir/"
  printf '%s\n' "$workdir"
}
