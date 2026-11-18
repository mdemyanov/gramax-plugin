# Справочник PlantUML / Salt / BPMN (Camunda XML)

Справочник навыка `gramax:plantuml`. Загружается при затруднениях — не при каждом вызове
(токен-бюджет: ядро контракта живёт в `SKILL.md`, здесь только синтаксис и каркасы).

Ground truth: документация движка Gramax (страница `article/editor/diagrams` и страница
полного синтаксиса) — рендер выполняет движок; навык только авторит текстовые исходники.

## Каркас PlantUML

```
@startuml
<тело диаграммы>
@enduml
```

- Файл — `.puml`, имя `<page-slug>-<diagram-slug>.puml`, рядом со статьёй.
- Внутри файла только чистый PlantUML: без тега `<plant-uml`, без fenced-блока
  `plant-uml`, без frontmatter.
- Salt-макеты живут в том же контуре: `@startsalt`/`@endsalt` в `.puml`-файле, вставка
  штатным тегом `<plant-uml path="…"/>`.

## Типы диаграмм (каркасы)

### Component (компоненты)

```
@startuml
package "Сервис" {
  [API]
  [Auth]
}
[API] --> [Auth] : проверяет токен
@enduml
```

### Deployment (развертывание)

```
@startuml
node "Кластер" {
  node "Pod 1" as p1
  node "Pod 2" as p2
}
database "БД" as db
p1 --> db
p2 --> db
@enduml
```

### Activity (активности)

```
@startuml
start
:Получить запрос;
if (Токен валиден?) then (да)
  :Отдать данные;
else (нет)
  :401;
endif
stop
@enduml
```

### Sequence (последовательность)

```
@startuml
actor User
participant "Frontend" as fe
participant "API" as api
User -> fe: клик
fe -> api: запрос
api --> fe: ответ
@enduml
```

### Timing (таймлайн)

```
@startuml
robust "Сервис" as svc
svc is "в работе" during 0..10
svc is "в обслуживании" during 11..15
@enduml
```

### State (состояния) и Use Case

```
@startuml
[*] -> Черновик
Чновик -> Опубликован : паблиш
Опубликован -> [*]
@enduml
```

```
@startuml
left to right direction
actor Читатель
usecase "Читать статью" as UC1
Читатель --> UC1
@enduml
```

## Salt — нотация макетов интерфейсов

Каркас: `@startsalt`/`@endsalt` в том же `.puml`-файле (отдельного файла и отдельного
тега вставки для Salt нет).

```
@startsalt
{
  { "Логин" | "Пароль" }
  [Отмена] | [Войти], default
}
@endsalt
```

Элементы:
- `"текст"` — поле ввода; `[Кнопка]` — кнопка; `()` — радиокнопка; `[]` — чекбокс
  (внутри строк таблицы); `X` — закрыть окно; `^Выпадающий список^`; `T` — дерево.
- `{ ... }` — вложенные панели/строки; `--` — горизонтальный разделитель; `|` —
  разделитель колонок.
- Модификатор после имени кнопки: `, default` — кнопка по умолчанию.

## BPMN (Camunda XML) — каркас `.bpmn`

Документированная форма — только файловая (inline-варианта для bpmn в docs движка нет).
Файл — `.bpmn`, имя `<page-slug>-<diagram-slug>.bpmn`, рядом со статьёй; вставка —
тег `<bpmn path="./<имя>.bpmn"/>`.

Минимальный валидный каркас:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
                  xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
                  id="definitions-<slug>"
                  targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="process-<slug>" isExecutable="false">
    <bpmn:startEvent id="Start_1">
      <bpmn:outgoing>Flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:task id="Task_1" name="Шаг">
      <bpmn:incoming>Flow_1</bpmn:incoming>
      <bpmn:outgoing>Flow_2</bpmn:outgoing>
    </bpmn:task>
    <bpmn:endEvent id="End_1">
      <bpmn:incoming>Flow_2</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_1" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_1" targetRef="End_1"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Diagram_1">
    <bpmndi:BPMNPlane id="Plane_1" bpmnElement="process-<slug>">
      <bpmndi:BPMNShape id="Start_1_di" bpmnElement="Start_1">
        <dc:Bounds x="160" y="100" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_1_di" bpmnElement="Task_1">
        <dc:Bounds x="250" y="82" width="100" height="80"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="End_1_di" bpmnElement="End_1">
        <dc:Bounds x="400" y="100" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="196" y="118"/>
        <di:waypoint x="250" y="118"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="350" y="118"/>
        <di:waypoint x="400" y="118"/>
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```

Правила:
- Первая строка — `<?xml version="1.0" encoding="UTF-8"?>`; без BOM.
- Корень — `bpmn:definitions`; процесс — `bpmn:process`; элементы связываются
  `sequenceFlow` по `sourceRef`/`targetRef`.
- `bpmndi`-секция (координаты) нужна BPMN-инструментам для раскладки; без неё файл
  остаётся валидным XML BPMN, но открывается без диаграммной раскладки — включай
  минимум координат, как в каркасе.
- Процесс должен оставаться редактируемым в BPMN-инструментах — не выдумывай
  нестандартные атрибуты сверх Camunda-namespace.

## Типовые ошибки

- **Разметка внутри исходника.** В `.puml` попал тег `<plant-uml` или fenced-обёртка —
  движок не отрендерит. Файл содержит только DSL между `@start…`/`@end…`.
- **Незакрытый каркас.** `@startuml` без `@enduml`, `@startsalt` без `@endsalt` — ошибка
  парсера PlantUML.
- **Кавычки в именах Salt.** Строковые значения полей — в кавычках; вложенные кавычки
  внутри значения не экранируются — переформулируй значение.
- **`width`/`height` без спецификатора.** Для тега `<plant-uml>` значения размеров — со
  спецификатором (`800px`); голое число для размеров не задокументировано — не подставляй
  без запроса пользователя.
- **Относительный `path`.** `path` в теге — относительный путь от статьи (`./<имя>.puml`),
  не абсолютный и не с префиксом каталога.
- **Отсутствующий файл.** Тег вставлен, а `.puml`/`.bpmn` не создан или создан в другой
  директории — движок не найдёт ресурс; файл обязан лежать рядом со статьёй.
- **Правка `.bpmn` вне BPMN-инструментов.** Правки `bpmndi`-координат вручную без
  пересчёта `di:waypoint` ломают раскладку стрелок.
