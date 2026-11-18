---
title: "RES-006: Окно обновлений движка Gramax jul→sep 2026 (61408ad9…48592b36) — семантика для навыков"
order: 8
properties:
  - name: Тип контента
    value: [Research]
  - name: Статус
    value: [Active]
  - name: Плагин
    value: [gramax]
---

# RES-006: Окно обновлений движка Gramax jul→sep 2026 (61408ad9…48592b36) — семантика для навыков

**Дата:** 2026-11-18. **Метод:** GitHub API (org `Gram-ax`; сайт gramax.ru мёртв — домен истёк 2024-08, парковка) → blobless-клон → `git diff-tree` по окну `61408ad9` (jun→jul, база знаний плагина 4.5.0) … `48592b36` (jul→sep, 2026-10-06). 2323 файла; docs-релевантные отфильтрованы, патчи ключевых зон прочитаны.

## Находки (с evidence)

1. **`${…}` — подстановка, не формула.** Парсер (`MdParser.ts`) получил явное правило: `$…$` не может открыться или закрыться на `${…}` — «value substitution — a secret placeholder, a shell variable in a command example». Регекс: `(\$[^\$][^\$\r\n]*?\$(?!…\{[^}\r\n]+\}))`.
2. **Новый редакторский элемент «ключи и пароли»:** `${key.field}`, поле ∈ `login|password|token|url` (`elements/secret/edit/logic/secretFields.ts`, `secretFormatter.ts` сериализует обратно в `${NAME.field}`).
3. **`<video>`: YouTube усилен** (`getYoutubeEmbedUrl.ts`, `RenderVideo.tsx`): `youtu.be/ID`, `shorts`, `live`, таймкоды `?t=`/`start=`, плейлисты `list=`; в tauri-десктопе — прокси-страница `gram.ax/embed/youtube.html`. Прямые mp4/webm/ogg, Rutube, Google Drive, Instagram — как прежде.
4. **Ссылка на бессуффиксный существующий файл** (LICENSE, Dockerfile, вложение без суффикса) теперь рендерится как файл-ссылка (скачивание), а не ошибочно как статья — gh#675 (`linkCreator.ts`, ветка `_isExistingFile`).
5. **Таблицы: сортировка в рендере стала численно-десятичной** (`compareCellValues.ts`): «0.1» и «0.03» сравниваются как числа, не по digital-run коллации. UI-поведение, в синтаксис не попадает.
6. **comments getAll на несуществующую статью возвращает `{}`** вместо «Article not found» (`app/commands/elements/comments/getAll.ts`) — семантика app-команды редактора.

Не изменились: mermaid, drawio (в окне путей нет), синтаксис тегов (аннотации — рефакторинг детекта обёрток `<tag>`/`{% tag %}` без семантики), табличные синтаксисы (3 формы как прежде).

## Решения (PM, автономно)

- В навык `writer`: находки 1-4 — `references/blocks.md` (§Формулы: правило подстановок + синтаксис `${key.field}`), `SKILL.md` (строка «Видео»; секция ссылок — случай бессуффиксного файла). Находки 5-6 — только в этот digest (нет doc-facing синтаксиса; навыки comments `.comments.yaml`-форматы не читают app-команды).
- Попутно устранены протухшие пост-инверсионные указатели в 3 файлах навыков (`SKILL.md:229` «в этом репозитории — content», `doc-root-schema.md:125`, ADR-указатели `jurisdiction-and-validation.md`) — хвост миграции ADR-0021, навыки тогда не переезжали.
- Версия плагина 4.5.0 → 4.6.0 (Minor, ADR-0006; прецедент: 4.2.0 «правила писателя»).

## Упоминание

- Валидатор плагина приёмки ссылок из резерва: SKILL-изменения не задевают пины plugin-contract (ac-003 → drawio.md, ac-005 → mermaid SKILL) — проверено `--full` после правок.
