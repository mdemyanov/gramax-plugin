# Рецепты запуска экспорта

Развёрнутые walkthrough'и: CLI, CI-стадия, UI, статический портал. Ядро — в `SKILL.md`.

**Граница исполнения:** каждый рецепт — инструкция окружению (Node.js + `gramax-cli` у
пользователя или в CI-раннере), а не действие агента. Агент готовит команду, шаблон или
файл стадии; навык экспорт не исполняет.

**Источники (verify-before-include).** RES-007 §1/§3; `npx gramax-cli --help`,
`npx gramax-cli export --help`, `npx gramax-cli build --help`, `npx gramax-cli --version`
(gramax-cli 1.0.54, Node v24.21.0, 2026-11-18); страницы gram.ax, выкачанные 2026-11-18:
`deploy/export-ci-cd`, `deploy/doc-portal/install/static-site-generator`,
`deploy/doc-portal/export-templates`, `collaboration/export-docx-pdf/app`,
`collaboration/export-docx-pdf` — путь указан у каждой группы фактов.

## CLI: `gramax-cli export`

Источник: `npx gramax-cli export --help` (gramax-cli 1.0.54, 2026-11-18); базовый факт
`npx gramax-cli export -f docx|pdf` — RES-007 §3.

```bash
# DOCX с шаблоном и автоматическим подтверждением
npx gramax-cli export -f docx -o artifacts/export -y -t ./my-template.docx

# PDF с титульной страницей, оглавлением, нумерацией заголовков и CSS-шаблоном
npx gramax-cli export -f pdf -o artifacts/export -y --pdf-title --pdf-toc --pdf-number -t ./template.css
```

Флаги (по `--help` 1.0.54):

| Флаг | Значение | По умолчанию |
|---|---|---|
| `-s`, `--source <path>` | путь к каталогу для экспорта | текущая директория |
| `-o`, `--output <path>` | путь сохраняемого файла | `export` |
| `-y`, `--yes` | пропуск запроса подтверждения | — |
| `-f`, `--format <string>` | формат: `docx`, `pdf`, `legacy-pdf` (временный режим совместимости, будет удалён) | `docx` |
| `-t`, `--template <string>` | путь к файлу шаблона или имя шаблона из воркспейса каталога | — |
| `--pdf-title` | титульная страница (только `pdf`) | — |
| `--pdf-toc` | оглавление (только `pdf`) | — |
| `--pdf-number` | нумерация заголовков (только `pdf`) | — |

Что выбирает `-f` — формат результирующего файла: `docx` или `pdf` (`legacy-pdf` —
обратная совместимость).

**Скоуп CLI.** `-s` указывает каталог; флагов выгрузки отдельной статьи/раздела из CLI
`--help` не документирует — скоуп статья/раздел/каталог покрывается UI-экспортом (см.
ниже). Указатель на апстрим: `deploy/export-ci-cd`.

**Расхождение форм (зафиксировано 2026-11-18).** Пример на странице `deploy/export-ci-cd`
использует `-f beta-pdf`; `npx gramax-cli export --help` версии 1.0.54 документирует
форматы `docx`, `pdf`, `legacy-pdf`. Страница docs может отставать от CLI — при
расхождении приоритет у `--help` текущей версии; рецепт выше использует верифицированную
форму `-f pdf`.

## CI: стадия `.gitlab-ci.yml`

Источник: `deploy/export-ci-cd` (gram.ax, 2026-11-18); факты стадии и `EXPORT_FILE_PATH`
также RES-007 §3. `gramax-cli` — npm-пакет, работает с файлами каталога в репозитории и
не зависит от редакции Gramax.

```yaml
stages:
  - export

variables:
  EXPORT_FILE_PATH: artifacts/export  # базовый путь/имя без расширения

export-docx:
  stage: export
  tags:
    - docker-linux-amd64
  image: node:latest                  # раннеру нужен Node.js — граница исполнения
  script:
    - npx gramax-cli export -f docx -o $EXPORT_FILE_PATH -y -t ./my-template.docx
  artifacts:
    paths:
      - artifacts

export-pdf:
  stage: export
  tags:
    - docker-linux-amd64
  image: node:latest
  script:
    - npx gramax-cli export -f pdf -o $EXPORT_FILE_PATH -y --pdf-title --pdf-toc --pdf-number -t ./template.css
  artifacts:
    paths:
      - artifacts
```

Разбор:

- `stages` — список стадий пайплайна; для экспорта используется стадия `export` (имя
  можно изменить — примеры исходят из `export`).
- `variables` — переменные окружения задач пайплайна. `EXPORT_FILE_PATH` — базовый
  путь/имя результирующего файла **без расширения**: `artifacts/export` даёт
  `artifacts/export.docx` или `artifacts/export.pdf` по выбранному `-f`.
- `image: node:latest` — раннеру нужен Node.js (`npx`); это та же граница исполнения, что
  и для локального запуска.
- `artifacts` — каталог с результатом забирается как артефакт джобы.
- `-t` необязателен: без него экспорт идёт в стандартных стилях Gramax.
- Гигиена: `EXPORT_FILE_PATH` — путь файла, не секрет; токены в рецепт не входят.

## UI: экспорт из приложения и с портала

Источник: `collaboration/export-docx-pdf/app`, `collaboration/export-docx-pdf`,
`deploy/doc-portal/export-templates` (gram.ax, 2026-11-18); скоуп статья/раздел/каталог
также RES-007 §3.

- **Весь каталог** (приложение): рядом с иконкой поиска кликнуть троеточие →
  «Экспортировать» — каталог скачается на компьютер.
- **Статья или раздел** (приложение): на статье/разделе в левой панели нажать троеточие →
  «Экспортировать».
- Скоуп — статья, раздел или весь каталог; форматы — DOCX и PDF. По умолчанию применяется
  стандартное оформление Gramax; при наличии загруженных шаблонов (воркспейс пространства
  для приложения, сервер портала для читателей портала — пути в
  `references/templates.md`) шаблон выбирается при экспорте.
- **Портал:** читатели портала документации выгружают статьи в PDF и DOCX, в том числе в
  собственных шаблонах, добавленных администратором.
- Автоматическую выгрузку при сборке продукта настраивает администратор — это рецепт CI
  выше (страница `collaboration/export-docx-pdf`).

Навык описывает путь пользователя в UI, не имитирует его действия — UI-действия агент не
выполняет.

## Статический портал: генерация через `gramax-cli`

Источник: `deploy/doc-portal/install/static-site-generator` (gram.ax, 2026-11-18);
`npx gramax-cli build --help` (1.0.54, 2026-11-18); факт «установка статическим сайтом
через gramax-cli» — RES-007 §1/§3.

Требования: Node.js 18+ (необходим для работы CLI), терминал. Установка CLI — `npm
install -g gramax-cli` (доступно из любой папки) либо разово через `npx`.

```bash
# установка (один раз)
npm install -g gramax-cli

# генерация статического сайта
gramax-cli build --source ./content --destination ./output
```

Ключевые флаги `build` (по `--help` 1.0.54 и таблице страницы docs):

| Флаг | Значение | По умолчанию |
|---|---|---|
| `-s`, `--source <path>` | путь к каталогу с контентом | текущая директория |
| `-d`, `--destination <path>` | папка результата | `./build` |
| `--skip-check` | пропустить проверки перед сборкой | `false` |
| `-l`, `--force-ui-lang-sync` | язык UI = язык контента (если локаль доступна) | `false` |
| `-f`, `--features <string>` | экспериментальные функции через запятую | — |
| `-cc`, `--custom-css <path>` | CSS-файл, подключаемый при сборке | — |
| `-dt`, `--docx-templates <path\|glob>` | DOCX-шаблоны для экспорта с сайта | — |
| `-pt`, `--pdf-templates <path\|glob>` | PDF-шаблоны для экспорта с сайта (по `--help` 1.0.54 требует включённой фичи `export-pdf`) | — |
| `--base-url <url>` | базовый URL; генерирует `sitemap.xml` и `robots.txt` | — |

Дополнительные настройки сайта (логотип, метрики, ИИ-поиск) — через `gramax.config.yaml`
в корне контента или переменные окружения; перечень — на странице
`deploy/doc-portal/install/static-site-generator` (указатель, не переизлагается).

Шаблоны экспорта на статическом сайте передаются при сборке флагами
`--pdf-templates`/`--docx-templates` (см. `references/templates.md`, раздел Placement).

**Граница навыка.** Генерация файлов сайта — рецепт выше; установка и деплой самого
портала (Docker, Helm, размещение на сервере, 404/поддиректории, сервис диаграмм
`diagram-renderer` и `DIAGRAM_RENDERER_SERVICE_URL`) — за границей: указатель на docs
`deploy/doc-portal/install/static-site-generator` и связанные страницы раздела
`deploy/doc-portal/*`.
