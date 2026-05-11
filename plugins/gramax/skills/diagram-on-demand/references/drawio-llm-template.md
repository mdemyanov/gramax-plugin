# Drawio XML Template для LLM-генерации

## Минимальный валидный mxfile

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" version="24.3.1">
  <diagram id="diagram-id" name="Page-1">
    <mxGraphModel pageWidth="800" pageHeight="600">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="2" value="Label" style="rounded=1;" vertex="1" parent="1">
          <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Обязательная структура

- Корневой элемент: `<mxfile>`
- Внутри: один `<diagram>` с атрибутами `id` и `name`
- Внутри diagram: `<mxGraphModel>` с `pageWidth` и `pageHeight`
- Внутри root: `<mxCell id="0"/>` и `<mxCell id="1" parent="0"/>` (обязательные служебные ячейки)
- Контент: `mxCell` с атрибутами `vertex="1"` или `edge="1"`

## Стили элементов

- Прямоугольник: `style="rounded=0;"`
- Скруглённый: `style="rounded=1;"`
- Ромб: `style="rhombus;"`
- Эллипс: `style="ellipse;"`
- Стрелка: `edge="1"` с `source` и `target` атрибутами, `<mxGeometry relative="1" as="geometry"/>`

## Требования к валидности (AC-012)

Файл должен проходить `python3 -c "import xml.etree.ElementTree as ET; ET.parse('<name>.drawio')"` без ошибок.
Кириллица в атрибуте `value` допустима — `drawio_convert.py` корректно её обрабатывает.
