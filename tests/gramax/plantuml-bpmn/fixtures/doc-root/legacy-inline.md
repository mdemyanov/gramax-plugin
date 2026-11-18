---
order: 2
title: "Легаси-inline plant-uml"
---

# Легаси-inline plant-uml

Статья-фикстура с inline-блоком устаревшей формы (кейс AC-061, FR-145:
распознавание inline ```plant-uml с опциями, миграция только по явному
подтверждению пользователя).

```plant-uml {title="Архитектура платежей", scale="1.5", float="right"}
@startuml
User -> System: request
System -> User: response
@enduml
```

Текст статьи после блока. Без подтверждения пользователя файл не меняется
(проверка: содержимое до/после прогона навыка — diff пуст).
