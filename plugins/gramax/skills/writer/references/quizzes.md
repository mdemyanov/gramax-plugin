# Вопрос-блоки и тесты (`quiz`)

Элемент «вопрос» задаётся в теле статьи парой тегов `<question>` (вопрос) и
`<questionAnswer>` (вариант ответа). Режим прохождения (тест или опрос) и поведение
проверки — frontmatter-ключ `quiz` статьи. Результаты прохождения (баллы, ответы
пользователей, статистика) — серверная сторона модуля обучения GES: вне этого
справочника, writer документирует только авторский синтаксис.

Источники помечены по строкам: «engine» — чтение исходника движка на пине
`48592b36` (`путь:строка`), «docs» — документация gram.ax (RES-007).

## `<question>` — вопрос

```markdown
<question id="q-main" type="one" required="true">

Столица Франции?

<questionAnswer answerId="paris" correct="true">Париж</questionAnswer>
<questionAnswer answerId="lyon">Лион</questionAnswer>

</question>
```

| Атрибут | Тип | Дефолт | Назначение | Источник |
|---------|-----|--------|------------|----------|
| `id` | String | — | Идентификатор вопроса | engine (`question.ts:5-12`) |
| `type` | String | `one` | Тип вопроса (см. перечень ниже) | engine (`question.ts:5-12`, дефолт — `questionSchema.ts:7-13`) |
| `required` | Boolean | `false` | Обязательный вопрос | engine (`questionSchema.ts:7-13`) |

Имена тегов — camelCase, обязательны ровно в этой форме: `<question>`,
`<questionAnswer>` — реестр контентных тегов движка регистрирует именно эти имена
(`getTagElementRenderModels.ts:115-116`).

## `<questionAnswer>` — вариант ответа

Вкладывается внутрь `<question>`; текст между открывающим и закрывающим тегом —
надпись варианта.

| Атрибут | Тип | Назначение | Источник |
|---------|-----|------------|----------|
| `answerId` | String | Идентификатор ответа (на него ссылается `showIf`) | docs |
| `correct` | Boolean | Пометка правильного ответа | docs |

Engine-дополнение: схема ответа читает также атрибуты `questionId` и `type`
(`answer.ts:5-13`) — в новом контенте не нужны: связь ответа с вопросом задаётся
вложением в `<question>`.

## Двенадцать типов вопросов

Перечень `one`, `many`, `select`, `text`, `date`, `user`, `number`, `slider`,
`scale`, `rating`, `ranking`, `matrix` — источник docs (RES-007 §3):

| Тип | Назначение (docs) |
|-----|-------------------|
| `one` | Один вариант из списка (дефолт) |
| `many` | Несколько вариантов |
| `select` | Выпадающий список |
| `text` | Свободный текст |
| `date` | Дата |
| `user` | Пользователь |
| `number` | Число |
| `slider` | Ползунок |
| `scale` | Шкала |
| `rating` | Оценка |
| `ranking` | Ранжирование |
| `matrix` | Матрица |

Engine-пометка (обязательна): парсер движка принимает любую строку `type` без
enum-валидации; рендер-модуль OSS-движка на пине покрывает `one` / `many` / `text`
(`question/types.ts:5`, `answer/types.ts:3`) — остальные типы рендерятся
серверной стороной GES, в OSS-дереве движка их нет. Полный набор типов и условия
показа — поверхность модуля обучения GES.

Пример на несколько типов (включая рабочий с `correct`):

```markdown
<question id="q-colors" type="many" required="true">

Какие цвета считаются основными? (несколько вариантов)

<questionAnswer answerId="red" correct="true">Красный</questionAnswer>
<questionAnswer answerId="green">Зелёный</questionAnswer>
<questionAnswer answerId="blue" correct="true">Синий</questionAnswer>

</question>

<question id="q-year" type="text">

В каком году вышла первая версия?

</question>
```

## Условие показа `showIf`

Атрибут `showIf` у `<question>` — список `answerId`: вопрос показывается только
если в предыдущих вопросах даны указанные ответы (ветвление анкеты).

```markdown
<question id="q-followup" type="text" showIf="paris">

Что вы знаете о Париже?

</question>
```

Источник — docs (RES-007 §3); в OSS-дереве движка на пине не найден — поверхность
модуля обучения GES.

## Frontmatter `quiz` — режим и поведение

Ключ `quiz` ставится во frontmatter статьи с вопросами (ключ статьи — engine:
`Article.ts:50`):

```yaml
---
order: 1
title: "Проверка знаний"
quiz:
  showAnswers: true
  canRetake: true
  countOfCorrectAnswers: 2
---
```

| Ключ | Тип | Назначение | Источник |
|------|-----|------------|----------|
| `showAnswers` | Boolean | Показывать правильные ответы после прохождения | engine (`quiz/models/types.ts:4-10`) |
| `canRetake` | Boolean | Разрешить повторное прохождение | engine (`quiz/models/types.ts:4-10`) |
| `countOfCorrectAnswers` | Number | Порог правильных ответов | engine (`quiz/models/types.ts:4-10`) |
| `mode` | `test` / `survey` | Режим: тест (с оценкой) или опрос (без оценки) | docs; в OSS-дереве не найден — поверхность GES |
| `shuffleQuestions` | Boolean | Перемешивать вопросы | docs; в OSS-дереве не найден — поверхность GES |

Результаты прохождения — серверная сторона GES (панель, PostgreSQL, рассылка) —
вне этого справочника.
