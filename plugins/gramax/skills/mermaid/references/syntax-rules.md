# Mermaid: справочник синтаксиса для Gramax

Расширенный справочник правил, edge cases и troubleshooting для mermaid-диаграмм в Gramax-каталогах. Загружай при ошибках парсера или нестандартных кейсах.

Адаптировано из [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) (MIT). Платформозависимые секции (Obsidian) заменены на Gramax.

## Оглавление

1. [Предотвращение критических ошибок](#предотвращение-критических-ошибок)
2. [Синтаксис нод](#синтаксис-нод)
3. [Синтаксис subgraph](#синтаксис-subgraph)
4. [Стрелки и связи](#стрелки-и-связи)
5. [Стили и цвета](#стили-и-цвета)
6. [Направление лейаута](#направление-лейаута)
7. [Advanced паттерны](#advanced-паттерны)
8. [Troubleshooting](#troubleshooting)
9. [Особенности Gramax](#особенности-gramax)

## Предотвращение критических ошибок

### Конфликт с list-syntax (самая частая)

**Проблема:** парсер интерпретирует `число. пробел` как Markdown-список.

**Сообщение:** `Parse error: Unsupported markdown: list`

**Решения:**

```
❌ [1. Восприятие]
❌ [2. Планирование]
❌ [3. Рассуждение]

✅ [1.Восприятие]           # без пробела после точки
✅ [① Восприятие]           # circled-number
✅ [(1) Восприятие]         # скобки
✅ [Шаг 1: Восприятие]      # префикс
✅ [Шаг 1 - Восприятие]     # дефис
✅ [Восприятие]             # без нумерации
```

Circled-numbers reference:
```
① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳
```

### Subgraph naming

**Правило:** subgraph с пробелами в имени требует формат `id["display name"]`.

```
❌ subgraph Основной процесс
     A --> B
   end

✅ subgraph core["Основной процесс"]
     A --> B
   end

✅ subgraph osnovnoy_process
     A --> B
   end
```

**Ссылка на subgraph:**
```
❌ Title --> Основной процесс      # display-имя не работает
✅ Title --> core                  # только ID
```

### Node references

**Правило:** ссылка на ноду — всегда по ID, никогда по тексту.

```
A[Текст A]
B["Текст B"]

✅ A --> B
❌ Текст A --> Текст B
```

## Синтаксис нод

### Базовые формы

```
A[Прямоугольник]
B(Скруглённый)
C([Stadium])
D((Круг<br/>Перенос))
E>Стрелка справа]
F{Решение?}
G{{Шестиугольник}}
H[/Параллелограмм/]
I[(База данных)]
J[/Трапеция\]
```

### Правила текста ноды

**Переносы:**
- `<br/>` работает только в круглых нодах: `((Текст<br/>Перенос))`
- В остальных — используй отдельные ноды-аннотации или укорачивай текст

**Спецсимволы:**
- Пробелы → оборачивай в кавычки: `["Текст с пробелами"]`
- Кавычки `"` → заменяй на `『』` или избегай
- Скобки `()` → заменяй на `「」` или избегай
- Двоеточия — обычно безопасны
- Дефисы — безопасны

**Длина:**
- До 50 символов в ноде
- Длиннее — отдельные ноды-аннотации или круглые ноды с `<br/>`
- Разбивай на несколько нод если текст слишком длинный

## Синтаксис subgraph

### Базовая структура

```
flowchart TB
    subgraph id["Имя для отображения"]
        direction TB
        A --> B
    end

    subgraph simple
        C --> D
    end

    subgraph horiz["Горизонтальный"]
        direction LR
        E --> F
    end
```

### Вложенные subgraph

```
flowchart TB
    subgraph outer["Внешняя группа"]
        direction TB

        subgraph inner1["Внутренняя 1"]
            A --> B
        end

        subgraph inner2["Внутренняя 2"]
            C --> D
        end

        inner1 -.-> inner2
    end
```

**Ограничение:** не более 2 уровней вложенности — иначе нечитаемо.

### Соединение subgraph

```
flowchart TB
    subgraph g1["Группа 1"]
        A[Нода A]
    end

    subgraph g2["Группа 2"]
        B[Нода B]
    end

    A --> B           # соединение нод (рекомендуется)
    g1 -.-> g2        # соединение subgraph (невидимая связь для лейаута)
```

## Стрелки и связи

### Базовые

```
A --> B          # сплошная
A -.-> B         # пунктирная
A ==> B          # жирная
A ~~~ B          # невидимая (только для лейаута)
```

### Стрелки с лейблами

```
A -->|Текст лейбла| B
A -.->|Опционально| B
A ==>|Важно| B
```

### Multi-target

```
A --> B & C & D       # один ко многим
A & B & C --> D       # многие к одному
A --> B --> C --> D   # цепочка
```

### Двунаправленные

```
A <--> B
A <-.-> B
```

## Стили и цвета

### Inline-стиль

```
style NodeID fill:#color,stroke:#color,stroke-width:2px
```

### Формат цветов

- Hex: `#ff0000` или `#f00`
- RGB: `rgb(255,0,0)`
- Имена: `red`, `blue` (поддержка ограничена)

### Типовые паттерны

```
# Professional
style A fill:#d3f9d8,stroke:#2f9e44,stroke-width:2px

# Акцент
style B fill:#ffe3e3,stroke:#c92a2a,stroke-width:3px

# Приглушённый
style C fill:#f8f9fa,stroke:#dee2e6,stroke-width:1px

# Заголовок
style D fill:#1971c2,stroke:#1971c2,stroke-width:3px,color:#ffffff
```

### Стиль на несколько нод

```
style A,B,C fill:#d3f9d8,stroke:#2f9e44,stroke-width:2px
```

## Направление лейаута

```
flowchart TB    # top→bottom (вертикаль)
flowchart BT    # bottom→top
flowchart LR    # left→right (горизонталь, для timeline)
flowchart RL    # right→left
flowchart TD    # top down (= TB)
```

Рекомендации:
- **TB/BT** — для последовательных процессов, иерархий
- **LR/RL** — для timeline, широких экранов
- **Mixed** — задавай `direction` внутри subgraph

## Advanced паттерны

### Feedback loop

```
flowchart TB
    A[Старт] --> B[Обработка]
    B --> C[Вывод]
    C -.->|Обратная связь| A

    style A fill:#d3f9d8,stroke:#2f9e44,stroke-width:2px
    style B fill:#e5dbff,stroke:#5f3dc4,stroke-width:2px
    style C fill:#c5f6fa,stroke:#0c8599,stroke-width:2px
```

### Swimlane

```
flowchart TB
    subgraph lane1["Полоса 1"]
        A[Шаг 1] --> B[Шаг 2]
    end

    subgraph lane2["Полоса 2"]
        C[Шаг 3] --> D[Шаг 4]
    end

    B --> C
```

### Hub and spoke

```
flowchart TB
    Hub[Центральный узел]

    A[Спица 1] --> Hub
    B[Спица 2] --> Hub
    C[Спица 3] --> Hub
    Hub --> D[Вывод]
```

### Decision tree

```
flowchart TB
    Start[Старт] --> Decision{Точка решения?}
    Decision -->|Вариант A| PathA[Путь A]
    Decision -->|Вариант B| PathB[Путь B]
    Decision -->|Вариант C| PathC[Путь C]

    PathA --> End[Конец]
    PathB --> End
    PathC --> End
```

### Comparison layout

```
flowchart TB
    Title[Сравнение]

    subgraph left["Система A"]
        A1[Свойство 1]
        A2[Свойство 2]
    end

    subgraph right["Система B"]
        B1[Свойство 1]
        B2[Свойство 2]
    end

    Title --> left
    Title --> right
```

## Troubleshooting

### `Parse error on line X: Expecting 'SEMI', 'NEWLINE', 'EOF'`

**Причины:**
1. Subgraph с пробелами в имени без ID-формата
2. Ссылка на ноду по display-тексту
3. Спецсимволы в тексте ноды

**Решения:**
- `subgraph id["Имя"]`
- Ссылки только по ID
- Оборачивай текст со спецсимволами в кавычки

### `Unsupported markdown: list`

**Причина:** паттерн `число. пробел` в тексте ноды.

**Решение:** убрать пробел или использовать `①`, `(1)`, `Шаг 1:`.

### `Parse error: unexpected character`

**Причины:**
1. Неэкранированные спецсимволы
2. Неправильные кавычки
3. Невалидный синтаксис

**Решения:**
- Заменяй `"` на `『』`, `()` на `「」`
- Используй корректный синтаксис нод
- Проверь стрелки

### Диаграмма не рендерится в Gramax

**Причины:**
1. Используется неподдерживаемый тип (`gitGraph`, `journey`, `requirementDiagram`, `C4Context`)
2. Отсутствуют пустые строки до/после блока
3. Смешанный syntax (XML и Markdown в одном каталоге)

**Решения:**
- Используй один из 8 поддерживаемых типов
- Добавь пустые строки
- Согласуй syntax с `.doc-root.yaml`

### Validation checklist

- [ ] Нет `число. пробел` в тексте нод
- [ ] Subgraph с пробелами в имени → ID-формат
- [ ] Ссылки на ноды по ID, не по display
- [ ] Стрелки валидные (`-->`, `-.->`, `==>`, `~~~`)
- [ ] Стили синтаксически корректны
- [ ] Направление задано явно
- [ ] Нет неэкранированных спецсимволов
- [ ] Все связи ссылаются на определённые ноды

## Особенности Gramax

### `.doc-root.yaml` syntax

- `syntax: XML` → блок `<mermaid>...</mermaid>` (без атрибутов, пустые строки до/после обязательны)
- `syntax: Markdown` → fenced ` ```mermaid ... ``` ` (пустые строки до/после)
- Нельзя смешивать в одном каталоге — выбери один и придерживайся.

### Поддерживаемые типы (Gramax)

`flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap` — 8 типов.

### НЕ поддерживается (рендер падает)

`gitGraph`, `journey`, `requirementDiagram`, `C4Context`. При запросе таких типов предложи альтернативу:
- `C4Context` → `flowchart TB` с подграфами для систем/слоёв
- `gitGraph` → `flowchart LR` со стрелками между коммитами
- `journey` → `flowchart LR` с эмоциональными метками на стрелках

### Quick reference

```
✅ 1.Текст     ✅ ①Текст     ✅ (1)Текст     ✅ Шаг 1:Текст
❌ 1. Текст

✅ subgraph id["Имя"]     ✅ subgraph simple_name
❌ subgraph Имя С Пробелами

✅ NodeID --> AnotherID
❌ "Display Text" --> "Other Text"

✅ 『』 вместо кавычек, 「」 вместо скобок
❌ незаэкранированные " и () в тексте ноды
```
