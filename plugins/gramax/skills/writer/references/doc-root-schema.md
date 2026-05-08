# `.doc-root.yaml` — справочник схемы

Конфигурация каталога Gramax. Лежит в корне (рядом с `.doc-root.yaml` НЕ должно быть `_index.md`).

## Корневые ключи

| Ключ | Тип | Обязательное | Назначение |
|------|-----|--------------|------------|
| `title` | string | да | Заголовок каталога в Gramax UI |
| `description` | string | да | Описание для каталог-листа |
| `language` | string | да | Основной язык (`ru` / `en`) |
| `syntax` | enum | да | `XML` (активирует `<note>`, `<tabs>`, `<view>`) или `Markdown` |
| `code` | string | нет | Короткий идентификатор каталога (для cross-каталожных ссылок) |
| `style` | string | нет | Цвет заголовка каталога. Палитра — та же, что для property-level `style:` (см. ниже). |
| `supportedLanguages` | array | нет | Список поддерживаемых языков; `[]` = без ограничений |
| `properties` | array | нет | Определения property для frontmatter (см. ниже) |
| `filterProperties` | array | нет | Имена property для боковой панели фильтров: `[Тип контента, Фаза]` |
| `editors` | array | нет | Email'ы с правами публикации |

## Property-определение

```yaml
properties:
  - name: <имя property>
    type: <Enum | String>
    style: <цвет бейджа>
    icon: <Lucide-иконка>
    values:
      - <значение 1>
      - <значение 2>
```

| Поле | Обязательное | Назначение |
|------|--------------|------------|
| `name` | да | Имя property; используется в frontmatter статей в `- name: <X>` |
| `type` | да | `Enum` для select из `values:`; `String` для свободного текста |
| `style` | нет | Цвет бейджа в frontmatter и sidebar |
| `icon` | нет | Lucide-иконка рядом с бейджем |
| `values` | для `Enum` | Массив строк — допустимые значения |

## Палитра `style:`

Применяется к двум уровням: к корневому ключу `style:` (цвет заголовка каталога) и к property-level `style:` (цвет бейджа property). Список валидных значений общий.

Подтверждённые валидные значения:

`gray`, `green`, `light-green`, `blue`, `light-blue`, `blue-green`, `purple`, `light-purple`, `orange`, `dark-orange`, `light-pink`

**Рекомендуемая семантика:**

- **categorical** (что это) — `green`, `light-blue`, `purple`
- **lifecycle** (где в цикле) — `light-green`, `dark-orange`
- **priority / attention** — `orange`, `dark-orange`, `light-pink`
- **metadata** (id, технические поля) — `gray`

## Иконки

Любая иконка из набора Lucide (`https://lucide.dev/icons`). Часто используемые:

`hash`, `layers`, `package`, `box`, `folder`, `user`, `users`, `zap`, `briefcase`, `link`, `repeat`, `play`, `target`, `circle-check`, `alert-triangle`, `git-branch`, `file-text`, `check-circle`, `user-check`

## Полный пример

```yaml
title: My Knowledge Base
description: Documentation catalog
language: ru
syntax: XML
style: blue
supportedLanguages: []

properties:
  - name: Тип контента
    type: Enum
    style: green
    icon: file-text
    values:
      - Требование
      - Архитектура
      - ADR

  - name: Статус
    type: Enum
    style: dark-orange
    icon: check-circle
    values:
      - Draft
      - Approved
      - Superseded

filterProperties: [Тип контента]
editors:
  - user@example.com
```

## Антипаттерны

### `required:` на property

Не используется на практике. Gramax не делает с ним ничего полезного — пропускать.

### `type: select` с `values: [{name: X}]`

Экспериментальный синтаксис, не рекомендуется. Использовать `type: Enum` со строковым массивом `values:`.
