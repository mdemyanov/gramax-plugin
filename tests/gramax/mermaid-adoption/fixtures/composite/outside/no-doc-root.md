# Инженерный документ вне юрисдикции content/

Пример по образцу `mango-cti-rest/content/70-operations/network-prerequisites.md` (research
G5) — инженерный документ вне поддерева, находящегося под `.doc-root.yaml` (FR-050). У этого
файла нет `.doc-root.yaml`-предка ни в своей директории, ни выше — инлайн mermaid здесь не
является нарушением плагина (BR-001) и не должен появляться в отчёте обнаружения (FR-055).

```mermaid
flowchart LR
    Plan --> Execution
```
