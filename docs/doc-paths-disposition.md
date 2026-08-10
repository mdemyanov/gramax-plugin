# Диспозиция 55 упоминаний `docs/`-путей внутри `content/`

Замер: `grep -rnE 'docs/(adr|qa-reports|acceptance|research|lessons-learned|superpowers/specs)' content/`
Дата замера: 2026-08-09, HEAD = c6f15ec. Итого 55 в 20 файлах.

Критерий разделения — **роль предложения**, не каталог:

- **POINTER** — путь есть указатель, по которому читателя приглашают перейти
  (trace-шапки `**Spec:**`/`**ADR:**`, футеры «Ссылки», проза «Spec `…` описывает фичу»).
  Такой путь ведёт в пустоту → чиним.
- **RECORD** — путь внутри записи о том, что было выполнено или решено на тот момент
  (процитированная команда, таблица найденных hits с вердиктами, список исключений
  на дату решения, рекомендация как она была сформулирована). Замена пути здесь
  переписывает запись → сохраняем дословно.

**Итого: 41 POINTER (чиним) / 14 RECORD (сохраняем).**

## Карта переездов (для POINTER)

| Старый префикс | Новый |
|---|---|
| `docs/adr/` | `content/00-project/adr/` |
| `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` | `content/30-requirements/2026-05-08-diagram-on-demand-design.md` |
| `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` | `content/30-requirements/2026-05-11-remove-diagram-skills.md` |
| `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` | `content/30-requirements/2026-05-11-routing-mermaid-drawio.md` |
| `docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md` | `content/30-requirements/2026-05-12-mermaid-file-based-design.md` |
| `docs/qa-reports/` | `content/60-implementation/test-reports/` |
| `docs/acceptance/` | `content/60-implementation/acceptance/` |
| `docs/research/` | `content/10-domain/research/` |
| `docs/lessons-learned.md` | `content/lessons-learned.md` |

Все целевые файлы проверены на существование (2026-08-09).

Осторожно: `docs/superpowers/specs/2026-05-08-apply-project-template-design.md` и
`…/2026-08-07-nauta-integration-design.md` остаются в `docs/` — это мета-артефакты о самом
репозитории. Под замер они не попадают (имена не входят в паттерн), но при массовой замене
префикса их легко задеть. Замена только по полным именам файлов, не по префиксу `docs/superpowers/specs/`.

---

## POINTER — чиним (41)

### content/lessons-learned.md
| Строка | Текст | → |
|---|---|---|
| 39 | `**ADR:** docs/adr/0010-mermaid-file-based-workflow.md` | `content/00-project/adr/…` |

### content/00-project/adr/0001-diagram-on-demand-plugin-split.md
| 19 | проза: «Spec `docs/superpowers/specs/2026-05-08-…md` вводит два движка» | `content/30-requirements/…` |
| 83 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md (open question #1)` | `content/30-requirements/…` |

### content/00-project/adr/0002-drawio-mcp-backend-selection.md
| 90 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |

### content/00-project/adr/0003-drawio-backend-vendoring-strategy.md
| 92 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md (FR-011, AC-009)` | `content/30-requirements/…` |

### content/00-project/adr/0004-router-and-engine-selection.md
| 100 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |

### content/00-project/adr/0005-save-flow-script-api-contract.md
| 195 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |

### content/00-project/adr/0006-marketplace-json-semver-strategy.md
| 75 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |

### content/00-project/adr/0007-out-of-scope-phase2.md
| 88 | футер: `- spec: docs/superpowers/specs/2026-05-08-…md (раздел Out of Scope)` | `content/30-requirements/…` |

### content/00-project/adr/0008-drop-internal-drawio-skills.md
| 23 | проза: «Spec `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` формулирует семь вопросов» | `content/30-requirements/…` |
| 237 | trace: `**Spec:** docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` | `content/30-requirements/…` |
| 238 | trace (self): `**ADR:** docs/adr/0008-…md` | `content/00-project/adr/…` |
| 325 | футер: `- spec: docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 326 | футер: `- research: docs/research/2026-05-11-drawio-skill-external.md` | `content/10-domain/research/…` |

### content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md
| 19 | проза: «Spec `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` описывает фичу» | `content/30-requirements/…` |
| 360 | trace: `**Spec:** docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 361 | trace (self): `**ADR:** docs/adr/0009-…md` | `content/00-project/adr/…` |
| 380 | футер: `- spec: docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 381 | футер: `- дополняет: docs/adr/0008-…md` | `content/00-project/adr/…` |
| 382 | футер: `- reconciles (в части OQ-001): docs/adr/0004-…md` | `content/00-project/adr/…` |
| 383 | футер: `- применяет semver-policy: docs/adr/0006-…md` | `content/00-project/adr/…` |

### content/00-project/adr/0010-mermaid-file-based-workflow.md
| 19 | проза: «Spec `docs/superpowers/specs/2026-05-12-…md` описывает фичу» | `content/30-requirements/…` |
| 234 | trace: `**Spec:** docs/superpowers/specs/2026-05-12-…md` | `content/30-requirements/…` |
| 235 | trace (self): `**ADR:** docs/adr/0010-…md` | `content/00-project/adr/…` |
| 314 | футер: `- spec: docs/superpowers/specs/2026-05-12-…md` | `content/30-requirements/…` |
| 316 | футер: `- применяет semver-policy: docs/adr/0006-…md` | `content/00-project/adr/…` |
| 317 | футер: `- supersedes …: docs/adr/0009-…md` | `content/00-project/adr/…` |
| 318 | футер: `- предшествующий контекст: docs/adr/0008-…md` | `content/00-project/adr/…` |

### content/30-requirements/ (trace-футеры, ссылка документа на самого себя)
| 2026-05-08-diagram-on-demand-design.md:237 | `**Spec:** docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |
| 2026-05-11-remove-diagram-skills.md:171 | `**Spec:** docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 2026-05-11-remove-diagram-skills.md:190 | `**Spec:** docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 2026-05-11-routing-mermaid-drawio.md:192 | `**Spec:** docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 2026-05-12-mermaid-file-based-design.md:148 | `**Spec:** docs/superpowers/specs/2026-05-12-…md` | `content/30-requirements/…` |

### content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md
| 14 | `**Spec:** docs/superpowers/specs/2026-05-08-…md` | `content/30-requirements/…` |
| 15 | `**QA Report:** docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md` | `content/60-implementation/test-reports/…` |

### content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md
| 15 | `Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` | `content/30-requirements/…` |
| 16 | `ADR: docs/adr/0008-…md` | `content/00-project/adr/…` |
| 17 | `QA: docs/qa-reports/2026-05-11-remove-diagram-skills-qa-report.md` | `content/60-implementation/test-reports/…` |

### content/60-implementation/acceptance/2026-05-11-routing-mermaid-drawio.md
| 14 | `**Spec:** docs/superpowers/specs/2026-05-11-…md` | `content/30-requirements/…` |
| 15 | `**ADR:** docs/adr/0009-…md` | `content/00-project/adr/…` |
| 16 | `**QA Report:** docs/qa-reports/2026-05-11-routing-mermaid-drawio.md` | `content/60-implementation/test-reports/…` |

---

## RECORD — сохраняем дословно (14)

Каждая строка попадает в allowlist гейта `tests/gramax/doc-paths/` с указанной причиной.

### content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md
| Строка | Что это | Почему сохраняем |
|---|---|---|
| 270 | «Файлы, требующие правки (кроме `docs/adr/` и `docs/superpowers/` — исторический контекст)» | Список исключений на дату решения. Замена пути превратила бы решение ADR в утверждение о сегодняшней раскладке каталогов. |

### content/60-implementation/acceptance/2026-05-11-remove-diagram-skills-acceptance.md
| 52 | Ячейка вердикта AC-016: «orphan-hits только в разрешённых исторических локациях (ADR-архив, `docs/research`, `docs/superpowers/specs`)» | Запись о том, где приёмка допустила hits **в тот прогон**. Это свидетельство, а не указатель. |
| 92 | «Рекомендую PM инициировать append в `docs/lessons-learned.md`» | Рекомендация в той формулировке, в какой была вынесена. |

### content/60-implementation/test-reports/2026-05-11-remove-diagram-skills-qa-report.md
| 60 | `docs/acceptance/2026-05-08-…md` — архив прошлого acceptance | Перечень найденных при скане локаций с классификацией. Свидетельство прогона. |
| 61 | `docs/qa-reports/2026-05-08-…md` — архив прошлого QA | То же. |
| 62 | `docs/adr/0001-0007*.md` — история ADR | То же. Плюс glob-паттерн, а не путь к файлу. |
| 63 | `docs/research/` — research outputs | То же. |
| 64 | `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/lessons-learned.md` — историческая документация | То же. |

### content/60-implementation/test-reports/2026-05-11-routing-mermaid-drawio.md
| 72 | Дословно процитированная выполненная команда: `grep -r "claude-mermaid" … --exclude-dir="docs/adr" --exclude-dir="docs/superpowers" -l` | Команда была выполнена **именно так**. Правка пути сделала бы отчёт ложным описанием собственного метода. |
| 83 | Строка таблицы hits: `docs/lessons-learned.md` → «Допустимо (lessons-journal)» | Таблица найденного с вердиктами. Свидетельство. |
| 84 | `docs/qa-reports/2026-05-11-…md` → «Допустимо (архив)» | То же. |
| 85 | `docs/qa-reports/2026-05-08-…md` → «Допустимо (архив)» | То же. |
| 86 | `docs/acceptance/2026-05-11-…md` → «Допустимо (архив)» | То же. |
| 87 | `docs/acceptance/2026-05-08-…md` → «Допустимо (архив)» | То же. |

---

## Замечание о хрупкости allowlist

Allowlist по `file:line` съезжает при любой правке выше по файлу. Из 14 записей 12 лежат в
двух отчётах и одном acceptance — файлах, которые по своей природе больше не редактируются
(записи о состоявшемся прогоне). Оставшиеся 2 (`adr/0009:270`, `acceptance:52`, `acceptance:92`)
— в документах со статусом Accepted.

Тем не менее гейт обязан падать внятно: при несовпадении содержимого строки с ожидаемым
он должен сообщать «allowlist устарел: строка N в файле F больше не содержит ожидаемого
паттерна», а не молча пропускать. Это требование к реализации гейта (см. AC в спеке).
