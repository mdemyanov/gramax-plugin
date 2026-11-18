---
title: "RES-007: Пробелы покрытия навыков плагина gramax против документации gram.ax (enterprise-server view)"
order: 9
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Active]
  - name: Плагин
    value: [gramax]
---

# RES-007: Пробелы покрытия навыков плагина gramax против документации gram.ax (enterprise-server view)

**Дата:** 2026-11-18. **Метод:** живой сайт `https://gram.ax/resources/docs/?view=enterprise-server` (HTTP 200) → sitemap `…/api/sitemap/docs` (163 русских URL) → выкачка всех 163 страниц (SSR-HTML, ошибок нет — пометок «not fetched» нет). Параметр `?view=enterprise-server` обрабатывается клиентом: дерево навигации совпадает с общим каталогом, различаются варианты внутри статей (табы «Облако / Энтерпрайз / Open Source»; наблюдение на `quick-start`). Fallback на GitHub-движок не понадобился. Сопоставление — плагин 4.6.0: пять SKILL.md навыков целиком, review-agent, скрипты валидации, справочники writer. Гейты внешних источников не применялись: gram.ax — первичный источник документации собственного продукта (детали выкачки — §5). Второй проход (тот же день) выполнен по полным текстам уже выкачанных страниц — повторной выкачки не было.

Ниже: (1) инвентарь областей, (2) карта покрытия, (3) непокрытые области со scope-заметками, (4) факты о пересечениях, (5) источники. Только факты; кандидаты на реализацию выводит PM.

## 1. Инвентарь областей документации

База URL: `https://gram.ax/resources/docs/` — все пути в таблицах указаны относительно неё. Разделы повторяют навигацию сайта; количество страниц — по факту выкачки.

### Быстрый старт (4 стр.)

| Область | Путь |
|---|---|
| Быстрый старт (обзор; варианты Облачная / Open Source / Энтерпрайз) | `quick-start` |
| Войти в приложение | `quick-start/sign-in` |
| Создать каталог | `quick-start/create-catalog` |
| Поделиться с командой (приглашение, роли Редактор/Читатель) | `quick-start/share` |

### Приложение (10 стр.)

| Область | Путь |
|---|---|
| Приложение (обзор; где хранятся каталоги по версиям) | `app` |
| Десктопная версия (вход, открытие ссылок, страница загрузок) | `app/desktop-editor` |
| Браузерная версия (поддерживаемые браузеры, хранение каталогов) | `app/web-editor` |
| Настройки (обзор) | `app/settings` |
| Настройки → Основные (язык, тема, сжатие изображений, сервисы) | `app/settings/general` |
| Настройки → Сжатие изображений (кодирование в WEBP) | `app/settings/image-compression` |
| Настройки → Ключи и пароли (токены/логины/пароли для ИИ-агента) | `app/settings/keys-and-passwords` |
| Настройки → Автообновление (частота проверки, каналы) | `app/settings/auto-updates` |
| Настройки → Диагностика (уровень логирования, экспорт логов) | `app/settings/logging` |
| Настройки → Сравнение (подсветка правок в тексте) | `app/settings/content-comparison` |

### Пространство (24 стр.)

| Область | Путь |
|---|---|
| Пространство (обзор по версиям) | `space` |
| Настройки пространства / организации | `space/settings` |
| Роли и доступы | `space/user-roles` |
| Лицензии и матрица доступов (лицензия нужна только редакторам) | `space/licenses` |
| Группы пользователей (собственные группы, архив) | `space/user-groups` |
| Внешние читатели (вход по одноразовому коду из письма, SMTP) | `space/external-readers` |
| Отображение каталогов (панель администрирования: каталоги для редактирования, базовые) | `space/catalog-management` |
| Общие материалы (общие фрагменты/шаблоны/скиллы на пространство) | `space/workspace-tools` |
| Проверки по стайлгайду (LanguageTool XML + LLM-правила, Gramax Check) | `space/styleguide` |
| Обучение (обзор: тесты и опросы в статьях) | `space/module-training` |
| Обучение → Создание теста, Типы вопросов, Опрос, Рассылка результатов, Прохождение теста, Просмотр результатов | `space/module-training/{create-test, question-types, survey, mailing, take-test, results}` (6 стр.) |
| Метрики (обзор: просмотры, визиты, оценки статей) | `space/module-metrics` |
| Метрики → Включить модуль, История посещений, Поисковые запросы (CTR) | `space/module-metrics/{setup, history, search-queries}` (3 стр.) |
| Уведомления (об изменениях статьи, по группам) | `space/notifications` |
| Стили приложения (CSS) | `space/css-styles` |
| Группировка каталогов (разделы, папки, Избранное) | `space/sections` |
| Виджеты на главной (текстовый блок, HTML, iframe) | `space/home-widgets` |

### Каталог (17 стр.)

| Область | Путь |
|---|---|
| Каталог (обзор) | `catalog` |
| Создание каталога | `catalog/create-new` |
| Загрузка каталога (из пространства / Git) | `catalog/load-existing` |
| Настройка каталога (обзор) | `catalog/settings` |
| Настройка → Основные параметры (название, логотип, стиль, язык) | `catalog/settings/main-parameters` |
| Настройка → Кнопки действия (`relatedLinks` в конфигурации) | `catalog/settings/action-buttons` |
| Настройка → Файл конфигурации `.doc-root.yaml` (пример со всеми ключами) | `catalog/settings/doc-root-yaml` |
| Миграция из других систем (обзор) | `catalog/migration` |
| Миграция → Confluence, Notion, Yandex Wiki | `catalog/migration/{confluence, notion, yandex-wiki}` (3 стр.) |
| Мультиязычность (20 языков, папки с кодом языка) | `catalog/multilanguage` |
| Версионирование (ветки/теги как версии, glob-паттерны) | `catalog/versioning` |
| Представление каталога (сохранённые фильтры и переменные) | `catalog/catalog-view` |
| Проверка на ошибки (статьи, ссылки, элементы, диаграммы, шапки, иконки; уровни в панели админ.) | `catalog/error-check` |
| История каталога (ревизии, сравнение) | `catalog/history` |
| Заметки (в репозитории, не на портале) | `catalog/notes` |

### Статья (31 стр.)

| Область | Путь |
|---|---|
| Статья (обзор) | `article` |
| Оформление (обзор редактора) | `article/editor` |
| Оформление → Форматирование текста (заголовки, списки, жирный) | `article/editor/text-formatting` |
| → Изображения (PNG/JPEG/GIF, до 500MB, масштаб, обтекание) | `article/editor/images` |
| → Ссылки (относительные с автообновлением, на заголовок, абсолютные) | `article/editor/links` |
| → Таблицы (markdown + фильтрация и сортировка в UI) | `article/editor/tables` |
| → Примечания (оформления, скрываемый текст-спойлер, цитата) | `article/editor/notes` |
| → Блок кода (блок/строка, подсветка по языку) | `article/editor/code` |
| → Видео (YouTube/Rutube/Google Drive/Dropbox/Mega; файл до 500MB; LFS; конвертация в MP4) | `article/editor/video` |
| → Файлы (любой формат; просмотр DOCX/PDF в статье) | `article/editor/files` |
| → Диаграммы (Diagrams.net/Draw.io, Mermaid, PlantUML, BPMN; «Mermaid в стиле Gramax» для gantt/flowchart/sequence; Макеты интерфейса PlantUML Salt) | `article/editor/diagrams` |
| → ИИ-редактирование (помечено «больше не развивается», замена — ИИ-агент) | `article/editor/ai-edit` |
| → Синтаксис и структура исходных файлов (полный синтаксис + готовые скиллы `gramax-skills.zip` для Claude Code) | `article/editor/syntax` |
| → Другие элементы (обзор) | `article/editor/other-elements` |
| → Другие элементы → Подсветка текста (`[color:hex]`), Типографические замены | `article/editor/other-elements/{colored-text, typography}` (2 стр.) |
| → Другие элементы → Иконки (Lucide + собственные `.icons/`), Формулы, Вкладки | `article/editor/other-elements/{icons, formulas, tabs}` (3 стр.) |
| → Другие элементы → Кнопки и метки (`[cmd:]`, `[kbd:]`), Фрагменты | `article/editor/other-elements/{buttons-and-labels, fragments}` (2 стр.) |
| → Другие элементы → HTML-компоненты, Описание API (OpenAPI, `$ref`) | `article/editor/other-elements/{html-component, open-api}` (2 стр.) |
| Шаблоны статей (в каталоге и на пространстве) | `article/templates` |
| Иерархия (вложенность до 8, перенос группами) | `article/hierarchy` |
| URL статьи (адрес = путь файла; изменение) | `article/url` |
| Поисковые фразы | `article/search-phrases` |
| Свойства (типы: Числовой, Флаг, Один/Несколько из списка, Дата, Текст) | `article/properties` |
| Представления и отчеты (Список/Доска/Таблица/Гант; «Отчет» в меню каталога) | `article/view` |
| История статьи (кто и что правил, подсветка правок) | `article/change-history` |
| Ширина статьи (настройка вида, не записывается в файл) | `article/article-width` |

### Хранилище (8 стр.)

| Область | Путь |
|---|---|
| Хранилище (обзор по версиям; Git-команды через кнопки UI) | `storage` |
| GitLab (с 14 версии), GitHub, GitVerse, Gitea, Другие (Bitbucket, Gogs, GitFlic) | `storage/{gitlab, github, gitverse, gitea, other-git-storages}` (5 стр.) |
| Аутентификация по токену (права токенов GitLab/Gitea) | `storage/access-token` |
| Git LFS (бинарные файлы в S3 хранилища) | `storage/git-lfs` |

### Совместная работа (13 стр.)

| Область | Путь |
|---|---|
| Совместная работа (обзор) | `collaboration` |
| Синхронизация (git pull через UI) | `collaboration/sync` |
| Публикация (git commit + push, выбор статей, автокомментарий) | `collaboration/publish` |
| Решение конфликтов (обе версии в статье) | `collaboration/resolve-conflicts` |
| Ветки (создание/переключение/слияние в UI) | `collaboration/branches` |
| Ревью и согласование (утверждающие, роли) | `collaboration/merge-request` |
| Комментарии (привязка к фрагменту, ответы, «решён», режим ревью с фильтрами) | `collaboration/comments` |
| Ссылка на статью (поделиться ссылкой на редактор) | `collaboration/review-link` |
| Экспорт в PDF и DOCX (обзор; CI/CD — отдельная статья) | `collaboration/export-docx-pdf` |
| Экспорт → Настройка шаблона (обзор; PDF как CSS-классы; DOCX как `.docx`/`.dotx` в Word); Экспорт в приложении и на портале | `collaboration/export-docx-pdf/{add-custom-template, add-custom-template/pdf, add-custom-template/docx, app}` (4 стр.) |

### ИИ-агент (5 стр.)

| Область | Путь |
|---|---|
| ИИ-агент (обзор; доступен в облаке и GES) | `agent` |
| Как включить (облако: AI-кредиты; GES: настройка ИИ-сервиса) | `agent/enable` |
| Работа в чате (транскрипция аудио, сессии, веб-поиск) | `agent/chat` |
| Инструменты и ограничения (чтение/создание статей, PDF/DOCX/XLSX, ветки, откат, HTTP с токенами; «закоммитить или опубликовать агент не может») | `agent/tools` |
| Скиллы (`.gramax/agent/skills`, скилл = статья; встроенные скиллы; `.gramax/agent/system-prompt.md`) | `agent/skills` |

### Поиск (3 стр.)

| Область | Путь |
|---|---|
| Поиск (обзор) | `search` |
| Поиск по тексту (Ctrl+/, фильтры, поиск по вложениям) | `search/text-search` |
| ИИ-поиск на портале документации (по смыслу, таблицы) | `search/ai-search` |

### Разворачивание и настройка (47 стр.)

Путь каждого подраздела GES начинается с `deploy/gramax-enterprise-server/`, портала — с `deploy/doc-portal/` (ниже — суффиксы).

| Область | Путь |
|---|---|
| Раздел (обзор: Энтерпрайз vs Open Source пути) | `deploy` |
| GES: обзор (состав комплекса, архитектура с Caddy, порядок работы) | `deploy/gramax-enterprise-server` |
| GES: требования (лицензия, `registry.gram.ax`, GitLab, домены) | `…/requirements` |
| GES: установка (обзор) | `…/install` |
| GES: установка Docker Compose (состав сервисов) | `…/install/docker-compose` |
| GES: установка в режиме Readonly (read-only ФС) | `…/install/readonly` |
| GES: установка Helm (обзор) | `…/install/helm` |
| GES: Helm quickstart (репозиторий чарта, values) | `…/install/helm/quickstart` |
| GES: Helm секреты (registry, чувствительные, TLS) | `…/install/helm/secret` |
| GES: Helm системные значения (CPU/память, Ingress) | `…/install/helm/system-values` |
| GES: SSO (`AUTH_METHOD` azure/adfs/keycloak/openid/ldap/kerberos, `CONNECTOR_TYPE`, `/sso/cb`) | `…/connection-sso` |
| GES: первый запуск (7 YAML настроек, владельцы из `GES_ADMIN_EMAILS`) | `…/first-run` |
| GES: настройка после установки (обзор) | `…/setup` |
| GES: база данных (PostgreSQL; метрики, обучение, поиск, токены) | `…/setup/database` |
| GES: ИИ-функции (ИИ-поиск, ИИ-агент, стайлгайд) | `…/setup/ai-ges` |
| GES: логирование (default/cef, Seq, Elasticsearch) | `…/setup/logging` |
| GES: проект для общих материалов (GitLab) | `…/setup/workspace-tools` |
| GES: обслуживание (обзор) | `…/operations` |
| GES: обновление (тег latest, автомиграции БД) | `…/operations/upgrade` |
| GES: резервное копирование (GitLab vs сервер) | `…/operations/backup` |
| GES: healthcheck (`HEALTHCHECK_TOKEN`) | `…/operations/healthchecks` |
| GES: мониторинг Prometheus (`/metrics`) | `…/operations/metrics` |
| GES: подпись образов (публичный ключ) | `…/operations/image-signature` |
| GES: переменные окружения (сводная; `DIAGRAM_RENDERER_SERVICE_URL` и др.) | `…/environment-variables` |
| Портал: обзор (в GES входит в комплекс) | `deploy/doc-portal` |
| Портал: установка (обзор: Docker / Helm / статический сайт) | `…/install` |
| Портал: Docker (обзор) | `…/install/docker` |
| Портал: Docker на собственном сервере (от 1 ГБ RAM) | `…/install/docker/deploy-docportal-on-own-server` |
| Портал: Docker в Yandex Cloud | `…/install/docker/deploy-on-yandex-cloud` |
| Портал: панель администратора `/admin` | `…/install/docker/administration` |
| Портал: Helm (Deployment, Secret, PVC, Ingress, HPA) | `…/install/helm` |
| Портал: статический сайт (`gramax-cli`) | `…/install/static-site-generator` |
| Портал: обновление контента (обзор) | `…/content-updates` |
| Портал: обновление по расписанию (`AUTO_PULL_*`) | `…/content-updates/autopull` |
| Портал: обновление по webhook (GitHub/GitLab) | `…/content-updates/webhook` |
| Портал: передача контента по API | `…/content-updates/api` |
| Портал: API-токен (`…/api/user/token`) | `…/content-updates/api-token` |
| Портал: логотип каталога / кнопка «На главную» | `…/logo-and-go-to-site` |
| Портал: индексация (sitemap.xml, robots.txt, `DISABLE_SEO`) | `…/indexing-in-search-engines` |
| Портал: веб-аналитика (Matomo и др.) | `…/metrics` |
| Портал: CSS-стили портала | `…/css-styles` |
| Портал: `workspace.yaml` на портале | `…/workspace-settings` |
| Портал: шаблоны экспорта (`assets/pdf`, `assets/word`) | `…/export-templates` |
| Портал: публикация в облако («не развивается») | `…/cloud-gramax` |
| Браузерная версия на своём сервере (`gramax/editor`, `git-proxy`, Podman) | `deploy/web-editor-on-own-server` |
| ИИ в Open Source (`docportal-ai` + Qdrant, `editor-ai`) | `deploy/ai-open-source` |
| Экспорт DOCX/PDF в CI/CD (`gramax-cli export`) | `deploy/export-ci-cd` |

### Что нового (1 стр.)

| Область | Путь |
|---|---|
| Что нового (release notes движка/редакций) | `whats-new` |

## 2. Карта покрытия

Вердикты: «покрыт» — синтаксис/структура/формат файла области воспроизведены в плагине; «частично» — покрыта часть документированной функциональности (что именно — в комментарии); «не покрыт» — в плагине нет ни одного навыка/скрипта на тему. Пунктир «—» — покрывающего компонента нет.

| Область документации | Вердикт | Покрытие |
|---|---|---|
| Быстрый старт (4 стр.) | не покрыт | — |
| Приложение → Настройки (общие, сжатие, автообновление, диагностика, сравнение) | не покрыт | — |
| Приложение → Ключи и пароли | частично | writer: `references/blocks.md` §Формулы — синтаксис плейсхолдера `${key.field}` (`login\|password\|token\|url`) в тексте статьи (4.6.0, RES-006). Сам раздел настроек приложения и подстановка токенов агентом — нет |
| Приложение → Десктопная/браузерная версия | не покрыт | — |
| Пространство → Настройки, Роли, Лицензии, Группы, Внешние читатели, Отображение каталогов | не покрыт | — |
| Пространство → Общие материалы (уровень пространства) | не покрыт | — (фрагменты уровня каталога — см. строку «Фрагменты» ниже) |
| Пространство → Проверки по стайлгайду | не покрыт | — Правила хранятся на сервере (панель), обмен — файлом настроек `LanguageToolRules.json` (экспорт/импорт; внутри — правила LanguageTool XML и LLM-промпты) |
| Пространство → Обучение (7 стр.) | не покрыт | Вопрос-блок — элемент исходника статьи (`<question type="…" required="true">` с `<questionAnswer answerId="…" correct="true">`; типы `one, many, select, text, date, user, number, slider, scale, rating, ranking, matrix`; условие показа `showIf`), режим тест/опрос — frontmatter `quiz` (`mode: test\|survey`, `showAnswers`, `canRetake`, `shuffleQuestions`, `countOfCorrectAnswers`). Writer этот элемент не упоминает ни в SKILL.md, ни в references (проверено grep). Результаты — только серверные: панель GES, PostgreSQL |
| Пространство → Метрики (4 стр.) | не покрыт | — |
| Пространство → Уведомления | не покрыт | — |
| Пространство → CSS-стили (приложения и портала) | не покрыт | — |
| Пространство → Группировка каталогов, Виджеты на главной | не покрыт | — |
| Каталог → Создание / Загрузка | не покрыт | — |
| Каталог → Настройка → Основные параметры | частично | writer: `references/doc-root-schema.md` — корневые ключи `title`, `description`, `language`, `syntax`, `code`, `style`, `supportedLanguages`, `properties`, `filterProperties`, `editors`; ключи `logo`, `order` из страницы docs в справочнике отсутствуют |
| Каталог → Настройка → Кнопки действия (`relatedLinks`) | не покрыт | — (ключ `relatedLinks` в `doc-root-schema.md` отсутствует) |
| Каталог → Настройка → `.doc-root.yaml` | частично | Полная таблица ключей на синтаксис-странице: `logo`/`logo_dark` (формы `icon:<код>`, `emoji:<символ>`), палитра `style` из 20 значений, `syntax: XML \| Legacy \| GitHub Flavored Markdown`, `filterProperty` (одиночный id), `versions`, `relatedLinks`, `lfs: {auto, exclude}`, `hidden`, служебные `name`/`repositoryName`/`sourceName`/`userInfo`. writer покрывает подмножество с расхождениями — см. §4 |
| Каталог → Миграция (Confluence/Notion/Yandex Wiki) | не покрыт | — |
| Каталог → Мультиязычность | частично | writer: ключи `language`, `supportedLanguages`. Синтаксис-страница: структура папки языка повторяет основную один-в-один, `order`/`properties` перевода должны совпадать с оригиналом, файл перевода без `title` считается непереведённым, разделы нельзя называть кодами языков — в writer нет |
| Каталог → Версионирование | не покрыт | Ключ `versions` (шаблоны веток/тегов) подтверждён полной таблицей синтаксиса; подстановка версии в контент — через привязку вкладок `<property id="…" value="…"/>`. writer не покрывает |
| Каталог → Представление каталога (фильтры+переменные навигации) | не покрыт | Представления — файловые: хранятся в `.gramax/views` (страница области и синтаксис-страница); writer не упоминает |
| Каталог → Проверка на ошибки | частично | офлайн-аналоги: `validate_structure.py` (frontmatter, `_index.md`, битые ссылки, плейсхолдеры, сироты) и `validate_render.py` (рендер-киллеры). Модуль проверок приложения, уровни «Ошибка/Предупреждение» в панели админ., проверка иконок `.icons/` и диаграмм — нет |
| Каталог → История каталога, Заметки | не покрыт | Заметки хранятся в репозитории; синтаксис-страница связывает личные заметки пользователей с `.gramax/inbox`, состояние ревью — с `.gramax/mr` (обе папки — «не редактировать») |
| Статья → Форматирование текста | не покрыт | — (базовый markdown writer не переизлагает) |
| Статья → Изображения | частично | writer: markdown `![](){width height}` и XML `<image crop objects float>`. Не покрыты: `scale` (ширина на странице; по синтаксису `width`/`height` — реальный размер файла, см. §4) и `<gallery>` (карусель/плитка, до 10 медиа) |
| Статья → Ссылки | частично | Каноническая форма по синтаксису — относительный путь **с** расширением `.md`; writer документирует форму **без** `.md` (валидатор W032 резолвит обе). Якоря заголовков `{#install}` и автопревью вложений в ссылке — в writer нет |
| Статья → Таблицы | покрыт | writer: `references/blocks.md` — таблицы в 3 синтаксисах; `<th>`-киллер в `validate_render.py`. Сортировка/фильтрация как UI-поведение рендера — вне синтаксиса |
| Статья → Примечания | покрыт | writer: `references/blocks.md` — 8 типов note (`tip/info/hotfixes/quote/lab/note/warning/danger`), атрибут `collapsed` (спойлер), markdown-admonitions `:::`, правило пустых строк |
| Статья → Блок кода | не покрыт | — (выделенного раздела о код-блоках в writer нет) |
| Статья → Видео | частично | writer: SKILL.md таблица блоков — mp4/webm/ogg, YouTube (shorts/live/таймкоды/плейлисты), Rutube, Google Drive, Instagram. Синтаксис-страница называет те же хостинги плюс Dropbox, Mega и «любую ссылку со словом embed», атрибуты `title`/`scale`/`cover` — в writer их нет; лимит 500MB и конвертация в MP4 — нет |
| Статья → Файлы | частично | writer: ссылка на вложение с расширением (рендер как файл-ссылка, gh#675). Встроенный просмотр DOCX/PDF в статье — нет |
| Статья → Диаграммы | частично | mermaid: 8 типов, file-based; drawio: делегация, тег `<drawio/>`. Синтаксис-страница дополнительно документирует inline-блоки ` ```mermaid ` и ` ```plant-uml ` с опциями `{title, scale, float}` (в mermaid-навыке inline — устаревший формат для миграции, см. §4), теги `<plant-uml path>` и `<bpmn>` (`.bpmn`, Camunda XML, только файлом) — не покрыты |
| Статья → ИИ-редактирование | не покрыт | — (фича в docs помечена неразвиваемой; заменена ИИ-агентом) |
| Статья → Синтаксис и структура исходных файлов | частично | writer покрывает ядро (структура каталога, базовый frontmatter `order`/`title`/`properties`, основные теги, валидаторы). Полный справочник синтаксиса на странице шире writer — перечень непокрытого в §3 (строка «Элементы и поля полного синтаксиса») и §4. Факт: docs распространяют готовые скиллы (`gramax-skills.zip`) и содержат «Чек-лист для скилла» — тематический аналог writer |
| Статья → Подсветка текста | покрыт | writer: `<color>`, `[color:hex]`, `<highlight>` |
| Статья → Типографические замены | не покрыт | — (автозамены при наборе — поведение редактора) |
| Статья → Иконки | частично | writer: `<icon code="lucide-*"/>`, Lucide-иконки в `properties.icon`. Собственные SVG-иконки (папка `.icons/` рядом с `.doc-root.yaml`, проверка в `catalog/error-check`) — нет |
| Статья → Формулы | покрыт | writer: `references/blocks.md` §Формулы — `$…$`, правило «`${…}` — подстановка, не формула», синтаксис `${key.field}` (4.6.0) |
| Статья → Вкладки | покрыт | writer: `<tabs>/<tab>` |
| Статья → Кнопки и метки | частично | Формы расходятся: страница элемента даёт `[cmd:Это кнопка]`, `[kbd:Ctrl+Z]`; синтаксис-страница — `<cmd text="…" icon="…" />`, `<kbd text="Ctrl+S" />`, `<alfa />`, `<beta />`. writer документирует только скобочную форму |
| Статья → Фрагменты | не покрыт | Формат расходится: docs (`article/editor/syntax`) — файл `.gramax/fragments/<id>.md`, теги `<fragment id="…"/>` и `<fragment-link id>текст</fragment-link>`; writer — `<snippet id="…"/>` из `.gramax/snippets/` (термин «snippets» в выкачанных docs не встречается). Какая форма поддерживается текущим движком — не устанавливалось |
| Статья → HTML-компоненты | покрыт | writer: `<html>` |
| Статья → Описание API (OpenAPI) | частично | writer: `<openapi src="./api.yaml"/>`. Синтаксис-страница добавляет `showSchemas="true"`, `showInfo="false"` и формат JSON (страница области называет только YAML); `$ref`-подгрузка и выполнение запросов — не описаны |
| Статья → Шаблоны | не покрыт | Шаблоны лежат в `.gramax/templates/<id>.md`; статья с frontmatter `template: <id>` собственного текста в файле не хранит (собирается из шаблона; синтаксис-страница запрещает агентам править такой текст). writer шаблоны не упоминает |
| Статья → Иерархия | покрыт | writer: `references/structure.md` — операции со структурой, правило `_index.md`, порядок `order` |
| Статья → URL | частично | Адрес = путь файла; при переносе/переименовании движок записывает старый путь в frontmatter `aliases` (список путей без `.md` относительно корня контента; при ручном переименовании — добавить самому). writer: нейминг (slugify.py), поле `aliases` не описано |
| Статья → Поисковые фразы | не покрыт | Ключ хранится в frontmatter статьи: `searchPhrases:` (список фраз; пример на синтаксис-странице). Эффект — подъём статьи в поиске по тексту; регистр не важен, срабатывание по части слова (`article/search-phrases`). В frontmatter-покрытии writer ключ отсутствует |
| Статья → Свойства | частично | Исходные имена типов по синтаксис-странице: `Flag`, `Enum`, `Many`, `Text`, `Numeric`, `Date`; в frontmatter значение пишется по `id` (Flag — только id, Date — ISO 8601); опция `options.docportalVisible: true`. writer описывает `Enum`/`String` с `name`-нотацией frontmatter. Ограничение «свойство нельзя переименовать» — нет |
| Статья → Представления и отчеты | частично | Полный набор атрибутов на синтаксис-странице: `display: List/Table/Kanban/Gantt` («пишите всегда, даже для List»), `orderby`, `groupby`, `select`, `hierarchy=none`; для Gantt первые два свойства в `select` — даты начала и окончания. writer описывает только `defs`/`groupby`/`display="List"`; трактовка `defs` расходится — см. §4 |
| Статья → История статьи, Ширина статьи | не покрыт | — |
| Хранилище (7 стр.) | не покрыт | Файловые следы в каталоге: `.gitattributes` рядом с `.doc-root.yaml` (LFS-паттерны, страница `storage/git-lfs`) и ключ `lfs: {auto, exclude}` в конфигурации (синтаксис-страница); writer не упоминает |
| Совместная работа → Синхронизация, Публикация, Конфликты, Ветки, Ревью и согласование, Ссылка на статью | не покрыт | — |
| Совместная работа → Комментарии | частично | comments-read (отчёты/JSON/сводка, фильтры по автору и ответам) + comments-write (add/reply/edit/delete, `.comments.yaml`, `<comment id>`/`[comment:id]`, `validate_comments.py`) + review-agent (координация ревью). Режим ревью UI (панель, прочитанность, фильтры по датам, «решён») — нет |
| Совместная работа → Экспорт DOCX/PDF (+ шаблоны, + приложение/портал) | не покрыт | — (см. также `deploy/export-ci-cd`) |
| ИИ-агент (4 стр.) | не покрыт | — |
| Поиск (2 стр.) | не покрыт | — |
| Разворачивание → GES (20 стр.) | не покрыт | — |
| Разворачивание → Портал документации (17 стр.) | не покрыт | — |
| Разворачивание → Браузерная версия на своём сервере, ИИ в Open Source, Экспорт в CI/CD | не покрыт | — |
| Что нового | не покрыт | — (release notes; не функциональная область) |

## 3. Непокрытые области — фактические scope-заметки

Пути — относительно `https://gram.ax/resources/docs/`.

| Область (пути) | Scope-заметка — что задокументировано |
|---|---|
| Элементы и поля полного синтаксиса вне writer (`article/editor/syntax`) | Полный текст страницы (второй проход) документирует как исходный формат то, чего в writer нет: элементы `<gallery view="carousel">`, инлайн-скрытый фрагмент `<cut text expanded>`, `<fragment>`/`<fragment-link>` (writer — `<snippet>`), `<property id value />`-привязка вкладок к фильтру каталога, `<inline-property bind="assignee" />` (значение свойства в тексте), `<question>`/`<questionAnswer>` + frontmatter `quiz`; атрибуты `<view>` (`orderby`, `select`, `hierarchy=none`, `display` List/Table/Kanban/Gantt), `aggregation` (sum/avg/min/max/count/countDistinct) и `sort` (asc/desc) в ячейках первой строки `<table>`, `header="row/column/both/none"`, `colspan`/`rowspan`/`align`, `{width}` в шапке; inline-блоки ` ```mermaid ` и ` ```plant-uml ` с `{title, scale, float}`, `<plant-uml path>`, `<bpmn path>`; frontmatter-поля `description`, `searchPhrases`, `aliases`, `hidden`, `expanded` (`_index.md` — свернуть раздел), `template`, `quiz`; `orderAsc: false` в `_index.md` (сортировка по убыванию); якоря заголовков `{#install}`; тире пишется как `--`, перенос строки — `\` в конце строки, экранирование `\$`, `\[note]`; свои иконки `.icons/<code>.svg`; блок кода — только полные имена языков highlight.js, обёртка в четыре кавычки; HTML-компонент — изолированный фрейм, только встроенные `<script>`/`<style>` и `data:`-картинки, тёмная тема через `html[data-theme="dark"]`; комментарии `<!-- … -->` видны только в файле; раздел «чего нет в синтаксисе» (нет `===`-заголовков, сносок, `==выделения==`, авто-ссылок) |
| Разворачивание GES (`deploy/gramax-enterprise-server/*`) | Требования (лицензия, `registry.gram.ax`, GitLab, домены); установка Docker Compose (сервисы: caddy, enterprise, docportal, GitLab, опц. ИИ-сервис и Qdrant) и Helm (chart, секреты, ресурсы); режим Readonly; SSO (`AUTH_METHOD`: azure/adfs/keycloak/openid/ldap/kerberos; `CONNECTOR_TYPE`: ldap/keycloak/scim/azure; callback `/sso/cb`); первый запуск (автосоздание 7 YAML-файлов настроек, владельцы из `GES_ADMIN_EMAILS`); настройка (PostgreSQL, ИИ-функции, логирование default/cef в Seq/Elasticsearch, GitLab-проект общих материалов); обслуживание (обновления с автомиграциями БД, бэкапы, healthcheck `HEALTHCHECK_TOKEN`, Prometheus `/metrics`, подпись образов); сводная статья переменных (включая `DIAGRAM_RENDERER_SERVICE_URL`) |
| Портал документации (`deploy/doc-portal/*`, 17 стр.) | Установка Docker/Helm/статическим сайтом через `gramax-cli`; панель `/admin`; обновление контента по расписанию (`AUTO_PULL_*`), webhook (GitHub/GitLab-форматы) и по API с токеном `…/api/user/token`; логотип/переход; индексация (sitemap.xml/robots.txt, `DISABLE_SEO`); веб-аналитика (Matomo и др.); CSS; `workspace.yaml` на портале; шаблоны экспорта; публикация в облако («не развивается») |
| Браузерная версия на своём сервере (`deploy/web-editor-on-own-server`) | Образы `gramax/editor` и `gramax/git-proxy`; docker-compose; переменные `PORT`, `GIT_PROXY_SERVICE_URL`, `ALLOWED_GRAMAX_URLS`; вариант Podman |
| ИИ в Open Source (`deploy/ai-open-source`) | Отдельные ИИ-серверы `gramax/docportal-ai` (эмбеддинги, векторная база Qdrant, чат-модель) и `gramax/editor-ai`; docker-compose примеры; требуется OpenAI-совместимый сервер моделей |
| Экспорт в CI/CD (`deploy/export-ci-cd`) | `npx gramax-cli export -f docx\|pdf` как стадия `.gitlab-ci.yml`; `EXPORT_FILE_PATH`; шаблоны |
| Администрирование пространства (`space/*`) | Панель администрирования: пользователи и лицензии (лицензия только редакторам), собственные группы, внешние читатели (одноразовые коды, свой SMTP), отображение каталогов, CSS-стили, группировка каталогов (разделы/папки/Избранное), виджеты главной |
| Проверки по стайлгайду (`space/styleguide`) | Правила двух типов: LanguageTool (XML) и LLM (текстовый промпт); хранятся на сервере (панель администрирования), обмен — файлом настроек `LanguageToolRules.json` (экспорт/импорт); внешний сервис Gramax Check; требуют настроенного ИИ-сервиса |
| Модуль метрик (`space/module-metrics/*`) | Включение в панели; PostgreSQL; отчёты «История посещений» (просмотры, визиты, уникальные посетители) и «Поисковые запросы» (запросы, уникальные пользователи, CTR) |
| Модуль обучения (`space/module-training/*`, 7 стр.) | Авторская сторона — вопрос-блок в исходнике статьи: `<question id="q1" type="one" required="true">…<questionAnswer answerId="a1" correct="true">…</questionAnswer></question>`; имена тегов с заглавной буквой в середине (`questionAnswer`, `questionColumn`); типы `one, many, select, text, date, user, number, slider, scale, rating, ranking, matrix`; `correct="true"`, условие показа `showIf="a1,a2"`. Режим тест/опрос и прохождение — frontmatter статьи `quiz`: `mode` (`test` \| `survey`), `showAnswers`, `canRetake`, `shuffleQuestions`, `countOfCorrectAnswers`. Разметку приводит только `article/editor/syntax`; страницы модуля описывают UI («Инструменты → Блок вопроса», секция «Тип» в тулбаре, «условия показа» по ответам выше). Результаты — только серверные: панель администрирования GES (таблица с почтой/версией теста/датой, разбор ответов), требует PostgreSQL и включённого модуля; рассылка — письма через почтовый сервер GES, сами ответы в письмо не попадают |
| Уведомления (`space/notifications`) | Настройка на статью (пункт меню «Настроить уведомления»): условия отправки, группы/пользователи; требует «Основную ветку» в настройках доступа каталога; уведомления приходят в ленту на портале после слияния в основную ветку. Где хранится настройка (файл каталога или сервер) — на выкачанных страницах не раскрыто |
| Хранилище (`storage/*`, 7 стр.) | Подключение GitLab (14+), GitHub, GitVerse, Gitea, прочих (Bitbucket, Gogs, GitFlic) по URL+токену; права токенов; Git LFS: паттерны настраиваются на каталог (вкладка «Git LFS» в настройках) или на пространство, файл `.gitattributes` рядом с `.doc-root.yaml` определяет отслеживаемые файлы; `lfs: {auto, exclude}` в `.doc-root.yaml` (синтаксис-страница) |
| Git-совместная работа (`collaboration/{sync, publish, resolve-conflicts, branches, merge-request, review-link}`) | Синхронизация и публикация через кнопки UI (git pull / commit+push, выбор статей, автокомментарий), интерактивное решение конфликтов в статье, ветки, ревью и согласование (утверждающие с ролью публикаций), share-ссылки на статью/каталог |
| Экспорт в приложении и на портале (`collaboration/export-docx-pdf/*`) | Выгрузка статьи/раздела/каталога в DOCX и PDF; шаблон PDF — CSS-файл с классами (`.page`, `.title-page`, колонтитулы); шаблон DOCX — `.docx`/`.dotx` в Word; загрузка шаблонов на портал в `assets/pdf`/`assets/word` |
| ИИ-агент (`agent/*`, 4 стр.) | Включение (облако — AI-кредиты; GES — ИИ-сервис, роль Редактор+); чат (транскрипция аудио, сессии, веб-поиск в десктопе); инструменты (создание/правка/перенос статей, разбор PDF/DOCX/XLSX до 50MB, история коммитов, ветки, откат, HTTP с токенами из «Ключей и паролей»; «закоммитить или опубликовать агент не может»); скиллы — статьи в `.gramax/agent/skills` (+ на пространство) и `.gramax/agent/system-prompt.md`; встроенные скиллы (Диаграммы, Скиллы, Планирование, Календарь CalDAV, Почта IMAP/SMTP) |
| Поиск (`search/*`) | Поиск по тексту в приложении и на портале (точные фразы, фильтры, по вложениям, Ctrl+/); ИИ-поиск на портале по смыслу с учётом таблиц; при подключённом ИИ-сервере |
| Миграция (`catalog/migration/*`) | Импорт из Confluence (облако и сервер по токену) и Notion (десктоп + VPN, таблицы Database); экспорт из Yandex Wiki через Gramax CLI (Node.js 18+); связано с «неподдерживаемыми элементами» проверки на ошибки |
| Версионирование и представления каталога (`catalog/versioning`, `catalog/catalog-view`) | Версии как ветки/теги (glob-паттерны `versions`, переключатель на портале и в редакторе); представление каталога — именованные фильтры, переменные и группировка, хранятся в каталоге по пути `.gramax/views` (страница области); в контенте версия подставляется привязкой `<property id="…" value="…"/>` к вкладкам (синтаксис-страница) |
| История каталога и заметки (`catalog/history`, `catalog/notes`) | Изменения в ветке, открытие каталога на момент ревизии, сравнение двух ревизий; заметки в репозитории, на портале не отображаются; синтаксис-страница связывает личные заметки пользователей с `.gramax/inbox` и состояние ревью с `.gramax/mr` (папки «не редактировать») |
| Мультиязычность (`catalog/multilanguage`) | Основной и дополнительные языки (20); переводы статей в папках с кодом языка; основной язык меняется только в конфигурации |
| Шаблоны и поисковые фразы (`article/templates`, `article/search-phrases`) | Шаблоны — файлы `.gramax/templates/<id>.md`; статья с frontmatter `template: <id>` текста в файле не хранит (синтаксис-страница запрещает агентам править такой текст, менять можно только `properties`); шаблоны бывают и на уровне пространства; статью по шаблону нельзя перенести в другой каталог. Поисковые фразы — frontmatter `searchPhrases:` (список); поднимают статью в поиске по тексту, регистр не важен, срабатывание по части слова |
| URL, история, ширина, типографика (`article/{url, change-history, article-width}`, `article/editor/other-elements/typography`) | URL = путь файла (переименование пишет старый адрес в `aliases` — из `article/editor/syntax`); история статьи с подсветкой правок; ширина колонки — настройка клиента, в файл не пишется; автозамены при наборе (тире, стрелки, валюты, математика) |
| Первые шаги и приложение (`quick-start/*`, `app/*`) | Вход (облако/GES/без аккаунта), создание и публикация первого каталога, выдача доступов; настройки приложения (тема, сжатие в WEBP, автообновление, диагностика, сравнение), десктопная и браузерная версии |

## 4. Факты о пересечениях (без оценки)

| Факт | Содержание |
|---|---|
| Официальные скиллы из docs | Страница `article/editor/syntax` распространяет архив `gramax-skills.zip` с двумя готовыми скиллами для Claude Code (`gramax-catalog-structure.md` — структура каталога; `gramax-article-syntax.md` — синтаксис статьи) с инструкцией положить их в `.claude/skills/{имя}/SKILL.md` репозитория каталога; в конце страницы — «Чек-лист для скилла» и раздел «Что агенту не трогать» (`<comment id>`, `*.comments.yaml`, `.gramax/mr`, `.gramax/inbox`, текст статей с полем `template`, указатели Git LFS). Тематически та же зона, что навык `writer` плагина |
| Frontmatter статьи: полный состав | По синтаксис-странице поля: `title`, `order`, `description` (для поиска и превью; без него берётся начало текста), `properties` (`id` + `value`), `searchPhrases`, `aliases`, `hidden`, `expanded` (`_index.md`), `template`, `quiz`. Неизвестное свойство сохраняется как есть; служебные `welcome`, `external`, `shouldBeCreated` — «не пишите». writer документирует только `order`/`title`/`properties` |
| Правка legacy-форм при сохранении | Синтаксис-страница: «старые формы» — `[note:tip]`, `:::tip`, `{% note %}`, блочный `<cut>`, `<br>`, `<kbd>Ctrl</kbd>` — читаются, но при сохранении редактор переписывает их в канон; YAML-комментарии пропадают, свойства переписываются заново. writer (`references/blocks.md`) документирует `:::info`-admonitions как валидный контент без оговорки о переписывании |
| Механика скиллов ИИ-агента | Скиллы встроенного агента — статьи в `.gramax/agent/skills`; агент «запускать команды и скрипты не умеет» (`agent/tools`, `agent/skills`). Навыки плагина исполняются в Claude Code с `uv run`-скриптами — механика исполнения разная |
| Серверный рендер диаграмм в GES | В переменных окружения GES есть `DIAGRAM_RENDERER_SERVICE_URL` — отдельный сервис рендеринга диаграмм. Навык `drawio` плагина требует локальный draw.io desktop |
| Список видео-хостингов и атрибуты | writer: mp4/webm/ogg, YouTube (расширенно), Rutube, Google Drive, Instagram. Синтаксис-страница: то же плюс Dropbox, Mega, «любая ссылка со словом embed», атрибуты `title`, `scale`, `cover`; страница `article/editor/video` называет YouTube/Rutube/Google Drive/Dropbox/Mega. В writer Dropbox/Mega/embed-any/cover отсутствуют |
| Нейминг фрагментов | docs (синтаксис-страница): `.gramax/fragments/<id>.md`, теги `<fragment id="…"/>` и `<fragment-link id>текст</fragment-link>`. writer (`blocks.md`): `<snippet id="…"/>` из `.gramax/snippets/`. Термин «snippets» в выкачанных docs не встречается; какая форма поддерживается текущим движком — не устанавливалось |
| Семантика `defs` у `<view>` | writer: «`defs="<property>=<v1>&<v2>&none"` — фильтр по property; `none` означает "и статьи без значения"». Синтаксис-страница: «В defs перечисляются значения, которые нужно скрыть» — `status=done` убирает статьи со статусом `done`, `свойство=none` скрывает статьи без свойства; плюс атрибуты `orderby`/`select`/`hierarchy=none`, которых в writer нет |
| Формы ссылок на статьи | writer: внутренние ссылки «без `.md`» (каноническая форма, FR-080/ADR-0016). Синтаксис-страница: «Путь к статье — относительно текущего файла и с расширением `.md`», примеры `[текст](./other.md)`. Валидатор W032 резолвит обе формы; позиция синтаксис-страницы против правила writer напрямую не проговорена |
| width/height/scale картинок | writer: `![](…){width=800 height=450}` как размер отображения. Синтаксис-страница: `width`/`height` — «реальный размер файла в пикселях» (резервирование места), ширина на странице — отдельный `scale=476px` |
| Скобочные токены vs теги | Страницы элементов дают `[cmd:Это кнопка]`, `[kbd:Ctrl+Z]`, `[color:#FF0000]…[/color]`; синтаксис-страница — `<cmd text="…" icon="…" />`, `<kbd text="Ctrl+S" />`, `<color color="#D32F2F">…</color>`. writer документирует только скобочные формы; статус скобочных токенов в классификации «старых форм» синтаксис-страницы не определён |
| Inline-диаграммы | Синтаксис-страница документирует блоки ` ```mermaid ` и ` ```plant-uml ` (с `{title, scale, float}`) как текущую форму наряду с файлами (`.mermaid`, `.puml`, `.bpmn`, `.svg`). Навык `mermaid` считает любой inline-блок устаревшим форматом и предлагает миграцию на file-based |
| Схема `.doc-root.yaml` | Синтаксис-страница: `syntax` принимает `XML`/`Legacy`/`GitHub Flavored Markdown` (writer: `XML`/`Markdown`); палитра `style` — 20 значений с двухцветными (`blue-pink`, `orange-red`…; writer: 11); `properties` с ключом `id` (writer — `name`-нотация frontmatter и определение без `id`); `filterProperty` — одиночный id (writer: `filterProperties` — список имён); вне writer: `logo_dark`, `lfs`, `hidden`, `orderAsc`, пример с `versions`/`relatedLinks` |
| Типы свойств (исходные имена) | Синтаксис-страница: `Flag`, `Enum`, `Many`, `Text`, `Numeric`, `Date` + `options.docportalVisible`; `article/properties` называет их по-русски (Числовой, Флаг, Один/Несколько из списка, Дата, Текст). writer: `Enum`/`String` (+экспериментальный `select`) |
| Модель комментариев | docs (`collaboration/comments`): привязка к выделенному фрагменту, ответы, пометка «решён» — файловая модель (`<comment id>` в md + `.comments.yaml`) воспроизведена в comments-read/comments-write |

## 5. Источники

| Источник | Детали |
|---|---|
| Сайт документации | `https://gram.ax/resources/docs/?view=enterprise-server` (точка входа enterprise-server view); общий корень `https://gram.ax/resources/docs/` |
| Sitemap | `https://gram.ax/resources/api/sitemap/docs` — 163 русских URL + зеркало `/docs/en/…` |
| Выкачка | Все 163 русских страниц каталога выкачаны 2026-11-18 (SSR-HTML, текст извлечён); URL каждой области — в инвентаре (§1). Пометок «not fetched» нет; английское зеркало не использовалось; `https://github.com/Gram-ax/gramax` не понадобился |
| Дерево навигации | Снято из SSR-HTML `https://gram.ax/resources/docs/deploy/gramax-enterprise-server` и из рендера страницы с параметром view |
| Локальные входы | `plugins/gramax/skills/{comments-read, comments-write, drawio, mermaid, writer}/SKILL.md`; `plugins/gramax/skills/writer/references/{blocks, doc-root-schema}.md`; `plugins/gramax/agents/review-agent.md`; `plugins/gramax/.claude-plugin/plugin.json` (4.6.0); `plugins/gramax/CHANGELOG.md` |
| Смежное | RES-006 (`2026-11-18-gramax-engine-window-jul-sep.md`) — окно движка jul→sep 2026, источник формулировок writer про видео и `${key.field}` |
| Уверенность | Высокая: утверждения о docs — на прямо выкачанном тексте страниц; о покрытии — на полном тексте SKILL.md и справочников плагина 4.6.0 |
