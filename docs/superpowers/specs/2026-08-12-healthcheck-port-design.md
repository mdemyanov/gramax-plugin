# Spec: портирование healthcheck-логики Gramax в validate_structure.py

**Дата:** 2026-08-12
**Статус:** design-approved
**Фаза:** MVP

## Контекст

Исследование репозитория поставщика `Gram-ax/gramax` выявило движок `Healthcheck`
(`core/extensions/healthcheck/logic/Healthcheck.ts`), который проверяет контент каталога
по 7 категориям ошибок (`CatalogErrorGroups`). Наш `validate_structure.py` покрывает
структурные проверки (frontmatter, doc-root, теги, сироты), но не покрывает ресурсные
проверки (изображения, диаграммы, продвинутый резолв ссылок). Healthcheck поставщика
нельзя запустить автономно — он требует живой Gramax-стек.

**Решение:** портировать недостающие проверки из Healthcheck в наш `validate_structure.py`
как нативный Python-код + расширить тестовые фикстуры.

## Цели

1. Добавить в `validate_structure.py` проверки: images, diagrams, advanced link resolution (no-ext, hash anchors), unsupported markup
2. Выровнять таксономию ошибок с `CatalogErrorGroups` поставщика (опциональный `--groups` вывод)
3. Расширить тестовые фикстуры в `tests/gramax/catalog-validator/`

## Не-цели

- **НЕ** портировать icons/comments — у нас нет этих систем
- **НЕ** портировать content parse errors — Gramax-специфичный парсер
- **НЕ** заменять `validate_structure.py` на `gramax-cli check` — CLI требует полный стек

---

## Дизайн

### 1. Новые проверки

#### 1.1 Resource checks: images

**Что:** проверить, что все markdown-изображения `![alt](path)` ссылаются на существующие файлы.

**Как:**
- Парсим все `.md`-файлы в каталоге, извлекаем `![alt](path)` через regex
- Для каждого image path — резолвим относительно директории статьи
- Проверяем существование файла через `os.path.exists()`
- Несуществующий → `W030: Image file not found: "<path>" referenced from <article>`

**Группа в таксономии:** `images` (как в `CatalogErrorGroups`)

#### 1.2 Resource checks: diagrams

**Что:** проверить, что все `<drawio path="..."/>` ссылаются на существующие `.drawio` файлы.

**Как:**
- Ищем теги `<drawio path="..."/>` в markdown (уже есть парсинг drawio-тегов в валидаторе)
- Резолвим path, проверяем существование
- Несуществующий → `W031: Diagram file not found: "<path>" referenced from <article>`

**Группа в таксономии:** `diagrams`

#### 1.3 Advanced link resolution: no-ext

**Что:** markdown-ссылка без расширения `[text](other)` должна резолвиться в `other.md`
если самого `other` нет.

**Как:**
- При проверке ссылки `[text](target)`:
  - Пробуем `target` как есть
  - Если не найден: пробуем `target.md`
  - Если не найден: пробуем `target/index.md` (для категорий)
  - Если ничего не найдено → ошибка `W032`
- Это зеркалирует поведение Gramax при рендеринге

**Группа в таксономии:** `links`

#### 1.4 Advanced link resolution: hash anchors

**Что:** markdown-ссылка с якорем `[text](article#section)` должна указывать на существующий заголовок.

**Как:**
- При проверке ссылки с `#fragment`:
  - Резолвим целевой файл (с учётом no-ext логики)
  - Парсим заголовки из целевого файла: `^#{1,6}\s+(.+)$`
  - Slugify-сравнение: `section` → `#section`, `My Title` → `#my-title`
  - Не найден → `W033: Hash anchor "#<fragment>" not found in <target> referenced from <article>`

**Slugify-правила** (совместимо с Gramax):
- lowercase
- пробелы → дефисы
- удалить спецсимволы кроме букв/цифр/дефисов

**Группа в таксономии:** `links`

#### 1.5 Unsupported markup detection

**Что:** найти HTML-теги и нестандартную разметку, которую Gramax не поддерживает.

**Как:**
- Ищем `<[a-z]+[^>]*>` в markdown (исключая известные: `<drawio`)
- Флаг — `W034: Unsupported markup: "<tag>" in <article>`
- Это консервативная проверка: некоторые HTML-теги могут быть валидны в markdown, поэтому WARNING, не ERROR

**Группа в таксономии:** `unsupported`

### 2. Таксономия ошибок (`--groups`)

Добавляем опциональный флаг `--groups` для группированного вывода:

```python
ERROR_GROUPS = {
    "content":  [],  # C1-C5 (parse/structure/frontmatter)
    "links":    [],  # W032, W033 + существующие битые ссылки
    "images":   [],  # W030
    "diagrams": [],  # W031
    "unsupported": [], # W034
    # icons/comments — не применимо, не выводим
}
```

Без `--groups` — плоский список (обратная совместимость с CI и pre-commit).
С `--groups` — вывод по группам как в `CatalogErrorGroups`.

### 3. Тестовые фикстуры

В `tests/gramax/catalog-validator/` создаём подкаталог `gramax-fixtures/`:

| Фикстура | Проверка | Ожидаемый код |
|----------|---------|---------------|
| `broken-image/` | `![alt](nonexistent.png)` | W030 |
| `broken-diagram/` | `<drawio path="missing.drawio"/>` | W031 |
| `link-no-ext/` | `[link](other)` где `other.md` существует | OK (no error) |
| `link-no-ext-broken/` | `[link](other)` где ни `other` ни `other.md` нет | W032 |
| `link-hash/` | `[link](article#nonexistent)` | W033 |
| `link-hash-ok/` | `[link](article#existing-section)` | OK |
| `unsupported-html/` | `<div>...</div>` в статье | W034 |

Каждая фикстура:
- Минимальный каталог: `doc-root.yaml` + 1-2 `.md` статьи
- Файл `expected.txt` — ожидаемый вывод `validate_structure.py`
- Запуск как suite через `tests/gramax/catalog-validator/run.sh`

### 4. CI/CD для GitLab (отдельная задача)

Зафиксировано как follow-up. Будет отдельный ADR + план после завершения healthcheck-port.

### 5. Обратная совместимость

- Все новые проверки — **WARNING** (не ERROR), не ломают exit code
- Постепенно повысим до ERROR после обкатки
- Без `--groups` вывод идентичен текущему формату
- Существующие коды ошибок (C1-C10, W010-W029) не меняются

---

## Границы ответственности

| Что | Где |
|-----|-----|
| Парсинг markdown-ссылок | Новый модуль `plugins/gramax/scripts/lib/md_link_parser.py` |
| Резолв ссылок (no-ext, hash) | Новый модуль `plugins/gramax/scripts/lib/link_resolver.py` |
| Resource checks | В `validate_structure.py` (новые функции) |
| Таксономия + `--groups` | В `validate_structure.py` (модификация вывода) |
| Тестовые фикстуры | `tests/gramax/catalog-validator/gramax-fixtures/` |

## Риски

| Риск | Митигация |
|------|----------|
| Regex-парсинг markdown хрупкий | Покрываем фикстурами все edge cases; не трогаем существующий парсинг |
| Slugify-правила не совпадают с Gramax | Документируем как best-effort, проверяем на реальных заголовках из `content/` |
| Ложные срабатывания unsupported HTML | WARNING, не ERROR; whitelist известных паттернов |

## Spec Self-Review

- [x] Placeholder scan — нет TBD/TODO
- [x] Internal consistency — группы ошибок соответствуют CatalogErrorGroups, фикстуры покрывают все новые проверки
- [x] Scope check — 4 новые проверки + taxonomy + fixtures; не раздуто
- [x] Ambiguity check — коды ошибок зафиксированы, правила slugify специфицированы
