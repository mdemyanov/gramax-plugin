---
name: export
description: "Экспорт документации Gramax в DOCX/PDF и сборка статического портала. Используй когда пользователь просит: «выгрузи/экспортируй статью, раздел или каталог в DOCX/PDF», «сделай шаблон экспорта», «настрой оформление PDF или DOCX», «поставь экспорт в CI/CD», «собери каталог статическим порталом». Навык инструктирует и готовит артефакты: CSS-шаблон PDF (классы .page, .title-page, колонтитулы), шаблон DOCX (.docx/.dotx, авторство в Word), размещение шаблонов на портале (assets/pdf, assets/word), команду npx gramax-cli export -f docx|pdf, стадию .gitlab-ci.yml с EXPORT_FILE_PATH. Граница исполнения: запуск требует Node.js и gramax-cli в окружении пользователя или CI-раннера — навык экспорт не исполняет. Не для правки контента статей → gramax:writer; не для диаграмм → gramax:mermaid / gramax:drawio."
---

# Экспорт DOCX/PDF: шаблоны, CI/CD, статический портал

Guidance-навык: инструктирует и готовит артефакты — CSS-шаблон PDF, инструкцию по шаблону
DOCX, текст CI-стадии, команды к исполнению. Сам экспорт исполняют окружение пользователя
или CI-раннер: навык экспорт не исполняет.

## When to use

- «выгрузи/экспортируй статью, раздел или каталог в DOCX/PDF»
- «сделай шаблон экспорта», «настрой оформление PDF или DOCX»
- «поставь экспорт в CI/CD»
- «собери каталог статическим порталом»
- «куда положить шаблоны экспорта» (placement)

**Не для:** правки контента статей → `gramax:writer`; диаграмм → `gramax:mermaid` /
`gramax:drawio`; установки и деплоя портала (Docker/Helm, GES) — навык даёт только рецепт
генерации статического сайта и указатель на документацию.

## Граница исполнения

Граница исполнения: запуск экспорта требует Node.js и gramax-cli в окружении пользователя
или CI-раннера — навыком не гарантируется. Агент в сессии без Node.js инструктирует
пользователя и готовит артефакты.

| Действие | Навык (агент в сессии) | Окружение (пользователь / CI-раннер) |
|---|---|---|
| Авторство CSS-шаблона PDF | да — пишет CSS-файл по требованиям пользователя | — |
| Авторство шаблона DOCX | нет — бинарный Word-формат; навык даёт инструкцию (`.docx`/`.dotx`, авторство в Word) | пользователь в Word |
| Локальный CLI-экспорт | нет — готовит команду к исполнению | `npx gramax-cli export -f docx\|pdf` |
| CI-стадия | да — готовит текст стадии копируемым блоком | раннер с Node.js исполняет |
| Загрузка шаблонов на портал | нет — инструкция placement (`assets/pdf`, `assets/word`) | пользователь / админ портала |
| Статический портал | нет — рецепт генерации + указатель на docs | пользователь; установка и деплой портала — вне навыка |
| UI-экспорт | нет — описывает путь пользователя, не имитирует действия | пользователь в UI приложения/портала |

## Шаблоны экспорта

### PDF — CSS-файл

Шаблон PDF — CSS-файл: шрифты, поля, колонтитулы, правила печати. Документированные классы:
`.page` — базовый класс всех страниц; `.title-page` — титульная страница (контейнеры
колонтитулов `.title-page-top` / `.title-page-bottom`, заголовок `h1.title-page-header`);
колонтитулы остальных страниц — контейнеры `.page-top` / `.page-bottom` с ячейками
`.page-top-left`, `.page-top-right`, `.page-bottom-left`, `.page-bottom-right`; содержимое —
`.page-content`; страница оглавления — `.toc-page`. Подключение к экспорту — флаг `-t`
(`--template`) команды `gramax-cli export`: путь к CSS-файлу или имя шаблона из воркспейса.
Полный список классов, CSS-переменные (`--title`, `--pdf-min-scale`, `--pdf-split-scale`) и
селекторы элементов → `references/templates.md`.

### DOCX — `.docx`/`.dotx`, авторство в Word

Шаблон DOCX — файл `.docx` или `.dotx`, авторство в Word: агент бинарный Word-формат не
авторит, навык даёт инструкцию. Обязательные элементы: плейсхолдер `{{gramax_content}}` в
месте вставки контента и стили списков `OrderedList`, `BulletList`, `TaskList` — без них
экспорт контента со списками завершается ошибкой. Библиотека стилей Word и шаги авторства →
`references/templates.md`.

### Placement: где живут шаблоны

Ветки placement различаются по формату: PDF → `assets/pdf`, DOCX → `assets/word`. Для
приложения шаблон кладётся в воркспейс пространства (`.workspace/assets/pdf` |
`.workspace/assets/word`); на портале файл добавляет администратор (Docker —
`[ROOT_PATH]/.workspace/…`, Helm — `/app/data` в контейнере); при сборке статического сайта
пути передаются флагами `--pdf-templates` / `--docx-templates` команды `gramax-cli build`.
Точные пути → `references/templates.md`.

## Рецепты запуска

### CLI (локально)

```bash
npx gramax-cli export -f docx|pdf
```

`-f` выбирает формат результата: `docx` (по умолчанию) или `pdf`. Сопровождающие флаги:
`-s` — каталог-источник (по умолчанию текущая директория), `-o` — путь результата,
`-y` — без запроса подтверждения, `-t` — шаблон (путь или имя из воркспейса). CLI работает
с каталогом целиком; выгрузка отдельной статьи/раздела делается в UI (см. ниже).

### CI (стадия `.gitlab-ci.yml`)

```yaml
stages:
  - export

variables:
  EXPORT_FILE_PATH: artifacts/export  # базовый путь/имя без расширения → artifacts/export.docx|.pdf

export-docx:
  stage: export
  image: node:latest                  # раннеру нужен Node.js — граница исполнения
  script:
    - npx gramax-cli export -f docx -o $EXPORT_FILE_PATH -y -t ./my-template.docx
  artifacts:
    paths:
      - artifacts

export-pdf:
  stage: export
  image: node:latest
  script:
    - npx gramax-cli export -f pdf -o $EXPORT_FILE_PATH -y --pdf-title --pdf-toc --pdf-number -t ./template.css
  artifacts:
    paths:
      - artifacts
```

`EXPORT_FILE_PATH` — базовый путь/имя результирующего файла без расширения. Раннер обязан
иметь Node.js (`npx`). Разбор полей и вариации → `references/recipes.md`.

### UI (приложение и портал)

Путь пользователя: в приложении весь каталог — троеточие рядом с иконкой поиска →
«Экспортировать»; статья или раздел — троеточие на элементе в левой панели →
«Экспортировать». Скоуп — статья, раздел или каталог; формат — DOCX или PDF; по умолчанию
применяются стандартные стили Gramax, при наличии загруженных шаблонов шаблон выбирается
при экспорте. Читатели портала тоже выгружают статьи в PDF/DOCX. Навык описывает путь, не
имитирует действия пользователя.

### Статический портал

Генерация статического сайта каталога через `gramax-cli`:

```bash
npx gramax-cli build --source ./content --destination ./output
```

Требуется Node.js 18+. Установка и деплой самого портала (Docker/Helm, размещение на
сервере) — за границей навыка: указатель на docs
(`deploy/doc-portal/install/static-site-generator`). Ключевые флаги сборки →
`references/recipes.md`.

## Терминология

Каталог, статья, раздел, `.doc-root.yaml` — по глоссарию `gramax:writer`; собственных имён
навык не вводит. «Шаблон экспорта» — файл оформления выгрузки (CSS для PDF,
`.docx`/`.dotx` для DOCX), не «шаблон статьи» writer (`.gramax/templates/`).

## References

- `references/templates.md` — авторство шаблонов: полный список CSS-классов PDF, переменные
  и селекторы элементов; обязательные элементы и библиотека стилей Word для DOCX; пути
  placement (приложение / портал Docker/Helm / статический сайт) с различием веток pdf/word.
- `references/recipes.md` — walkthrough'и рецептов: флаги и форматы CLI, полная CI-стадия,
  путь UI-экспорта, генерация и настройка статического сайта.

### Источники фактов (verify-before-include)

- RES-007 §3 (`docs/10-domain/research/2026-11-18-enterprise-server-skill-gap.md`): скоуп
  статья/раздел/каталог, классы `.page`/`.title-page`/колонтитулы, `.docx`/`.dotx`,
  `assets/pdf`/`assets/word`, стадия `.gitlab-ci.yml` с `EXPORT_FILE_PATH`, статический
  портал через `gramax-cli`.
- Верифицировано Dev 2026-11-18: `npx gramax-cli --help`, `npx gramax-cli export --help`,
  `npx gramax-cli build --help`, `npx gramax-cli --version` (gramax-cli 1.0.54, Node
  v24.21.0); страницы gram.ax `collaboration/export-docx-pdf`,
  `…/add-custom-template/pdf`, `…/add-custom-template/docx`, `…/app`, `deploy/export-ci-cd`,
  `deploy/doc-portal/export-templates`, `deploy/doc-portal/install/static-site-generator`.
  Пофактные источники записаны в `references/`.
