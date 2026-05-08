---
name: comments-write
description: Добавление, ответы, редактирование, удаление комментариев Gramax в файлах документации. Используй при запросах "добавь комментарий", "ответь на комментарий", "напиши замечание", "оставь комментарий", "write comment", "reply to comment".
---

# Gramax Comments Write

Операционный workflow для работы с комментариями Gramax: add / reply / edit / delete.

## Триггеры

- "добавь комментарий"
- "оставь комментарий к документу"
- "напиши замечание"
- "ответь на комментарий"
- "write comment"
- "reply to comment"

## Использование

```
# Добавить
/gramax:comments-write <md> --add "текст" --anchor "фрагмент"

# Ответить
/gramax:comments-write <md> --reply <id> "текст ответа"

# Редактировать
/gramax:comments-write <md> --edit <id> "новый текст"

# Удалить
/gramax:comments-write <md> --delete <id>
```

## Формат комментариев Gramax

### В `.md`

**Inline-комментарий** (привязан к фрагменту текста):
```markdown
Текст с <comment id="wworI">выделенным фрагментом</comment> продолжение.
```

**Block-комментарий** (привязан к блоку):
```markdown
[comment:abc12]

Блок текста с комментарием.

[/comment]
```

### `.comments.yaml` (рядом с md)

Именование: `{basename}.comments.yaml` (`_index.md` → `_index.comments.yaml`).

```yaml
GaRkQ:
  comment:
    dateTime: '2026-04-01T10:00:00.000Z'
    user:
      mail: author@example.com
      name: Имя Автора
    content: 'Текст комментария'
  answers:
    - user:
        mail: reviewer@example.com
        name: Имя Рецензента
      dateTime: '2026-04-01T11:00:00.000Z'
      content: >-
        Многострочный текст ответа
```

## Workflow

```
1. PARSE      → Определить операцию (add/reply/edit/delete)
2. VALIDATE   → Проверить существование файлов и якорей
3. GENERATE   → Сгенерировать ID (для add), подготовить данные
4. CONFIRM    → Показать превью и получить подтверждение пользователя
5. WRITE      → Записать изменения в md и yaml
6. VERIFY     → Запустить validate_comments.py
```

## Данные автора

При первой операции записи в сессии спроси у пользователя имя и email:

> Для комментария нужны данные автора. Укажи email и имя (например: `ivan@company.ru Иван Петров`)

Используй эти данные для всех последующих комментариев/ответов в текущей сессии.

## Операция 1: Добавить (add)

### Вход
- `md_file` — путь к `.md`
- `anchor` — фрагмент текста в документе (для inline) или блок (для block)
- `comment_text` — текст комментария
- автор (имя + email)

### Шаги

**Шаг 1: Сгенерировать ID**

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/gen_comment_id.py --check <basename>.comments.yaml
```

Если yaml не существует — запускай без `--check`.

**Шаг 2: Найти anchor в md**

Используй Grep для поиска фрагмента в файле.

- Если найден → обернуть `<comment id="XXXXX">фрагмент</comment>`
- Если не найден → предложить пользователю:
  1. Указать другой фрагмент
  2. Использовать block-формат `[comment:XXXXX]...[/comment]`

**Шаг 3: Показать превью**

```
## Превью комментария
**Файл:** path/to/page.md
**ID:** XXXXX
**Привязка:** "фрагмент текста"
**Автор:** Имя (email)
**Комментарий:** текст комментария

Добавить комментарий? (y/n)
```

**Шаг 4: Записать**

1. **В md:** обернуть anchor тегом `<comment id="XXXXX">anchor</comment>`
2. **В `.comments.yaml`:** добавить блок:

```yaml
XXXXX:
  comment:
    dateTime: '{current_iso8601}'
    user:
      mail: email@example.com
      name: Имя
    content: 'Текст комментария'
  answers: []
```

Если yaml не существует — создать новый файл.

**Получение текущей ISO 8601 даты:**

```bash
python3 -c "from datetime import datetime, timezone; now=datetime.now(timezone.utc); print(now.strftime('%Y-%m-%dT%H:%M:%S.') + f'{now.microsecond // 1000:03d}Z')"
```

**Шаг 5: Верификация**

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py <md_file>
```

Exit 0 → всё хорошо. Exit 1 → показать ошибки и предложить откат.

## Операция 2: Ответить (reply)

### Вход
- `comment_id` — ID существующего комментария
- `reply_text` — текст ответа
- автор

### Шаги

1. Прочитать `.comments.yaml`, убедиться что `comment_id` существует
2. Показать превью:

```
## Превью ответа
**Комментарий ID:** XXXXX
**Исходный комментарий:** "текст оригинала"
**Автор ответа:** Имя (email)
**Ответ:** текст ответа

Добавить ответ? (y/n)
```

3. Добавить элемент в `answers`:

```yaml
    - user:
        mail: email@example.com
        name: Имя
      dateTime: '{current_iso8601}'
      content: >-
        Текст ответа на комментарий
```

4. Запустить `validate_comments.py` для верификации.

## Операция 3: Редактировать (edit)

### Вход
- `comment_id` — ID
- `new_text` — новый текст

### Шаги

1. Найти блок в `.comments.yaml` по ID
2. Заменить **только** `content` на новый текст
3. **НЕ менять** `dateTime` и `user` (они фиксируют оригинального автора и время)

## Операция 4: Удалить (delete)

### Вход
- `comment_id` — ID

### Шаги

1. Показать превью того, что будет удалено
2. Получить подтверждение
3. В md: убрать тег `<comment id="XXXXX">...</comment>` **оставив текст внутри** (или `[comment:XXXXX]...[/comment]` — оставить текст)
4. В yaml: удалить ключ `XXXXX`
5. Если yaml стал пустым — удалить файл целиком
6. Запустить `validate_comments.py`

## Правила YAML-форматирования

### content в одинарных кавычках

Для простого текста без переносов:
```yaml
content: 'Простой текст комментария'
```

Если текст содержит одинарные кавычки — экранируй их удвоением:
```yaml
content: 'Текст с ''кавычками'' внутри'
```

### content с `>-` (folded block scalar)

Для длинного или многострочного текста:
```yaml
content: >-
  Длинный текст комментария, который
  занимает несколько строк и будет
  объединён в один абзац при парсинге.
```

### dateTime

Всегда в ISO 8601 UTC, в одинарных кавычках:
```yaml
dateTime: '2026-04-19T10:30:00.000Z'
```

## Валидация после каждой операции

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py <md_file>
```

Проверяет:
1. Каждый `<comment id>` в md имеет ключ в yaml и наоборот
2. ID уникальны в пределах страницы
3. ID соответствует `^[a-zA-Z0-9]{5}$`
4. YAML парсится
5. Обязательные поля присутствуют (`dateTime`, `user.mail`, `user.name`, `content`)

## Обработка ошибок

| Ситуация | Действие |
|----------|----------|
| Anchor не найден в md | Предложить альтернативный фрагмент или block-формат |
| ID уже существует | `gen_comment_id.py --check` сгенерирует другой |
| YAML невалиден | Показать ошибку, не записывать |
| `.comments.yaml` в read-only зоне | Предупредить, предложить работать в копии |
| `validate_comments.py` exit 1 после записи | Показать ошибки, предложить откат последнего изменения |

## Связанные skill-ы

- `gramax:comments-read` — чтение и отчёт по комментариям
- `gramax:writer` — создание и редактирование документов Gramax
