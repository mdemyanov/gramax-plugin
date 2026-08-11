---
order: 1
title: "Inline tag mention"
properties:
  - name: Тип контента
    value: [Требование]
---

Regression fixture (`check_tags` false positive, found via dogfooding on ADR-0012 and
`2026-08-11-writer-consumer-rules.md`): a Gramax tag named in prose as inline code must
not be counted as an unpaired opening tag.

Тег `<note>` используется для заметок, тег `<tabs>` — для вкладок. Упомянуты дважды каждый
в прозе как имя тега, а не как разметка: `<note>` и `<tabs>`.

А это настоящая, реально сбалансированная пара тегов — должна по-прежнему детектироваться
как парная (регрессия на позитивный случай):

<note>Реальный тег note, открыт и закрыт корректно.</note>
