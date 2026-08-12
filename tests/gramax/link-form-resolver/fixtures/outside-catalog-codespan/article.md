---
order: 1
title: "Статья с код-спаном вне каталога"
---

Реализация валидатора — `plugins/gramax/scripts/validate_structure.py` (упомянут
код-спаном, не markdown-ссылкой, FR-084) — путь физически не существует внутри этой
фикстуры (в ней нет каталога `plugins/`). Код-спан не резолвится как markdown-ссылка
(`_mask_code` вырезает его до сканирования `_collect_links`) и не попадает ни в
`check_broken_links`, ни в `check_orphans` (AC-012, граница FR-084/BR-005).
